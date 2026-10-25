//
//  MADDataTypeTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/MADDataTypeTests.m: coverage for the
//  MADDataType enum, the name mapping and the sort-selector lookup that every
//  database driver shares.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/NSData+Comparison.h>

static void testEnumRawValues(void) {
	// The enum skips value 4; the values below are the source of truth for
	// persistence and the SQL result-binding path.
	MAD_PASS(MADDataTypeBit == 0, "MADDataTypeBit's raw value");
	MAD_PASS(MADDataTypeBlob == 1, "MADDataTypeBlob's raw value");
	MAD_PASS(MADDataTypeDate == 2, "MADDataTypeDate's raw value");
	MAD_PASS(MADDataTypeDateTime == 3, "MADDataTypeDateTime's raw value");
	MAD_PASS(MADDataTypeFloat == 5, "MADDataTypeFloat's raw value");
	MAD_PASS(MADDataTypeGeometry == 6, "MADDataTypeGeometry's raw value");
	MAD_PASS(MADDataTypeImage == 7, "MADDataTypeImage's raw value");
	MAD_PASS(MADDataTypeInteger == 8, "MADDataTypeInteger's raw value");
	MAD_PASS(MADDataTypeNumber == 9, "MADDataTypeNumber's raw value");
	MAD_PASS(MADDataTypeSet == 10, "MADDataTypeSet's raw value");
	MAD_PASS(MADDataTypeString == 11, "MADDataTypeString's raw value");
	MAD_PASS(MADDataTypeTime == 12, "MADDataTypeTime's raw value");
	MAD_PASS(MADDataTypeTimeStamp == 13, "MADDataTypeTimeStamp's raw value");
	MAD_PASS(MADDataTypeYear == 14, "MADDataTypeYear's raw value");
	MAD_PASS(MADDataTypeUnknown == 15, "MADDataTypeUnknown's raw value");
	MAD_PASS(MADDataTypeDecimal == 16, "MADDataTypeDecimal's raw value");
	MAD_PASS(MADDataTypeDouble == 17, "MADDataTypeDouble's raw value");
	MAD_PASS(MADDataTypeEnum == 18, "MADDataTypeEnum's raw value");
	MAD_PASS(MADDataTypeInt24 == 19, "MADDataTypeInt24's raw value");
	MAD_PASS(MADDataTypeLong == 20, "MADDataTypeLong's raw value");
	MAD_PASS(MADDataTypeLongLong == 21, "MADDataTypeLongLong's raw value");
	MAD_PASS(MADDataTypeVarChar == 22, "MADDataTypeVarChar's raw value");
	MAD_PASS(MADDataTypeShort == 23, "MADDataTypeShort's raw value");
	MAD_PASS(MADDataTypeNull == 24, "MADDataTypeNull's raw value");
}

static void testNameMapping(void) {
	MAD_PASS_EQUAL(NSStringFromMADDataType(MADDataTypeBit), @"MADDataTypeBit", "Bit's name");
	MAD_PASS_EQUAL(NSStringFromMADDataType(MADDataTypeBlob), @"MADDataTypeBlob", "Blob's name");
	MAD_PASS_EQUAL(NSStringFromMADDataType(MADDataTypeString), @"MADDataTypeString", "String's name");
	MAD_PASS_EQUAL(NSStringFromMADDataType(MADDataTypeUnknown), @"MADDataTypeUnknown", "Unknown's name");
	MAD_PASS_EQUAL(NSStringFromMADDataType(MADDataTypeDecimal), @"MADDataTypeDecimal", "Decimal's name");
	MAD_PASS_EQUAL(NSStringFromMADDataType(MADDataTypeNull), @"MADDataTypeNull", "Null's name");
	// The skipped value (4) falls through to the default.
	MAD_PASS_EQUAL(NSStringFromMADDataType((MADDataType)4), @"Unknown", "the skipped value's fallback name");
}

static void testSortSelectorForString(void) {
	MAD_PASS(MADDataTypeSelectorForSorting(MADDataTypeString) == @selector(localizedCaseInsensitiveCompare:), "string sorts case-insensitively");
}

static void testSortSelectorForBlob(void) {
	MAD_PASS(MADDataTypeSelectorForSorting(MADDataTypeBlob) == @selector(compareData:), "blob sorts by byte comparison");
}

static void testSortSelectorForNumericAndOthers(void) {
	MAD_PASS(MADDataTypeSelectorForSorting(MADDataTypeInteger) == @selector(compare:), "integer sorts with compare:");
	MAD_PASS(MADDataTypeSelectorForSorting(MADDataTypeFloat) == @selector(compare:), "float sorts with compare:");
	MAD_PASS(MADDataTypeSelectorForSorting(MADDataTypeDate) == @selector(compare:), "date sorts with compare:");
	MAD_PASS(MADDataTypeSelectorForSorting(MADDataTypeDouble) == @selector(compare:), "double sorts with compare:");
	MAD_PASS(MADDataTypeSelectorForSorting(MADDataTypeNull) == @selector(compare:), "null sorts with compare:");
}

MAD_TEST_MAIN("MADDataTypeTests",
	MAD_TEST(testEnumRawValues),
	MAD_TEST(testNameMapping),
	MAD_TEST(testSortSelectorForString),
	MAD_TEST(testSortSelectorForBlob),
	MAD_TEST(testSortSelectorForNumericAndOthers));
