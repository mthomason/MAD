//
//  MADQueryFullTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 3 coverage for MADQueryFull, the SELECT/JOIN/WHERE/ORDER BY generator behind
//  the report's data load.  The SQL is assembled against the *first* document in the
//  store context (newDocumentReadFromManagedObjectContext:), and the database dialect
//  comes from -dataDelegate.
//
//  Pinned here: the empty-query early return, the single-table FROM with its alias, the
//  limit clause, the predicate splice, the all-fields vs active-fields select list, and
//  the "no active fields" error contract (code 5774).
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import "MADMock.h"
#import "MADQueryFull.h"
#import "MADQueryPredicate.h"
#import "MADPredicateOperator.h"
#import "MADQueryLinkType.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADTdsClient/MADDatabaseSQLServer.h>

#pragma mark - Test double

// The generator asks its data delegate for the database whose dialect to emit.
@interface MADTestDataDelegate : NSObject <MADDataProtocol>
@property (nonatomic, strong) MADDatabase *database;
@end

@implementation MADTestDataDelegate
- (NSArray *)sortDescriptors { return @[]; }
@end

@interface MADQueryFullTests : XCTestCase
@property (nonatomic, strong) MADTestDataDelegate *dataDelegate;
@end

@implementation MADQueryFullTests

- (void)setUp {
	[super setUp];
	self.dataDelegate = [[MADTestDataDelegate alloc] init];
}

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

// -newDocumentForManagedObjectContext: builds only the document skeleton; the
// generator reads the database and query through the document's to-one/to-many
// relationships, so the fixture has to supply those.
- (RptqDocument *)documentWithDatabaseAndQueryInContext:(RptqStoreContext *)context {
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqDatabase *database = [context insertObjectForEntity:@"RptqDatabase" identifier:10];
	RptqQuery *query = [context insertObjectForEntity:@"RptqQuery" identifier:20];
	[document addHasDatabaseSchemasObject:database];
	[database addHasQueriesObject:query];
	return document;
}

- (RptqQueryField *)queryFieldNamed:(NSString *)name
							   type:(MADDataType)type
						   database:(RptqDatabase *)database
							context:(RptqStoreContext *)context {

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

- (MADQueryFull *)queryFullForDocument:(RptqDocument *)document limit:(NSUInteger)limit {
	return [self queryFullForDocument:document limit:limit database:[MADMock mockDatabase]];
}

- (MADQueryFull *)queryFullForDocument:(RptqDocument *)document
								 limit:(NSUInteger)limit
							  database:(MADDatabase *)database {
	MADQueryFull *query = [[MADQueryFull alloc] initWithQuery:document.mainQuery andQueryLimit:limit];
	// The query holds its data delegate weakly (it is normally the document itself), so
	// the fixture has to keep it alive for the whole test.
	self.dataDelegate.database = database;
	query.dataDelegate = self.dataDelegate;
	return query;
}

#pragma mark - Fixture: tables, links and predicates

// The single-table helper above creates a fresh schema table per field; the
// golden fixtures need one schema table per name and one query table per copy of
// it, so these four helpers are the multi-table form of it.
- (RptqDatabaseSchemaTable *)schemaTableNamed:(NSString *)name
									 database:(RptqDatabase *)database
									  context:(RptqStoreContext *)context {
	RptqDatabaseSchemaTable *schemaTable =
		[RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																				 name:name
																		 andQueryable:YES];
	[database addHasTablesObject:schemaTable];
	return schemaTable;
}

- (RptqQueryTable *)queryTableForSchemaTable:(RptqDatabaseSchemaTable *)schemaTable
									database:(RptqDatabase *)database {
	for (RptqQueryTable *existing in database.defaultQuery.hasQueryTables) {
		if (existing.databaseSchemaTable == schemaTable) return existing;
	}
	return [RptqQueryTable newQueryTableForSchemaTable:schemaTable
											  database:database
								forManagedObjectContext:schemaTable.storeContext];
}

// A second copy of one schema table (a self join) is made the way the factory
// makes every copy: counted past the copies already in the query.
- (RptqQueryTable *)secondCopyOfSchemaTable:(RptqDatabaseSchemaTable *)schemaTable
								   database:(RptqDatabase *)database {
	return [RptqQueryTable newQueryTableForSchemaTable:schemaTable
											  database:database
								forManagedObjectContext:schemaTable.storeContext];
}

- (RptqQueryField *)queryFieldNamed:(NSString *)name
							   type:(MADDataType)type
					   onSchemaTable:(RptqDatabaseSchemaTable *)schemaTable
						   database:(RptqDatabase *)database
							context:(RptqStoreContext *)context {
	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = type;

	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																												 andField:databaseField];
	schemaField.inTable = schemaTable;

	RptqQueryField *queryField = [RptqQueryField newQueryField:context];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = [self queryTableForSchemaTable:schemaTable database:database];
	return queryField;
}

