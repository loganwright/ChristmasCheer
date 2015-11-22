//
//  ApplicationSettings.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/22/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit

protocol SettingsKeyAccessible {
    var key: String { get }
    var defaults: NSUserDefaults { get }
}

extension SettingsKeyAccessible {
    var defaults: NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    func writeToDefaults(any: AnyObject?) {
        if let any = any {
            defaults.setValue(any, forKey: key)
        } else {
            defaults.removeObjectForKey(key)
        }
        defaults.synchronize()
    }
    
    func readFromDefaults<T>() -> T? {
        return defaults.objectForKey(key) as? T
    }
}

protocol EnumSettingsKeyAccessible : SettingsKeyAccessible {
    var rawValue: String { get }
    init?(rawValue: String)
}

extension EnumSettingsKeyAccessible {
    var key: String {
        return rawValue
    }
}

enum Setting : String, EnumSettingsKeyAccessible {
    case DisplayName = "CCApplicationSettingsDisplayNameKey"
    case LastSentChristmasCheerTimestamp = "CCApplicationSettingsLastSentChristmasCheerTimestampKey"
    case LocationName = "CCApplicationSettingsLocationNameKey"
    case UserIdentifier = "CCApplicationSettingsUserIdentifierKey"
    case DeviceTokenData = "CCApplicationSettingsDeviceTokenDataKey"
}

class ApplicationSettings: NSObject {
    
    static let defaults = NSUserDefaults.standardUserDefaults()
    
    class var hasEnteredName: Bool {
        return displayName != "<unknown>"
    }
    
    class var displayName: String {
        get {
            return Setting.DisplayName.readFromDefaults() ?? "<unknown>"
        }
        set {
            Setting.DisplayName.writeToDefaults(newValue)
        }
    }
    
    class var locationName: String {
        get {
            return Setting.LocationName.readFromDefaults() ?? "North Pole"
        }
        set {
            Setting.LocationName.writeToDefaults(newValue)
        }
    }
 
    class var userIdentifier: String {
        let identifierKey = Setting.UserIdentifier
        let uniqueId: String
        if let currentUserId: String = identifierKey.readFromDefaults() {
            uniqueId = currentUserId
        } else {
            uniqueId = NSUUID().UUIDString
            identifierKey.writeToDefaults(uniqueId)
        }
        return uniqueId
    }
    
    class var lastSentChristmasCheerTimestamp: NSDate? {
        get {
            return Setting.LastSentChristmasCheerTimestamp.readFromDefaults()
        }
        set {
            Setting.LastSentChristmasCheerTimestamp.writeToDefaults(newValue)
        }
    }

    class var timeSinceLastSentChristmasCheerTimestamp: NSTimeInterval {
        guard let last = lastSentChristmasCheerTimestamp?.timeIntervalSince1970 else { return 0 }
        let now = NSDate().timeIntervalSince1970
        return now - last
    }
    
    class var canSendChristmasCheer: Bool {
        if IS_DEVELOPMENT_TARGET {
            return true
        }
        
        if let timestamp = lastSentChristmasCheerTimestamp?.timeIntervalSince1970 {
            return timestamp > 1.minute
        } else {
            return true
        }
    }
    
    /*
    For the rare situation where a user registers for notifications without a connection and then the app crashes, we store the token here.  Otherwise, our PFInstallation doesn't have a connection to it.
    */
    class var deviceTokenData: NSData? {
        get {
            return Setting.DeviceTokenData.readFromDefaults()
        }
        set {
            Setting.DeviceTokenData.writeToDefaults(newValue)
        }
    }
}

extension Double {
    var minute: NSTimeInterval {
        return self * 60
    }
}

import Parse

extension ApplicationSettings {
    class var installationId: String {
        guard
            let installationId = PFInstallation.currentInstallation().objectId
            else { return "<unknown>" }
        return installationId
    }
}
