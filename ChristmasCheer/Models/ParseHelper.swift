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
    
    class func returnCheer(notification: Notification, completion: Result<ChristmasCheerNotification> -> Void) {
        ChristmasCheerNotification.fetchWithNotification(notification) { result in
            switch result {
            case let .Success(originalNote):
                ParseHelper.returnCheer(originalNote, completion: completion)
            case .Failure(let error):
                completion(.Failure(error))
            }
        }
    }
    
    class func returnCheer(originalNote: ChristmasCheerNotification, completion: Result<ChristmasCheerNotification> -> Void) {
        var params = baseNotificationParams()
        params["originalNoteId"] = originalNote.objectId

        Qu.Background {
            let result: Result<ChristmasCheerNotification>
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
    
    class func fetchNotifications(completion: Result<[ChristmasCheerNotification]> -> Void) {
        guard
            let query = ChristmasCheerNotification.query(),
            let installationId = PFInstallation.currentInstallation().objectId
            else {
                let error = ParseError.Unknown("Unable to create notification query")
                completion(.Failure(error))
                return
            }
        
        query.whereKey("toInstallationId", equalTo: installationId)
        query.limit = 1000
        query.orderByDescending("createdAt")
        query.cachePolicy = .NetworkElseCache
        
        Qu.Background {
            let result: Result<[ChristmasCheerNotification]>
            do {
                result = .Success(try query.findObjects())
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                completion(result)
            }
        }
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
    func findObjects<T : PFObject>() throws -> [T] {
        guard let objects = try findObjects() as? [T] else {
            throw ParseError.FailedQuery("Unable to cast to type: \([T].self)")
        }
        return objects
    }
}
