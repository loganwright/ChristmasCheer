//
//  EnvironmentVariables.m
//  ChristmasCheer
//
//  Created by Logan Wright on 12/6/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

/*
 Preprocessor Macros don't work and are behaving super fucking weirdly so Instead I'm doing this to help
 */

#import "EnvironmentVariables.h"

#ifdef DEVELOPMENT_TARGET
BOOL const IS_DEVELOPMENT_TARGET = YES;
#else
BOOL const IS_DEVELOPMENT_TARGET = NO;
#endif
