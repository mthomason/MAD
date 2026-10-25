//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQueryFullTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQueryFullTests.m: MADQueryFull, the
//  SELECT/JOIN/WHERE/ORDER BY generator behind the report's data load.  The SQL
//  is assembled against the *first* document in the store context
//  (newDocumentReadFromManagedObjectContext:), and the database dialect comes
//  from -dataDelegate.  The store is a real SQLite file under a per-test temp
//  directory, as in the Xcode suite; the mock database is the portable half of
//  MADMock (Tests/Support/MADMock.h).
//
//  Pinned here: the empty-query early return, the single-table FROM with its
//  alias, the limit clause, the predicate splice, the all-fields vs
//  active-fields select list, and the "no active fields" error contract
//  (code 5774).
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import "MADMock.h"
#import <MAD/MADQueryFull.h>
#import <MAD/MADQueryPredicate.h>
#import <MAD/MADPredicateOperator.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/MADQueryLinkType.h>

#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADTdsClient/MADDatabaseSQLServer.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>

#pragma mark - Test double

// The generator asks its data delegate for the database whose dialect to emit.
@interface MADTestDataDelegate : NSObject <MADDataProtocol>
@property (nonatomic, strong) MADDatabase *database;
@end

@implementation MADTestDataDelegate
- (NSArray *)sortDescriptors { return @[]; }
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

// -newDocumentForManagedObjectContext: builds only the document skeleton; the
// generator reads the database and query through the document's to-one/to-many
// relationships, so the fixture has to supply those.
static RptqDocument *documentWithDatabaseAndQueryInContext(RptqStoreContext *context) {
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqDatabase *database = (RptqDatabase *)[context insertObjectForEntity:@"RptqDatabase" identifier:10];
	RptqQuery *query = (RptqQuery *)[context insertObjectForEntity:@"RptqQuery" identifier:20];
	[document addHasDatabaseSchemasObject:database];
	[database addHasQueriesObject:query];
	return document;
}

static RptqQueryField *queryFieldNamed(NSString *name, MADDataType type,
									   RptqDatabase *database, RptqStoreContext *context) {
	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = type;

	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																												 andField:databaseField];
	RptqDatabaseSchemaTable *schemaTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																													name:@"Invoice"
																											andQueryable:YES];
	[database addHasTablesObject:schemaTable];
	schemaField.inTable = schemaTable;

	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
																	database:database
													  forManagedObjectContext:context];

	RptqQueryField *queryField = [RptqQueryField newQueryField:context];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTable;
	return queryField;
}

static MADQueryFull *queryFullForDocumentWithDatabase(RptqDocument *document, NSUInteger limit, MADDatabase *database) {
	MADQueryFull *query = [[MADQueryFull alloc] initWithQuery:document.mainQuery andQueryLimit:limit];
	// The query holds its data delegate weakly (it is normally the document itself), so
	// this MRC test translation unit keeps the delegate's +1 for the test's life.
	MADTestDataDelegate *dataDelegate = [[MADTestDataDelegate alloc] init];
	dataDelegate.database = database;
	query.dataDelegate = dataDelegate;
	return query;
}

static MADQueryFull *queryFullForDocument(RptqDocument *document, NSUInteger limit) {
	return queryFullForDocumentWithDatabase(document, limit, [MADMock mockDatabase]);
}

// The single-table helper above creates a fresh schema table per field; the
// golden fixtures need one schema table per name and one query table per copy of
// it, so these are the multi-table form of it.
static RptqDatabaseSchemaTable *schemaTableNamed(NSString *name, RptqDatabase *database, RptqStoreContext *context) {
	RptqDatabaseSchemaTable *schemaTable =
		[RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																				 name:name
																		 andQueryable:YES];
	[database addHasTablesObject:schemaTable];
	return schemaTable;
}