- (RptqQueryField *)queryFieldNamed:(NSString *)name
							   type:(MADDataType)type
					  inQueryTable:(RptqQueryTable *)queryTable
						   context:(RptqStoreContext *)context {
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

- (RptqQueryLinks *)addLinkOfType:(MADLinkType)type
							left:(RptqQueryField *)left
						   right:(RptqQueryField *)right
						 context:(RptqStoreContext *)context {
	RptqQueryLinks *link = (RptqQueryLinks *)[context insertObjectForEntity:@"RptqQueryLinks" identifier:0];
	link.type = (int16_t)type;
	link.hasLeftField = left;
	link.hasRightField = right;
	[left.inQueryTable.inQuery addHasQueryLinksObject:link];
	return link;
}

#pragma mark - Empty query

- (void)testQueryWithNoTablesIsEmpty {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	MADQueryFull *query = [self queryFullForDocument:document limit:0];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertEqualObjects(sql, @"");
	XCTAssertNil(error);
}

#pragma mark - Single table

- (void)testSingleTableAllFieldsSql {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	[self queryFieldNamed:@"Name" type:MADDataTypeString database:document.defaultDatabase context:context];
	[self queryFieldNamed:@"Amount" type:MADDataTypeDecimal database:document.defaultDatabase context:context];
	MADQueryFull *query = [self queryFullForDocument:document limit:0];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertTrue([sql hasPrefix:@"SELECT\n"]);
	XCTAssertTrue([sql containsString:@"\nFROM\n\tInvoice AS Invoice0"]);
	// Both fields are selected; their order inside the table's set is undefined.
	XCTAssertTrue([sql containsString:@"Invoice0.Name"]);
	XCTAssertTrue([sql containsString:@"Invoice0.Amount"]);
	// No predicate and no limit.
	XCTAssertFalse([sql containsString:@"WHERE"]);
	XCTAssertFalse([sql containsString:@"LIMIT"]);
}

- (void)testLimitClauseIsAppended {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	[self queryFieldNamed:@"Name" type:MADDataTypeString database:document.defaultDatabase context:context];
	MADQueryFull *query = [self queryFullForDocument:document limit:10];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertTrue([sql hasSuffix:@"\nLIMIT 10"]);
}

- (void)testPredicateIsSplicedAfterFrom {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" type:MADDataTypeString database:document.defaultDatabase context:context];

	RptqQueryPredicate *predicate = [context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorEqual;
	predicate.hasLeftField = field;
	predicate.rigthFieldID = @"O'Brien";
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = [self queryFullForDocument:document limit:0];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertTrue([sql hasSuffix:@"\nWHERE\n\t(Invoice0.Name = 'O''Brien')"]);
}

#pragma mark - Active fields

- (void)testActiveFieldsSelectListOmitsUnreferencedFields {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqQueryField *referenced = [self queryFieldNamed:@"Name" type:MADDataTypeString database:document.defaultDatabase context:context];
	[self queryFieldNamed:@"Amount" type:MADDataTypeDecimal database:document.defaultDatabase context:context];

	RptqQueryGroup *group = [context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = referenced;

	MADQueryFull *query = [self queryFullForDocument:document limit:0];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertTrue([sql containsString:@"Invoice0.Name"]);
	XCTAssertFalse([sql containsString:@"Invoice0.Amount"]);
}

- (void)testNoActiveFieldsReportsError {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	// A query table with a field exists, but nothing in the report references it.
	[self queryFieldNamed:@"Name" type:MADDataTypeString database:document.defaultDatabase context:context];
	MADQueryFull *query = [self queryFullForDocument:document limit:0];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	XCTAssertEqualObjects(sql, @"");
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 5774);
	XCTAssertEqualObjects(error.domain, @"MADQuery");
}

- (void)testCopySQLUsesActiveFields {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqQueryField *referenced = [self queryFieldNamed:@"Name" type:MADDataTypeString database:document.defaultDatabase context:context];
	RptqQueryGroup *group = [context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = referenced;
	MADQueryFull *query = [self queryFullForDocument:document limit:0];

	NSError *error = nil;
	NSString *copied = [query copySQLWithManagedObjectContext:context error:&error];
	NSString *direct = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	XCTAssertEqualObjects(copied, direct);
}

#pragma mark - Field keys

- (void)testFieldKeysReflectActiveFieldOrder {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqQueryField *referenced = [self queryFieldNamed:@"Name" type:MADDataTypeString database:document.defaultDatabase context:context];
	RptqQueryGroup *group = [context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	group.hasField = referenced;
	MADQueryFull *query = [self queryFullForDocument:document limit:0];

	NSError *error = nil;
	[query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	XCTAssertEqual(query.fieldKeys.count, (NSUInteger)1);
	XCTAssertEqualObjects(query.fieldKeys.firstObject, @"Invoice0.Name");
	XCTAssertEqualObjects([query fieldKeyForIndex:0], @"Invoice0.Name");
}

#pragma mark - Golden SQL, per dialect

// The exact strings the importer must round-trip (MAD_SQL_ENTRY.md §10.1): the
// full statement, not fragments, one per dialect.  These pin the generator the
// parser is built against.

- (void)testMySQLDialectSingleTableSql {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:document.defaultDatabase context:context];
	[self queryFieldNamed:@"Amount" type:MADDataTypeDecimal onSchemaTable:invoice database:document.defaultDatabase context:context];
	[self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:document.defaultDatabase context:context];
	MADQueryFull *query = [self queryFullForDocument:document limit:10 database:[[MADDatabaseMySQL alloc] init]];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(sql,
		@"SELECT\n\t`Invoice0`.`Amount`,\n\t`Invoice0`.`Name`\n"
		@"FROM\n\t`Invoice` AS `Invoice0`\nLIMIT 10");
}

- (void)testTDSDialectSingleTableSql {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:document.defaultDatabase context:context];
	[self queryFieldNamed:@"Amount" type:MADDataTypeDecimal onSchemaTable:invoice database:document.defaultDatabase context:context];
	[self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:document.defaultDatabase context:context];
	MADQueryFull *query = [self queryFullForDocument:document limit:10 database:[[MADDatabaseSQLServer alloc] init]];

	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	// TOP carries the limit instead of a LIMIT clause.
	XCTAssertNil(error);
	XCTAssertEqualObjects(sql,
		@"SELECT\nTOP 10\n\t[Invoice0].[Amount],\n\t[Invoice0].[Name]\n"
		@"FROM\n\t[Invoice] AS [Invoice0]");
}

#pragma mark - Golden SQL, joins

- (void)testEveryJoinTypeSql {
	NSDictionary<NSNumber *, NSString *> *expected = @{
		@(MADLinkTypeInnerJoin): @" INNER JOIN ",
		@(MADLinkTypeEquiJoin): @" JOIN ",
		@(MADLinkTypeNaturalJoin): @" NATURAL JOIN ",
		@(MADLinkTypeCrossJoin): @" CROSS JOIN ",
		@(MADLinkTypeLeftOuterJoin): @" LEFT OUTER JOIN ",
		@(MADLinkTypeRightOuterJoin): @" RIGHT OUTER JOIN ",
		@(MADLinkTypeFullOuterJoin): @" FULL OUTER JOIN ",
	};
	for (NSNumber *typeNumber in expected) {
		RptqStoreContext *context = [self inMemoryContext];
		RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
		RptqDatabase *database = document.defaultDatabase;

		RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:database context:context];
		RptqDatabaseSchemaTable *customer = [self schemaTableNamed:@"Customer" database:database context:context];
		RptqQueryField *invoiceName = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:database context:context];
		RptqQueryField *customerName = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:customer database:database context:context];
		[self addLinkOfType:(MADLinkType)typeNumber.integerValue left:invoiceName right:customerName context:context];

		MADQueryFull *query = [self queryFullForDocument:document limit:0];
		NSError *error = nil;
		NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

		XCTAssertNil(error);
		NSString *joinPart = expected[typeNumber];
		XCTAssertEqualObjects(sql,
			([[NSString alloc] initWithFormat:
			 @"SELECT\n\tInvoice0.Name,\n\tCustomer0.Name\n"
			 @"FROM\n\tInvoice AS Invoice0\n\t\t%@Customer AS Customer0\n\t\t\tON Invoice0.Name = Customer0.Name",
			 joinPart]),
			@"link type %@", typeNumber);
	}
}

