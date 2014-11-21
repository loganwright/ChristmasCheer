//
//  PJActivityIndicator.h
//  TYMActivityIndicatorView
//
//  Created by Logan Wright on 7/15/14.
//  Contributions by Yiming Tang: https://github.com/yimingtang/TYMActivityIndicatorView
//  Copyright (c) 2014 Intrepid Pursuits. All rights reserved.
//

#import "PJSingleActivityIndicator.h"

static NSString * const kDefaultClockwiseIndicatorImage = @"circle_loader_0";
static NSString * const kDefaultCounterClockwiseIndicatorImage = @"circle_loader_0";

@interface PJSingleActivityIndicator ()

@property (nonatomic, assign) BOOL animating;
@property (nonatomic, strong) UIImageView *indicatorImageView;

@end

@implementation PJSingleActivityIndicator

#pragma mark - UIView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialize];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self initialize];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.indicatorImageView.frame = self.bounds;
}

#pragma mark - Public

- (void)startAnimating
{
    if (self.animating) return;
    
    self.animating = YES;
    self.hidden = NO;
    CGFloat toValue = M_PI * 2.0;
    
    if (!_rotatesClockwise) {
        toValue = -toValue;
    }
    
    [self rotateImageViewFrom:0.0f to:toValue duration:self.fullRotationDuration repeatCount:HUGE_VALF];
}


- (void)stopAnimating
{
    if (!self.animating) return;
    
    self.animating = NO;
    [self.indicatorImageView.layer removeAllAnimations];
    if (self.hidesWhenStopped) {
        self.hidden = YES;
    }
}

#pragma mark - Private

- (void)initialize {
    self.userInteractionEnabled = NO;
    
    _animating = NO;
    _hidesWhenStopped = YES;
    _fullRotationDuration = 3.2f; // 2.6
    _minProgressUnit = 0.01f;
    _progress = 0.0f;
    _rotatesClockwise = YES;
    
    [self addSubview:self.indicatorImageView];
}


- (void)rotateImageViewFrom:(CGFloat)fromValue to:(CGFloat)toValue duration:(CFTimeInterval)duration repeatCount:(CGFloat)repeatCount
{
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:fromValue];
    rotationAnimation.toValue = [NSNumber numberWithFloat:toValue];
    rotationAnimation.duration = duration;
    rotationAnimation.repeatCount = repeatCount;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.fillMode = kCAFillModeForwards;
    [self.indicatorImageView.layer addAnimation:rotationAnimation forKey:@"rotation"];
}

#pragma mark GETTERS | SETTERS

- (void)setProgress:(CGFloat)progress {
    
    if (progress < 0.0f || progress > 1.0f) return;
    if (fabs(_progress - progress) < self.minProgressUnit) return;
    
    CGFloat fromValue = M_PI * 2 * _progress;
    CGFloat toValue = M_PI * 2 * progress;
    [self rotateImageViewFrom:fromValue to:toValue duration:0.15f repeatCount:0];
    
    _progress = progress;
}

- (UIImageView *)indicatorImageView {
    if (!_indicatorImageView) {
        _indicatorImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _indicatorImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _indicatorImageView.contentMode = UIViewContentModeScaleAspectFit;
        _indicatorImageView.image = [UIImage imageNamed:kDefaultClockwiseIndicatorImage];
        _indicatorImageView.clipsToBounds = YES;
    }
    return _indicatorImageView;
}

- (void)setIndicatorImage:(UIImage *)indicatorImage {
    self.indicatorImageView.image = indicatorImage;
    [self setNeedsLayout];
}

- (UIImage *)indicatorImage {
    return self.indicatorImageView.image;
}

- (BOOL)isAnimating {
    return self.animating;
}

- (void)setRotatesClockwise:(BOOL)rotatesClockwise {
    _rotatesClockwise = rotatesClockwise;
    if (_rotatesClockwise) {
        self.indicatorImageView.image = [UIImage imageNamed:kDefaultClockwiseIndicatorImage];
    }
    else {
        self.indicatorImageView.image = [UIImage imageNamed:kDefaultCounterClockwiseIndicatorImage];
    }
}

@end

