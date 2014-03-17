//
//  UIColor+EverydayApps.m
//  Reports
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIColor+EverydayApps.h"

#define vendColor(r, g, b) static UIColor *ret; if (ret == nil) ret = [[UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:1.0000f] retain]; return ret

#define vendColorWithAlpha(r, g, b, a) static UIColor *ret; if (ret == nil) ret = [[UIColor colorWithRed:(CGFloat)r/255.0000f green:(CGFloat)g/255.0000f blue:(CGFloat)b/255.0000f alpha:a] retain]; return ret

@implementation UIColor(EverydayApps)

+ (id)edaBlackish                       {vendColor(0.0000f, 0.0000f, 0.0000f);}
+ (id)edaBlueDark                       {vendColor(2.0000f, 108.0000f, 182.0000f);}
+ (id)edaBlueLight                      {vendColor(185.0000f, 224.0000f, 247.0000f);}
+ (id)edaBlueDarkSelection              {vendColorWithAlpha(2.0000f, 108.0000f, 182.0000f, 0.5000f);}
+ (id)edaBlueLightSelection             {vendColorWithAlpha(185.0000f, 224.0000f, 247.0000f, 0.5000f);}
+ (id)edaBlackFiftyPercent              {vendColor(147.0000f, 149.0000f, 152.0000f);}
+ (id)edaBlackTwentyFivePercent         {vendColor(199.0000f, 200.0000f, 202.0000f);}
+ (id)edaOrange                         {vendColor(246.0000f, 160.0000f, 26.0000f);}
+ (id)edaYellow                         {vendColor(255.0000f, 227.0000f, 99.0000f);}
+ (id)edaGreenDark                      {vendColor(94.0000f, 151.0000f, 50.0000f);}
+ (id)edaGreenLight                     {vendColor(180.0000f, 216.0000f, 139.0000f);}
+ (id)edaTableHeaderBackground          {return [UIColor colorWithHue:0.5500f saturation:0.8000f brightness:0.8000f alpha:0.5000f];}

+ (id)tintColor { vendColor(13.0000f, 158.0000f, 215.0000f); }
+ (id)tintColorRed { vendColor(222.0000f, 36.0000f, 72.0000f); }
+ (id)tintColor2 {static UIColor *ret; if (ret == nil) ret = [[UIColor whiteColor] retain]; return ret; }
+ (id)tintColor3 { vendColor(164.0000f, 157.0000f, 26.0000f); }
+ (id)tintColor4 { vendColor(138.0000f, 131.0000f, 1.0000f); }

//vendColor(6.0000f, 156.0000f, 217.0000f);}

@end
