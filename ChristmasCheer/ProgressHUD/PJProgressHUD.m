//
//  PJProgressHUD.m
//  Qup
//
//  Created by Logan Wright on 7/18/14.
//  Copyright (c) 2014 Intrepid Pursuits. All rights reserved.
//

#import "PJProgressHUD.h"
#import "PJDoubleActivityIndicator.h"

#ifdef DEVELOPMENT_TARGET
#import "ChristmasCheerDevelopment-Swift.h"
#else
#import "ChristmasCheer-Swift.h"
#endif

@interface PJProgressHUD ()

@property (weak, nonatomic) IBOutlet PJDoubleActivityIndicator *doubleActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation PJProgressHUD

+ (instancetype)masterProgressHUD {
    
    static dispatch_once_t pred;
    static PJProgressHUD *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[[NSBundle mainBundle] loadNibNamed:@"PJProgressHUD" owner:self options:nil] objectAtIndex:0];
        shared.translatesAutoresizingMaskIntoConstraints = NO;
    });
    
    return shared;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    
    self.doubleActivityIndicator.backgroundColor = [UIColor clearColor];
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.statusLabel.font = [UIFont christmasCheerCrackFontOfSize:42.0];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.minimumScaleFactor = 0.5;
    self.statusLabel.textColor = [UIColor christmasCheerSparklyRedColor];
    
    self.layer.cornerRadius = 15.0;
    self.layer.borderColor = [UIColor christmasCheerSparklyRedColor].CGColor;
    self.layer.borderWidth = 5.0;
    self.backgroundColor = [UIColor christmasCheerTexturedBackgroundColor];
    
}

+ (void)showWithStatus:(NSString *)status {
    
    UIWindow *globalWindow = [[[UIApplication sharedApplication] delegate] window];
    
    PJProgressHUD *progHUD = [PJProgressHUD masterProgressHUD];
    [progHUD.doubleActivityIndicator loadNewRandomImage];
    [progHUD.doubleActivityIndicator startAnimating];
    progHUD.statusLabel.text = status;
    progHUD.center = globalWindow.center;
    progHUD.alpha = 0;
    
    [globalWindow addSubview:progHUD];
    [globalWindow addConstraint:[NSLayoutConstraint constraintWithItem:progHUD attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:globalWindow attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [globalWindow addConstraint:[NSLayoutConstraint constraintWithItem:progHUD attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:globalWindow attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [UIView animateWithDuration:0.2 animations:^{
        progHUD.alpha = 1.0;
    }];
}

+ (void)hide {
    PJProgressHUD *masterHUD = [PJProgressHUD masterProgressHUD];
    [UIView animateWithDuration:0.2 animations:^{
        masterHUD.alpha = 0.0;
    } completion:^(BOOL finished) {
        [masterHUD.doubleActivityIndicator stopAnimating];
        [masterHUD removeFromSuperview];
    }];
}

@end