- (void)testSelfJoinUsesTheDropIndexAlias {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabase *database = document.defaultDatabase;

	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:database context:context];
	RptqQueryField *key = [self queryFieldNamed:@"Key" type:MADDataTypeInteger onSchemaTable:invoice database:database context:context];
	RptqQueryField *parentKey = [self queryFieldNamed:@"ParentKey" type:MADDataTypeInteger onSchemaTable:invoice database:database context:context];

	RptqQueryTable *secondCopy = [self secondCopyOfSchemaTable:invoice database:database];
	RptqQueryField *secondKey = [self queryFieldNamed:@"Key" type:MADDataTypeInteger inQueryTable:secondCopy context:context];
	RptqQueryField *secondParentKey = [self queryFieldNamed:@"ParentKey" type:MADDataTypeInteger inQueryTable:secondCopy context:context];
	[self addLinkOfType:MADLinkTypeInnerJoin left:secondKey right:key context:context];

	MADQueryFull *query = [self queryFullForDocument:document limit:0];
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertTrue([sql containsString:@"Invoice AS Invoice1"], @"%@", sql);
	XCTAssertTrue([sql containsString:@"ON Invoice1.Key = Invoice0.Key"], @"%@", sql);
}

#pragma mark - Golden SQL, predicates

- (void)testEveryPredicateOperatorQuotesStringLiterals {
	NSDictionary<NSNumber *, NSString *> *expected = @{
		@(MADPredicateOperatorEqual): @"=",
		@(MADPredicateOperatorNotEqual): @"<>",
		@(MADPredicateOperatorGreaterThan): @">",
		@(MADPredicateOperatorGreaterThanOrEqualTo): @">=",
		@(MADPredicateOperatorLessThan): @"<",
		@(MADPredicateOperatorLessThanOrEqualTo): @"<=",
	};
	for (NSNumber *operatorNumber in expected) {
		RptqStoreContext *context = [self inMemoryContext];
		RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
		RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:document.defaultDatabase context:context];
		RptqQueryField *field = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:document.defaultDatabase context:context];

		RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
		predicate.comparson = (int16_t)operatorNumber.integerValue;
		predicate.hasLeftField = field;
		predicate.rigthFieldID = @"O'Brien";
		[document.mainQuery addHasQueryPredicateObject:predicate];

		MADQueryFull *query = [self queryFullForDocument:document limit:0];
		NSError *error = nil;
		NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

		XCTAssertNil(error);
		XCTAssertEqualObjects(sql,
			([[NSString alloc] initWithFormat:
			 @"SELECT\n\tInvoice0.Name\nFROM\n\tInvoice AS Invoice0\n"
			 @"WHERE\n\t(Invoice0.Name %@ 'O''Brien')",
			 expected[operatorNumber]]),
			@"operator %@", operatorNumber);
	}
}

