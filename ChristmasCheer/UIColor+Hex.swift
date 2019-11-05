//
//  UIColor+Hex.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/27/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hex: String) {
        var cleanHex: String = hex.uppercased()
        if hex.hasPrefix("#") {
            cleanHex.dropFirst()
        }
        if cleanHex.count != 6 {
            cleanHex = "FFFFFF"
        }

        let chars = Array(cleanHex)
        let rChars = chars[0...1]
        let gChars = chars[2...3]
        let bChars = chars[4...5]
        
        var r: CUnsignedInt = 0, g: CUnsignedInt = 0, b: CUnsignedInt = 0;
        Scanner(string: .init(rChars)).scanHexInt32(&r)
        Scanner(string: .init(gChars)).scanHexInt32(&g)
        Scanner(string: .init(bChars)).scanHexInt32(&b)
        
        
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(1)
        )
    }
}
