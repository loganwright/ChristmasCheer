//
//  String+Substrings.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/27/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import Foundation

extension String {
    subscript(range range: Range<Int>) -> String {
        let chars = Array(self)
        let substringCharacters = chars[range]
        return String(substringCharacters)
    }
}
