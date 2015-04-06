//
//  UIColor+EverydayApps.h
//  Reports
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIColor_EverydayApps_h
#define Reports_UIColor_EverydayApps_h

#import <UIKit/UIKit.h>

@interface UIColor(EverydayApps)

#define vendColor(r, g, b) return [UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:1.0000f]
#define vendColorWithAlpha(r, g, b, a) return [UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:a]

+ (instancetype)edaBlackish;
+ (instancetype)edaBlueDark;
+ (instancetype)edaBlueLight;
+ (instancetype)edaBlueDarkSelection;
+ (instancetype)edaBlueLightSelection;
+ (instancetype)edaBlackSeventyFivePercent;
+ (instancetype)edaBlackFiftyPercent;
+ (instancetype)edaBlackTwentyFivePercent;
+ (instancetype)edaOrange;
+ (instancetype)edaYellow;
+ (instancetype)edaGreenDark;
+ (instancetype)edaGreenLight;

+ (instancetype)headerColor;
+ (instancetype)tintColorWhiteAlpha;
+ (instancetype)edaBlueLightBackground;
+ (instancetype)edaTableHeaderBackground;
+ (instancetype)tintColorBackground;
+ (instancetype)tintColorBlue;
+ (instancetype)tintColorRed;
+ (instancetype)tintColorWhite;
+ (instancetype)tintColorGold;
+ (instancetype)tintColorGold2;

+ (instancetype)tintColorAnalogous4;
+ (instancetype)borderColor;

@end

#endif
