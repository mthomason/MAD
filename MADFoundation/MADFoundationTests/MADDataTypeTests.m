//
//  MADDataTypeTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the MADDataType enum: the name mapping and the sort-selector
//  lookup that every database driver shares.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/NSData+Comparison.h>

@interface MADDataTypeTests : XCTestCase
@end

@implementation MADDataTypeTests

- (void)testEnumRawValues {
	// The enum skips value 4; the values below are the source of truth for
	// persistence and the SQL result-binding path.
	XCTAssertEqual(MADDataTypeBit, 0);
	XCTAssertEqual(MADDataTypeBlob, 1);
	XCTAssertEqual(MADDataTypeDate, 2);
	XCTAssertEqual(MADDataTypeDateTime, 3);
	XCTAssertEqual(MADDataTypeFloat, 5);
	XCTAssertEqual(MADDataTypeGeometry, 6);
	XCTAssertEqual(MADDataTypeImage, 7);
	XCTAssertEqual(MADDataTypeInteger, 8);
	XCTAssertEqual(MADDataTypeNumber, 9);
	XCTAssertEqual(MADDataTypeSet, 10);
	XCTAssertEqual(MADDataTypeString, 11);
	XCTAssertEqual(MADDataTypeTime, 12);
	XCTAssertEqual(MADDataTypeTimeStamp, 13);
	XCTAssertEqual(MADDataTypeYear, 14);
	XCTAssertEqual(MADDataTypeUnknown, 15);
	XCTAssertEqual(MADDataTypeDecimal, 16);
	XCTAssertEqual(MADDataTypeDouble, 17);
	XCTAssertEqual(MADDataTypeEnum, 18);
	XCTAssertEqual(MADDataTypeInt24, 19);
	XCTAssertEqual(MADDataTypeLong, 20);
	XCTAssertEqual(MADDataTypeLongLong, 21);
	XCTAssertEqual(MADDataTypeVarChar, 22);
	XCTAssertEqual(MADDataTypeShort, 23);
	XCTAssertEqual(MADDataTypeNull, 24);
}

- (void)testNameMapping {
	XCTAssertEqualObjects(NSStringFromMADDataType(MADDataTypeBit), @"MADDataTypeBit");
	XCTAssertEqualObjects(NSStringFromMADDataType(MADDataTypeBlob), @"MADDataTypeBlob");
	XCTAssertEqualObjects(NSStringFromMADDataType(MADDataTypeString), @"MADDataTypeString");
	XCTAssertEqualObjects(NSStringFromMADDataType(MADDataTypeUnknown), @"MADDataTypeUnknown");
	XCTAssertEqualObjects(NSStringFromMADDataType(MADDataTypeDecimal), @"MADDataTypeDecimal");
	XCTAssertEqualObjects(NSStringFromMADDataType(MADDataTypeNull), @"MADDataTypeNull");
	// The skipped value (4) falls through to the default.
	XCTAssertEqualObjects(NSStringFromMADDataType((MADDataType)4), @"Unknown");
}

- (void)testSortSelectorForString {
	XCTAssertEqual(MADDataTypeSelectorForSorting(MADDataTypeString), @selector(mad_orderedCompare:));
}

- (void)testSortSelectorForBlob {
	XCTAssertEqual(MADDataTypeSelectorForSorting(MADDataTypeBlob), @selector(compareData:));
}

- (void)testSortSelectorForNumericAndOthers {
	XCTAssertEqual(MADDataTypeSelectorForSorting(MADDataTypeInteger), @selector(compare:));
	XCTAssertEqual(MADDataTypeSelectorForSorting(MADDataTypeFloat), @selector(compare:));
	XCTAssertEqual(MADDataTypeSelectorForSorting(MADDataTypeDate), @selector(compare:));
	XCTAssertEqual(MADDataTypeSelectorForSorting(MADDataTypeDouble), @selector(compare:));
	XCTAssertEqual(MADDataTypeSelectorForSorting(MADDataTypeNull), @selector(compare:));
}

@end
