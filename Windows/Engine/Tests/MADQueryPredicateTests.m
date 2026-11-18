//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQueryPredicateTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQueryPredicateTests.m: MADQueryPredicate turns a
//  set of RptqQueryPredicate rows into the WHERE clause of a generated query.
//  The store is a real SQLite file under a per-test temp directory, as in the
//  Xcode suite; the mock database is the portable half of MADMock
//  (Tests/Support/MADMock.h).
//
//  The interesting behaviours pinned here are the two right-hand-side spellings
//  -- a field reference (both sides are qualified names) and a user value (a
//  number is a bare literal, anything else goes through -newSafeLiteral:) --
//  plus the leading "WHERE" / joining " AND " scaffolding.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabaseField.h>

#import "MADMock.h"
#import <MAD/MADQueryPredicate.h>
#import <MAD/MADPredicateOperator.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>

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

// A query field wired the way the document model expects: schema field -> schema
// table -> query table -> query field.
static RptqQueryField *queryFieldNamed(NSString *name, MADDataType type, NSString *tableName,
									   RptqStoreContext *context, RptqDocument *document) {
	MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
	databaseField.fieldType = type;

	RptqDatabaseSchemaField *schemaField = [RptqDatabaseSchemaField newDatabaseSchemaFieldFactoryForManagedObjectContext:context
																												 andField:databaseField];
	RptqDatabaseSchemaTable *schemaTable = [RptqDatabaseSchemaTable newDatabaseSchemaTableFactoryForManagedObjectContext:context
																													name:tableName
																											andQueryable:YES];
	[document.defaultDatabase addHasTablesObject:schemaTable];
	schemaField.inTable = schemaTable;

	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
																	database:document.defaultDatabase
													  forManagedObjectContext:context];

	RptqQueryField *queryField = [RptqQueryField newQueryField:context];
	queryField.databaseSchemaField = schemaField;
	queryField.inQueryTable = queryTable;
	return queryField;
}

static RptqQueryPredicate *predicateInContext(RptqStoreContext *context,
											  RptqQueryField *leftField,
											  RptqQueryField *rightField,
											  NSString *rightValue,
											  MADPredicateOperator op) {
	RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
	predicate.comparson = (int16_t)op;
	predicate.hasLeftField = leftField;
	if (rightField) {
		predicate.hasRightField = rightField;
	} else {
		// Despite the spelling of the property, this holds the user's typed value.
		predicate.rigthFieldID = rightValue;
	}
	return predicate;
}

#pragma mark - Tests

static void testEmptyPredicateSetProducesNoWhereClause(void) {
	__unused RptqStoreContext *context = inMemoryContext();
	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet set]
																		andDatabase:[MADMock mockDatabase]];
	MAD_PASS_EQUAL(builder.sql, @"", "an empty predicate set builds no WHERE clause");
}

static void testFieldToFieldPredicateQualifiesBothSides(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = queryFieldNamed(@"Name", MADDataTypeString, @"Invoice", context, document);
	RptqQueryField *right = queryFieldNamed(@"Name", MADDataTypeString, @"Customer", context, document);

	RptqQueryPredicate *predicate = predicateInContext(context, left, right, nil, MADPredicateOperatorEqual);

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObject:predicate]
																		andDatabase:[MADMock mockDatabase]];

	// The alias carries the drop index ("Invoice" -> "Invoice0"), and both sides are
	// qualified table.field references.
	MAD_PASS_EQUAL(builder.sql, @"\nWHERE\n\t(Invoice0.Name = Customer0.Name)",
				   "a field-to-field predicate qualifies both sides");
}

static void testStringValuePredicateIsQuoted(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = queryFieldNamed(@"Name", MADDataTypeString, @"Invoice", context, document);
	RptqQueryPredicate *predicate = predicateInContext(context, left, nil, @"O'Brien", MADPredicateOperatorEqual);

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObject:predicate]
																		andDatabase:[MADMock mockDatabase]];

	// A string value is quoted and its interior quote doubled, via -newSafeLiteral:.
	MAD_PASS_EQUAL(builder.sql, @"\nWHERE\n\t(Invoice0.Name = 'O''Brien')",
				   "a string value is quoted and its interior quote doubled");
}

static void testNumericValuePredicateIsBare(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = queryFieldNamed(@"Amount", MADDataTypeInteger, @"Invoice", context, document);
	RptqQueryPredicate *predicate = predicateInContext(context, left, nil, @"42", MADPredicateOperatorGreaterThan);

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObject:predicate]
																		andDatabase:[MADMock mockDatabase]];

	// A numeric field's value is already a valid SQL literal.
	MAD_PASS_EQUAL(builder.sql, @"\nWHERE\n\t(Invoice0.Amount > 42)",
				   "a numeric value is a bare literal");
}

static void testMultiplePredicatesAreJoinedWithAnd(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = queryFieldNamed(@"Name", MADDataTypeString, @"Invoice", context, document);
	RptqQueryPredicate *first = predicateInContext(context, left, nil, @"London", MADPredicateOperatorEqual);
	RptqQueryPredicate *second = predicateInContext(context, left, nil, @"Paris", MADPredicateOperatorNotEqual);

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObjects:first, second, nil]
																		andDatabase:[MADMock mockDatabase]];

	// Set iteration order is not defined, so both predicates are asserted present
	// rather than their order.
	NSString *sql = builder.sql;
	MAD_PASS([sql hasPrefix:@"\nWHERE\n"], "the clause opens with WHERE");
	MAD_PASS([sql containsString:@"(Invoice0.Name = 'London')"], "the first predicate is present");
	MAD_PASS([sql containsString:@"(Invoice0.Name <> 'Paris')"], "the second predicate is present");
	MAD_PASS([sql containsString:@" AND \n"], "the predicates are joined with AND");
}

MAD_TEST_MAIN("MADQueryPredicateTests",
	MAD_TEST(testEmptyPredicateSetProducesNoWhereClause),
	MAD_TEST(testFieldToFieldPredicateQualifiesBothSides),
	MAD_TEST(testStringValuePredicateIsQuoted),
	MAD_TEST(testNumericValuePredicateIsBare),
	MAD_TEST(testMultiplePredicatesAreJoinedWithAnd));
