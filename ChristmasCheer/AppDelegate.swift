//
//  AppDelegate.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/21/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Parse
import Genome

import Fabric
import Crashlytics

var IS_SIMULATOR: Bool = {
    #if arch(i386) || arch(x86_64)
        return true
    #else
        return false
    #endif
}()

let MainBundle = NSBundle.mainBundle()

typealias Application = UIApplication

extension Parse {
    static func configure(launchOptions: [NSObject : AnyObject]?) {
        if IS_DEVELOPMENT_TARGET {
            Parse.setApplicationId("Bb6vmkJpOfJJXnam6Sz1QhrtcIie5KzKgREZccId", clientKey: "RA7rEfXsi9zIC2ylJkOWu9WQ8WsBTLlSClTARSCw")
        } else {
            Parse.setApplicationId("uZwcu9TSxPkYzAANnShydDUrjtMmrLxXCWuSyrEB", clientKey: "Uh13gPzg3vxYvMpYmq25wDbBEq1AJCuuldkxL9Ef")
        }
        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
    }
}

extension Application {
    static func resetBadgeCount() {
        let installation = PFInstallation.currentInstallation()
        guard installation.badge != 0 else { return }
        installation.badge = 0
        installation.saveEventually()
    }
}

private extension AppDelegate {
   
    func setupDevelopmentUI() {
        guard IS_DEVELOPMENT_TARGET else { return }
        let statusBarView = UIView()
        statusBarView.frame = CGRect(x: 0, y: 0, width: CGRectGetWidth(UIScreen.mainScreen().bounds), height: 20)
        statusBarView.backgroundColor = UIColor.orangeColor()
        window?.addSubview(statusBarView)
    }
    
    func updateForActiveState() {
        homeViewController.updateForApplicationActiveState()
    }
    
    func setupCrashlytics() {
        // Production only
        guard !IS_DEVELOPMENT_TARGET else { return }
        Fabric.with([Crashlytics.self])
    }
    
}

private extension HomeViewController {
    func updateForApplicationActiveState() {
        guard checkAndUpdatePresentedControllerIfNecessary() else { return }
        updateSession()
    }
    
    func refreshCheerListIfPossible() {
        guard
            let presentedNav = navigationController?.presentedViewController as? UINavigationController,
            let visible = presentedNav.topViewController as? CheerListViewController
            else { return }
        
        visible.fetchDataAndReloadTableView()
    }
    
    func checkAndUpdatePresentedControllerIfNecessary() -> Bool {
        guard
            let presentedNav = navigationController?.presentedViewController as? UINavigationController,
            let visible = presentedNav.topViewController
            else { return true }
        
        switch visible {
        case let permissionsVC as PermissionsRequestViewController:
            permissionsVC.ensurePermissionsRequired()
            return false
        case let cheerListVC as CheerListViewController:
            cheerListVC.fetchDataAndReloadTableView()
            return false
        default:
            return true
        }
    }
}

extension PFInstallation {
    func saveIfRegisteredForNotifications() {
        /*
        The installation will only save if necessary,
        
        This exists to solve a problem where the user installation fails after registering, so they never receive push notifications because we never save again.
        
        This is necessary until we save somewhere else in the app.  At this point, a user's installation object will never save again.
        
        
        We don't want to save before device token exists because otherwise it will save users before they save.
        */
        guard let _ = deviceToken else { return }
        saveInBackground()
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let homeViewController = HomeViewController()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Parse.configure(launchOptions)
        
        setupWindow()
        setupDevelopmentUI()
        Theme.stylize()
        
        setupCrashlytics()
        
        let installation = PFInstallation.currentInstallation()
        installation.saveIfRegisteredForNotifications()
        
        /**
        *  This will not request authorization unless the user has already approved.
        * 
        *  This is done so that adding notification actions / categories happens automatically for upgrading users
        */
        if NotificationManager.notificationsAuthorized {
            NotificationManager.requestRemoteNotificationAuthorization { _ in }
        }
        return true
    }

    private func setupWindow() {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = NavigationController(rootViewController: self.homeViewController)
        window?.makeKeyAndVisible()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        Application.resetBadgeCount()
        updateForActiveState()
    }
    
    // MARK: Notifications Response
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    // Has Registered
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        PFInstallation.currentInstallation().setDeviceTokenFromData(deviceToken)
        
        ApplicationSettings.deviceTokenData = deviceToken
        
        NotificationManager.hasReceivedNotificationRegistrationPrompt = true
        NotificationManager.didRegisterNotificationSettings()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("FAILED TO REGISTER ERROR: \(error)")
        NotificationManager.didFailToRegisterNotificationSettings()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        guard
            let info = userInfo as? JSON,
            let notification = try? Notification.mappedInstance(info)
            else {
                return
            }
        
        SCLAlertView.showNotification(notification)
        notification.aps.sound?.play()
        
        homeViewController.refreshCheerListIfPossible()
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        guard
            let id = identifier,
            let action = NotificationAction(rawValue: id),
            let info = userInfo as? JSON,
            let notification = try? Notification.mappedInstance(info)
            else {
                completionHandler()
                return
            }
        
        action.handleNotification(notification, completion: completionHandler)
    }
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        guard let shortcut = ApplicationShortcut(rawValue: shortcutItem.type) else {
            completionHandler(false)
            return
        }
        
        switch shortcut {
        case .SendRandomCheer:
            handleSendRandomCheerShortcut(completionHandler)
        }
    }
    
    private func handleSendRandomCheerShortcut(completionHandler: Bool -> Void) {
        /*
        I realize this probably isn't the best way to do this w/ mixing UI and model, but for now, this is the best way I can think of w/o too much time.
        */
        let op = {
            self.homeViewController.sendCheer(completionHandler)
        }
        if homeViewController.presentedViewController != nil {
            homeViewController.dismissViewControllerAnimated(false, completion: op)
        } else {
            homeViewController.sendCheer(completionHandler)
        }
    }
}

enum ApplicationShortcut : String {
    // Defined in .plist
    case SendRandomCheer = "io.loganwright.christmasCheer.sendRandomCheer"
}