//
//  MESnowfallView.swift
//  MagicEyes
//
//  Created by Logan Wright on 12/26/14.
//  Copyright (c) 2014 Intrepid Pursuits, LLC. All rights reserved.
//

import UIKit

private let MESnowFlakeImageNameOne = "snowflake1"
private let MESnowFlakeImageNameTwo = "snowflake2"
private let MEMinimumSnowFlakeSize: CGFloat = 22.0
private let MEMaximumSnowFlakeSize: CGFloat = 88.0

class MESnowFallView: UIView, UICollisionBehaviorDelegate {
    
    // MARK: Properties
    
    lazy var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self)
    
    lazy var gravity: UIGravityBehavior = {
        let behavior = UIGravityBehavior()
        self.animator.addBehavior(behavior)
        behavior.magnitude = 0.1
        return behavior
        }()
    
    lazy var collision: UICollisionBehavior = {
        let collision = UICollisionBehavior()
        let viewWidth = CGRectGetWidth(self.bounds)
        let viewHeight = CGRectGetHeight(self.bounds)
        let minX = -viewWidth // Offscreen Left to account for wind
        let maxX = viewWidth * 2.0 // Offscreen Right to account for wind
        
        let lowerLeft = CGPointMake(-1000, 1000)
        let lowerRight = CGPointMake(2000, 1000)
        collision.addBoundaryWithIdentifier("bottom", fromPoint: lowerLeft, toPoint: lowerRight)
        collision.collisionMode = .Boundaries
        collision.collisionDelegate = self
        self.animator.addBehavior(collision)
        return collision
        }()
    
    var windTimer: NSTimer?
    var snowTimer: NSTimer?
    
    // MARK: Initialization
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: LifeCycle
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if windTimer == nil {
            self.windTimerFired(nil)
        }
        if snowTimer == nil {
            self.snowTimerFired(nil)
        }
    }
    
    // MARK: Wind
    
    func windTimerFired(timer: NSTimer?) {
        gravity.angle = randomWindDirection()
        
        // 2 ... 10
        let randomTimeInterval = NSTimeInterval(arc4random_uniform(9) + 2)
        self.windTimer = NSTimer.scheduledTimerWithTimeInterval(randomTimeInterval, target: self, selector: "windTimerFired:", userInfo: nil, repeats: false)
    }
    
    // MARK: Snowfall
    
    func snowTimerFired(timer: NSTimer?) {
        let randomSnowflake = randomSnowflakeImageView()
        self.addSubview(randomSnowflake)
        gravity.addItem(randomSnowflake)
        collision.addItem(randomSnowflake)
        
        // 0.6 - 2.0 Seconds
        let randomInterval = NSTimeInterval(CGFloat(arc4random_uniform(15) + 6) / 10.0)
        self.snowTimer = NSTimer.scheduledTimerWithTimeInterval(randomInterval, target: self, selector: "snowTimerFired:", userInfo: nil, repeats: false)
    }
    
    func randomWindDirection() -> CGFloat {
        // 0 is to the right, 180 is directly left. 70 degree buffer on each side, don't get too windy :)
        let minDegrees = 70
        let maxDegrees = 110
        let range = maxDegrees - minDegrees
        let randomDegree = arc4random_uniform(UInt32(range)) + UInt32(minDegrees)
        let radians = CGFloat(randomDegree) * CGFloat(M_PI / 180.0)
        return radians
    }
    
    // MARK: Snowflake
    
    var availableSnowflakeImageNames = [MESnowFlakeImageNameOne, MESnowFlakeImageNameTwo]
    
    func randomSnowflakeImageView() -> UIButton {
        
        let randomImgName = availableSnowflakeImageNames[Int(arc4random_uniform(UInt32(availableSnowflakeImageNames.count)))]
        let randomImage = UIImage(named: randomImgName)
        let randomImageView = UIButton(type: .System) as UIButton
        randomImageView.setImage(randomImage, forState: .Normal)
        randomImageView.tintColor = ColorPalette.SparklyWhite.color
        let range = MEMaximumSnowFlakeSize - MEMinimumSnowFlakeSize
        let randomSize: CGFloat = CGFloat(arc4random_uniform(UInt32(range))) + MEMinimumSnowFlakeSize
        randomImageView.bounds.size = CGSizeMake(randomSize, randomSize)
        
        let maxX = CGRectGetWidth(self.bounds)
        let randomStartX = arc4random_uniform(UInt32(maxX + 1))
        
        let randomStartY = arc4random_uniform(60)
        let randomPoint = CGPoint(x: CGFloat(randomStartX), y: -CGFloat(randomStartY))
        
        randomImageView.center = randomPoint
        return randomImageView
    }
    
    // MARK: UICollisionBehaviorDelegate
    
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, atPoint p: CGPoint) {
        if let v = item as? UIView {
            v.removeFromSuperview()
            self.gravity.removeItem(v)
            self.collision.removeItem(v)
            
        }
    }
    
}
