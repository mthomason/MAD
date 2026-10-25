//
//  MADModelQueryTableTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADModelQueryTable: a query table in the lightweight
//  model layer.  Pinned here: the schema-table identifier round-trips, -alias is the
//  table's name when the table is the first copy (dropIndex 0) and the name with the drop
//  index appended otherwise, -addField:schemaField: registers a MADModelQueryField under
//  its identifier, and the model member is held weakly.
//
//  One quirk, pinned as it stands: -addField:schemaField: does not set the new field's
//  inQueryTable, so the back-pointer the property exists for stays nil.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>

#import "MADModelQueryTable.h"
#import "MADModelQueryField.h"
#import "MADModelDatabase.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

@interface MADModelQueryTableTests : XCTestCase
@end

@implementation MADModelQueryTableTests

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

// Database row 1 owns table 10 ("Invoice"); the table holds field 20 ("Name").
- (MADModelDatabase *)modelDatabaseForContext:(RptqStoreContext *)context {
	RptqDatabase *database = (RptqDatabase *)[context insertObjectForEntity:@"RptqDatabase" identifier:1];
	RptqDatabaseSchemaTable *table = (RptqDatabaseSchemaTable *)[context insertObjectForEntity:@"RptqDatabaseSchemaTable" identifier:10];
	table.name = @"Invoice";
	table.queryable = YES;
	[database addHasTablesObject:table];

	RptqDatabaseSchemaField *nameField = (RptqDatabaseSchemaField *)[context insertObjectForEntity:@"RptqDatabaseSchemaField" identifier:20];
	nameField.name = @"Name";
	nameField.primaryKey = NO;
	nameField.dataType = MADDataTypeString;
	nameField.inTable = table;

	return [[MADModelDatabase alloc] initWithIdentifier:1 queryIdentifier:0 managedObjectContext:context];
}

- (MADModelQueryTable *)queryTableInDatabase:(MADModelDatabase *)database dropIndex:(int64_t)dropIndex {
	return [[MADModelQueryTable alloc] initWithIdentifier:30
												dropIndex:dropIndex
											  schemaTable:10
											   inDatabase:database];
}

#pragma mark - Tests

- (void)testInitStoresTheSchemaTableIdentifier {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];

	MADModelQueryTable *table = [self queryTableInDatabase:database dropIndex:0];

	XCTAssertEqual(table.identifier, (int64_t)30);
	XCTAssertEqual(table.schemaTable, (int64_t)10);
	XCTAssertEqualObjects(table.schemaTableID, @10);
}

- (void)testQueryFieldsStartEmptyAndNonNil {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];

	MADModelQueryTable *table = [self queryTableInDatabase:database dropIndex:0];

	XCTAssertNotNil(table.queryFields);
	XCTAssertEqual(table.queryFields.count, (NSUInteger)0);
	XCTAssertNotNil(table.queryFieldIDs);
	XCTAssertEqual(table.queryFieldIDs.count, (NSUInteger)0);
}

- (void)testAddFieldRegistersTheFieldUnderItsIdentifier {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];
	MADModelQueryTable *table = [self queryTableInDatabase:database dropIndex:0];

	[table addField:77 schemaField:20];

	XCTAssertEqual(table.queryFieldIDs.count, (NSUInteger)1);
	XCTAssertEqualObjects(table.queryFieldIDs.firstObject, @77);
	MADModelQueryField *queryField = table.queryFields[@77];
	XCTAssertNotNil(queryField);
	XCTAssertEqual(queryField.identifier, (int64_t)77);
	XCTAssertEqual(queryField.schemaFieldIdentifier, (int64_t)20);
	// The field is built with the table's schema table, not the query table id.
	XCTAssertEqual(queryField.schemaFieldID.integerValue, (long long)20);
	// Quirk: -addField:schemaField: never assigns the field's inQueryTable.
	XCTAssertNil(queryField.inQueryTable);
}

- (void)testAliasIsTheTableNameForTheFirstCopy {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];

	MADModelQueryTable *table = [self queryTableInDatabase:database dropIndex:0];

	XCTAssertEqualObjects(table.alias, @"Invoice");
}

- (void)testAliasAppendsTheDropIndexForLaterCopies {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];

	MADModelQueryTable *table = [self queryTableInDatabase:database dropIndex:3];

	XCTAssertEqualObjects(table.alias, @"Invoice3");
}

- (void)testInQueryIsHeldWeakly {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];
	MADModelQueryTable *table = [self queryTableInDatabase:database dropIndex:0];

	@autoreleasepool {
		NSObject *query = [[NSObject alloc] init];
		table.inQuery = (id)query;
	}

	XCTAssertNil(table.inQuery);
}

#pragma mark - MADModel identity

- (void)testIdentityIsTheIdentifierWithinTheSameClass {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];
	MADModelQueryTable *first = [[MADModelQueryTable alloc] initWithIdentifier:30 dropIndex:0 schemaTable:10 inDatabase:database];
	MADModelQueryTable *same = [[MADModelQueryTable alloc] initWithIdentifier:30 dropIndex:4 schemaTable:10 inDatabase:database];
	MADModelQueryTable *other = [[MADModelQueryTable alloc] initWithIdentifier:31 dropIndex:0 schemaTable:10 inDatabase:database];

	XCTAssertEqualObjects(first, same);
	XCTAssertNotEqualObjects(first, other);
}

@end
