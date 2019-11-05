//
//  Theme.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/24/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import Foundation

struct Theme {
    static func stylize() {
        stylizeStatusBar()
    }
    
    private static func stylizeStatusBar() {
        // todo()
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: false)
    }
}

/// We can't use navigation bar appearance because using the images as color patterns crashes on sharing
class NavigationController : UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setTitleVerticalPositionAdjustment(4.0, for: .default)
        navigationBar.setBackgroundImage(UIImage(named: "red_christmas_bg"), for: .default)
        let attributes =  [
            NSAttributedString.Key.foregroundColor : ColorPalette.SparklyWhite.color,
            NSAttributedString.Key.font : ChristmasCrackFont.Regular(42.0).font
        ]
        navigationBar.titleTextAttributes = attributes
        navigationBar.tintColor = ColorPalette.SparklyWhite.color
        navigationBar.isTranslucent = false

    }
}
