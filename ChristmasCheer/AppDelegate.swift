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
            fatalError("KEYS NOT CONFIGURED")
        }
        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
    }
    
    static func updateOffSeasonStatus() {
        if IS_DEVELOPMENT_TARGET {
            ApplicationSettings.isOffSeason = false
        } else {
            PFConfig.getConfigInBackgroundWithBlock { config, _ in
                guard
                    let config = config,
                    let isOffSeason = config["isOffSeason"] as? Bool
                    else { return }
                ApplicationSettings.isOffSeason = isOffSeason
            }
        }
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
        ensureSessionIsStillValid()
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let homeViewController = HomeViewController()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Parse.configure(launchOptions)
        Parse.updateOffSeasonStatus()
        
        setupWindow()
        setupDevelopmentUI()
        Theme.stylize()
        
        setupCrashlytics()
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
        ApplicationSettings.deviceTokenData = deviceToken
        NotificationManager.hasReceivedNotificationRegistrationPrompt = true
        NotificationManager.didRegisterNotificationSettings()
        
        PFInstallation.currentInstallation().setDeviceTokenFromData(deviceToken)
        PFInstallation.currentInstallation().saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("FAILED TO REGISTER ERROR: \(error)")
        
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
}
