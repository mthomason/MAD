//
//  NSDataComparisonTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/NSDataComparisonTests.m: coverage for the
//  NSData (Comparison) category, the lexicographic byte ordering used for
//  sorting BLOB columns.
//

#import "MADTestSupport.h"
#import <MADFoundation/NSData+Comparison.h>

static void testCompareNil(void) {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	MAD_PASS([data compareData:nil] == NSOrderedDescending, "data sorts after nil");
}

static void testCompareSelfIsSame(void) {
	NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	MAD_PASS([data compareData:data] == NSOrderedSame, "data compares same as itself");
}

static void testCompareEqualDataIsSame(void) {
	NSData *a = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *b = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	MAD_PASS([a compareData:b] == NSOrderedSame, "equal bytes compare the same");
}

static void testCompareLexicographic(void) {
	NSData *a = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *b = [@"abd" dataUsingEncoding:NSUTF8StringEncoding];
	MAD_PASS([a compareData:b] == NSOrderedAscending, "abc sorts before abd");
	MAD_PASS([b compareData:a] == NSOrderedDescending, "abd sorts after abc");
}

static void testLongerCommonPrefixIsGreater(void) {
	NSData *a = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
	NSData *b = [@"abcd" dataUsingEncoding:NSUTF8StringEncoding];
	MAD_PASS([a compareData:b] == NSOrderedAscending, "the shorter prefix sorts first");
	MAD_PASS([b compareData:a] == NSOrderedDescending, "the longer data sorts last");
}

static void testEmptyVsNonEmpty(void) {
	NSData *empty = [NSData data];
	NSData *nonEmpty = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
	MAD_PASS([empty compareData:nonEmpty] == NSOrderedAscending, "empty data sorts first");
	MAD_PASS([nonEmpty compareData:empty] == NSOrderedDescending, "non-empty data sorts last");
}

MAD_TEST_MAIN("NSDataComparisonTests",
	MAD_TEST(testCompareNil),
	MAD_TEST(testCompareSelfIsSame),
	MAD_TEST(testCompareEqualDataIsSame),
	MAD_TEST(testCompareLexicographic),
	MAD_TEST(testLongerCommonPrefixIsGreater),
	MAD_TEST(testEmptyVsNonEmpty));