static RptqQueryTable *queryTableForSchemaTable(RptqDatabaseSchemaTable *schemaTable, RptqDatabase *database) {
	for (RptqQueryTable *existing in database.defaultQuery.hasQueryTables) {
		if (existing.databaseSchemaTable == schemaTable) return existing;
	}
	return [RptqQueryTable newQueryTableForSchemaTable:schemaTable
											  database:database
								forManagedObjectContext:schemaTable.storeContext];
}

// A second copy of one schema table (a self join) is made the way the factory
// makes every copy: counted past the copies already in the query.
static RptqQueryTable *secondCopyOfSchemaTable(RptqDatabaseSchemaTable *schemaTable, RptqDatabase *database) {
	return [RptqQueryTable newQueryTableForSchemaTable:schemaTable
											  database:database
								forManagedObjectContext:schemaTable.storeContext];
}

static RptqQueryField *queryFieldNamedOnTable(NSString *name, MADDataType type,
											  RptqDatabaseSchemaTable *schemaTable,
											  RptqDatabase *database, RptqStoreContext *context) {
	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = type;

	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																												 andField:databaseField];
	schemaField.inTable = schemaTable;

	RptqQueryField *queryField = [RptqQueryField newQueryField:context];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTableForSchemaTable(schemaTable, database);
	return queryField;
}

static RptqQueryField *queryFieldNamedInTable(NSString *name, MADDataType type,
											  RptqQueryTable *queryTable, RptqStoreContext *context) {
	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = type;

	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																												 andField:databaseField];
	schemaField.inTable = queryTable.databaseSchemaTable;

	RptqQueryField *queryField = [RptqQueryField newQueryField:context];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTable;
	return queryField;
}

static RptqQueryLinks *addLinkOfType(MADLinkType type, RptqQueryField *left, RptqQueryField *right, RptqStoreContext *context) {
	RptqQueryLinks *link = (RptqQueryLinks *)[context insertObjectForEntity:@"RptqQueryLinks" identifier:0];
	link.type = (int16_t)type;
	link.hasLeftField = left;
	link.hasRightField = right;
	[left.inQueryTable.inQuery addHasQueryLinksObject:link];
	return link;
}

#pragma mark - Empty query

static void testQueryWithNoTablesIsEmpty(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	MADQueryFull *query = queryFullForDocument(document, 0);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS_EQUAL(sql, @"", "a query with no tables is empty");
	MAD_PASS(error == nil, "the empty query is not an error");
}

#pragma mark - Single table

static void testSingleTableAllFieldsSql(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	queryFieldNamed(@"Name", MADDataTypeString, document.defaultDatabase, context);
	queryFieldNamed(@"Amount", MADDataTypeDecimal, document.defaultDatabase, context);
	MADQueryFull *query = queryFullForDocument(document, 0);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the single-table query builds without error");
	MAD_PASS([sql hasPrefix:@"SELECT\n"], "the statement starts with SELECT");
	MAD_PASS([sql containsString:@"\nFROM\n\tInvoice AS Invoice0"], "the FROM names the table and its alias");
	// Both fields are selected; their order inside the table's set is undefined.
	MAD_PASS([sql containsString:@"Invoice0.Name"], "the first field is selected");
	MAD_PASS([sql containsString:@"Invoice0.Amount"], "the second field is selected");
	// No predicate and no limit.
	MAD_PASS(![sql containsString:@"WHERE"], "there is no predicate");
	MAD_PASS(![sql containsString:@"LIMIT"], "there is no limit");
}

static void testLimitClauseIsAppended(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	queryFieldNamed(@"Name", MADDataTypeString, document.defaultDatabase, context);
	MADQueryFull *query = queryFullForDocument(document, 10);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the limited query builds without error");
	MAD_PASS([sql hasSuffix:@"\nLIMIT 10"], "the limit clause closes the statement");
}

static void testPredicateIsSplicedAfterFrom(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqQueryField *field = queryFieldNamed(@"Name", MADDataTypeString, document.defaultDatabase, context);

	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorEqual;
	predicate.hasLeftField = field;
	predicate.rigthFieldID = @"O'Brien";
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = queryFullForDocument(document, 0);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the predicated query builds without error");
	MAD_PASS([sql hasSuffix:@"\nWHERE\n\t(Invoice0.Name = 'O''Brien')"], "the predicate is spliced in after FROM");
}

