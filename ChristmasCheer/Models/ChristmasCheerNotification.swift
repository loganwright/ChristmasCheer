//
//  ChristmasCheerNotification.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/25/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Parse

class ChristmasCheerNotification: PFObject, PFSubclassing {
    
    // MARK: Properties

    @NSManaged var fromName: String
    @NSManaged var fromLocation: String
    @NSManaged var fromInstallationId: String
    @NSManaged var fromUserId: String
    @NSManaged var toInstallationId: String
    @NSManaged var message: String
    @NSManaged var hasBeenRespondedTo: Bool
    @NSManaged var initiationNoteId: String?
    
    // MARK: Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: PFObject Requirements

    // TODO: 
//    override class func initialize() {
//        super.initialize()
//        registerSubclass()
//    }
    
    class func parseClassName() -> String {
        return "ChristmasCheerNotification"
    }
}
