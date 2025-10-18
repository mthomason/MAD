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
 
+ (UIColor *)newColorBlackish                       { id color = newColorWitColors(0.0, 0.0, 0.0); return color; }
+ (UIColor *)newColorBlueDark                       { id color = newColorWitColors(2.0, 108.0, 182.0); return color; }
+ (UIColor *)newColorBlueLight                      { id color = newColorWitColors(185.0, 224.0, 247.0); return color; }
+ (UIColor *)newColorBlueDarkSelection              { id color = newColorWithColorsAlpha(2.0, 108.0, 182.0, 0.5); return color; }
+ (UIColor *)newColorBlueLightSelection             { id color = newColorWithColorsAlpha(185.0, 224.0, 247.0, 0.5); return color; }
+ (UIColor *)newColorBlueLightBackground            { id color = newColorWithColorsAlpha(2.0, 108.0, 182.0, 0.89); return color; }
+ (UIColor *)newColorHeaderColor {
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
		if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return [UIColor secondarySystemBackgroundColor];
		} else {
			return [UIColor colorWithRed:2.0 green:108.0 blue:182.0 alpha:0.20000f];
		}
	}];
}

+ (UIColor *)blueHeaderSecondaryColor {
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
		if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return [UIColor secondarySystemBackgroundColor];
		} else {
			return [UIColor colorWithRed:13.0 green:158.0 blue:215.0 alpha:0.0];
		}
	}];
}

+ (UIColor *)newColorBlackSeventyFivePercent        { id color = newColorWitColors(64.0, 64.0, 64.0); return color; }
+ (UIColor *)newColorBlackFiftyPercent              { id color = newColorWitColors(147.0, 149.0, 152.0); return color; }
+ (UIColor *)newColorBlackTwentyFivePercent         { id color = newColorWitColors(199.0, 200.0, 202.0); return color; }
+ (UIColor *)newColorOrange                         { id color = newColorWitColors(246.0, 160.0, 26.0); return color; }
+ (UIColor *)newColorYellow                         { id color = newColorWitColors(255.0, 227.0, 99.0); return color; }
+ (UIColor *)newColorGreenDark                      { id color = newColorWitColors(94.0, 151.0, 50.0); return color; }
+ (UIColor *)newColorGreenLight                     { id color = newColorWitColors(180.0, 216.0, 139.0); return color; }
+ (UIColor *)newColorTableHeaderBackground          { id color = [[UIColor alloc] initWithHue:0.5500f saturation:0.8000f brightness:0.8000f alpha:0.5000f]; return color; }

 //Triad on newColorBlue
 // Visit url: https://kuler.adobe.com/create/color-wheel/?base=2&rule=Triad&selected=2&name=My%20Kuler%20Theme&mode=rgb&rgbvalues=0.08715458276333791,0.41446887712012853,0.5431372549019609,0.869281045751634,0.13948928408572733,0.28340036579992106,0.050980392156862744,0.6196078431372549,0.8431372549019608,0.6431372549019607,0.6144138065677613,0.10320109439124488,0.5431372549019609,0.5145458915419016,0.005683994528043774&swatchOrder=0,1,2,3,4
 
 + (UIColor *)newColorBlue { id color = newColorWitColors(13.0, 158.0, 215.0); return color; }
 + (UIColor *)newColorRed { id color = newColorWitColors(222.0, 36.0, 72.0); return color; }
 + (UIColor *)newColorBackground { id color = newColorWitColors(22.0, 106.0, 138.0); return color; }
 + (UIColor *)newColorWhite { id color = [UIColor whiteColor]; return color; }
 + (UIColor *)newColorWhiteAlpha { id color = newColorWithColorsAlpha(255.0, 255.0, 255.0, 0.3333f); return color; }
 + (UIColor *)newColorGold { id color = newColorWitColors(164.0, 157.0, 26.0); return color; }
 + (UIColor *)newColorGold2 { id color = newColorWitColors(138.0, 131.0, 1.0); return color; }
 
 //Analogous on newColorBlue
 + (UIColor *)newColorAnalogous1 { id color = newColorWitColors(2.0, 46.0, 228.0); return color; };
 + (UIColor *)newColorAnalogous2 { id color = newColorWitColors(2.0, 110.0, 238.0); return color; };
 + (UIColor *)newColorAnalogous3 { id color = newColorWitColors(2.0, 233.0, 238.0); return color; };
 + (UIColor *)newColorAnalogous4 { id color = newColorWitColors(2.0, 228.0, 169.0); return color; };
 + (UIColor *)newColorBorderColor { id color = [UIColor blackColor]; return color; }
 
 + (UIColor *)newColorDisabledColor {
	 UIColor *color = [self newColorBlackFiftyPercent];
	 color = [color colorWithAlphaComponent:selectedAlpha];
	 return color;
 }
 
@end
