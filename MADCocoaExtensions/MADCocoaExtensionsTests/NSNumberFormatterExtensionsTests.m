//
//  NSNumberFormatterExtensionsTests.m
//  MADCocoaExtensionsTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
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
