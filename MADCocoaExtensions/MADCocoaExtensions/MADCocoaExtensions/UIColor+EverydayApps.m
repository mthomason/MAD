//
//  UIColor+EverydayApps.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UIColor+EverydayApps.h"

#import <UIKit/UIColor.h>
#import <UIKit/UITraitCollection.h>


@implementation MADColorEverydayApps
 
 static const CGFloat selectedAlpha = 0.33333333f;
 
+ (UIColor *)newColorBlackish                       { id color = newColorWitColors(0.0000f, 0.0000f, 0.0000f); return color; }
+ (UIColor *)newColorBlueDark                       { id color = newColorWitColors(2.0000f, 108.0000f, 182.0000f); return color; }
+ (UIColor *)newColorBlueLight                      { id color = newColorWitColors(185.0000f, 224.0000f, 247.0000f); return color; }
+ (UIColor *)newColorBlueDarkSelection              { id color = newColorWithColorsAlpha(2.0000f, 108.0000f, 182.0000f, 0.5000f); return color; }
+ (UIColor *)newColorBlueLightSelection             { id color = newColorWithColorsAlpha(185.0000f, 224.0000f, 247.0000f, 0.5000f); return color; }
+ (UIColor *)newColorBlueLightBackground            { id color = newColorWithColorsAlpha(2.0000f, 108.0000f, 182.0000f, 0.8900f); return color; }
+ (UIColor *)newColorHeaderColor {
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
		if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return [UIColor secondarySystemBackgroundColor];
		} else {
			return [UIColor colorWithRed:2.0000f green:108.0000f blue:182.0000f alpha:0.20000f];
		}
	}];
}
+ (UIColor *)newColorBlackSeventyFivePercent        { id color = newColorWitColors(64.0000f, 64.0000f, 64.0000f); return color; }
+ (UIColor *)newColorBlackFiftyPercent              { id color = newColorWitColors(147.0000f, 149.0000f, 152.0000f); return color; }
+ (UIColor *)newColorBlackTwentyFivePercent         { id color = newColorWitColors(199.0000f, 200.0000f, 202.0000f); return color; }
+ (UIColor *)newColorOrange                         { id color = newColorWitColors(246.0000f, 160.0000f, 26.0000f); return color; }
+ (UIColor *)newColorYellow                         { id color = newColorWitColors(255.0000f, 227.0000f, 99.0000f); return color; }
+ (UIColor *)newColorGreenDark                      { id color = newColorWitColors(94.0000f, 151.0000f, 50.0000f); return color; }
+ (UIColor *)newColorGreenLight                     { id color = newColorWitColors(180.0000f, 216.0000f, 139.0000f); return color; }
+ (UIColor *)newColorTableHeaderBackground          { id color = [[UIColor alloc] initWithHue:0.5500f saturation:0.8000f brightness:0.8000f alpha:0.5000f]; return color; }

 //Triad on newColorBlue
 // Visit url: https://kuler.adobe.com/create/color-wheel/?base=2&rule=Triad&selected=2&name=My%20Kuler%20Theme&mode=rgb&rgbvalues=0.08715458276333791,0.41446887712012853,0.5431372549019609,0.869281045751634,0.13948928408572733,0.28340036579992106,0.050980392156862744,0.6196078431372549,0.8431372549019608,0.6431372549019607,0.6144138065677613,0.10320109439124488,0.5431372549019609,0.5145458915419016,0.005683994528043774&swatchOrder=0,1,2,3,4
 
 + (UIColor *)newColorBlue { id color = newColorWitColors(13.0000f, 158.0000f, 215.0000f); return color; }
 + (UIColor *)newColorRed { id color = newColorWitColors(222.0000f, 36.0000f, 72.0000f); return color; }
 + (UIColor *)newColorBackground { id color = newColorWitColors(22.0000f, 106.0000f, 138.0000f); return color; }
 + (UIColor *)newColorWhite { id color = [UIColor whiteColor]; return color; }
 + (UIColor *)newColorWhiteAlpha { id color = newColorWithColorsAlpha(255.0000f, 255.0000f, 255.0000f, 0.3333f); return color; }
 + (UIColor *)newColorGold { id color = newColorWitColors(164.0000f, 157.0000f, 26.0000f); return color; }
 + (UIColor *)newColorGold2 { id color = newColorWitColors(138.0000f, 131.0000f, 1.0000f); return color; }
 
 //Analogous on newColorBlue
 + (UIColor *)newColorAnalogous1 { id color = newColorWitColors(2.0000f, 46.0000f, 228.0000f); return color; };
 + (UIColor *)newColorAnalogous2 { id color = newColorWitColors(2.0000f, 110.0000f, 238.0000f); return color; };
 + (UIColor *)newColorAnalogous3 { id color = newColorWitColors(2.0000f, 233.0000f, 238.0000f); return color; };
 + (UIColor *)newColorAnalogous4 { id color = newColorWitColors(2.0000f, 228.0000f, 169.0000f); return color; };
 + (UIColor *)newColorBorderColor { id color = [UIColor blackColor]; return color; }
 
 + (UIColor *)newColorDisabledColor {
	 UIColor *color = [self newColorBlackFiftyPercent];
	 color = [color colorWithAlphaComponent:selectedAlpha];
	 return color;
 }
 
@end
