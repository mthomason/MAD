//
//  UIColor+EverydayApps.m
//  Reports
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//
#import "UIColor+EverydayApps.h"

 @implementation MADColorEverydayApps
 
 static const CGFloat selectedAlpha = 0.33333333f;
 
 + (UIColor *)newColorBlackish                       { return newColorWitColors(0.0000f, 0.0000f, 0.0000f);}
 + (UIColor *)newColorBlueDark                       { return newColorWitColors(2.0000f, 108.0000f, 182.0000f);}
 + (UIColor *)newColorBlueLight                      { return newColorWitColors(185.0000f, 224.0000f, 247.0000f);}
 + (UIColor *)newColorBlueDarkSelection              { return newColorWithColorsAlpha(2.0000f, 108.0000f, 182.0000f, 0.5000f);}
 + (UIColor *)newColorBlueLightSelection             { return newColorWithColorsAlpha(185.0000f, 224.0000f, 247.0000f, 0.5000f);}
 + (UIColor *)newColorBlueLightBackground            { return newColorWithColorsAlpha(2.0000f, 108.0000f, 182.0000f, 0.8900f);}
 + (UIColor *)newColorHeaderColor                    { UIColor *color = [self newColorBlueLightBackground]; return [color colorWithAlphaComponent:0.20000f]; }
 + (UIColor *)newColorBlackSeventyFivePercent        { return newColorWitColors(64.0000f, 64.0000f, 64.0000f);}
 + (UIColor *)newColorBlackFiftyPercent              { return newColorWitColors(147.0000f, 149.0000f, 152.0000f);}
 + (UIColor *)newColorBlackTwentyFivePercent         { return newColorWitColors(199.0000f, 200.0000f, 202.0000f);}
 + (UIColor *)newColorOrange                         { return newColorWitColors(246.0000f, 160.0000f, 26.0000f);}
 + (UIColor *)newColorYellow                         { return newColorWitColors(255.0000f, 227.0000f, 99.0000f);}
 + (UIColor *)newColorGreenDark                      { return newColorWitColors(94.0000f, 151.0000f, 50.0000f);}
 + (UIColor *)newColorGreenLight                     { return newColorWitColors(180.0000f, 216.0000f, 139.0000f);}
 + (UIColor *)newColorTableHeaderBackground          { return [UIColor colorWithHue:0.5500f saturation:0.8000f brightness:0.8000f alpha:0.5000f];}
 
 //Triad on newColorBlue
 // Visit url: https://kuler.adobe.com/create/color-wheel/?base=2&rule=Triad&selected=2&name=My%20Kuler%20Theme&mode=rgb&rgbvalues=0.08715458276333791,0.41446887712012853,0.5431372549019609,0.869281045751634,0.13948928408572733,0.28340036579992106,0.050980392156862744,0.6196078431372549,0.8431372549019608,0.6431372549019607,0.6144138065677613,0.10320109439124488,0.5431372549019609,0.5145458915419016,0.005683994528043774&swatchOrder=0,1,2,3,4
 
 + (UIColor *)newColorBlue { return newColorWitColors(13.0000f, 158.0000f, 215.0000f); }
 + (UIColor *)newColorRed { return newColorWitColors(222.0000f, 36.0000f, 72.0000f); }
 + (UIColor *)newColorBackground { return newColorWitColors(22.0000f, 106.0000f, 138.0000f); }
 + (UIColor *)newColorWhite { return [UIColor whiteColor]; }
 + (UIColor *)newColorWhiteAlpha { return newColorWithColorsAlpha(255.0000f, 255.0000f, 255.0000f, 0.3333f); }
 + (UIColor *)newColorGold { return newColorWitColors(164.0000f, 157.0000f, 26.0000f); }
 + (UIColor *)newColorGold2 { return newColorWitColors(138.0000f, 131.0000f, 1.0000f); }
 
 //Analogous on newColorBlue
 + (UIColor *)newColorAnalogous1 { return newColorWitColors(2.0000f, 46.0000f, 228.0000f); };
 + (UIColor *)newColorAnalogous2 { return newColorWitColors(2.0000f, 110.0000f, 238.0000f); };
 + (UIColor *)newColorAnalogous3 { return newColorWitColors(2.0000f, 233.0000f, 238.0000f); };
 + (UIColor *)newColorAnalogous4 { return newColorWitColors(2.0000f, 228.0000f, 169.0000f); };
 + (UIColor *)newColorBorderColor { return [UIColor blackColor]; }
 
 + (UIColor *)newColorDisabledColor {
     UIColor *color = [self newColorBlackFiftyPercent];
     return [color colorWithAlphaComponent:selectedAlpha];
 }
 
@end
