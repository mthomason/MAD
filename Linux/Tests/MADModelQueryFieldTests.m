//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADModelQueryFieldTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADModelQueryFieldTests.m: characterization
//  coverage for MADModelQueryField -- schema-field resolution through the weak
//  database's table dictionary, the raw identifier accessors, and MADModel's
//  identity semantics.  The Xcode suite's in-memory Core Data context is a real
//  SQLite store under a per-test temp directory here.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>

#import <MAD/MADModelQueryField.h>
#import <MAD/MADModelQueryTable.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelField.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaField.h>

#pragma mark - Fixture

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

// Database row 1 owns table 10 ("Invoice"); the table holds field 20 ("Name").
static MADModelDatabase *modelDatabaseForContext(RptqStoreContext *context) {
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

static void testInitStoresTheRawSchemaIdentifiers(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);

	MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithIdentifier:77
																		schemaTable:10
																		schemaField:20
																		   database:database];

	MAD_PASS(queryField.identifier == (int64_t)77, "the identifier round-trips");
	MAD_PASS(queryField.schemaFieldIdentifier == (int64_t)20, "the schema-field identifier round-trips");
	MAD_PASS_EQUAL(queryField.schemaFieldID, @20, "the schema-field id object round-trips");
}

static void testSchemaFieldResolvesThroughTheDatabaseTableDictionary(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);

	MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithIdentifier:77
																		schemaTable:10
																		schemaField:20
																		   database:database];

	MADModelField *field = [queryField schemaField];
	MAD_PASS(field != nil, "the schema field resolves");
	MAD_PASS(field.identifier == (int64_t)20, "the resolved field carries the schema-field identifier");
	MAD_PASS_EQUAL(field.name, @"Name", "the resolved field carries the schema-field name");
}

static void testSchemaFieldIsNilForAnUnknownTableOrField(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);

	MADModelQueryField *unknownTable = [[MADModelQueryField alloc] initWithIdentifier:77
																		  schemaTable:99
																		  schemaField:20
																			 database:database];
	MADModelQueryField *unknownField = [[MADModelQueryField alloc] initWithIdentifier:77
																		  schemaTable:10
																		  schemaField:99
																			 database:database];

	MAD_PASS([unknownTable schemaField] == nil, "an unknown table resolves nothing");
	MAD_PASS([unknownField schemaField] == nil, "an unknown field resolves nothing");
}

static void testSchemaFieldIsNilWithoutADatabase(void) {
	MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithIdentifier:77
																		schemaTable:10
																		schemaField:20
																		   database:nil];

	MAD_PASS([queryField schemaField] == nil, "without a database there is nothing to resolve through");
	// The raw identifier still answers, whatever the lookup can do.
	MAD_PASS_EQUAL(queryField.schemaFieldID, @20, "the raw identifier still answers");
}

static void testInQueryTableIsHeldWeakly(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);
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
		// MRC test: release explicitly so the weak property must nil, as it does at
		// the Xcode test's ARC scope end.
		[table release];
	}

	MAD_PASS(queryField.inQueryTable == nil, "the query table is held weakly");
}

#pragma mark - MADModel identity

static void testPlainInitGivesTheModelIdentifierMinusOne(void) {
	MADModelQueryField *queryField = [[MADModelQueryField alloc] init];

	MAD_PASS(queryField.identifier == (int64_t)-1, "a plain init gives identifier -1");
	MAD_PASS_EQUAL(queryField.objectID, @(-1), "the object id is -1");
}

static void testIdentityIsTheIdentifierWithinTheSameClass(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);
	MADModelQueryField *first = [[MADModelQueryField alloc] initWithIdentifier:77 schemaTable:10 schemaField:20 database:database];
	MADModelQueryField *same = [[MADModelQueryField alloc] initWithIdentifier:77 schemaTable:10 schemaField:20 database:database];
	MADModelQueryField *other = [[MADModelQueryField alloc] initWithIdentifier:78 schemaTable:10 schemaField:20 database:database];

	MAD_PASS([first isEqual:same], "the same identifier and class compare equal");
	MAD_PASS(first.hash == same.hash, "equal fields hash the same");
	MAD_PASS(![first isEqual:other], "a different identifier does not compare equal");
}

MAD_TEST_MAIN("MADModelQueryFieldTests",
	MAD_TEST(testInitStoresTheRawSchemaIdentifiers),
	MAD_TEST(testSchemaFieldResolvesThroughTheDatabaseTableDictionary),
	MAD_TEST(testSchemaFieldIsNilForAnUnknownTableOrField),
	MAD_TEST(testSchemaFieldIsNilWithoutADatabase),
	MAD_TEST(testInQueryTableIsHeldWeakly),
	MAD_TEST(testPlainInitGivesTheModelIdentifierMinusOne),
	MAD_TEST(testIdentityIsTheIdentifierWithinTheSameClass));
