//
//  MADQueryFullTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
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
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

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
	MADQueryFull *query = [[MADQueryFull alloc] initWithQuery:document.mainQuery andQueryLimit:limit];
	// The query holds its data delegate weakly (it is normally the document itself), so
	// the fixture has to keep it alive for the whole test.
	self.dataDelegate.database = [MADMock mockDatabase];
	query.dataDelegate = self.dataDelegate;
	return query;
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

@end
