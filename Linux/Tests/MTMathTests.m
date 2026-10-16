//
//  MTMathTests.m
//  Linux/Tests
//
//  Ported from MADCocoaExtensionsTests/MTMathTests.m: the MTMath helpers and
//  the inline random/size functions.
//

#import "MADTestSupport.h"
#import <MADCocoaExtensions/MTMath.h>

static void testRandomNumberBetweenSingleValue(void) {
	MAD_PASS(madRandomNumberBetween(5, 5) == (NSUInteger)5, "a single-value range yields that value");
	MAD_PASS(madRandomNumberBetween(0, 0) == (NSUInteger)0, "zero yields zero");
}

static void testRandomNumberBetweenBounds(void) {
	MAD_PASS(YES, "bounds hold over a thousand draws");
	for (int i = 0; i < 1000; i++) {
		NSUInteger n = madRandomNumberBetween(0, 10);
		MAD_PASS(n <= (NSUInteger)10, "the draw stays within the range");
	}
}

static void testRandomNumberInRange(void) {
	MAD_PASS(madRandomNumberInRange(NSMakeRange(5, 1)) == (NSUInteger)5, "a single-element range yields its location");
	for (int i = 0; i < 1000; i++) {
		NSUInteger n = madRandomNumberInRange(NSMakeRange(3, 4));
		MAD_PASS(n >= (NSUInteger)3 && n <= (NSUInteger)6, "the draw stays within the range");
	}
}

static void testSystemFileSizeToMB(void) {
	MAD_PASS(madSystemFileSizeToMB(5000000) == 5.0, "five megabytes");
	MAD_PASS(madSystemFileSizeToMB(1500000) == 1.5, "the fractional megabyte survives");
	MAD_PASS(madSystemFileSizeToMB(0) == 0.0, "zero bytes is zero megabytes");
}

static void testNewSystemFileSizeToMB(void) {
	MAD_PASS_EQUAL([MTMath newSystemFileSizeToMB:5000000], @5.0, "five megabytes as a number");
	MAD_PASS_EQUAL([MTMath newSystemFileSizeToMB:1500000], @1.5, "1.5 megabytes as a number");
}

MAD_TEST_MAIN("MTMathTests",
	MAD_TEST(testRandomNumberBetweenSingleValue),
	MAD_TEST(testRandomNumberBetweenBounds),
	MAD_TEST(testRandomNumberInRange),
	MAD_TEST(testSystemFileSizeToMB),
	MAD_TEST(testNewSystemFileSizeToMB));
