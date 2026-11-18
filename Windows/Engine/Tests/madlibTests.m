//
//  madlibTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/madlibTests.m: coverage for the C string
//  helpers in madlib.c -- the hand-rolled integer-to-ASCII converters and
//  digit counters.  These predate the framework and are used where a
//  formatter allocation in a hot loop was unwelcome.
//
//  Pinned edge cases:
//    * The counters answer 0 for zero (the loop never runs), unlike madmath's
//      digit_count_* which answer 1.  See madmathTests / MADCoreLogicTests.
//    * The converters answer "0" for zero (do/while).
//    * mad_ltoa takes only non-negative input; a negative value emits garbage because
//      the remainder stays negative.  Callers pass array indices, so that is not
//      exercised here -- it is recorded rather than pinned.
//
//  madlib.c is plain C, so nothing here is platform-dependent beyond the
//  limits it exercises (long is 64-bit on both targets).
//

#import "MADTestSupport.h"
#import <MADFoundation/madlib.h>

#include <limits.h>

#pragma mark - Digit counters

static void testCountDigitsUL(void) {
	// Zero takes zero iterations.
	MAD_PASS(count_digits_ul(0) == (unsigned long)0, "zero has no digits");
	MAD_PASS(count_digits_ul(1) == (unsigned long)1, "one has one digit");
	MAD_PASS(count_digits_ul(9) == (unsigned long)1, "nine has one digit");
	MAD_PASS(count_digits_ul(10) == (unsigned long)2, "ten has two digits");
	MAD_PASS(count_digits_ul(99) == (unsigned long)2, "ninety-nine has two digits");
	MAD_PASS(count_digits_ul(100) == (unsigned long)3, "one hundred has three digits");
	// Windows is LLP64: unsigned long is 32 bits there, so ULONG_MAX has ten
	// digits, not the twenty the LP64 targets (Linux, Apple) pin.
#if defined(_WIN32)
	MAD_PASS(count_digits_ul(ULONG_MAX) == (unsigned long)10, "ULONG_MAX has ten digits (32-bit unsigned long)");
#else
	MAD_PASS(count_digits_ul(ULONG_MAX) == (unsigned long)20, "ULONG_MAX has twenty digits");
#endif
}

static void testCountDigits(void) {
	MAD_PASS(count_digits(0) == 0, "zero has no digits");
	MAD_PASS(count_digits(7) == 1, "seven has one digit");
	MAD_PASS(count_digits(10) == 2, "ten has two digits");
	// Integer division truncates toward zero, so negatives count their digits.
	MAD_PASS(count_digits(-9) == 1, "minus nine has one digit");
	MAD_PASS(count_digits(-10) == 2, "minus ten has two digits");
	MAD_PASS(count_digits(INT_MAX) == 10, "INT_MAX has ten digits");
}

#pragma mark - Unsigned converters

static void testUltoa(void) {
	char buffer[32];

	MAD_PASS(mad_ultoa(0, buffer) == 1, "mad_ultoa reports one character for zero");
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"0", "mad_ultoa of zero");

	MAD_PASS(mad_ultoa(12345, buffer) == 5, "mad_ultoa reports five characters for 12345");
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"12345", "mad_ultoa of 12345");

#if defined(_WIN32)
	MAD_PASS(mad_ultoa(ULONG_MAX, buffer) == 10, "mad_ultoa reports ten characters for ULONG_MAX (32-bit unsigned long)");
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"4294967295", "mad_ultoa of ULONG_MAX");
#else
	MAD_PASS(mad_ultoa(ULONG_MAX, buffer) == 20, "mad_ultoa reports twenty characters for ULONG_MAX");
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"18446744073709551615", "mad_ultoa of ULONG_MAX");
#endif
}

static void testUitoa(void) {
	char buffer[32];

	uitoa(0, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"0", "uitoa of zero");

	uitoa(42, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"42", "uitoa of 42");

	uitoa(UINT_MAX, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"4294967295", "uitoa of UINT_MAX");
}

#pragma mark - Signed converters

static void testItoa(void) {
	char buffer[32];

	mad_itoa(0, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"0", "mad_itoa of zero");

	mad_itoa(7, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"7", "mad_itoa of seven");

	mad_itoa(-7, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"-7", "mad_itoa of minus seven");

	mad_itoa(12345, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"12345", "mad_itoa of 12345");

	mad_itoa(-12345, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"-12345", "mad_itoa of minus 12345");

	mad_itoa(INT_MAX, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"2147483647", "mad_itoa of INT_MAX");
}

static void testLtoa(void) {
	char buffer[32];

	mad_ltoa(0, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"0", "mad_ltoa of zero");

	mad_ltoa(9, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"9", "mad_ltoa of nine");

	mad_ltoa(10, buffer);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"10", "mad_ltoa of ten");

	// The callers (query-table aliases) hand it a non-negative index.
	mad_ltoa(LONG_MAX, buffer);
#if defined(_WIN32)
	// Windows is LLP64: long is 32 bits, so LONG_MAX is 2147483647.
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"2147483647", "mad_ltoa of LONG_MAX (32-bit long)");
#else
	MAD_PASS_EQUAL([NSString stringWithUTF8String:buffer], @"9223372036854775807", "mad_ltoa of LONG_MAX");
#endif
}

#pragma mark - Reverse

static void testReverse(void) {
	char shortString[] = "a";
	reverse(shortString);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:shortString], @"a", "a one-character string is unchanged");

	char evenString[] = "ab";
	reverse(evenString);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:evenString], @"ba", "an even-length string");

	char oddString[] = "abc";
	reverse(oddString);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:oddString], @"cba", "an odd-length string");

	char palindrome[] = "level";
	reverse(palindrome);
	MAD_PASS_EQUAL([NSString stringWithUTF8String:palindrome], @"level", "a palindrome is unchanged");
}

MAD_TEST_MAIN("madlibTests",
	MAD_TEST(testCountDigitsUL),
	MAD_TEST(testCountDigits),
	MAD_TEST(testUltoa),
	MAD_TEST(testUitoa),
	MAD_TEST(testItoa),
	MAD_TEST(testLtoa),
	MAD_TEST(testReverse));
