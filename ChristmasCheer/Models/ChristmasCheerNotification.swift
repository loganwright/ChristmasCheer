//
//  ChristmasCheerNotification.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/25/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Parse

struct ChristmasCheerNotification {
    let createdAt: Date
    let fromName: String
    let fromLocation: String
    let fromInstallationId: String
    let fromUserId: String
    let toInstallationId: String
    let message: String
    let hasBeenRespondedTo: Bool
    let initiationNoteId: String?
}
