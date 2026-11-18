//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADBorderStyleTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/MADBorderStyleTests.m: the
//  MADBorderType enum, init, accessors, the coding round trip and NSCopying
//  independence.  The Xcode suite's secure-coding round trip runs on the
//  permissive path off Apple, as the toolchain probe records.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/MADBorderStyle.h>

static void testBorderTypeValues(void) {
	MAD_PASS(MADBorderStyleNone == (MADBorderType)1, "None is 1");
	MAD_PASS(MADBorderStyleDash == (MADBorderType)2, "Dash is 2");
	MAD_PASS(MADBorderStyleDot == (MADBorderType)3, "Dot is 3");
	MAD_PASS(MADBorderStyleLine == (MADBorderType)4, "Line is 4");
}

static void testInitDefaults(void) {
	MADBorderStyle *style = [[MADBorderStyle alloc] init];
	MAD_PASS(style.left == (float)0, "left defaults to zero");
	MAD_PASS(style.right == (float)0, "right defaults to zero");
	MAD_PASS(style.top == (float)0, "top defaults to zero");
	MAD_PASS(style.bottom == (float)0, "bottom defaults to zero");
	MAD_PASS(style.leftStyle == MADBorderStyleNone, "the left style defaults to None");
	MAD_PASS(style.rightStyle == MADBorderStyleNone, "the right style defaults to None");
	MAD_PASS(style.topStyle == MADBorderStyleNone, "the top style defaults to None");
	MAD_PASS(style.bottomStyle == MADBorderStyleNone, "the bottom style defaults to None");
}

static void testInitWithEdgesAndStyles(void) {
	MADBorderStyle *style = [[MADBorderStyle alloc] initWithLeft:1 right:2 top:3 bottom:4
													   leftStyle:MADBorderStyleLine rightStyle:MADBorderStyleDash
														topStyle:MADBorderStyleDot bottomStyle:MADBorderStyleNone];
	MAD_PASS(style.left == (float)1, "left comes back");
	MAD_PASS(style.right == (float)2, "right comes back");
	MAD_PASS(style.top == (float)3, "top comes back");
	MAD_PASS(style.bottom == (float)4, "bottom comes back");
	MAD_PASS(style.leftStyle == MADBorderStyleLine, "the left style comes back");
	MAD_PASS(style.rightStyle == MADBorderStyleDash, "the right style comes back");
	MAD_PASS(style.topStyle == MADBorderStyleDot, "the top style comes back");
	MAD_PASS(style.bottomStyle == MADBorderStyleNone, "the bottom style comes back");
}

static void testSetters(void) {
	MADBorderStyle *style = [[MADBorderStyle alloc] init];
	style.leftStyle = MADBorderStyleDot;
	style.top = 5;
	MAD_PASS(style.leftStyle == MADBorderStyleDot, "the left style round trips");
	MAD_PASS(style.top == (float)5, "the top width round trips");
}

static void testCopyIsIndependent(void) {
	MADBorderStyle *style = [[MADBorderStyle alloc] initWithLeft:1 right:2 top:3 bottom:4
													   leftStyle:MADBorderStyleLine rightStyle:MADBorderStyleLine
														topStyle:MADBorderStyleLine bottomStyle:MADBorderStyleLine];
	MADBorderStyle *copy = [style copy];
	MAD_PASS(copy != nil, "the copy exists");
	copy.left = 99;
	MAD_PASS(copy.left == (float)99, "the copy takes the new value");
	MAD_PASS(style.left == (float)1, "the original is unchanged");
}

static void testCodingRoundTrip(void) {
	MADBorderStyle *style = [[MADBorderStyle alloc] initWithLeft:1.5 right:2.5 top:3.5 bottom:4.5
													   leftStyle:MADBorderStyleLine rightStyle:MADBorderStyleDash
														topStyle:MADBorderStyleDot bottomStyle:MADBorderStyleNone];
	NSError *error = nil;
#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:style requiringSecureCoding:YES error:&error];
	MAD_PASS(error == nil, "no error from the secure archive");
	MAD_PASS(data != nil, "the secure archive has bytes");

	MADBorderStyle *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADBorderStyle class] fromData:data error:&error];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:style requiringSecureCoding:NO error:&error];
	MAD_PASS(error == nil, "no error from the archive");
	MAD_PASS(data != nil, "the archive has bytes");

	MADBorderStyle *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
#endif
	MAD_PASS(error == nil, "no error from unarchiving");
	MAD_PASS(decoded != nil, "the border style round trips");
	MAD_PASS(decoded.left == (float)1.5, "left survives the round trip");
	MAD_PASS(decoded.right == (float)2.5, "right survives the round trip");
	MAD_PASS(decoded.top == (float)3.5, "top survives the round trip");
	MAD_PASS(decoded.bottom == (float)4.5, "bottom survives the round trip");
	MAD_PASS(decoded.leftStyle == MADBorderStyleLine, "the left style survives the round trip");
	MAD_PASS(decoded.rightStyle == MADBorderStyleDash, "the right style survives the round trip");
	MAD_PASS(decoded.topStyle == MADBorderStyleDot, "the top style survives the round trip");
	MAD_PASS(decoded.bottomStyle == MADBorderStyleNone, "the bottom style survives the round trip");
}

MAD_TEST_MAIN("MADBorderStyleTests",
	MAD_TEST(testBorderTypeValues),
	MAD_TEST(testInitDefaults),
	MAD_TEST(testInitWithEdgesAndStyles),
	MAD_TEST(testSetters),
	MAD_TEST(testCopyIsIndependent),
	MAD_TEST(testCodingRoundTrip));
