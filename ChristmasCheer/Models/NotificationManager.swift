//
//  NotificationManager.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/26/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Genome

class NotificationManager: NSObject {

    // MARK: Auth Status
    
    enum AuthorizationStatus {
        case Denied, NotYetDetermined, Authorized
    }
    
    class var notificationsAuthorized: Bool {
        return authorizationStatus == .Authorized
    }
    
    class var authorizationStatus: AuthorizationStatus {
        let authStatus: AuthorizationStatus
        if !self.hasReceivedNotificationRegistrationPrompt {
            authStatus = .NotYetDetermined
        } else {
            let registeredTypes = UIApplication.sharedApplication().currentUserNotificationSettings()!.types
            if UIUserNotificationType.Alert == UIUserNotificationType.Alert.intersect(registeredTypes) {
                authStatus = .Authorized
            } else {
                authStatus = .Denied
            }
        }
        return authStatus
    }
    
    static var authorizationStatusUpdated: AuthorizationStatus -> Void = { _ in }
    
    class func didRegisterNotificationSettings() {
        authorizationStatusUpdated(authorizationStatus)
    }
    
    class func didFailToRegisterNotificationSettings() {
        authorizationStatusUpdated(authorizationStatus)
    }
    
    
    // MARK: Initial Prompt
    
    private class var NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt: String {
        get {
            return "NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt"
        }
    }
    
    class var hasReceivedNotificationRegistrationPrompt: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt)
        }
        set {
            if !newValue {
                fatalError("Can not set `hasReceivedNotificationRegistrationPrompt` to false!")
            }
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    // MARK: Permissions Request
    
    class func requestRemoteNotificationAuthorization(completion: AuthorizationStatus -> Void) {
        if !self.hasReceivedNotificationRegistrationPrompt {
            authorizationStatusUpdated = completion
            let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
            let notificationSettings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        } else {
            completion(authorizationStatus)
            print("User already prompted for remote notifications!")
        }
    }
}

struct Notification : BasicMappable {
    
    var isResponse: Bool = false
    var originalNoteId: String = ""
    var aps: Aps!
    
    var title: String {
        if isResponse {
            return "Cheer Returned!"
        } else {
            return "Received Cheer!"
        }
    }
    
    var confirmation: String {
        if isResponse {
            return "Gee, Thanks!"
        } else {
            return "That's Nice!"
        }
    }
    
    mutating func sequence(map: Map) throws {
        try isResponse <~ map["isResponse"]
        try originalNoteId <~ map["originalNoteId"]
        try aps <~ map["aps"]
    }
}

struct Aps : BasicMappable {
    
    var message: String!
    var sound: NotificationSounds?
    
    mutating func sequence(map: Map) throws {
        try message <~ map["alert"]
        try sound <~ map["sound"]
            .transformFromJson {
                NotificationSounds(rawValue: $0)
        }
    }
}

extension SCLAlertView {
    static func showNotification(notification: Notification) {
        let alert = SCLAlertView()
        if !notification.isResponse {
            alert.addButton("Return The Cheer!") {
                PJProgressHUD.showWithStatus("Contacting the North Pole ...")
                ParseHelper.returnCheer(notification) { result in
                    switch result {
                    case .Success(let originalNote):
                        notifyReturnCheerSendSuccessForName(originalNote.fromName)
                    case .Failure(_):
                        notifyReturnCheerSendFailure()
                    }
                    PJProgressHUD.hide()
                }
            }
        }
        
        alert.showSuccess(notification)
    }
    
    static func notifyReturnCheerSendFailure() {
        let title = "Uh Oh!"
        let message = "There was a problem connecting with the workshop, and it looks like we couldn't send your response.  Check your connection and try again in a little bit. "
        let confirmation = "Malarky!"
        let alert = SCLAlertView()
        alert.showError(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    static func notifyReturnCheerSendSuccessForName(toName: String) {
        let title = "Sweet!"
        let message = "The elves are delivering your cheer to \(toName) as we speak!  Way to get into the Christmas spirit!"
        let confirmation = "Done!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    func showSuccess(notification: Notification) {
        showSuccess(notification.title, subTitle: notification.aps.message, closeButtonTitle: notification.confirmation)
    }
}
