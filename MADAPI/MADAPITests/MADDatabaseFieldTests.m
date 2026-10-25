//
//  MADDatabaseFieldTests.m
//  MADAPITests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 2 coverage for MADDatabaseField: the value type that represents a column
//  in a database table.  Exercises initialization defaults, the numeric-type
//  classifier, the sort-selector mapping, and NSCopying / NSSecureCoding.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabaseField.h>

@interface MADDatabaseFieldTests : XCTestCase
@end

@implementation MADDatabaseFieldTests

#pragma mark - Initialization

- (void)testInitWithNameDefaults {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	XCTAssertEqualObjects(field.name, @"amount");
	XCTAssertEqual(field.calculatedWidth, (NSUInteger)0);
	XCTAssertEqual(field.fieldType, MADDataTypeUnknown);
	XCTAssertEqual(field.width, (int64_t)0);
	XCTAssertEqual(field.decimals, (int16_t)0);
	XCTAssertEqual(field.fieldTypeNative, (int16_t)0);
	XCTAssertFalse(field.primaryKey);
}

#pragma mark - Numeric classification

- (void)testIsNumericTrueTypes {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeBit), @(MADDataTypeFloat), @(MADDataTypeInteger),
		@(MADDataTypeNumber), @(MADDataTypeDecimal), @(MADDataTypeDouble),
		@(MADDataTypeEnum), @(MADDataTypeInt24), @(MADDataTypeLong),
		@(MADDataTypeLongLong), @(MADDataTypeShort),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		XCTAssertTrue([MADDatabaseField isNumeric:type], @"%@ should be numeric", NSStringFromMADDataType(type));

		MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"n"];
		field.fieldType = type;
		XCTAssertTrue([field isNumeric], @"%@ field should be numeric", NSStringFromMADDataType(type));
	}
}

- (void)testIsNumericFalseTypes {
	NSArray<NSNumber *> *types = @[
		@(MADDataTypeBlob), @(MADDataTypeDate), @(MADDataTypeDateTime),
		@(MADDataTypeGeometry), @(MADDataTypeImage), @(MADDataTypeSet),
		@(MADDataTypeString), @(MADDataTypeTime), @(MADDataTypeTimeStamp),
		@(MADDataTypeYear), @(MADDataTypeUnknown), @(MADDataTypeVarChar),
		@(MADDataTypeNull),
	];
	for (NSNumber *boxed in types) {
		MADDataType type = (MADDataType)boxed.intValue;
		XCTAssertFalse([MADDatabaseField isNumeric:type], @"%@ should not be numeric", NSStringFromMADDataType(type));
	}
}

#pragma mark - Sort selector mapping

- (void)testSelectorForSorting {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"n"];

	field.fieldType = MADDataTypeString;
	XCTAssertEqualObjects(NSStringFromSelector([field selectorForSorting]), @"mad_orderedCompare:");

	field.fieldType = MADDataTypeBlob;
	XCTAssertEqualObjects(NSStringFromSelector([field selectorForSorting]), @"compareData:");

	field.fieldType = MADDataTypeInteger;
	XCTAssertEqualObjects(NSStringFromSelector([field selectorForSorting]), @"compare:");

	// MADDataTypeDecimal falls through the switch's default branch.
	field.fieldType = MADDataTypeDecimal;
	XCTAssertEqualObjects(NSStringFromSelector([field selectorForSorting]), @"compare:");
}

#pragma mark - NSCopying

- (void)testCopy {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	field.calculatedWidth = 12;
	field.fieldType = MADDataTypeDecimal;
	field.width = 8;
	field.decimals = 2;
	field.fieldTypeNative = 3;
	field.primaryKey = YES;

	MADDatabaseField *copy = [field copy];
	XCTAssertNotEqual(copy, field);
	XCTAssertEqualObjects(copy.name, @"amount");
	XCTAssertEqual(copy.calculatedWidth, (NSUInteger)12);
	XCTAssertEqual(copy.fieldType, MADDataTypeDecimal);
	XCTAssertEqual(copy.width, (int64_t)8);
	XCTAssertEqual(copy.decimals, (int16_t)2);
	XCTAssertEqual(copy.fieldTypeNative, (int16_t)3);
	XCTAssertTrue(copy.primaryKey);
}

#pragma mark - NSSecureCoding

- (void)testSupportsSecureCoding {
	XCTAssertTrue([MADDatabaseField supportsSecureCoding]);
}

- (void)testNSCodingRoundTrip {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	field.calculatedWidth = 12;
	field.fieldType = MADDataTypeDecimal;
	field.width = 8;
	field.decimals = 2;
	field.fieldTypeNative = 3;
	field.primaryKey = YES;

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:field requiringSecureCoding:YES error:NULL];
	MADDatabaseField *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseField class] fromData:data error:NULL];

	XCTAssertNotNil(decoded);
	XCTAssertEqualObjects(decoded.name, @"amount");
	XCTAssertEqual(decoded.calculatedWidth, (NSUInteger)12);
	XCTAssertEqual(decoded.fieldType, MADDataTypeDecimal);
	XCTAssertEqual(decoded.width, (int64_t)8);
	XCTAssertEqual(decoded.decimals, (int16_t)2);
	XCTAssertEqual(decoded.fieldTypeNative, (int16_t)3);
	XCTAssertTrue(decoded.primaryKey);
}

#pragma mark - Description

- (void)testDescriptionContainsName {
	MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:@"amount"];
	XCTAssertTrue([[field description] containsString:@"amount"]);
}

@end
