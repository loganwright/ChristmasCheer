//
//  PJDoubleActivityIndicator.m
//  TYMActivityIndicatorView
//
//  Created by Logan Wright on 7/15/14.
//  Copyright (c) 2014 Yiming Tang. All rights reserved.
//

#import "PJDoubleActivityIndicator.h"
#import "PJSingleActivityIndicator.h"

#ifdef DEVELOPMENT_TARGET
#import "ChristmasCheerDevelopment-Swift.h"
#else
#import "ChristmasCheer-Swift.h"
#endif


static NSString * const kOuterIndicatorImage = @"circle_loader_1";
static NSString * const kInnerIndicatorImage = @"inner_spinner";

@interface PJDoubleActivityIndicator ()

@property (strong, nonatomic) PJSingleActivityIndicator *outerActivityIndicator;
@property (strong, nonatomic) PJSingleActivityIndicator *innerActivityIndicator;

@end

@implementation PJDoubleActivityIndicator

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.outerActivityIndicator.frame = self.bounds;
    self.innerActivityIndicator.bounds = CGRectMake(0, 0, self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    self.innerActivityIndicator.center = self.outerActivityIndicator.center;
}

#pragma mark PUBLIC

- (void)startAnimating {
    [self.innerActivityIndicator startAnimating];
    [self.outerActivityIndicator startAnimating];
}
- (void)stopAnimating {
    [self.innerActivityIndicator stopAnimating];
    [self.outerActivityIndicator stopAnimating];
}
- (BOOL)isAnimating {
    return self.innerActivityIndicator.isAnimating;
}
- (void)loadNewRandomImage {
    self.outerActivityIndicator.indicatorImage = [UIImage randomCircleLoader];
}

#pragma mark GETTERS | SETTERS

- (PJSingleActivityIndicator *)outerActivityIndicator {
    if (!_outerActivityIndicator) {
        _outerActivityIndicator = [PJSingleActivityIndicator new];
        _outerActivityIndicator.indicatorImage = [UIImage randomCircleLoader];
        [self addSubview:_outerActivityIndicator];
        [self setNeedsLayout];
    }
    return _outerActivityIndicator;
}

- (PJSingleActivityIndicator *)innerActivityIndicator {
    if (!_innerActivityIndicator) {
        _innerActivityIndicator = [PJSingleActivityIndicator new];
        _innerActivityIndicator.rotatesClockwise = NO;
        _innerActivityIndicator.indicatorImage = [UIImage imageNamed:kInnerIndicatorImage];
        [self addSubview:_innerActivityIndicator];
        [self setNeedsLayout];
    }
    return _innerActivityIndicator;
}

@end
