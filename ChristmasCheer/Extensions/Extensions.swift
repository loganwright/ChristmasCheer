//
//  Extensions.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/22/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import CoreLocation.CLPlacemark

// MARK: Sounds

enum FeedbackSounds : String, SoundFile {
    case ErrorSound = "error_tone.mp3"
    case SuccessSound = "success_tone.wav"
    
    var soundFile: String {
        return rawValue
    }
}

enum NotificationSounds: String, SoundFile, Codable {
    case MerryChristmas = "merry_christmas.mp3"
    case SantaLaugh = "santa_laugh.wav"
    case SleighBells = "sleighbells.wav"
    case MerryChristmasDarling = "merry_christmas_darling"
    
    var soundFile: String {
        return rawValue
    }
}

// MARK: ColorPalette

enum ColorPalette : ColorDescriptor {
    case White = "254,216,130,255"
    case Green = "60,132,86,255"
    case DarkGreen = "51,58,24,255"
    case DarkGray = "64,48,56,255"
    case ReddishOrange = "161,43,39,255"
    case Red = "201,39,59,255"
    case DarkRed = "103,5,2,255"
    
    case SparklyWhite = "white_christmas_bg"
    case SparklyRed = "red_christmas_bg"
    case TexturedBackground = "texturedBackground"
    
    var color: UIColor {
        return rawValue.color
    }
}

// MARK: Fonts

protocol Fontable {
    var fontName: String { get }
    var fontSize: CGFloat { get }
}

extension Fontable {
    var font: UIFont {
        return UIFont(name: fontName, size: fontSize)!
    }
}

enum ChristmasCrackFont : Fontable {
    
    case Regular(CGFloat)
    
    // case Bold(CGFloat)
    // case Thin(CGFloat)
    
    var fontName: String {
        return "Christmas On Crack" // No Bold or italic here
    }
    
    var fontSize: CGFloat {
        switch self {
        case .Regular(let size):
            return size
        }
    }
}

extension CLPlacemark {
    var cc_locationDescription: String {
        var description = locality ?? "North Pole"
        if let countryCode = isoCountryCode, countryCode != "US" {
            description += ", \(countryCode)"
        } else if let administrative = administrativeArea {
            description += ", \(administrative)"
        }
        return description
    }
}


extension UIImage {
    @objc
    class func randomChristmasIcon() -> UIImage {
        let randomInt = Int(arc4random_uniform(10))
        let randomImage = "christmas_icon_\(randomInt)"
        return UIImage(named: randomImage)!
    }

    @objc
    class func randomCircleLoader() -> UIImage {
        let randomInt = Int(arc4random_uniform(16))
        let randomImage = "circle_loader_\(randomInt)"
        return UIImage(named: randomImage)!
    }
}


extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "Localized:\(self)")
    }
}


// MARK: ObjC

extension UIColor {
    @objc
    class func christmasCheerTexturedBackgroundColor() -> UIColor {
        return ColorPalette.TexturedBackground.color
    }

    @objc
    class func christmasCheerSparklyRedColor() -> UIColor {
        return ColorPalette.SparklyRed.color
    }
}

extension UIFont {
    @objc
    class func christmasCheerCrackFont(withSize size: CGFloat) -> UIFont {
        return ChristmasCrackFont.Regular(size).font
    }
}



