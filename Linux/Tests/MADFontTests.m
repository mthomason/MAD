//
//  MADFontTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADFontTests.m: the two class-level defaults the
//  designer's style inspector starts from -- "Helvetica Neue" at 9 points.
//  MADFont is not the excluded MADFonts: it holds no UIFont families.
//

#import "MADTestSupport.h"

#import <MAD/MADFont.h>

static void testDefaultFamilyIsHelveticaNeue(void) {
	MAD_PASS_EQUAL([MADFont defaultFamily], @"Helvetica Neue", "the default family is Helvetica Neue");
}

static void testDefaultSizeIsNinePoints(void) {
	MAD_PASS([MADFont defaultSize] == 9.0f, "the default size is nine points");
}

MAD_TEST_MAIN("MADFontTests",
	MAD_TEST(testDefaultFamilyIsHelveticaNeue),
	MAD_TEST(testDefaultSizeIsNinePoints));