#pragma mark - Active fields

static void testActiveFieldsSelectListOmitsUnreferencedFields(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqQueryField *referenced = queryFieldNamed(@"Name", MADDataTypeString, document.defaultDatabase, context);
	queryFieldNamed(@"Amount", MADDataTypeDecimal, document.defaultDatabase, context);

	RptqQueryGroup *group = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = referenced;

	MADQueryFull *query = queryFullForDocument(document, 0);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the active-fields query builds without error");
	MAD_PASS([sql containsString:@"Invoice0.Name"], "the referenced field is selected");
	MAD_PASS(![sql containsString:@"Invoice0.Amount"], "the unreferenced field is omitted");
}

static void testNoActiveFieldsReportsError(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	// A query table with a field exists, but nothing in the report references it.
	queryFieldNamed(@"Name", MADDataTypeString, document.defaultDatabase, context);
	MADQueryFull *query = queryFullForDocument(document, 0);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	MAD_PASS_EQUAL(sql, @"", "the no-active-fields query yields no SQL");
	MAD_PASS(error != nil, "the no-active-fields query reports an error");
	MAD_PASS(error.code == 5774, "the error carries code 5774");
	MAD_PASS_EQUAL(error.domain, @"MADQuery", "the error carries the MADQuery domain");
}

static void testCopySQLUsesActiveFields(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqQueryField *referenced = queryFieldNamed(@"Name", MADDataTypeString, document.defaultDatabase, context);
	RptqQueryGroup *group = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = referenced;
	MADQueryFull *query = queryFullForDocument(document, 0);

	NSError *error = nil;
	NSString *copied = [query copySQLWithManagedObjectContext:context error:&error];
	NSString *direct = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	MAD_PASS_EQUAL(copied, direct, "the copied SQL is the active-fields SQL");
}

#pragma mark - Field keys

static void testFieldKeysReflectActiveFieldOrder(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqQueryField *referenced = queryFieldNamed(@"Name", MADDataTypeString, document.defaultDatabase, context);
	RptqQueryGroup *group = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = referenced;
	MADQueryFull *query = queryFullForDocument(document, 0);

	NSError *error = nil;
	[query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	MAD_PASS(query.fieldKeys.count == (NSUInteger)1, "the query reports one field key");
	MAD_PASS_EQUAL(query.fieldKeys.firstObject, @"Invoice0.Name", "the field key is the qualified name");
	MAD_PASS_EQUAL([query fieldKeyForIndex:0], @"Invoice0.Name", "the indexed field key agrees");
}

#pragma mark - Golden SQL, per dialect

// The exact strings the importer must round-trip (docs/project/MAD_SQL_ENTRY.md §10.1): the
// full statement, not fragments, one per dialect.  These pin the generator the
// parser is built against.

static void testMySQLDialectSingleTableSql(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", document.defaultDatabase, context);
	queryFieldNamedOnTable(@"Amount", MADDataTypeDecimal, invoice, document.defaultDatabase, context);
	queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, document.defaultDatabase, context);
	MADQueryFull *query = queryFullForDocumentWithDatabase(document, 10, [[MADDatabaseMySQL alloc] init]);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the MySQL query builds without error");
	MAD_PASS_EQUAL(sql,
		@"SELECT\n\t`Invoice0`.`Amount`,\n\t`Invoice0`.`Name`\n"
		@"FROM\n\t`Invoice` AS `Invoice0`\nLIMIT 10",
		"the MySQL statement is exact");
}

