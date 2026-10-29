//
//  UIColor+EverydayApps.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "UIColor+EverydayApps.h"

#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
#import <AppKit/NSColor.h>
#import <AppKit/NSAppearance.h>
#else
#import <UIKit/UIColor.h>
#import <UIKit/UITraitCollection.h>
#endif


@implementation MADColorEverydayApps
 
 static const CGFloat selectedAlpha = 0.33333333f;
 
+ (MADPlatformColor *)newColorBlackish                       { id color = newColorWitColors(0.0, 0.0, 0.0); return color; }
+ (MADPlatformColor *)newColorBlueDark                       { id color = newColorWitColors(2.0, 108.0, 182.0); return color; }
+ (MADPlatformColor *)newColorBlueLight                      { id color = newColorWitColors(185.0, 224.0, 247.0); return color; }
+ (MADPlatformColor *)newColorBlueDarkSelection              { id color = newColorWithColorsAlpha(2.0, 108.0, 182.0, 0.5); return color; }
+ (MADPlatformColor *)newColorBlueLightSelection             { id color = newColorWithColorsAlpha(185.0, 224.0, 247.0, 0.5); return color; }
+ (MADPlatformColor *)newColorBlueLightBackground            { id color = newColorWithColorsAlpha(2.0, 108.0, 182.0, 0.89); return color; }
+ (MADPlatformColor *)newColorHeaderColor {
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
	return [NSColor colorWithSRGBRed:2.0/MADF255 green:108.0/MADF255 blue:182.0/MADF255 alpha:0.20000f];
#else
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
		if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return [UIColor secondarySystemBackgroundColor];
		} else {
			return [UIColor colorWithRed:2.0 green:108.0 blue:182.0 alpha:0.20000f];
		}
	}];
#endif
}

+ (MADPlatformColor *)blueHeaderSecondaryColor {
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
	return [NSColor colorWithSRGBRed:13.0/MADF255 green:158.0/MADF255 blue:215.0/MADF255 alpha:0.0];
#else
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
		if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return [UIColor secondarySystemBackgroundColor];
		} else {
			return [UIColor colorWithRed:13.0 green:158.0 blue:215.0 alpha:0.0];
		}
	}];
#endif
}

+ (MADPlatformColor *)newColorBlackSeventyFivePercent        { id color = newColorWitColors(64.0, 64.0, 64.0); return color; }
+ (MADPlatformColor *)newColorBlackFiftyPercent              { id color = newColorWitColors(147.0, 149.0, 152.0); return color; }
+ (MADPlatformColor *)newColorBlackTwentyFivePercent         { id color = newColorWitColors(199.0, 200.0, 202.0); return color; }
+ (MADPlatformColor *)newColorOrange                         { id color = newColorWitColors(246.0, 160.0, 26.0); return color; }
+ (MADPlatformColor *)newColorYellow                         { id color = newColorWitColors(255.0, 227.0, 99.0); return color; }
+ (MADPlatformColor *)newColorGreenDark                      { id color = newColorWitColors(94.0, 151.0, 50.0); return color; }
+ (MADPlatformColor *)newColorGreenLight                     { id color = newColorWitColors(180.0, 216.0, 139.0); return color; }
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
+ (MADPlatformColor *)newColorTableHeaderBackground          { id color = [NSColor colorWithHue:0.5500f saturation:0.8000f brightness:0.8000f alpha:0.5000f]; return color; }
#else
+ (MADPlatformColor *)newColorTableHeaderBackground          { id color = [[UIColor alloc] initWithHue:0.5500f saturation:0.8000f brightness:0.8000f alpha:0.5000f]; return color; }
#endif

 //Triad on newColorBlue
 // Visit url: https://kuler.adobe.com/create/color-wheel/?base=2&rule=Triad&selected=2&name=My%20Kuler%20Theme&mode=rgb&rgbvalues=0.08715458276333791,0.41446887712012853,0.5431372549019609,0.869281045751634,0.13948928408572733,0.28340036579992106,0.050980392156862744,0.6196078431372549,0.8431372549019608,0.6431372549019607,0.6144138065677613,0.10320109439124488,0.5431372549019609,0.5145458915419016,0.005683994528043774&swatchOrder=0,1,2,3,4
 
 + (MADPlatformColor *)newColorBlue { id color = newColorWitColors(13.0, 158.0, 215.0); return color; }
 + (MADPlatformColor *)newColorRed { id color = newColorWitColors(222.0, 36.0, 72.0); return color; }
 + (MADPlatformColor *)newColorBackground { id color = newColorWitColors(22.0, 106.0, 138.0); return color; }
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
 + (MADPlatformColor *)newColorWhite { id color = [NSColor whiteColor]; return color; }
#else
 + (MADPlatformColor *)newColorWhite { id color = [UIColor whiteColor]; return color; }
#endif
 + (MADPlatformColor *)newColorWhiteAlpha { id color = newColorWithColorsAlpha(255.0, 255.0, 255.0, 0.3333f); return color; }
 + (MADPlatformColor *)newColorGold { id color = newColorWitColors(164.0, 157.0, 26.0); return color; }
 + (MADPlatformColor *)newColorGold2 { id color = newColorWitColors(138.0, 131.0, 1.0); return color; }
 
 //Analogous on newColorBlue
 + (MADPlatformColor *)newColorAnalogous1 { id color = newColorWitColors(2.0, 46.0, 228.0); return color; };
 + (MADPlatformColor *)newColorAnalogous2 { id color = newColorWitColors(2.0, 110.0, 238.0); return color; };
 + (MADPlatformColor *)newColorAnalogous3 { id color = newColorWitColors(2.0, 233.0, 238.0); return color; };
 + (MADPlatformColor *)newColorAnalogous4 { id color = newColorWitColors(2.0, 228.0, 169.0); return color; };
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
 + (MADPlatformColor *)newColorBorderColor { id color = [NSColor blackColor]; return color; }
#else
 + (MADPlatformColor *)newColorBorderColor { id color = [UIColor blackColor]; return color; }
#endif
 
 + (MADPlatformColor *)newColorDisabledColor {
	 MADPlatformColor *color = [self newColorBlackFiftyPercent];
	 color = [color colorWithAlphaComponent:selectedAlpha];
	 return color;
 }
 
@end
