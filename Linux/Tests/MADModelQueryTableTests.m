//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADModelQueryTableTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADModelQueryTableTests.m: characterization
//  coverage for MADModelQueryTable -- the schema-table identifier round-trip,
//  -alias, field registration, and the weakly held model member.  The Xcode
//  suite's in-memory Core Data context is a real SQLite store under a per-test
//  temp directory here.
//
//  One quirk, pinned as it stands: -addField:schemaField: does not set the new
//  field's inQueryTable, so the back-pointer the property exists for stays nil.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>

#import <MAD/MADModelQueryTable.h>
#import <MAD/MADModelQueryField.h>
#import <MAD/MADModelDatabase.h>
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

static MADModelQueryTable *queryTableInDatabase(MADModelDatabase *database, int64_t dropIndex) {
	return [[MADModelQueryTable alloc] initWithIdentifier:30
												dropIndex:dropIndex
											  schemaTable:10
											   inDatabase:database];
}

#pragma mark - Tests

static void testInitStoresTheSchemaTableIdentifier(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);

	MADModelQueryTable *table = queryTableInDatabase(database, 0);

	MAD_PASS(table.identifier == (int64_t)30, "the identifier round-trips");
	MAD_PASS(table.schemaTable == (int64_t)10, "the schema-table identifier round-trips");
	MAD_PASS_EQUAL(table.schemaTableID, @10, "the schema-table id object round-trips");
}

static void testQueryFieldsStartEmptyAndNonNil(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);

	MADModelQueryTable *table = queryTableInDatabase(database, 0);

	MAD_PASS(table.queryFields != nil, "the query-field dictionary exists");
	MAD_PASS(table.queryFields.count == (NSUInteger)0, "the query-field dictionary starts empty");
	MAD_PASS(table.queryFieldIDs != nil, "the query-field id set exists");
	MAD_PASS(table.queryFieldIDs.count == (NSUInteger)0, "the query-field id set starts empty");
}

static void testAddFieldRegistersTheFieldUnderItsIdentifier(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);
	MADModelQueryTable *table = queryTableInDatabase(database, 0);

	[table addField:77 schemaField:20];

	MAD_PASS(table.queryFieldIDs.count == (NSUInteger)1, "one field id is registered");
	MAD_PASS_EQUAL(table.queryFieldIDs.firstObject, @77, "the registered id is the field identifier");
	MADModelQueryField *queryField = table.queryFields[@77];
	MAD_PASS(queryField != nil, "the field is registered under its identifier");
	MAD_PASS(queryField.identifier == (int64_t)77, "the field carries the identifier");
	MAD_PASS(queryField.schemaFieldIdentifier == (int64_t)20, "the field carries the schema-field identifier");
	// The field is built with the table's schema table, not the query table id.
	MAD_PASS(queryField.schemaFieldID.integerValue == (long long)20, "the schema-field id is the schema field's");
	// Quirk: -addField:schemaField: never assigns the field's inQueryTable.
	MAD_PASS(queryField.inQueryTable == nil, "the back-pointer stays nil (pinned quirk)");
}

static void testAliasIsTheTableNameForTheFirstCopy(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);

	MADModelQueryTable *table = queryTableInDatabase(database, 0);

	MAD_PASS_EQUAL(table.alias, @"Invoice", "the first copy's alias is the table name");
}

static void testAliasAppendsTheDropIndexForLaterCopies(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);

	MADModelQueryTable *table = queryTableInDatabase(database, 3);

	MAD_PASS_EQUAL(table.alias, @"Invoice3", "a later copy's alias appends the drop index");
}

static void testInQueryIsHeldWeakly(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);
	MADModelQueryTable *table = queryTableInDatabase(database, 0);

	@autoreleasepool {
		NSObject *query = [[NSObject alloc] init];
		table.inQuery = (id)query;
		// MRC test: release explicitly so the weak property must nil, as it does at
		// the Xcode test's ARC scope end.
		[query release];
	}

	MAD_PASS(table.inQuery == nil, "the query is held weakly");
}

#pragma mark - MADModel identity

static void testIdentityIsTheIdentifierWithinTheSameClass(void) {
	RptqStoreContext *context = inMemoryContext();
	MADModelDatabase *database = modelDatabaseForContext(context);
	MADModelQueryTable *first = [[MADModelQueryTable alloc] initWithIdentifier:30 dropIndex:0 schemaTable:10 inDatabase:database];
	MADModelQueryTable *same = [[MADModelQueryTable alloc] initWithIdentifier:30 dropIndex:4 schemaTable:10 inDatabase:database];
	MADModelQueryTable *other = [[MADModelQueryTable alloc] initWithIdentifier:31 dropIndex:0 schemaTable:10 inDatabase:database];

	MAD_PASS([first isEqual:same], "the same identifier and class compare equal");
	MAD_PASS(![first isEqual:other], "a different identifier does not compare equal");
}

MAD_TEST_MAIN("MADModelQueryTableTests",
	MAD_TEST(testInitStoresTheSchemaTableIdentifier),
	MAD_TEST(testQueryFieldsStartEmptyAndNonNil),
	MAD_TEST(testAddFieldRegistersTheFieldUnderItsIdentifier),
	MAD_TEST(testAliasIsTheTableNameForTheFirstCopy),
	MAD_TEST(testAliasAppendsTheDropIndexForLaterCopies),
	MAD_TEST(testInQueryIsHeldWeakly),
	MAD_TEST(testIdentityIsTheIdentifierWithinTheSameClass));
