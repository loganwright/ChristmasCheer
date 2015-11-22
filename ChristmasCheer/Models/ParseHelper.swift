//
//  ParseHelper.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/22/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import AVFoundation
import Parse

enum ParseError : ErrorType {
    case FailedQuery(String)
    case Unknown(String)
    case UnableToConvertToData(String)
}

enum Result<T> {
    case Success(T)
    case Failure(ErrorType)
}

struct CheerPair {
    let initiator: Cheer
    let response: Cheer?
}

final class ParseHelper {
    
    class func sendRandomCheer(completion: Result<Void> -> Void) {
        let params: [String : String] = self.baseNotificationParams()
        Qu.Background {
            let result: Result<Void>
            do {
                let _ = try PFCloud.callFunction("sendRandomCheer", withParameters: params)
                result = .Success()
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                self.playAlertSoundfForResult(result)
                completion(result)
            }
        }
    }
    
    class func returnCheer(notification: Notification, completion: Result<Cheer> -> Void) {
        ChristmasCheerNotification.fetchWithNotification(notification) { result in
            switch result {
            case let .Success(originalNote):
                ParseHelper.returnCheer(originalNote, completion: completion)
            case .Failure(let error):
                completion(.Failure(error))
            }
        }
    }
    
    class func returnCheer(originalNote: Cheer, completion: Result<Cheer> -> Void) {
        var params = baseNotificationParams()
        params["originalNoteId"] = originalNote.objectId
        
        Qu.Background {
            let result: Result<Cheer>
            do {
                let _ = try PFCloud.callFunction("returnCheer", withParameters: params)
                // No need to save, it is mirrored server side.  Just edit locally.
                originalNote.hasBeenRespondedTo = true
                result = .Success(originalNote)
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                self.playAlertSoundfForResult(result)
                completion(result)
            }
        }
    }
    
    class func baseNotificationParams() -> [String : String] {
        var params: [String : String] = [:]
        params["fromUserId"] = ApplicationSettings.userIdentifier
        params["fromInstallationId"] = PFInstallation.currentInstallation().objectId
        params["fromLocation"] = ApplicationSettings.locationName
        params["fromName"] = ApplicationSettings.displayName
        return params
    }
    
    
    class func playAlertSoundfForResult<T>(result: Result<T>) {
        let sound: SoundFile
        switch result {
        case .Success(_):
            sound = FeedbackSounds.SuccessSound
        case .Failure(_):
            sound = FeedbackSounds.ErrorSound
        }
        sound.play()
    }
    
    // MARK: Get Notifications
    
    class func fetchUnreturnedCheer(completion: Result<[Cheer]> -> Void) {
        guard let query = PFQuery.cheerQuery() else {
            let error = ParseError.Unknown("Unable to create cheer query")
            completion(.Failure(error))
            return
        }
        
        query.whereKeyDoesNotExist("initiationNoteId")
        query.whereKey("hasBeenRespondedTo", equalTo: false)
        query.cachePolicy = .CacheThenNetwork
        // Using block method to use cache then network policy
        query.findObjects(completion)
    }
    
    class func fetchNotifications(completion: Result<[Cheer]> -> Void) {
        guard let query = PFQuery.cheerQuery() else {
            let error = ParseError.Unknown("Unable to create cheer query")
            completion(.Failure(error))
            return
        }
        
        query.execute(completion)
    }
    
    class func _fetchNotifications(completion: Result<[CheerPair]> -> Void) {
        guard let query = PFQuery.alt_cheerQuery() else {
            let error = ParseError.Unknown("Unable to create cheer query")
            completion(.Failure(error))
            return
        }
        
        query.execute { (result: Result<[Cheer]>) in
            switch result {
            case let .Success(cheer):
                parseCheer(cheer, completion: completion)
            case let .Failure(error):
                completion(.Failure(error))
            }
            
        }
    }
    
    private class func parseCheer(cheers: [Cheer], completion: Result<[CheerPair]> -> Void) {
        let (initiators, responses) = cheers.splitFilter { $0.isInitiatorCheer }
        
        var responseDictionary: [String : Cheer] = [:]
        responses.forEach { response in
            guard let id = response.initiationNoteId else { return }
            responseDictionary[id] = response
        }

        let pairs = initiators.map { initiator -> CheerPair in
            let currentInitiatorObjectId = initiator.objectId ?? ""
            let first = responseDictionary[currentInitiatorObjectId]
            return CheerPair(initiator: initiator, response: first)
        }
        
        completion(.Success(pairs))
    }
    
    // MARK: Feedback / Support
    
    class func sendFeedback(string: String, completion: Result<Void> -> Void) {
        guard let feedback = feedback(string) else {
            let error = ParseError.UnableToConvertToData("Unable to convert feedback to data!")
            completion(.Failure(error))
            return
        }
        
        Qu.Background {
            let result: Result<Void>
            do {
                try feedback.save()
                result = .Success()
            } catch {
                result = .Failure(error)
            }
            Qu.Main {
                completion(result)
            }
        }
    }
    
