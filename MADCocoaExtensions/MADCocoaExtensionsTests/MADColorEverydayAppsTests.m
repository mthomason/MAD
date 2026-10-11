//
//  MADColorEverydayAppsTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADColorEverydayApps, the app's fixed palette.  The factory methods
//  build sRGB colors from 8-bit triples (the helper divides by 255), so the pins here
//  are the resolved components, not just non-nil-ness: a palette change should be a
//  deliberate edit to this file.
//
//  The light-mode branches of -newColorHeaderColor and -blueHeaderSecondaryColor pass
//  those same 8-bit triples straight to +colorWithRed:green:blue:alpha: (which expects
//  0-1) instead of through the dividing helper, so the colors are stored out of range.
//  That is pinned as it currently behaves and recorded in BUGS.md.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIColor.h>
#import <UIKit/UITraitCollection.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@interface MADColorEverydayAppsTests : XCTestCase
@end

@implementation MADColorEverydayAppsTests

#pragma mark - Helpers

- (void)assertColor:(UIColor *)color
				red:(CGFloat)red
			  green:(CGFloat)green
			   blue:(CGFloat)blue
			  alpha:(CGFloat)alpha
			   line:(NSUInteger)line {
	CGFloat r = 0, g = 0, b = 0, a = 0;
	BOOL converted = [color getRed:&r green:&g blue:&b alpha:&a];
	XCTAssertTrue(converted, @"line %lu: color is not representable in sRGB", (unsigned long)line);
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

#pragma mark - Dynamic colors

- (void)testHeaderColorDarkModeIsTheSystemBackground {
	UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
	UIColor *resolved = [[MADColorEverydayApps newColorHeaderColor] resolvedColorWithTraitCollection:dark];
	UIColor *expected = [[UIColor secondarySystemBackgroundColor] resolvedColorWithTraitCollection:dark];

	XCTAssertEqualObjects(resolved, expected);
}

- (void)testHeaderColorLightModeComponentsAreOutOfRange {
	UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
	UIColor *resolved = [[MADColorEverydayApps newColorHeaderColor] resolvedColorWithTraitCollection:light];

	// Characterization of a defect documented in BUGS.md: the light branch passes the
	// 8-bit triple (2, 108, 182) to +colorWithRed:green:blue:alpha:, which expects 0-1.
	// The components are stored as given -- an extended-range sRGB color -- instead of
	// the intended (2/255, 108/255, 182/255), so the blue treatment is lost: at draw
	// time the out-of-range color resolves to white at 20% alpha.
	MADAssertColor(resolved, 2.0, 108.0, 182.0, 0.2);
}

- (void)testBlueHeaderSecondaryLightModeComponentsAreOutOfRange {
	UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
	UIColor *resolved = [[MADColorEverydayApps blueHeaderSecondaryColor] resolvedColorWithTraitCollection:light];

	// Same defect as above; here the alpha is 0, so the color is invisible either way.
	MADAssertColor(resolved, 13.0, 158.0, 215.0, 0.0);
}

- (void)testBlueHeaderSecondaryDarkModeIsTheSystemBackground {
	UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
	UIColor *resolved = [[MADColorEverydayApps blueHeaderSecondaryColor] resolvedColorWithTraitCollection:dark];
	UIColor *expected = [[UIColor secondarySystemBackgroundColor] resolvedColorWithTraitCollection:dark];

	XCTAssertEqualObjects(resolved, expected);
}

@end
