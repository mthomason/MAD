//
//  MADColorEverydayAppsTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADColorEverydayApps, the app's fixed palette.  The factory methods
//  build sRGB colors from 8-bit triples (the helper divides by 255), so the pins here
//  are the resolved components, not just non-nil-ness: a palette change should be a
//  deliberate edit to this file.
//
//  The light-mode branches of -newColorHeaderColor and -blueHeaderSecondaryColor
//  divide the same 8-bit triples by 255, like the rest of the palette.
//

#import <XCTest/XCTest.h>
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIColor.h>
#import <UIKit/UITraitCollection.h>
#elif TARGET_OS_OSX
#import <AppKit/NSColor.h>
#import <AppKit/NSColorSpace.h>
#endif

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@interface MADColorEverydayAppsTests : XCTestCase
@end

@implementation MADColorEverydayAppsTests

#pragma mark - Helpers

- (void)assertColor:(MADPlatformColor *)color
				red:(CGFloat)red
			  green:(CGFloat)green
			   blue:(CGFloat)blue
			  alpha:(CGFloat)alpha
			   line:(NSUInteger)line {
	CGFloat r = 0, g = 0, b = 0, a = 0;
#if TARGET_OS_IPHONE
	BOOL converted = [color getRed:&r green:&g blue:&b alpha:&a];
	XCTAssertTrue(converted, @"line %lu: color is not representable in sRGB", (unsigned long)line);
#else
	NSColor *srgb = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
	XCTAssertNotNil(srgb, @"line %lu: color is not representable in sRGB", (unsigned long)line);
	[srgb getRed:&r green:&g blue:&b alpha:&a];
#endif
	XCTAssertEqualWithAccuracy(r, red, 0.0001, @"line %lu", (unsigned long)line);
	XCTAssertEqualWithAccuracy(g, green, 0.0001, @"line %lu", (unsigned long)line);
	XCTAssertEqualWithAccuracy(b, blue, 0.0001, @"line %lu", (unsigned long)line);
	XCTAssertEqualWithAccuracy(a, alpha, 0.0001, @"line %lu", (unsigned long)line);
}

#define MADAssertColor(color, r, g, b, a) \
	[self assertColor:(color) red:(r) green:(g) blue:(b) alpha:(a) line:__LINE__]

- (CGFloat)byte:(NSUInteger)value { return (CGFloat)value / 255.0; }

#pragma mark - Palette

- (void)testBlueFamily {
	MADAssertColor([MADColorEverydayApps newColorBlueDark], [self byte:2], [self byte:108], [self byte:182], 1.0);
	MADAssertColor([MADColorEverydayApps newColorBlueLightBackground], [self byte:2], [self byte:108], [self byte:182], 0.89);
	MADAssertColor([MADColorEverydayApps newColorBlue], [self byte:13], [self byte:158], [self byte:215], 1.0);
}

- (void)testGreyscaleFamily {
	MADAssertColor([MADColorEverydayApps newColorBlackSeventyFivePercent], [self byte:64], [self byte:64], [self byte:64], 1.0);
	MADAssertColor([MADColorEverydayApps newColorBlackTwentyFivePercent], [self byte:199], [self byte:200], [self byte:202], 1.0);
	MADAssertColor([MADColorEverydayApps newColorWhite], 1.0, 1.0, 1.0, 1.0);
}

- (void)testAccents {
	MADAssertColor([MADColorEverydayApps newColorRed], [self byte:222], [self byte:36], [self byte:72], 1.0);
	MADAssertColor([MADColorEverydayApps newColorAnalogous4], [self byte:2], [self byte:228], [self byte:169], 1.0);
	MADAssertColor([MADColorEverydayApps newColorBorderColor], 0.0, 0.0, 0.0, 1.0);
}

- (void)testDisabledColorIsTheFiftyPercentGreyAtOneThirdAlpha {
	MADAssertColor([MADColorEverydayApps newColorDisabledColor], [self byte:147], [self byte:149], [self byte:152], 0.33333333);
}

#if TARGET_OS_IPHONE
#pragma mark - Dynamic colors

- (void)testHeaderColorDarkModeIsTheSystemBackground {
	UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
	UIColor *resolved = [[MADColorEverydayApps newColorHeaderColor] resolvedColorWithTraitCollection:dark];
	UIColor *expected = [[UIColor secondarySystemBackgroundColor] resolvedColorWithTraitCollection:dark];

	XCTAssertEqualObjects(resolved, expected);
}

- (void)testHeaderColorLightModeUsesTheIntendedComponents {
	UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
	UIColor *resolved = [[MADColorEverydayApps newColorHeaderColor] resolvedColorWithTraitCollection:light];

	MADAssertColor(resolved, [self byte:2], [self byte:108], [self byte:182], 0.2);
}

- (void)testBlueHeaderSecondaryLightModeUsesTheIntendedComponents {
	UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
	UIColor *resolved = [[MADColorEverydayApps blueHeaderSecondaryColor] resolvedColorWithTraitCollection:light];

	// Alpha is 0 by design, so the color is invisible; the components are still unit-scale.
	MADAssertColor(resolved, [self byte:13], [self byte:158], [self byte:215], 0.0);
}

- (void)testBlueHeaderSecondaryDarkModeIsTheSystemBackground {
	UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
	UIColor *resolved = [[MADColorEverydayApps blueHeaderSecondaryColor] resolvedColorWithTraitCollection:dark];
	UIColor *expected = [[UIColor secondarySystemBackgroundColor] resolvedColorWithTraitCollection:dark];

	XCTAssertEqualObjects(resolved, expected);
}
#endif

@end
