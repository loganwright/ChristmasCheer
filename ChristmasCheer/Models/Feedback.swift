//
//  Feedback.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/30/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import Foundation
import Parse

extension PFACL {
    static var MasterKey: PFACL {
        let acl = PFACL()
        // todo
        return acl
    }
}

class Feedback : PFObject, PFSubclassing {
    
    @NSManaged private(set) var feedbackTextFile: PFFileObject
    @NSManaged private(set) var userId: String
    @NSManaged private(set) var installationId: String
    @NSManaged private(set) var name: String
    @NSManaged private(set) var locationDescription: String
    
    // MARK: Initialization
    
    override init() {
        super.init()
    }
    
    init?(feedback: String, userId: String, installationId: String, name: String, locationDescription: String) {
        super.init()
        guard
            let feedbackData = feedback.data(using: .utf8, allowLossyConversion: false),
            let feedbackTextFile = PFFileObject(name: "feedback.txt", data: feedbackData)
            else { return nil }
        
        self.name = name
        self.userId = userId
        self.installationId = installationId
        self.locationDescription = locationDescription
        self.feedbackTextFile = feedbackTextFile
        self.acl = PFACL.MasterKey
    }
    
    // MARK: PFObject Requirements
    
//    override class func initialize() {
//        super.initialize()
//        registerSubclass()
//    }
    
    class func parseClassName() -> String {
        return "Feedback"
    }
}
