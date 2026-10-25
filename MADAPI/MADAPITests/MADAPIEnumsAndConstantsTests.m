//
//  MADAPIEnumsAndConstantsTests.m
//  MADAPITests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 1 coverage for MADAPI: the framework's public enums (MADDatabaseType,
//  MADQueryType) and its exported string constants.  These are compile-time
//  definitions with no runtime dependencies, so they are locked down directly.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADQueryType.h>
#import <MADAPI/MADQuery.h>

@interface MADAPIEnumsAndConstantsTests : XCTestCase
@end

@implementation MADAPIEnumsAndConstantsTests

#pragma mark - MADDatabaseType

- (void)testDatabaseTypeRawValues {
	XCTAssertEqual((int)MADDatabaseTypeNotSet, (int)-1);
	XCTAssertEqual((int)MADDatabaseTypeUnknown, (int)0);
	XCTAssertEqual((int)MADDatabaseTypeDatabaseCom, (int)1);
	XCTAssertEqual((int)MADDatabaseTypeMySQL, (int)2);
	XCTAssertEqual((int)MADDatabaseTypeMicrosoftSqlAzure, (int)3);
	XCTAssertEqual((int)MADDatabaseTypeAmazonSimpleDb, (int)4);
	XCTAssertEqual((int)MADDatabaseTypeTDS, (int)5);
	XCTAssertEqual((int)MADDatabaseTypeOracle, (int)6);
	XCTAssertEqual((int)MADDatabaseTypeODBC, (int)7);
	XCTAssertEqual((int)MADDatabaseTypeGooleAppEngine, (int)8);
	XCTAssertEqual((int)MADDatabaseTypeNone, (int)9);
	XCTAssertEqual((int)MADDatabaseTypeSqlite3, (int)10);
	XCTAssertEqual((int)MADDatabaseTypeSample1, (int)11);
}

#pragma mark - MADQueryType string mapping

- (void)testNSStringFromMADQueryType {
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeUnknown), @"MADQueryTypeUnknown");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeMaxFieldLength), @"MADQueryTypeMaxFieldLength");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeCustomSql), @"MADQueryTypeCustomSql");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeFull), @"MADQueryTypeFull");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeConnectionTest), @"MADQueryTypeConnectionTest");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeSampleDataField), @"MADQueryTypeSampleDataField");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeSampleDataTable), @"MADQueryTypeSampleDataTable");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeCacheAddColumn), @"MADQueryTypeCacheAddColumn");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeCacheVacuum), @"MADQueryTypeCacheVacuum");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeCacheSelectRowIds), @"MADQueryTypeCacheSelectRowIds");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeCacheAggregateFunction), @"MADQueryTypeCacheAggregateFunction");
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeCacheIndexCreateTemplate), @"MADQueryTypeCacheIndexCreateTemplate");
}

- (void)testNSStringFromMADQueryTypeCacheIndexDropParameters {
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeCacheIndexDropParameters), @"MADQueryTypeCacheIndexDropParameters");
}

- (void)testNSStringFromMADQueryTypeSampleDataTableRange {
	XCTAssertEqualObjects(NSStringFromMADQueryType(MADQueryTypeSampleDataTableRange), @"MADQueryTypeSampleDataTableRange");
}

- (void)testNSStringFromMADQueryTypeUnhandledValueFallsThrough {
	// Value 2 is skipped in the MADQueryType enum; it has no case and resolves to Unknown.
	XCTAssertEqualObjects(NSStringFromMADQueryType((MADQueryType)2), @"MADQueryTypeUnknown");
}

#pragma mark - MADQuery constants

- (void)testMADQueryKeyConstants {
	XCTAssertEqualObjects(MADQueryKeyPredicateColumn, @"c");
	XCTAssertEqualObjects(MADQueryKeyPredicateValue, @"v");
	XCTAssertEqualObjects(MADIdentifierROWID, @"ROWID");
}

@end
