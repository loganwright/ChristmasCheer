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
//import Genome

enum ParseError: Error {
    case FailedQuery(String)
    case Unknown(String)
    case UnableToConvertToData(String)
}

enum Result<T> {
    case Success(T)
    case Failure(Error)
}

struct ServerResponse: Codable {
    private(set) var message: String?
    private(set) var isOffSeason: Bool = false
}

final class ParseHelper {
    
    class func sendRandomCheer(_ completion: @escaping (Result<ServerResponse>) -> Void) {
        let params: [String : String] = baseCheerParams()
        Qu.Background {
            let result: Result<ServerResponse>
            do {
                todo()
//                let rawResponse = try PFCloud.callFunction("sendRandomCheer", withParameters: params)
//                let json = rawResponse as? JSON ?? [:]
//                let response = try ServerResponse.mappedInstance(json)
//                result = .Success(response)
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                self.playAlertSoundfForResult(result)
                completion(result)
            }
        }
    }
    
    class func returnCheer(_ notification: Notification, completion: @escaping (Result<(ChristmasCheerNotification, ServerResponse)>) -> Void) {
        ChristmasCheerNotification.fetchWithNotification(notification) { result in
            switch result {
            case let .Success(originalNote):
                ParseHelper.returnCheer(originalNote, completion: completion)
            case .Failure(let error):
                completion(.Failure(error))
            }
        }
    }
    
    class func returnCheer(_ originalNote: ChristmasCheerNotification, completion: @escaping (Result<(ChristmasCheerNotification, ServerResponse)>) -> Void) {
        var params = baseCheerParams()
        params["originalNoteId"] = originalNote.objectId
        
        Qu.Background {
            todo()
//            let result: Result<(originalNote: ChristmasCheerNotification, response: ServerResponse)>
//            do {
//                let rawResponse = try PFCloud.callFunction("returnCheer", withParameters: params)
//                let json = rawResponse as? JSON ?? [:]
//                let response = try ServerResponse.mappedInstance(json)
//                // No need to save, it is mirrored server side.  Just edit locally.
//                originalNote.hasBeenRespondedTo = true
//                result = .Success((originalNote: originalNote, response: response))
//            } catch {
//                result = .Failure(error)
//            }
//
//            Qu.Main {
//                self.playAlertSoundfForResult(result)
//                completion(result)
//            }
        }
    }
    
    class func baseCheerParams() -> [String : String] {
        var params: [String : String] = [:]
        params["fromUserId"] = ApplicationSettings.userIdentifier
        params["fromInstallationId"] = PFInstallation.current()?.objectId ?? "<unknown>"
        params["fromLocation"] = ApplicationSettings.locationName
        params["fromName"] = ApplicationSettings.displayName
        params["appVersion"] = MainBundle.infoDictionary?["\(kCFBundleVersionKey)"] as? String
        return params
    }
    

    class func playAlertSoundfForResult<T>(_ result: Result<T>) {
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
    
    class func fetchUnreturnedCheer(_ completion: @escaping (Result<[ChristmasCheerNotification]>) -> Void) {
        todo()
//        guard let query = PFQuery.cheerQuery() else {
//            let error = ParseError.Unknown("Unable to create cheer query")
//            completion(.Failure(error))
//            return
//        }
//
//        query.whereKeyDoesNotExist("initiationNoteId")
//        query.whereKey("hasBeenRespondedTo", equalTo: false)
//        query.cachePolicy = .cacheThenNetwork
//        // Using block method to use cache then network policy
//        QueryWrapper(query: query).findObjects(completion)
    }
    
    class func fetchNotifications(_ completion: @escaping (Result<[ChristmasCheerNotification]>) -> Void) {
        todo()
//        guard let query = PFQuery.cheerQuery() else {
//            let error = ParseError.Unknown("Unable to create cheer query")
//            completion(.Failure(error))
//            return
//        }
//
//        QueryWrapper(query: query).execute(completion)
    }
    
    // MARK: Feedback / Support
    
    class func sendFeedback(_ string: String, completion: @escaping (Result<Int>) -> Void) {
        guard let feedback = feedback(string) else {
            let error = ParseError.UnableToConvertToData("Unable to convert feedback to data!")
            completion(.Failure(error))
            return
        }
        
        Qu.Background {
            let result: Result<Int>
            do {
                try feedback.save()
                result = .Success(1)
            } catch {
                result = .Failure(error)
            }
            Qu.Main {
                completion(result)
            }
        }
    }
    
    private class func feedback(_ string: String) -> Feedback? {
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
    @objc
    static func cheerQuery() -> PFQuery? {
        guard
            let query = ChristmasCheerNotification.query(),
            let installationId = PFInstallation.current()?.objectId
            else {
                return nil
        }
        
        query.whereKey("toInstallationId", equalTo: installationId)
        query.limit = 1000
        query.order(byDescending: "createdAt")
        query.cachePolicy = .networkElseCache
        return nil
//        return query
    }
}

extension ChristmasCheerNotification {
    static func fetchWithNotification(_ notification: Notification, completion: @escaping (Result<ChristmasCheerNotification>) -> Void) {
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

//struct QueryWrapper<T: PFObject> {
//    let query: PFQuery<T>
//}
//
//extension QueryWrapper {
//    func findObjects<T : PFObject>(_ completion: @escaping (Result<[T]>) -> Void) {
//        query.findObjectsInBackground { objects, error in
//            let result: Result<[T]>
//            if let objects = objects as? [T] {
//                result = .Success(objects)
//            } else if let objects = objects {
//                let error = ParseError.Unknown("Expected type: \(T.self) got: \(objects)")
//                result = .Failure(error)
//            } else if let error = error {
//                result = .Failure(error)
//            } else {
//                let error = ParseError.Unknown("No result or objects for unreturned cheer query")
//                result = .Failure(error)
//            }
//            
//            Qu.Main {
//                completion(result)
//            }
//
//        }
//    }
//
//    func findObjects<T : PFObject>() throws -> [T] {
//        guard let objects = try findObjects() as? [T] else {
//            throw ParseError.FailedQuery("Unable to cast to type: \([T].self)")
//        }
//        return objects
//    }
//
//    func execute<T : PFObject>(_ completion: @escaping (Result<[T]>) -> Void) {
//        Qu.Background {
//            let result: Result<[T]>
//            do {
//                result = .Success(try self.findObjects())
//            } catch {
//                result = .Failure(error)
//            }
//            
//            Qu.Main {
//                completion(result)
//            }
//        }
//    }
//}
