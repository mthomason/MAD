//
//  MADColor.h
//  Reports
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIColor_EverydayApps_h
#define Reports_UIColor_EverydayApps_h

#import <UIKit/UIKit.h>

@interface MADColor : UIColor

static inline MADColor *vendColor(CGFloat r, CGFloat g, CGFloat b);
static inline MADColor *vendColorWithAlpha(CGFloat r, CGFloat g, CGFloat b, CGFloat a);

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

+ (instancetype)disabledColor;

+ (instancetype)tintColorAnalogous4;
+ (instancetype)borderColor;

+ (instancetype)blueTwitter;
+ (instancetype)blueLinkedIn;
+ (instancetype)blueFacebook;


@end

#endif
