//
//  MADStringUtilitiesTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADStringUtilitiesTests.m: coverage for
//  MADStringUtilities, the two tiny string-assembly helpers used for key
//  paths and display strings throughout the app.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADStringUtilities.h>

static void testAppendPeriodToEmptyString(void) {
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingPeriod:@""], @".", "empty string gets a period");
}

static void testAppendPeriodToPlainString(void) {
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingPeriod:@"foo"], @"foo.", "plain string gets a period");
}

static void testAppendPeriodDoesNotDoubleUp(void) {
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingPeriod:@"foo."], @"foo.", "an existing period is not doubled");
}

static void testAppendPeriodToNilReturnsPeriod(void) {
	// nil.length == 0, so this follows the empty-string path.
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingPeriod:nil], @".", "nil gets a period");
}

static void testAppendKeyPath(void) {
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingKeyPath:@"bar" toString:@"foo"], @"foo.bar", "key path is appended after a period");
}

static void testAppendEmptyKeyPathReturnsStringUnchanged(void) {
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingKeyPath:@"" toString:@"foo"], @"foo", "empty key path leaves the string unchanged");
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingKeyPath:nil toString:@"foo"], @"foo", "nil key path leaves the string unchanged");
}

static void testAppendKeyPathToNilString(void) {
	MAD_PASS_EQUAL([MADStringUtilities stringByAppendingKeyPath:@"bar" toString:nil], @".bar", "key path onto a nil string");
}

MAD_TEST_MAIN("MADStringUtilitiesTests",
	MAD_TEST(testAppendPeriodToEmptyString),
	MAD_TEST(testAppendPeriodToPlainString),
	MAD_TEST(testAppendPeriodDoesNotDoubleUp),
	MAD_TEST(testAppendPeriodToNilReturnsPeriod),
	MAD_TEST(testAppendKeyPath),
	MAD_TEST(testAppendEmptyKeyPathReturnsStringUnchanged),
	MAD_TEST(testAppendKeyPathToNilString));
