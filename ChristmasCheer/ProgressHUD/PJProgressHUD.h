//
//  PJProgressHUD.h
//  Qup
//
//  Created by Logan Wright on 7/18/14.
//  Copyright (c) 2014 Intrepid Pursuits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PJProgressHUD : UIView

+ (void)showWithStatus:(NSString *)status;

+ (void)hide;

@end
