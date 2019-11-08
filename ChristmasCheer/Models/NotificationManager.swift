//
//  NotificationManager.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/26/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
//import Genome
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

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
            let registeredTypes = UIApplication.shared.currentUserNotificationSettings!.types
            if UIUserNotificationType.alert == UIUserNotificationType.alert.intersection(registeredTypes) {
                authStatus = .Authorized
            } else {
                authStatus = .Denied
            }
        }
        return authStatus
    }
    
    static var authorizationStatusUpdated: (AuthorizationStatus) -> Void = { _ in }
    
    class func didRegisterNotificationSettings() {
        authorizationStatusUpdated(authorizationStatus)
    }
    
    class func didFailToRegisterNotificationSettings() {
        authorizationStatusUpdated(authorizationStatus)
    }
    
    
    // MARK: Initial Prompt
    
    private static let NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt = "NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt"
    
    static var hasReceivedNotificationRegistrationPrompt: Bool {
        get {
            return UserDefaults.standard.bool(forKey: NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt)
        }
        set {
            if !newValue {
                fatalError("Can not set `hasReceivedNotificationRegistrationPrompt` to false!")
            }
            UserDefaults.standard.set(newValue, forKey: NotificationManagerDefaultsKeyHasReceivedNotificationRegistrationPrompt)
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: Permissions Request
    
    class func requestRemoteNotificationAuthorization(completion: @escaping (AuthorizationStatus) -> Void) {
        guard !self.hasReceivedNotificationRegistrationPrompt
            || authorizationStatus == .Authorized
            // If the user is already authorized, we call this function multiple times so that we can register new notification types on upgrade
            else {
                completion(authorizationStatus)
                return
            }
        
        authorizationStatusUpdated = completion
        let categories = NotificationCategory.allCategories.compactMap { $0.category }
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories(.init(categories))
        center.getNotificationSettings { settings in
            print(settings.authorizationStatus)
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                if let error = error {
                    print("failed to get notification permissions \(error)")
                }
                guard granted else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
//        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
//            if let error = error {
//                print("failed to get notification permissions \(error)")
//            }
//            guard granted else { return }
//        }
//        let userNotificationTypes: UIUserNotificationType = [
//            .alert,
//            .badge,
//            .sound
//        ]
//        let categories = NotificationCategory.allCategories.flatMap { $0.category }
//        let notificationSettings = UIUserNotificationSettings(
//            types: userNotificationTypes,
//            categories: Set(categories)
//        )
//        UIApplication.shared.registerUserNotificationSettings(1 as! UIUserNotificationSettings)
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("will present \(notification)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("received response \(completionHandler)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        print("open settings for \(notification)")
    }
}

/*
I go between names, but I prefer this

receivedCheer == InitiatorCheer
returnedCheer == ResponseCheer

Initiator and Response is more clear
*/
enum NotificationCategory: String, Codable {
    // These keys are replicated on server, must be updated there, or WILL NOT WORK
    case InitiatorCheer
    case ResponseCheer
    
    static let allCategories: [NotificationCategory] = [.InitiatorCheer, .ResponseCheer]
    
    var category: UNNotificationCategory? {
        switch self {
        case .InitiatorCheer:
            return .init(
                identifier: rawValue,
                actions: [NotificationAction.ReturnCheer.action],
                intentIdentifiers: [],
                options: [])
        case .ResponseCheer:
            return nil
        }
    }
}

enum NotificationAction : String {
    case ReturnCheer
    
    var action: UNNotificationAction {
        switch self {
        case .ReturnCheer:
            return .init(identifier: rawValue, title: "Return Cheer", options: [])
        }
    }
    
    func handleNotification(_ notification: Notification, completion: @escaping () -> Void) {
        switch self {
        case .ReturnCheer:
            ParseHelper.returnCheer(notification) { result in
                switch result {
                case .Success(_):
                    // Success in background, do nothing
                    completion()
                case let .Failure(error):
                    // Failure in background, perhaps in future, schedule local notification for user to try again
                    print("Failed to return cheer via quick action: \(error)")
                    break
                }
            }
        }
    }
}


struct Notification: Codable {
    
    var isResponse: Bool
    var originalNoteId: String
    var aps: Aps
    
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
}

struct Aps: Codable {
    var message: String?
    var sound: NotificationSounds?
    var category: NotificationCategory?
}

extension SCLAlertView {
    static func showNotification(_ notification: Notification) {
        let alert = SCLAlertView()
        if !notification.isResponse {
            alert.addButton("Return The Cheer!") {
                PJProgressHUD.show(withStatus: "Contacting the North Pole ...")
                ParseHelper.returnCheer(notification) { result in
                    switch result {
                    case let .Success(originalNote, response):
                        notifyReturnCheerSendSuccessForName(originalNote.fromName, successMessage: response.message)
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
        todo()
//        present(alert, animated: true, completion: nil)
    }
    
    static func notifyReturnCheerSendSuccessForName(_ toName: String, successMessage: String?) {
        let title = "Sweet!"
        let message = successMessage
            ?? "The elves are delivering your cheer to \(toName) as we speak!  Way to get into the Christmas spirit!"
        let confirmation = "Done!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
        todo()
    }
    
    func showSuccess(_ notification: Notification) {
        showSuccess(notification.title, subTitle: notification.aps.message ?? "", closeButtonTitle: notification.confirmation)
        todo()
    }
}