    private class func feedback(string: String) -> Feedback? {
        return Feedback(
            feedback: string,
            userId: ApplicationSettings.userIdentifier,
            installationId: ApplicationSettings.installationId,
            name: ApplicationSettings.userIdentifier,
            locationDescription: ApplicationSettings.locationName
        )
    }
    
}

private extension PFQuery {
    static func cheerQuery() -> PFQuery? {
        guard
            let query = ChristmasCheerNotification.query(),
            let installationId = PFInstallation.currentInstallation().objectId
            else {
                return nil
        }
        
        query.whereKey("toInstallationId", equalTo: installationId)
        query.limit = 1000
        query.orderByDescending("createdAt")
        query.cachePolicy = .NetworkElseCache
        return query
    }
    
    static func alt_cheerQuery() -> PFQuery? {
        guard
            let sent = sentCheerQuery(),
            let received = receivedCheerQuery()
            else {
                return nil
        }
        
        let query = PFQuery.orQueryWithSubqueries([sent, received])
        query.limit = 1000
        query.orderByDescending("createdAt")
        query.cachePolicy = .NetworkElseCache
        return query
    }
    
    static func baseCheerQuery() -> PFQuery? {
        guard
            let query = ChristmasCheerNotification.query()
            else {
                return nil
        }
        query.cachePolicy = .NetworkElseCache
        return query
    }
    
    /**
     Sent doesn't inherently mean initiated, this is any cheer that the user returned or intitiated.  When initiated, we only want the ones returned.
     
     - returns: A query for all sent cheer
     */
    static func sentCheerQuery() -> PFQuery? {
        guard
            let query = baseCheerQuery(),
            let installationId = PFInstallation.currentInstallation().objectId
            else {
                return nil
        }
        
        query.whereKey("fromInstallationId", equalTo: installationId)
        query.whereKey("hasBeenRespondedTo", equalTo: true)
        return query
    }
    
    
    /**
     Received cheer doesn't inherently mean initiated.  This is any cheer that was received by the current user.
     
     - returns: all received cheer.
     */
    static func receivedCheerQuery() -> PFQuery? {
        guard
            let query = baseCheerQuery(),
            let installationId = PFInstallation.currentInstallation().objectId
            else {
                return nil
        }
        
        query.whereKey("toInstallationId", equalTo: installationId)
        return query
    }
}

extension ChristmasCheerNotification {
    static func fetchWithNotification(notification: Notification, completion: Result<ChristmasCheerNotification> -> Void) {
        let originalNote = ChristmasCheerNotification()
        originalNote.objectId = notification.originalNoteId
        Qu.Background {
            let result: Result<ChristmasCheerNotification>
            do {
                let fullNote = try originalNote.fetch()
                result = .Success(fullNote)
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                completion(result)
            }
        }
    }
}

extension PFQuery {
    
    func findObjects<T : PFObject>(completion: Result<[T]> -> Void) {
        findObjectsInBackgroundWithBlock { objects, error in
            let result: Result<[T]>
            if let objects = objects as? [T] {
                result = .Success(objects)
            } else if let objects = objects {
                let error = ParseError.Unknown("Expected type: \(T.self) got: \(objects)")
                result = .Failure(error)
            } else if let error = error {
                result = .Failure(error)
            } else {
                let error = ParseError.Unknown("No result or objects for unreturned cheer query")
                result = .Failure(error)
            }
            
            Qu.Main {
                completion(result)
            }
        }
    }
    
    func findObjects<T : PFObject>() throws -> [T] {
        guard let objects = try findObjects() as? [T] else {
            throw ParseError.FailedQuery("Unable to cast to type: \([T].self)")
        }
        return objects
    }
    
    func execute<T : PFObject>(completion: Result<[T]> -> Void) {
        Qu.Background {
            let result: Result<[T]>
            do {
                result = .Success(try self.findObjects())
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                completion(result)
            }
        }
    }
}

extension CollectionType {
    public func splitFilter(@noescape filter: (Generator.Element) throws -> Bool) rethrows -> (passed: [Generator.Element], failed: [Generator.Element]) {
        var passed: [Generator.Element] = []
        var failed: [Generator.Element] = []
        try forEach {
            if try filter($0) {
                passed.append($0)
            } else {
                failed.append($0)
            }
        }
        return (passed, failed)
    }
    
    public func first(@noescape test: (Generator.Element) throws -> Bool) rethrows -> Generator.Element? {
        for element in self where try test(element) {
            return element
        }
        return nil
    }
}

extension Dictionary {
    init(pairs: [(Key, Value)]) {
        self.init()
        pairs.forEach { (key, val) in
            self[key] = val
        }
    }
}
//func + <Key : Hashable, Value>(lhs: [Key : Value], rhs: [Key : Value]) -> [Key : Value] {
//    var combined: [Key : Value] = lhs
//    rhs.forEach {
//        combined[$0] = $1
//    }
//    return combined
//}
