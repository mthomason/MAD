//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADRptqDatabaseTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADRptqDatabaseTests.m: the pure-logic RptqDatabase
//  and RptqDatabaseSchemaField "Extras" categories -- the schema-field data-type
//  display table, its unmapped-value fallback, the database key paths, and the
//  index-aligned database-type tables.  The store the Xcode suite borrows from
//  Core Data is a real SQLite file under a per-test temp directory here.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADDataType.h>

#import <MAD/RptqDatabase.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#pragma mark - Schema-field data-type display

static void testSchemaFieldDataTypeDisplay(void) {
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeBit], @"Bit", "Bit displays as Bit");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeBlob], @"Blob", "Blob displays as Blob");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeDate], @"Date", "Date displays as Date");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeDateTime], @"Date Time", "Date Time displays as Date Time");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeFloat], @"Float", "Float displays as Float");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeInteger], @"Integer", "Integer displays as Integer");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeString], @"String", "String displays as String");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeDecimal], @"Decimal", "Decimal displays as Decimal");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeLongLong], @"Long Long", "Long Long displays as Long Long");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeVarChar], @"Var Char", "Var Char displays as Var Char");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeYear], @"Year", "Year displays as Year");
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeUnknown], @"Unknown", "Unknown displays as Unknown");
}

static void testSchemaFieldDataTypeDisplayFallbackForUnmappedType(void) {
	// Unmapped values fall back to "Type <n>".  MADDataTypeNull has no display case.
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:MADDataTypeNull], @"Type 24", "an unmapped Null falls back to Type 24");
	// Raw value 4 is skipped in the MADDataType enum and likewise has no case.
	MAD_PASS_EQUAL([RptqDatabaseSchemaField dataTypeDisplay:4], @"Type 4", "the skipped raw value 4 falls back to Type 4");
}

static void testSchemaFieldFieldTypeDisplay(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	[store openWithError:NULL];
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	[context loadAllWithError:NULL];

	RptqDatabaseSchemaField *field = (RptqDatabaseSchemaField *)[context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:0];
	field.dataType = MADDataTypeString;
	MAD_PASS_EQUAL([field fieldTypeDisplay], @"String", "the field type display follows the data type");
}

#pragma mark - Database key paths

static void testDatabaseKeyConstants(void) {
	MAD_PASS_EQUAL([RptqDatabase keyDatabaseDriverType], @"databaseDriverTypeEnum", "the driver-type key");
	MAD_PASS_EQUAL([RptqDatabase keyOwnedByUserDriverID], @"ownedByUser.driverID", "the driver-id key");
	MAD_PASS_EQUAL([RptqDatabase keyOwnedByUserDatabaseName], @"ownedByUser.dbname", "the database-name key");
}

#pragma mark - Database-type identifier/name tables

static void testDatabaseTypeReuseIdsAndNamesAlign(void) {
	// The two tables are index-aligned: entry N of the reuse-id table names the same
	// database type as entry N of the localized-name table.
	// (The macro expansion contains commas, so it must be captured in a variable
	// before it can be passed to a MAD_PASS macro.)
	NSArray *reuseIds = MADDatabaseTypeReuseIds;
	NSArray *names = MADDatabaseTypeNames;
	MAD_PASS(reuseIds.count == names.count, "the reuse-id and name tables are the same length");
	MAD_PASS_EQUAL(names[5], @"Microsoft SQL Server", "index 5 names Microsoft SQL Server");
	MAD_PASS(reuseIds.count == (NSUInteger)10, "there are ten database types");
}

MAD_TEST_MAIN("MADRptqDatabaseTests",
	MAD_TEST(testSchemaFieldDataTypeDisplay),
	MAD_TEST(testSchemaFieldDataTypeDisplayFallbackForUnmappedType),
	MAD_TEST(testSchemaFieldFieldTypeDisplay),
	MAD_TEST(testDatabaseKeyConstants),
	MAD_TEST(testDatabaseTypeReuseIdsAndNamesAlign));
