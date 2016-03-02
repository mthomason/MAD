//
//  UIColor+EverydayApps.m
//  Reports
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIColor.h>
#import "MADColor.h"
#import "MacroVendColor.h"

@implementation MADColor

static const CGFloat selectedAlpha = 0.33333333f;

static inline MADColor *vendColor(CGFloat r, CGFloat g, CGFloat b) {
    return (MADColor *)[UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:1.0000f];
}
static inline MADColor *vendColorWithAlpha(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return (MADColor *)[UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:a];
}


+ (instancetype)edaBlackish                       {return vendColor(0.0000f, 0.0000f, 0.0000f);}
+ (instancetype)edaBlueDark                       {return vendColor(2.0000f, 108.0000f, 182.0000f);}
+ (instancetype)edaBlueLight                      {return vendColor(185.0000f, 224.0000f, 247.0000f);}
+ (instancetype)edaBlueDarkSelection              {return vendColorWithAlpha(2.0000f, 108.0000f, 182.0000f, 0.5000f);}
+ (instancetype)edaBlueLightSelection             {return vendColorWithAlpha(185.0000f, 224.0000f, 247.0000f, 0.5000f);}
+ (instancetype)edaBlueLightBackground            {return vendColorWithAlpha(2.0000f, 108.0000f, 182.0000f, 0.8900f);}

+ (instancetype)headerColor                       { return (MADColor *)[[MADColor edaBlueLightBackground] colorWithAlphaComponent:0.20000f]; }
+ (instancetype)edaBlackSeventyFivePercent        { return vendColor(64.0000f, 64.0000f, 64.0000f); }
+ (instancetype)edaBlackFiftyPercent              { return vendColor(147.0000f, 149.0000f, 152.0000f); }
+ (instancetype)edaBlackTwentyFivePercent         { return vendColor(199.0000f, 200.0000f, 202.0000f); }
+ (instancetype)edaOrange                         { return vendColor(246.0000f, 160.0000f, 26.0000f); }
+ (instancetype)edaYellow                         { return vendColor(255.0000f, 227.0000f, 99.0000f); }
+ (instancetype)edaGreenDark                      { return vendColor(94.0000f, 151.0000f, 50.0000f); }
+ (instancetype)edaGreenLight                     { return vendColor(180.0000f, 216.0000f, 139.0000f); }
+ (instancetype)edaTableHeaderBackground          { return (MADColor *)[UIColor colorWithHue:0.5500f saturation:0.8000f brightness:0.8000f alpha:0.5000f]; }

//Triad on tintColorBlue
// Visit url: https://kuler.adobe.com/create/color-wheel/?base=2&rule=Triad&selected=2&name=My%20Kuler%20Theme&mode=rgb&rgbvalues=0.08715458276333791,0.41446887712012853,0.5431372549019609,0.869281045751634,0.13948928408572733,0.28340036579992106,0.050980392156862744,0.6196078431372549,0.8431372549019608,0.6431372549019607,0.6144138065677613,0.10320109439124488,0.5431372549019609,0.5145458915419016,0.005683994528043774&swatchOrder=0,1,2,3,4

+ (instancetype)tintColorBlue { return vendColor(13.0000f, 158.0000f, 215.0000f); }
+ (instancetype)tintColorRed { return vendColor(222.0000f, 36.0000f, 72.0000f); }
+ (instancetype)tintColorBackground { return vendColor(22.0000f, 106.0000f, 138.0000f); }
+ (instancetype)tintColorWhite { return (MADColor *)[UIColor whiteColor]; }
+ (instancetype)tintColorWhiteAlpha { return vendColorWithAlpha(255.0000f, 255.0000f, 255.0000f, 0.3333f); }
+ (instancetype)tintColorGold { return vendColor(164.0000f, 157.0000f, 26.0000f); }
+ (instancetype)tintColorGold2 { return vendColor(138.0000f, 131.0000f, 1.0000f); }

//Analogous on tintColorBlue
+ (instancetype)tintColorAnalogous1 { return vendColor(2.0000f, 46.0000f, 228.0000f); };
+ (instancetype)tintColorAnalogous2 { return vendColor(2.0000f, 110.0000f, 238.0000f); };
+ (instancetype)tintColorAnalogous3 { return vendColor(2.0000f, 233.0000f, 238.0000f); };
+ (instancetype)tintColorAnalogous4 { return vendColor(2.0000f, 228.0000f, 169.0000f); };
+ (instancetype)borderColor { return (MADColor *)[UIColor blackColor]; }

+ (instancetype)disabledColor { return (MADColor *)[[MADColor edaBlackFiftyPercent] colorWithAlphaComponent:selectedAlpha]; }

+ (instancetype)blueTwitter                       { return vendColor(0.0000f, 172.0000f, 237.0000f); }
+ (instancetype)blueLinkedIn                      { return vendColor(0.0000f, 123.0000f, 182.0000f); }
+ (instancetype)blueFacebook                      { return vendColor(59.0000f, 89.0000f, 152.0000f); }

@end
