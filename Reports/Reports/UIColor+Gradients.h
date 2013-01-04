//
//  Gradients.h
//  Reports
//
//  Created by Michael Thomason on 1/3/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIColor (Gradients)

+ (CGGradientRef)backgroundGradientWhiteToBlack;
+ (CGGradientRef)backgroundGradientBlack;
+ (CGGradientRef)backgroundGradientWhite;
+ (CGGradientRef)backgroundGradientGray;
+ (CGGradientRef)backgroundGradientGreen;
+ (CGGradientRef)backgroundGradientBlue;
+ (CGGradientRef)backgroundGradientPurple;
+ (CGGradientRef)backgroundGradientRed;
+ (CGGradientRef)backgroundGradientBlackShine;
+ (CGGradientRef)backgroundGradientFadeFromBlack;
+ (CGGradientRef)backgroundGradientFadeFromRandom;
+ (CGGradientRef)backgroundGradientFadeFromBlackRadial;
+ (CGGradientRef)backgroundGradientFadeToBlackRadial;
+ (CGGradientRef)backgroundGradientFadeToBlackRadialIcon;
+ (CGGradientRef)backgroundGradientGreenToRedIcon;

@end