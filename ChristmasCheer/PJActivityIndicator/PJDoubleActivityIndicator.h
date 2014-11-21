//
//  PJDoubleActivityIndicator.h
//  TYMActivityIndicatorView
//
//  Created by Logan Wright on 7/15/14.
//  Copyright (c) 2014 Yiming Tang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PJDoubleActivityIndicator : UIView

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;
- (void)loadNewRandomImage;

@end
