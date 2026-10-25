//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  NSNumberFormatterExtensionsTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/NSNumberFormatterExtensionsTests.m:
//  the NSNumberFormatter (MADExtensions) factory.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/NSNumberFormatter+MADExtensions.h>

static void testTwoDecimalPlacesFormatter(void) {
	NSNumberFormatter *formatter = [NSNumberFormatter ma_twoDecimalPlacesFormatter];
	MAD_PASS(formatter != nil, "the formatter exists");
	MAD_PASS(formatter.numberStyle == NSNumberFormatterDecimalStyle, "the style is decimal");
	MAD_PASS(formatter.maximumFractionDigits == (NSUInteger)2, "two fraction digits");
	MAD_PASS_EQUAL(formatter.decimalSeparator, @".", "the decimal separator is a period");
	MAD_PASS_EQUAL(formatter.groupingSeparator, @",", "the grouping separator is a comma");
}

MAD_TEST_MAIN("NSNumberFormatterExtensionsTests",
	MAD_TEST(testTwoDecimalPlacesFormatter));
