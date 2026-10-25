//
//  MADQuerySampleDataTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the three sample-data queries: MADQuerySampleDataField,
//  MADQuerySampleDataTable and MADQuerySampleDataTableRange.  These back the sample
//  preview in the query editor.
//
//  What is pinned here is the store-free half: the field query's SQL (it only asks its
//  database for string fragments), and the table/range classes' field-alias join and
//  range predicate.  Their -getSql: is deliberately NOT exercised: it builds a second
//  "max field length" query and calls -executeQuery:withDataTable:andError: on the
//  database that query constructs from the document's credential chain -- a real
//  driver instance with no session.  Driving a driver with no connection is exactly
//  the kind of call a unit test must not make.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADQueryType.h>

#import "MADMock.h"
#import "MADQuery+Extras.h"
#import "MADQuerySampleDataField.h"
#import "MADQuerySampleDataTable.h"
#import "MADQuerySampleDataTableRange.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

// The field-alias join and the range predicate are implemented but declared in no
// header; this test-only category is the deliberate bridge, for both classes that
// carry a copy.  The range class also needs -dataTableForQuery: bridged: its header
// does not list MADDatabaseResultsProtocol (the .m's class extension does), so the
// compiler cannot see the optional protocol method.
@interface MADQuerySampleDataTable (TestSurface)
+ (NSString *)sqlAllFieldsInTable:(RptqDatabaseSchemaTable *)schemaTable
					usingDatabase:(MADDatabase *)database;
- (MADDataTable *)dataTableForQuery:(MADQuery *)query;
@end

@interface MADQuerySampleDataTableRange (TestSurface)
+ (NSString *)sqlAllFieldsInTable:(RptqDatabaseSchemaTable *)schemaTable
					usingDatabase:(MADDatabase *)database;
- (bool)useRange;
- (MADDataTable *)dataTableForQuery:(MADQuery *)query;
@end

@interface MADQuerySampleDataTests : XCTestCase
@end

@implementation MADQuerySampleDataTests

#pragma mark - Fixture

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

- (RptqDatabaseSchemaTable *)invoiceTableWithFieldNamed:(NSString *)name context:(RptqStoreContext *)context {
	RptqDatabaseSchemaTable *table = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																												name:@"Invoice"
																										andQueryable:YES];
	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = MADDataTypeString;
	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																											   andField:databaseField];
	schemaField.inTable = table;
	return table;
}

#pragma mark - MADQuerySampleDataField

- (void)testSampleDataFieldInitBuildsADataTable {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDatabaseSchemaTable *table = [self invoiceTableWithFieldNamed:@"Name" context:context];
	RptqDatabaseSchemaField *field = table.hasFields.firstObject;

	MADQuerySampleDataField *query = [[MADQuerySampleDataField alloc] initWithObject:field];

	XCTAssertNotNil(query.dataTable);
	XCTAssertEqual(query.type, MADQueryTypeSampleDataTable);
	XCTAssertEqual([query dataTableForQuery:query], query.dataTable);
	// Quirk: the class conforms to MADQueryFieldKeysProtocol but answers -fields with
	// nil (the SQL path only uses -fieldKeys).
	XCTAssertNil(query.fields);
}

- (void)testSampleDataFieldSql {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDatabaseSchemaTable *table = [self invoiceTableWithFieldNamed:@"Name" context:context];
	RptqDatabaseSchemaField *field = table.hasFields.firstObject;
	MADQuerySampleDataField *query = [[MADQuerySampleDataField alloc] initWithObject:field];
	query.database = [MADMock mockDatabase];

	NSString *sql = [query getSql:NULL];

	// The base sample-data statement with the mock's table.field key; the double
	// spaces around AS come from the connector already carrying its own spaces.
	XCTAssertEqualObjects(sql, @"SELECT\n DISTINCT Invoice.Name  AS  NameInvoice \nFROM\n Invoice LIMIT 511;");
	XCTAssertEqualObjects(query.fieldKeys, (@[@"NameInvoice"]));
}

#pragma mark - MADQuerySampleDataTable and Range: the field-alias join

- (void)testSampleDataTableAliasJoin {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDatabaseSchemaTable *table = [self invoiceTableWithFieldNamed:@"Name" context:context];
	MADDatabase *database = [MADMock mockDatabase];

	NSString *sql = [MADQuerySampleDataTable sqlAllFieldsInTable:table usingDatabase:database];

	XCTAssertEqualObjects(sql, @"Invoice.Name");
}

- (void)testSampleDataTableRangeAliasJoinMatchesTheTableClass {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDatabaseSchemaTable *table = [self invoiceTableWithFieldNamed:@"Name" context:context];
	MADDatabase *database = [MADMock mockDatabase];

	NSString *tableSql = [MADQuerySampleDataTable sqlAllFieldsInTable:table usingDatabase:database];
	NSString *rangeSql = [MADQuerySampleDataTableRange sqlAllFieldsInTable:table usingDatabase:database];

	XCTAssertEqualObjects(rangeSql, tableSql);
}

- (void)testSampleDataTableRangeInitAndUseRange {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDatabaseSchemaTable *table = [self invoiceTableWithFieldNamed:@"Name" context:context];

	MADQuerySampleDataTableRange *query = [[MADQuerySampleDataTableRange alloc] initWithObject:table];

	// Quirk: -init fills the private dataTableMaxFieldLength, so the protocol's
	// -dataTable property stays nil; -dataTableForQuery: is the live accessor.
	XCTAssertNotNil([query dataTableForQuery:query]);
	XCTAssertEqual(query.limit, (NSUInteger)0);
	XCTAssertEqual(query.offset, (NSUInteger)0);
	// A limit of zero means "sample the first 255 rows" rather than a LIMIT clause.
	XCTAssertFalse([query useRange]);

	query.limit = 5;
	query.offset = 10;
	XCTAssertTrue([query useRange]);
}

@end