static void testTDSDialectSingleTableSql(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", document.defaultDatabase, context);
	queryFieldNamedOnTable(@"Amount", MADDataTypeDecimal, invoice, document.defaultDatabase, context);
	queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, document.defaultDatabase, context);
	MADQueryFull *query = queryFullForDocumentWithDatabase(document, 10, [[MADDatabaseSQLServer alloc] init]);

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	// TOP carries the limit instead of a LIMIT clause.
	MAD_PASS(error == nil, "the TDS query builds without error");
	MAD_PASS_EQUAL(sql,
		@"SELECT\nTOP 10\n\t[Invoice0].[Amount],\n\t[Invoice0].[Name]\n"
		@"FROM\n\t[Invoice] AS [Invoice0]",
		"the TDS statement is exact");
}

#pragma mark - Golden SQL, joins

static void testEveryJoinTypeSql(void) {
	NSDictionary *expected = @{
		@(MADLinkTypeInnerJoin): @" INNER JOIN ",
		@(MADLinkTypeEquiJoin): @" JOIN ",
		@(MADLinkTypeNaturalJoin): @" NATURAL JOIN ",
		@(MADLinkTypeCrossJoin): @" CROSS JOIN ",
		@(MADLinkTypeLeftOuterJoin): @" LEFT OUTER JOIN ",
		@(MADLinkTypeRightOuterJoin): @" RIGHT OUTER JOIN ",
		@(MADLinkTypeFullOuterJoin): @" FULL OUTER JOIN ",
	};
	for (NSNumber *typeNumber in expected) {
		RptqStoreContext *context = inMemoryContext();
		RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
		RptqDatabase *database = document.defaultDatabase;

		RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", database, context);
		RptqDatabaseSchemaTable *customer = schemaTableNamed(@"Customer", database, context);
		RptqQueryField *invoiceName = queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, database, context);
		RptqQueryField *customerName = queryFieldNamedOnTable(@"Name", MADDataTypeString, customer, database, context);
		addLinkOfType((MADLinkType)typeNumber.integerValue, invoiceName, customerName, context);

		MADQueryFull *query = queryFullForDocument(document, 0);
		NSError *error = nil;
		NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

		MAD_PASS(error == nil, "the joined query builds without error");
		NSString *expectedSQL = [[NSString alloc] initWithFormat:
			@"SELECT\n\tInvoice0.Name,\n\tCustomer0.Name\n"
			@"FROM\n\tInvoice AS Invoice0\n\t\t%@Customer AS Customer0\n\t\t\tON Invoice0.Name = Customer0.Name",
			expected[typeNumber]];
		MAD_PASS_EQUAL(sql, expectedSQL, "the statement for link type %ld is exact", (long)typeNumber.integerValue);
	}
}

static void testSelfJoinUsesTheDropIndexAlias(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabase *database = document.defaultDatabase;

	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", database, context);
	RptqQueryField *key = queryFieldNamedOnTable(@"Key", MADDataTypeInteger, invoice, database, context);
	queryFieldNamedOnTable(@"ParentKey", MADDataTypeInteger, invoice, database, context);

	RptqQueryTable *secondCopy = secondCopyOfSchemaTable(invoice, database);
	RptqQueryField *secondKey = queryFieldNamedInTable(@"Key", MADDataTypeInteger, secondCopy, context);
	queryFieldNamedInTable(@"ParentKey", MADDataTypeInteger, secondCopy, context);
	addLinkOfType(MADLinkTypeInnerJoin, secondKey, key, context);

	MADQueryFull *query = queryFullForDocument(document, 0);
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the self-joined query builds without error");
	MAD_PASS([sql containsString:@"Invoice AS Invoice1"], "the second copy carries the drop-index alias: %s", [sql UTF8String]);
	MAD_PASS([sql containsString:@"ON Invoice1.Key = Invoice0.Key"], "the self join's condition: %s", [sql UTF8String]);
}

#pragma mark - Golden SQL, predicates

