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
        let viewWidth = self.bounds.width
        let viewHeight = self.bounds.height
        let minX = -viewWidth // Offscreen Left to account for wind
        let maxX = viewWidth * 2.0 // Offscreen Right to account for wind
        
        let lowerLeft = CGPoint(x: -1000, y: 1000)
        let lowerRight = CGPoint(x: 2000, y: 1000)
        collision.addBoundary(withIdentifier: "bottom" as NSString, from: lowerLeft, to: lowerRight)
        collision.collisionMode = .boundaries
        collision.collisionDelegate = self
        self.animator.addBehavior(collision)
        return collision
        }()
    
    var windTimer: Timer?
    var snowTimer: Timer?
    
    // MARK: Initialization
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: LifeCycle
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if windTimer == nil {
            self.windTimerFired(nil)
        }
        if snowTimer == nil {
            self.snowTimerFired(nil)
        }
    }
    
    // MARK: Wind

    @objc
    func windTimerFired(_ timer: Timer?) {
        gravity.angle = randomWindDirection()
        
        // 2 ... 10
        let randomTimeInterval = TimeInterval(arc4random_uniform(9) + 2)
        self.windTimer = Timer.scheduledTimer(timeInterval: randomTimeInterval, target: self, selector: #selector(windTimerFired), userInfo: nil, repeats: false)
    }
    
    // MARK: Snowfall

    @objc
    func snowTimerFired(_ timer: Timer?) {
        let randomSnowflake = randomSnowflakeImageView()
        self.addSubview(randomSnowflake)
        gravity.addItem(randomSnowflake)
        collision.addItem(randomSnowflake)
        
        // 0.6 - 2.0 Seconds
        let randomInterval = TimeInterval(CGFloat(arc4random_uniform(15) + 6) / 10.0)
        self.snowTimer = Timer.scheduledTimer(
            timeInterval: randomInterval,
            target: self,
            selector: #selector(snowTimerFired),
            userInfo: nil,
            repeats: false
        )
    }
    
    func randomWindDirection() -> CGFloat {
        // 0 is to the right, 180 is directly left. 70 degree buffer on each side, don't get too windy :)
        let minDegrees = 70
        let maxDegrees = 110
        let range = maxDegrees - minDegrees
        let randomDegree = arc4random_uniform(UInt32(range)) + UInt32(minDegrees)
        let radians = CGFloat(randomDegree) * CGFloat(.pi / 180.0)
        return radians
    }
    
    // MARK: Snowflake
    
    var availableSnowflakeImageNames = [MESnowFlakeImageNameOne, MESnowFlakeImageNameTwo]
    
    func randomSnowflakeImageView() -> UIButton {
        
        let randomImgName = availableSnowflakeImageNames[Int(arc4random_uniform(UInt32(availableSnowflakeImageNames.count)))]
        let randomImage = UIImage(named: randomImgName)
        let randomImageView = UIButton(type: .system) as UIButton
        randomImageView.setImage(randomImage, for: .normal)
        randomImageView.tintColor = ColorPalette.SparklyWhite.color
        let range = MEMaximumSnowFlakeSize - MEMinimumSnowFlakeSize
        let randomSize: CGFloat = CGFloat(arc4random_uniform(UInt32(range))) + MEMinimumSnowFlakeSize
        randomImageView.bounds.size = CGSize(width: randomSize, height: randomSize)
        
        let maxX = self.bounds.width
        let randomStartX = arc4random_uniform(UInt32(maxX + 1))
        
        let randomStartY = arc4random_uniform(60)
        let randomPoint = CGPoint(x: CGFloat(randomStartX), y: -CGFloat(randomStartY))
        
        randomImageView.center = randomPoint
        return randomImageView
    }
    
    // MARK: UICollisionBehaviorDelegate
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        if let v = item as? UIView {
            v.removeFromSuperview()
            self.gravity.removeItem(v)
            self.collision.removeItem(v)
            
        }
    }
    
}
