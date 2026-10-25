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
	XCTAssertEqualObjects(formatter.decimalSeparator, @".");
	XCTAssertEqualObjects(formatter.groupingSeparator, @",");
}

@end