static void testEveryPredicateOperatorQuotesStringLiterals(void) {
	NSDictionary *expected = @{
		@(MADPredicateOperatorEqual): @"=",
		@(MADPredicateOperatorNotEqual): @"<>",
		@(MADPredicateOperatorGreaterThan): @">",
		@(MADPredicateOperatorGreaterThanOrEqualTo): @">=",
		@(MADPredicateOperatorLessThan): @"<",
		@(MADPredicateOperatorLessThanOrEqualTo): @"<=",
	};
	for (NSNumber *operatorNumber in expected) {
		RptqStoreContext *context = inMemoryContext();
		RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
		RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", document.defaultDatabase, context);
		RptqQueryField *field = queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, document.defaultDatabase, context);

		RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
		predicate.comparson = (int16_t)operatorNumber.integerValue;
		predicate.hasLeftField = field;
		predicate.rigthFieldID = @"O'Brien";
		[document.mainQuery addHasQueryPredicateObject:predicate];

		MADQueryFull *query = queryFullForDocument(document, 0);
		NSError *error = nil;
		NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

		MAD_PASS(error == nil, "the predicated query builds without error");
		NSString *expectedSQL = [[NSString alloc] initWithFormat:
			@"SELECT\n\tInvoice0.Name\nFROM\n\tInvoice AS Invoice0\n"
			@"WHERE\n\t(Invoice0.Name %@ 'O''Brien')",
			expected[operatorNumber]];
		MAD_PASS_EQUAL(sql, expectedSQL, "the statement for operator %ld is exact", (long)operatorNumber.integerValue);
	}
}

static void testTDSPredicatePrefixesStringLiterals(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", document.defaultDatabase, context);
	RptqQueryField *field = queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, document.defaultDatabase, context);

	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorEqual;
	predicate.hasLeftField = field;
	predicate.rigthFieldID = @"O'Brien";
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = queryFullForDocumentWithDatabase(document, 0, [[MADDatabaseSQLServer alloc] init]);
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the TDS predicated query builds without error");
	MAD_PASS_EQUAL(sql,
		@"SELECT\n\t[Invoice0].[Name]\nFROM\n\t[Invoice] AS [Invoice0]\n"
		@"WHERE\n\t([Invoice0].[Name] = N'O''Brien')",
		"the TDS predicate statement is exact");
}

static void testNumericPredicateLiteralIsBare(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", document.defaultDatabase, context);
	RptqQueryField *field = queryFieldNamedOnTable(@"Amount", MADDataTypeDecimal, invoice, document.defaultDatabase, context);

	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorGreaterThan;
	predicate.hasLeftField = field;
	predicate.rigthFieldID = @"100";
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = queryFullForDocument(document, 0);
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the numeric predicated query builds without error");
	MAD_PASS_EQUAL(sql,
		@"SELECT\n\tInvoice0.Amount\nFROM\n\tInvoice AS Invoice0\n"
		@"WHERE\n\t(Invoice0.Amount > 100)",
		"the numeric statement is exact");
}

static void testColumnToColumnPredicate(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabase *database = document.defaultDatabase;

	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", database, context);
	RptqDatabaseSchemaTable *customer = schemaTableNamed(@"Customer", database, context);
	RptqQueryField *invoiceKey = queryFieldNamedOnTable(@"Key", MADDataTypeInteger, invoice, database, context);
	RptqQueryField *invoiceName = queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, database, context);
	RptqQueryField *customerKey = queryFieldNamedOnTable(@"CustomerKey", MADDataTypeInteger, customer, database, context);
	RptqQueryField *customerName = queryFieldNamedOnTable(@"Name", MADDataTypeString, customer, database, context);
	addLinkOfType(MADLinkTypeInnerJoin, invoiceKey, customerKey, context);

	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorEqual;
	predicate.hasLeftField = invoiceName;
	predicate.hasRightField = customerName;
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = queryFullForDocument(document, 0);
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the column-to-column query builds without error");
	MAD_PASS([sql containsString:@"\nWHERE\n\t(Invoice0.Name = Customer0.Name)"],
			 "the column-to-column predicate: %s", [sql UTF8String]);
}

