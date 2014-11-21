//
//  PJActivityIndicator.h
//  TYMActivityIndicatorView
//
//  Created by Logan Wright on 7/15/14.
//  Contributions by Yiming Tang: https://github.com/yimingtang/TYMActivityIndicatorView
//  Copyright (c) 2014 Intrepid Pursuits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PJSingleActivityIndicator : UIView

/*!
 Defaults to YES
 */
@property (nonatomic) BOOL rotatesClockwise;

@property (nonatomic, strong) UIImage *indicatorImage UI_APPEARANCE_SELECTOR;

/**
 It determines whether the view will be hidden when the animation was stopped.
 
 The view sets its `hidden` property to accomplish it.
 */
@property (nonatomic, assign) BOOL hidesWhenStopped;

/**
 The duration time it takes the indicator to finish a 360-degree clockwise rotation.
 */
@property (nonatomic, assign) CFTimeInterval fullRotationDuration;

/**
 The overall progress of the indicator. The acceptable value is `0.0f` to `1.0f`.
 
 The default value is 0.
 
 @warning For performance issue, you'd better control your invoking frequency during a period of time.
 */
@property (nonatomic, assign) CGFloat progress;

/**
 The minimal progress unit.
 
 The indicator will only be rotated when the delta value of the progress is larger than the unit value. The default value is `0.01f`.
 */
@property (nonatomic, assign) CGFloat minProgressUnit UI_APPEARANCE_SELECTOR;


///-----------------------------
/// @name Controlling Animations
///-----------------------------

/**
 Start animating. 360-degree clockwise rotation. Repeated forever.
 */
- (void)startAnimating;

/**
 Stop animating.
 */
- (void)stopAnimating;

/**
 Whether the indicator is animating.
 */
- (BOOL)isAnimating;

@end