- (void)testTDSPredicatePrefixesStringLiterals {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:document.defaultDatabase context:context];
	RptqQueryField *field = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:document.defaultDatabase context:context];

	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorEqual;
	predicate.hasLeftField = field;
	predicate.rigthFieldID = @"O'Brien";
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = [self queryFullForDocument:document limit:0 database:[[MADDatabaseSQLServer alloc] init]];
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(sql,
		@"SELECT\n\t[Invoice0].[Name]\nFROM\n\t[Invoice] AS [Invoice0]\n"
		@"WHERE\n\t([Invoice0].[Name] = N'O''Brien')");
}

- (void)testNumericPredicateLiteralIsBare {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:document.defaultDatabase context:context];
	RptqQueryField *field = [self queryFieldNamed:@"Amount" type:MADDataTypeDecimal onSchemaTable:invoice database:document.defaultDatabase context:context];

	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorGreaterThan;
	predicate.hasLeftField = field;
	predicate.rigthFieldID = @"100";
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = [self queryFullForDocument:document limit:0];
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(sql,
		@"SELECT\n\tInvoice0.Amount\nFROM\n\tInvoice AS Invoice0\n"
		@"WHERE\n\t(Invoice0.Amount > 100)");
}

- (void)testColumnToColumnPredicate {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabase *database = document.defaultDatabase;

	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:database context:context];
	RptqDatabaseSchemaTable *customer = [self schemaTableNamed:@"Customer" database:database context:context];
	RptqQueryField *invoiceKey = [self queryFieldNamed:@"Key" type:MADDataTypeInteger onSchemaTable:invoice database:database context:context];
	RptqQueryField *invoiceName = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:database context:context];
	RptqQueryField *customerKey = [self queryFieldNamed:@"CustomerKey" type:MADDataTypeInteger onSchemaTable:customer database:database context:context];
	RptqQueryField *customerName = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:customer database:database context:context];
	[self addLinkOfType:MADLinkTypeInnerJoin left:invoiceKey right:customerKey context:context];

	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)MADPredicateOperatorEqual;
	predicate.hasLeftField = invoiceName;
	predicate.hasRightField = customerName;
	[document.mainQuery addHasQueryPredicateObject:predicate];

	MADQueryFull *query = [self queryFullForDocument:document limit:0];
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertTrue([sql containsString:@"\nWHERE\n\t(Invoice0.Name = Customer0.Name)"], @"%@", sql);
}

