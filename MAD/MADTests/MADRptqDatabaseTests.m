//
//  MADRptqDatabaseTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 4 (Core Data database-schema domain) coverage for the MAD framework.
//  These tests exercise the pure-logic "Extras" categories that map schema data
//  types and database key paths to their display/string forms.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import <MADFoundation/MADDataType.h>

#import <MAD/RptqDatabase.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

@interface MADRptqDatabaseTests : XCTestCase
@end

@implementation MADRptqDatabaseTests

#pragma mark - Schema-field data-type display

- (void)testSchemaFieldDataTypeDisplay {
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeBit], @"Bit");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeBlob], @"Blob");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeDate], @"Date");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeDateTime], @"Date Time");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeFloat], @"Float");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeInteger], @"Integer");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeString], @"String");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeDecimal], @"Decimal");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeLongLong], @"Long Long");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeVarChar], @"Var Char");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeYear], @"Year");
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeUnknown], @"Unknown");
}

- (void)testSchemaFieldDataTypeDisplayFallbackForUnmappedType {
	// Unmapped values fall back to "Type <n>".  MADDataTypeNull has no display case.
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeNull], @"Type 24");
	// Raw value 4 is skipped in the MADDataType enum and likewise has no case.
	XCTAssertEqualObjects([RptqDatabaseSchemaField dataTypeDisplay:4], @"Type 4");
}

- (void)testSchemaFieldFieldTypeDisplay {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	[store openWithError:NULL];
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	[context loadAllWithError:NULL];

	RptqDatabaseSchemaField *field = [context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:0];
	field.dataType = MADDataTypeString;
	XCTAssertEqualObjects([field fieldTypeDisplay], @"String");
}

#pragma mark - Database key paths

- (void)testDatabaseKeyConstants {
	XCTAssertEqualObjects([RptqDatabase keyDatabaseDriverType], @"databaseDriverTypeEnum");
	XCTAssertEqualObjects([RptqDatabase keyOwnedByUserDriverID], @"ownedByUser.driverID");
	XCTAssertEqualObjects([RptqDatabase keyOwnedByUserDatabaseName], @"ownedByUser.dbname");
}

#pragma mark - Database-type identifier/name tables

- (void)testDatabaseTypeReuseIdsAndNamesAlign {
	// The two tables are index-aligned: entry N of the reuse-id table names the same
	// database type as entry N of the localized-name table.
	// (The macro expansion contains commas, so it must be captured in a variable
	// before it can be passed to an XCTAssert macro.)
	NSArray *reuseIds = MADDatabaseTypeReuseIds;
	NSArray *names = MADDatabaseTypeNames;
	XCTAssertEqual(reuseIds.count, names.count);
	XCTAssertEqualObjects(names[5], @"Microsoft SQL Server");
	XCTAssertEqual(reuseIds.count, (NSUInteger)10);
}

@end
