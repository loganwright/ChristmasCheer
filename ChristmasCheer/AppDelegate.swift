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
        let navigationController = slidingRootViewController?.slidableNavigationController
        let topVC = navigationController?.topViewController
        switch topVC {
        case let permissionVC as PermissionsRequestViewController:
            permissionVC.ensurePermissionsRequired()
        case let homeVC as HomeViewController:
            homeVC.ensureSessionIsStillValid()
        default: break
        }
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    weak var slidingRootViewController: SlidingMenuRootViewController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Parse.configure(launchOptions)
        Parse.updateOffSeasonStatus()
        
        setupWindow()
        setupDevelopmentUI()
        Theme.stylize()
        return true
    }

    private func setupWindow() {
        let slidingRootViewController = SlidingMenuRootViewController.cc_mainController()
        self.slidingRootViewController = slidingRootViewController

        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.rootViewController = slidingRootViewController
        window.makeKeyAndVisible()
        self.window = window
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
        
        if let open = slidingRootViewController?.menuIsOpen where open {
            slidingRootViewController?.menuViewController?.fetchDataAndReloadTableView()
        }
    }
}
