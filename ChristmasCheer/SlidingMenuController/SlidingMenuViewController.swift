//
//  SlidingMenuViewController.swift
//  FriendLender
//
//  Created by Logan Wright on 9/24/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit

extension SlidingMenuRootViewController {
    static func cc_mainController() -> SlidingMenuRootViewController {
        let homeVC = HomeViewController()
        let mainNav = NavigationController(rootViewController: homeVC)
        let menuVC = CheerListViewController()
        
        let slidingMenuVC = SlidingMenuRootViewController()
        slidingMenuVC.slidableNavigationController = mainNav
        slidingMenuVC.menuViewController = menuVC
        return slidingMenuVC
    }
}

class SlidingMenuRootViewController: UIViewController {
    
    // MARK: Public Properties
    
    var menuIsOpen = false

    var menuViewController: CheerListViewController? {
        didSet {
            if let menuVC = menuViewController {
                menuVC.willMoveToParentViewController(self)
                // TODO: 
//                let frame = CGRect(x: 0, y: 0, width: menuVC.view.bounds.size.width, height: menuVC.view.bounds.size.height)
                if let navView = navigationView {
                    self.view.insertSubview(menuVC.view, belowSubview: navView)
                }
                else {
                    self.view.addSubview(menuVC.view)
                }
                self.addChildViewController(menuVC)
                menuVC.didMoveToParentViewController(self)
            }
        }
    }
    
    var slidableNavigationController: UINavigationController? {
        didSet {
            if let nav = slidableNavigationController {
                nav.willMoveToParentViewController(self)
                if let menuView = menuViewController?.view {
                    self.view.insertSubview(nav.view, aboveSubview: menuView)
                }
                else {
                    self.view.addSubview(nav.view)
                }
                self.addChildViewController(nav)
                nav.didMoveToParentViewController(self)
                
                self.addMenuBarButtonItemToNavigationController(nav)
                self.stylizeNavigationControllerShadows(nav)
            }
            
            if let oldValue = oldValue {
                oldValue.willMoveToParentViewController(nil)
                oldValue.view.removeFromSuperview()
                self.removeFromParentViewController()
                oldValue.didMoveToParentViewController(nil)
            }
        }
    }
    
    // MARK: Nav Controller Setup
    
    private func addMenuBarButtonItemToNavigationController(navController: UINavigationController) {
        let button: UIButton = UIButton(type: .System)
        button.setImage(UIImage(named: "snowflake_icon"), forState: .Normal)
        button.addTarget(self, action: "menuButtonPressed:", forControlEvents: .TouchUpInside)
        button.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 24)
        let barButton = UIBarButtonItem(customView: button)
        navController.topViewController?.navigationItem.leftBarButtonItem = barButton
        navController.navigationBar.opaque = true
    }
    
    private func stylizeNavigationControllerShadows(navController: UINavigationController) {
        navController.view.layer.shadowColor = UIColor.blackColor().CGColor
        navController.view.layer.shadowOffset = CGSize(width: -1.0, height: 1.0)
        navController.view.layer.shadowOpacity = 0.5
        navController.view.layer.shadowRadius = 0.8
    }
    
    // MARK: Helper
    
    private var navigationView: UIView? {
        return slidableNavigationController?.view
    }
    
    // MARK: Open / Close
    
    func menuButtonPressed(sender: UIButton) {
        if let navView = navigationView {
            if navView.frame.origin.x == menuViewController!.view.bounds.size.width {
                slidableNavigationController?.visibleViewController?.view.userInteractionEnabled = true
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    navView.frame.origin.x = 0
                    self.menuIsOpen = false
                })
            }
            else {
                self.menuViewController!.resize()
                self.menuViewController!.fetchDataAndReloadTableView()
                slidableNavigationController?.visibleViewController?.view.userInteractionEnabled = false
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    navView.frame.origin.x += self.menuViewController!.view.bounds.size.width
                    self.menuIsOpen = true
                })
            }
        }
    }

}
