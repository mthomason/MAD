//
//  MADColorTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADColor (hex string, RGB components, copy) and the free color
//  factory functions.  Documents the "instancetype lie" in MADColorSocial, whose
//  +newBlueTwitter actually returns a UIColor.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIColor.h>

#import <MADCocoaExtensions/MADColor.h>
#import <MADCocoaExtensions/MADColorSocial.h>

@interface MADColorTests : XCTestCase
@end

@implementation MADColorTests

- (void)testHexStringValueRed {
	MADColor *color = [[MADColor alloc] initWithColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
	XCTAssertEqualObjects(color.hexStringValue, @"FF0000");
}

- (void)testHexStringValueGreen {
	MADColor *color = [[MADColor alloc] initWithColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0]];
	XCTAssertEqualObjects(color.hexStringValue, @"00FF00");
}

- (void)testHexStringValueBlue {
	MADColor *color = [[MADColor alloc] initWithColor:[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0]];
	XCTAssertEqualObjects(color.hexStringValue, @"0000FF");
}

- (void)testRGBComponentFlags {
	MADColor *color = [[MADColor alloc] initWithColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
	XCTAssertTrue(color.canProvideRGBComponents);
	XCTAssertTrue(color.usesRGBColorspace);
	XCTAssertFalse(color.usesMonochromeColorspace);
}

- (void)testRGBBytes {
	MADColor *color = [[MADColor alloc] initWithColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
	XCTAssertEqual(color.redByte, (Byte)0xFF);
	XCTAssertEqual(color.greenByte, (Byte)0x00);
	XCTAssertEqual(color.blueByte, (Byte)0x00);
	XCTAssertEqual(color.alphaByte, (Byte)0xFF);
}

- (void)testCopy {
	MADColor *color = [[MADColor alloc] initWithColor:[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0]];
	MADColor *copy = [color copy];
	XCTAssertNotNil(copy);
	XCTAssertEqualObjects(copy.hexStringValue, @"0000FF");
}

- (void)testFactoryFunctions {
	UIColor *red = newColorWitColors(255, 0, 0);
	CGFloat r = -1, g = -1, b = -1, a = -1;
	XCTAssertTrue([red getRed:&r green:&g blue:&b alpha:&a]);
	XCTAssertEqualWithAccuracy(r, 1.0, 0.001);
	XCTAssertEqualWithAccuracy(g, 0.0, 0.001);
	XCTAssertEqualWithAccuracy(b, 0.0, 0.001);
	XCTAssertEqualWithAccuracy(a, 1.0, 0.001);

	UIColor *translucentBlue = newColorWithColorsAlpha(0, 0, 255, 0.5);
	CGFloat r2 = -1, g2 = -1, b2 = -1, a2 = -1;
	XCTAssertTrue([translucentBlue getRed:&r2 green:&g2 blue:&b2 alpha:&a2]);
	XCTAssertEqualWithAccuracy(b2, 1.0, 0.001);
	XCTAssertEqualWithAccuracy(a2, 0.5, 0.001);
}

- (void)testSocialColorIsUIColor {
	// +newBlueTwitter builds a plain UIColor, and now declares that it does.
	UIColor *twitter = [MADColorSocial newBlueTwitter];
	XCTAssertTrue([twitter isKindOfClass:[UIColor class]]);
}

@end
