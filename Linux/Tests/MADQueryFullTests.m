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
#import <MAD/RptqQueryPredicate.h>
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

static MADQueryFull *queryFullForDocument(RptqDocument *document, NSUInteger limit) {
	MADQueryFull *query = [[MADQueryFull alloc] initWithQuery:document.mainQuery andQueryLimit:limit];
	// The query holds its data delegate weakly (it is normally the document itself), so
	// this MRC test translation unit keeps the delegate's +1 for the test's life.
	MADTestDataDelegate *dataDelegate = [[MADTestDataDelegate alloc] init];
	dataDelegate.database = [MADMock mockDatabase];
	query.dataDelegate = dataDelegate;
	return query;
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

MAD_TEST_MAIN("MADQueryFullTests",
	MAD_TEST(testQueryWithNoTablesIsEmpty),
	MAD_TEST(testSingleTableAllFieldsSql),
	MAD_TEST(testLimitClauseIsAppended),
	MAD_TEST(testPredicateIsSplicedAfterFrom),
	MAD_TEST(testActiveFieldsSelectListOmitsUnreferencedFields),
	MAD_TEST(testNoActiveFieldsReportsError),
	MAD_TEST(testCopySQLUsesActiveFields),
	MAD_TEST(testFieldKeysReflectActiveFieldOrder));