- (void)testPredicateConjunctionUsesAndSeparator {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:document.defaultDatabase context:context];
	RptqQueryField *name = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:document.defaultDatabase context:context];
	RptqQueryField *amount = [self queryFieldNamed:@"Amount" type:MADDataTypeDecimal onSchemaTable:invoice database:document.defaultDatabase context:context];

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

	MADQueryFull *query = [self queryFullForDocument:document limit:0];
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:NO managedObjectContext:context error:&error];

	XCTAssertNil(error);
	// The predicates are a set, so their order is the set's; the conjunction shape is
	// what is pinned here, not the order.
	XCTAssertTrue([sql containsString:@"\nWHERE\n"], @"%@", sql);
	XCTAssertTrue([sql containsString:@" AND \n"], @"%@", sql);
	XCTAssertTrue([sql containsString:@"(Invoice0.Name = 'A')"], @"%@", sql);
	XCTAssertTrue([sql containsString:@"(Invoice0.Amount > 5)"], @"%@", sql);
}

#pragma mark - Golden SQL, active fields

- (void)testActiveFieldOrderingIsByAlias {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [self documentWithDatabaseAndQueryInContext:context];
	RptqDatabaseSchemaTable *invoice = [self schemaTableNamed:@"Invoice" database:document.defaultDatabase context:context];
	RptqQueryField *amount = [self queryFieldNamed:@"Amount" type:MADDataTypeDecimal onSchemaTable:invoice database:document.defaultDatabase context:context];
	RptqQueryField *name = [self queryFieldNamed:@"Name" type:MADDataTypeString onSchemaTable:invoice database:document.defaultDatabase context:context];

	RptqQueryGroup *amountGroup = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	amountGroup.hasField = amount;
	RptqQueryGroup *nameGroup = (RptqQueryGroup *)[context insertObjectForEntity:@"RptqQueryGroup" identifier:0];
	nameGroup.hasField = name;

	MADQueryFull *query = [self queryFullForDocument:document limit:0];
	NSError *error = nil;
	NSString *sql = [query SQLOnlyActiveFields:YES managedObjectContext:context error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(sql,
		@"SELECT\n\tInvoice0.Amount,\n\tInvoice0.Name\nFROM\n\tInvoice AS Invoice0");
	XCTAssertEqualObjects(query.fieldKeys, (@[ @"Invoice0.Amount", @"Invoice0.Name" ]));
}

@end
