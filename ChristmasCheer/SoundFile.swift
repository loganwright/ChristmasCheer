//
//  SoundFile.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/25/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import Foundation

import AVFoundation

protocol SoundFile {
    var soundFile: String { get }
}

extension SoundFile {
    
    private var nameComponents: [String] {
        return soundFile.components(separatedBy: ".")
    }
    
    private var name: String {
        return nameComponents.first!
    }
    
    private var type: String {
        return nameComponents.last!
    }
    
    private var path: String {
        return MainBundle.path(forResource: name, ofType: type)!
    }
    
    private var url: URL {
        return NSURL.fileURL(withPath: path)
    }
    
    func play() {
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}