static void testPredicateConjunctionUsesAndSeparator(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", document.defaultDatabase, context);
	RptqQueryField *name = queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, document.defaultDatabase, context);
	RptqQueryField *amount = queryFieldNamedOnTable(@"Amount", MADDataTypeDecimal, invoice, document.defaultDatabase, context);

	RptqQueryPredicate *namePredicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	namePredicate.comparson = (int16_t)MADPredicateOperatorEqual;
	namePredicate.hasLeftField = name;
	namePredicate.rigthFieldID = @"A";
	[document.mainQuery addHasQueryPredicateObject:namePredicate];

	RptqQueryPredicate *amountPredicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	amountPredicate.comparson = (int16_t)MADPredicateOperatorGreaterThan;
	amountPredicate.hasLeftField = amount;
	amountPredicate.rigthFieldID = @"5";
	[document.mainQuery addHasQueryPredicateObject:amountPredicate];

	MADQueryFull *query = queryFullForDocument(document, 0);
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the conjunction builds without error");
	// The predicates are a set, so their order is the set's; the conjunction shape is
	// what is pinned here, not the order.
	MAD_PASS([sql containsString:@"\nWHERE\n"], "the WHERE header: %s", [sql UTF8String]);
	MAD_PASS([sql containsString:@" AND \n"], "the AND separator: %s", [sql UTF8String]);
	MAD_PASS([sql containsString:@"(Invoice0.Name = 'A')"], "the first predicate: %s", [sql UTF8String]);
	MAD_PASS([sql containsString:@"(Invoice0.Amount > 5)"], "the second predicate: %s", [sql UTF8String]);
}

#pragma mark - Golden SQL, active fields

static void testActiveFieldOrderingIsByAlias(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = documentWithDatabaseAndQueryInContext(context);
	RptqDatabaseSchemaTable *invoice = schemaTableNamed(@"Invoice", document.defaultDatabase, context);
	RptqQueryField *amount = queryFieldNamedOnTable(@"Amount", MADDataTypeDecimal, invoice, document.defaultDatabase, context);
	RptqQueryField *name = queryFieldNamedOnTable(@"Name", MADDataTypeString, invoice, document.defaultDatabase, context);

	RptqQueryGroup *amountGroup = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	amountGroup.hasField = amount;
	RptqQueryGroup *nameGroup = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	nameGroup.hasField = name;

	MADQueryFull *query = queryFullForDocument(document, 0);
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	MAD_PASS(error == nil, "the active-fields query builds without error");
	MAD_PASS_EQUAL(sql,
		@"SELECT\n\tInvoice0.Amount,\n\tInvoice0.Name\nFROM\n\tInvoice AS Invoice0",
		"the active select list is ordered by alias");
	MAD_PASS_EQUAL(query.fieldKeys, (@[ @"Invoice0.Amount", @"Invoice0.Name" ]), "the field keys follow the same order");
}

MAD_TEST_MAIN("MADQueryFullTests",
	MAD_TEST(testQueryWithNoTablesIsEmpty),
	MAD_TEST(testSingleTableAllFieldsSql),
	MAD_TEST(testLimitClauseIsAppended),
	MAD_TEST(testPredicateIsSplicedAfterFrom),
	MAD_TEST(testActiveFieldsSelectListOmitsUnreferencedFields),
	MAD_TEST(testNoActiveFieldsReportsError),
	MAD_TEST(testCopySQLUsesActiveFields),
	MAD_TEST(testFieldKeysReflectActiveFieldOrder),
	MAD_TEST(testMySQLDialectSingleTableSql),
	MAD_TEST(testTDSDialectSingleTableSql),
	MAD_TEST(testEveryJoinTypeSql),
	MAD_TEST(testSelfJoinUsesTheDropIndexAlias),
	MAD_TEST(testEveryPredicateOperatorQuotesStringLiterals),
	MAD_TEST(testTDSPredicatePrefixesStringLiterals),
	MAD_TEST(testNumericPredicateLiteralIsBare),
	MAD_TEST(testColumnToColumnPredicate),
	MAD_TEST(testPredicateConjunctionUsesAndSeparator),
	MAD_TEST(testActiveFieldOrderingIsByAlias));
