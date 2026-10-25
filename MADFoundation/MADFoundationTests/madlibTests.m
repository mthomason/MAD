//
//  madlibTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the C string helpers in madlib.c: the hand-rolled integer-to-ASCII
//  converters and digit counters.  These predate the framework and are used where a
//  formatter allocation in a hot loop was unwelcome.
//
//  Pinned edge cases:
//    * The counters answer 0 for zero (the loop never runs), unlike madmath's
//      digit_count_* which answer 1.  See madmathTests / MADCoreLogicTests.
//    * The converters answer "0" for zero (do/while).
//    * ltoa takes only non-negative input; a negative value emits garbage because
//      the remainder stays negative.  Callers pass array indices, so that is not
//      exercised here -- it is recorded rather than pinned.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/madlib.h>

#include <limits.h>

@interface madlibTests : XCTestCase
@end

@implementation madlibTests

#pragma mark - Digit counters

- (void)testCountDigitsUL {
	// Zero takes zero iterations.
	XCTAssertEqual(count_digits_ul(0), (unsigned long)0);
	XCTAssertEqual(count_digits_ul(1), (unsigned long)1);
	XCTAssertEqual(count_digits_ul(9), (unsigned long)1);
	XCTAssertEqual(count_digits_ul(10), (unsigned long)2);
	XCTAssertEqual(count_digits_ul(99), (unsigned long)2);
	XCTAssertEqual(count_digits_ul(100), (unsigned long)3);
	XCTAssertEqual(count_digits_ul(ULONG_MAX), (unsigned long)20);
}

- (void)testCountDigits {
	XCTAssertEqual(count_digits(0), 0);
	XCTAssertEqual(count_digits(7), 1);
	XCTAssertEqual(count_digits(10), 2);
	// Integer division truncates toward zero, so negatives count their digits.
	XCTAssertEqual(count_digits(-9), 1);
	XCTAssertEqual(count_digits(-10), 2);
	XCTAssertEqual(count_digits(INT_MAX), 10);
}

#pragma mark - Unsigned converters

- (void)testUltoa {
	char buffer[32];

	XCTAssertEqual(ultoa(0, buffer), 1);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"0");

	XCTAssertEqual(ultoa(12345, buffer), 5);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"12345");

	XCTAssertEqual(ultoa(ULONG_MAX, buffer), 20);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"18446744073709551615");
}

- (void)testUitoa {
	char buffer[32];

	uitoa(0, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"0");

	uitoa(42, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"42");

	uitoa(UINT_MAX, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"4294967295");
}

#pragma mark - Signed converters

- (void)testItoa {
	char buffer[32];

	itoa(0, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"0");

	itoa(7, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"7");

	itoa(-7, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"-7");

	itoa(12345, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"12345");

	itoa(-12345, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"-12345");

	itoa(INT_MAX, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"2147483647");
}

- (void)testLtoa {
	char buffer[32];

	ltoa(0, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"0");

	ltoa(9, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"9");

	ltoa(10, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"10");

	// The callers (query-table aliases) hand it a non-negative index.
	ltoa(LONG_MAX, buffer);
	XCTAssertEqualObjects([NSString stringWithUTF8String:buffer], @"9223372036854775807");
}

#pragma mark - Reverse

- (void)testReverse {
	char shortString[] = "a";
	reverse(shortString);
	XCTAssertEqualObjects([NSString stringWithUTF8String:shortString], @"a");

	char evenString[] = "ab";
	reverse(evenString);
	XCTAssertEqualObjects([NSString stringWithUTF8String:evenString], @"ba");

	char oddString[] = "abc";
	reverse(oddString);
	XCTAssertEqualObjects([NSString stringWithUTF8String:oddString], @"cba");

	char palindrome[] = "level";
	reverse(palindrome);
	XCTAssertEqualObjects([NSString stringWithUTF8String:palindrome], @"level");
}

@end
