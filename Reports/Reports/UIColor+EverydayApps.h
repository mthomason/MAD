//
//  UIColor+EverydayApps.h
//  Reports
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIColor_EverydayApps_h
#define Reports_UIColor_EverydayApps_h

@interface UIColor(EverydayApps)

#define vendColor(r, g, b) return [UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:1.0000f]
#define vendColorWithAlpha(r, g, b, a) return [UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:a]

+ (id)edaBlackish;
+ (id)edaBlueDark;
+ (id)edaBlueLight;
+ (id)edaBlueDarkSelection;
+ (id)edaBlueLightSelection;
+ (id)edaBlackFiftyPercent;
+ (id)edaBlackTwentyFivePercent;
+ (id)edaOrange;
+ (id)edaYellow;
+ (id)edaGreenDark;
+ (id)edaGreenLight;

+ (id)edaBlueLightBackground;
+ (id)edaTableHeaderBackground;
+ (id)tintColorBlue;
+ (id)tintColorRed;
+ (id)tintColorWhite;
+ (id)tintColorGold;
+ (id)tintColorGold2;

+ (id)tintColorAnalogous4;

@end

#endif
