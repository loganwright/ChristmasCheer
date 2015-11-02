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
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    }
}

/// We can't use navigation bar appearance because using the images as color patterns crashes on sharing
class NavigationController : UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setTitleVerticalPositionAdjustment(4.0, forBarMetrics: .Default)
        navigationBar.setBackgroundImage(UIImage(named: "red_christmas_bg"), forBarMetrics: .Default)
        let attributes =  [
            NSForegroundColorAttributeName : ColorPalette.SparklyWhite.color,
            NSFontAttributeName : ChristmasCrackFont.Regular(42.0).font
        ]
        navigationBar.titleTextAttributes = attributes
        navigationBar.tintColor = ColorPalette.SparklyWhite.color
        navigationBar.translucent = false

    }
}