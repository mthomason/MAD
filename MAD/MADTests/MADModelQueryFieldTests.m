//
//  MADModelQueryFieldTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADModelQueryField: a query field in the lightweight
//  model layer.  It resolves its schema field through the weak database by looking the
//  schema-table identifier up in the database's table dictionary and the field identifier
//  up in that table's fields; -schemaFieldIdentifier / -schemaFieldID hand back the raw
//  field id.  MADModel's identifier semantics (init -> -1, identity by id and class) are
//  pinned here too.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>

#import "MADModelQueryField.h"
#import "MADModelQueryTable.h"
#import "MADModelDatabase.h"
#import "MADModelField.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

@interface MADModelQueryFieldTests : XCTestCase
@end

@implementation MADModelQueryFieldTests

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

#pragma mark - Tests

- (void)testInitStoresTheRawSchemaIdentifiers {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];

	MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithIdentifier:77
																		schemaTable:10
																		schemaField:20
																		   database:database];

	XCTAssertEqual(queryField.identifier, (int64_t)77);
	XCTAssertEqual(queryField.schemaFieldIdentifier, (int64_t)20);
	XCTAssertEqualObjects(queryField.schemaFieldID, @20);
}

- (void)testSchemaFieldResolvesThroughTheDatabaseTableDictionary {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];

	MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithIdentifier:77
																		schemaTable:10
																		schemaField:20
																		   database:database];

	MADModelField *field = [queryField schemaField];
	XCTAssertNotNil(field);
	XCTAssertEqual(field.identifier, (int64_t)20);
	XCTAssertEqualObjects(field.name, @"Name");
}

- (void)testSchemaFieldIsNilForAnUnknownTableOrField {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];

	MADModelQueryField *unknownTable = [[MADModelQueryField alloc] initWithIdentifier:77
																		  schemaTable:99
																		  schemaField:20
																			 database:database];
	MADModelQueryField *unknownField = [[MADModelQueryField alloc] initWithIdentifier:77
																		  schemaTable:10
																		  schemaField:99
																			 database:database];

	XCTAssertNil([unknownTable schemaField]);
	XCTAssertNil([unknownField schemaField]);
}

- (void)testSchemaFieldIsNilWithoutADatabase {
	MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithIdentifier:77
																		schemaTable:10
																		schemaField:20
																		   database:nil];

	XCTAssertNil([queryField schemaField]);
	// The raw identifier still answers, whatever the lookup can do.
	XCTAssertEqualObjects(queryField.schemaFieldID, @20);
}

- (void)testInQueryTableIsHeldWeakly {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];
	MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithIdentifier:77
																		schemaTable:10
																		schemaField:20
																		   database:database];
	@autoreleasepool {
		MADModelQueryTable *table = [[MADModelQueryTable alloc] initWithIdentifier:30
																		dropIndex:0
																	  schemaTable:10
																	   inDatabase:database];
		queryField.inQueryTable = table;
	}

	XCTAssertNil(queryField.inQueryTable);
}

#pragma mark - MADModel identity

- (void)testPlainInitGivesTheModelIdentifierMinusOne {
	MADModelQueryField *queryField = [[MADModelQueryField alloc] init];

	XCTAssertEqual(queryField.identifier, (int64_t)-1);
	XCTAssertEqualObjects(queryField.objectID, @(-1));
}

- (void)testIdentityIsTheIdentifierWithinTheSameClass {
	RptqStoreContext *context = [self inMemoryContext];
	MADModelDatabase *database = [self modelDatabaseForContext:context];
	MADModelQueryField *first = [[MADModelQueryField alloc] initWithIdentifier:77 schemaTable:10 schemaField:20 database:database];
	MADModelQueryField *same = [[MADModelQueryField alloc] initWithIdentifier:77 schemaTable:10 schemaField:20 database:database];
	MADModelQueryField *other = [[MADModelQueryField alloc] initWithIdentifier:78 schemaTable:10 schemaField:20 database:database];

	XCTAssertEqualObjects(first, same);
	XCTAssertEqual(first.hash, same.hash);
	XCTAssertNotEqualObjects(first, other);
}

@end
