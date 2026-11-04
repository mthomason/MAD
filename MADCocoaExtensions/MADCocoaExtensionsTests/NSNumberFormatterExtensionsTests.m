//
//  NSNumberFormatterExtensionsTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the NSNumberFormatter (MADExtensions) factory.
//

#import <XCTest/XCTest.h>

#import <MADCocoaExtensions/NSNumberFormatter+MADExtensions.h>

@interface NSNumberFormatterExtensionsTests : XCTestCase
@end

@implementation NSNumberFormatterExtensionsTests

- (void)testTwoDecimalPlacesFormatter {
	NSNumberFormatter *formatter = [NSNumberFormatter ma_twoDecimalPlacesFormatter];
	XCTAssertNotNil(formatter);
	XCTAssertEqual(formatter.numberStyle, NSNumberFormatterDecimalStyle);
	XCTAssertEqual(formatter.maximumFractionDigits, (NSUInteger)2);

	// The factory must not pin separators; a plain formatter carries the locale.
	NSNumberFormatter *reference = [[NSNumberFormatter alloc] init];
	reference.numberStyle = NSNumberFormatterDecimalStyle;
	XCTAssertEqualObjects(formatter.decimalSeparator, reference.decimalSeparator);
	XCTAssertEqualObjects(formatter.groupingSeparator, reference.groupingSeparator);
}

@end
