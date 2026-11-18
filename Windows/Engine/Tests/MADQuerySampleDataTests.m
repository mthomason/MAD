//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQuerySampleDataTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQuerySampleDataTests.m: the three sample-data
//  queries -- MADQuerySampleDataField, MADQuerySampleDataTable and
//  MADQuerySampleDataTableRange -- that back the sample preview in the query
//  editor.  The store is a real SQLite file under a per-test temp directory,
//  as in the Xcode suite; the mock database is the portable half of MADMock
//  (Tests/Support/MADMock.h).
//
//  What is pinned is the store-free half: the field query's SQL (it only asks
//  its database for string fragments), and the table/range classes' field-alias
//  join and range predicate.  Their -getSql: is deliberately NOT exercised: it
//  builds a second "max field length" query and calls
//  -executeQuery:withDataTable:andError: on the database that query constructs
//  from the document's credential chain -- a real driver instance with no
//  session.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADQueryType.h>

#import "MADMock.h"
#import <MAD/MADQuery+Extras.h>
#import <MAD/MADQuerySampleDataField.h>
#import <MAD/MADQuerySampleDataTable.h>
#import <MAD/MADQuerySampleDataTableRange.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>

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

static RptqDatabaseSchemaTable *invoiceTableWithFieldNamed(NSString *name, RptqStoreContext *context) {
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

static void testSampleDataFieldInitBuildsADataTable(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDatabaseSchemaTable *table = invoiceTableWithFieldNamed(@"Name", context);
	RptqDatabaseSchemaField *field = table.hasFields.firstObject;

	MADQuerySampleDataField *query = [[MADQuerySampleDataField alloc] initWithObject:field];

	MAD_PASS(query.dataTable != nil, "the init builds a data table");
	MAD_PASS(query.type == MADQueryTypeSampleDataTable, "the field query reports the sample-data type");
	MAD_PASS([query dataTableForQuery:query] == query.dataTable, "the data table is the query's own");
	// Quirk: the class conforms to MADQueryFieldKeysProtocol but answers -fields with
	// nil (the SQL path only uses -fieldKeys).
	MAD_PASS(query.fields == nil, "the fields dictionary stays nil");
}

static void testSampleDataFieldSql(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDatabaseSchemaTable *table = invoiceTableWithFieldNamed(@"Name", context);
	RptqDatabaseSchemaField *field = table.hasFields.firstObject;
	MADQuerySampleDataField *query = [[MADQuerySampleDataField alloc] initWithObject:field];
	query.database = [MADMock mockDatabase];

	NSString *sql = [query getSql:NULL];

	// The base sample-data statement with the mock's table.field key; the double
	// spaces around AS come from the connector already carrying its own spaces.
	MAD_PASS_EQUAL(sql, @"SELECT\n DISTINCT Invoice.Name  AS  NameInvoice \nFROM\n Invoice LIMIT 511;",
				   "the sample-data field SQL");
	MAD_PASS_EQUAL(query.fieldKeys, (@[ @"NameInvoice" ]), "the field key is the aliased name");
}

#pragma mark - MADQuerySampleDataTable and Range: the field-alias join

static void testSampleDataTableAliasJoin(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDatabaseSchemaTable *table = invoiceTableWithFieldNamed(@"Name", context);
	MADDatabase *database = [MADMock mockDatabase];

	NSString *sql = [MADQuerySampleDataTable sqlAllFieldsInTable:table usingDatabase:database];

	MAD_PASS_EQUAL(sql, @"Invoice.Name", "the alias join qualifies the field through the table");
}

static void testSampleDataTableRangeAliasJoinMatchesTheTableClass(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDatabaseSchemaTable *table = invoiceTableWithFieldNamed(@"Name", context);
	MADDatabase *database = [MADMock mockDatabase];

	NSString *tableSql = [MADQuerySampleDataTable sqlAllFieldsInTable:table usingDatabase:database];
	NSString *rangeSql = [MADQuerySampleDataTableRange sqlAllFieldsInTable:table usingDatabase:database];

	MAD_PASS_EQUAL(rangeSql, tableSql, "the range class joins fields the same way");
}

static void testSampleDataTableRangeInitAndUseRange(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDatabaseSchemaTable *table = invoiceTableWithFieldNamed(@"Name", context);

	MADQuerySampleDataTableRange *query = [[MADQuerySampleDataTableRange alloc] initWithObject:table];

	// Quirk: -init fills the private dataTableMaxFieldLength, so the protocol's
	// -dataTable property stays nil; -dataTableForQuery: is the live accessor.
	MAD_PASS([query dataTableForQuery:query] != nil, "the range query's data table is built");
	MAD_PASS(query.limit == (NSUInteger)0, "the limit starts at zero");
	MAD_PASS(query.offset == (NSUInteger)0, "the offset starts at zero");
	// A limit of zero means "sample the first 255 rows" rather than a LIMIT clause.
	MAD_PASS(![query useRange], "a zero limit is not a range");

	query.limit = 5;
	query.offset = 10;
	MAD_PASS([query useRange], "a limit and offset make a range");
}

MAD_TEST_MAIN("MADQuerySampleDataTests",
	MAD_TEST(testSampleDataFieldInitBuildsADataTable),
	MAD_TEST(testSampleDataFieldSql),
	MAD_TEST(testSampleDataTableAliasJoin),
	MAD_TEST(testSampleDataTableRangeAliasJoinMatchesTheTableClass),
	MAD_TEST(testSampleDataTableRangeInitAndUseRange));
