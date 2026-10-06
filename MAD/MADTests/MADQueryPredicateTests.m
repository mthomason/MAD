//
//  MADQueryPredicateTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 3 coverage for MADQueryPredicate: the object that turns a set of
//  RptqQueryPredicate rows into the WHERE clause of a generated query.
//
//  The interesting behaviours pinned here are the two right-hand-side spellings --
//  a field reference (both sides are qualified names) and a user value (a number is a
//  bare literal, anything else goes through -newSafeLiteral:) -- plus the leading
//  "WHERE" / joining " AND " scaffolding.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabaseField.h>

#import "MADMock.h"
#import "MADQueryPredicate.h"
#import "MADPredicateOperator.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

@interface MADQueryPredicateTests : XCTestCase
@end

@implementation MADQueryPredicateTests

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

// A query field wired the way the document model expects: schema field -> schema
// table -> query table -> query field.
- (RptqQueryField *)queryFieldNamed:(NSString *)name
							   type:(MADDataType)type
						  tableName:(NSString *)tableName
							context:(RptqStoreContext *)context
						   document:(RptqDocument *)document {

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

- (RptqQueryPredicate *)predicateInContext:(RptqStoreContext *)context
								 leftField:(RptqQueryField *)leftField
								rightField:(RptqQueryField *)rightField
								rightValue:(NSString *)rightValue
								 operator:(MADPredicateOperator)op {
	RptqQueryPredicate *predicate = [context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
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

- (void)testEmptyPredicateSetProducesNoWhereClause {
	RptqStoreContext *context = [self inMemoryContext];
	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet set]
																		andDatabase:[MADMock mockDatabase]];
	XCTAssertEqualObjects(builder.sql, @"");
}

- (void)testFieldToFieldPredicateQualifiesBothSides {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = [self queryFieldNamed:@"Name" type:MADDataTypeString tableName:@"Invoice" context:context document:document];
	RptqQueryField *right = [self queryFieldNamed:@"Name" type:MADDataTypeString tableName:@"Customer" context:context document:document];

	RptqQueryPredicate *predicate = [self predicateInContext:context
												   leftField:left
												  rightField:right
												  rightValue:nil
													operator:MADPredicateOperatorEqual];

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObject:predicate]
																		andDatabase:[MADMock mockDatabase]];

	// The alias carries the drop index ("Invoice" -> "Invoice0"), and both sides are
	// qualified table.field references.
	XCTAssertEqualObjects(builder.sql, @"\nWHERE\n\t(Invoice0.Name = Customer0.Name)");
}

- (void)testStringValuePredicateIsQuoted {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = [self queryFieldNamed:@"Name" type:MADDataTypeString tableName:@"Invoice" context:context document:document];
	RptqQueryPredicate *predicate = [self predicateInContext:context
												   leftField:left
												  rightField:nil
												  rightValue:@"O'Brien"
													operator:MADPredicateOperatorEqual];

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObject:predicate]
																		andDatabase:[MADMock mockDatabase]];

	// A string value is quoted and its interior quote doubled, via -newSafeLiteral:.
	XCTAssertEqualObjects(builder.sql, @"\nWHERE\n\t(Invoice0.Name = 'O''Brien')");
}

- (void)testNumericValuePredicateIsBare {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = [self queryFieldNamed:@"Amount" type:MADDataTypeInteger tableName:@"Invoice" context:context document:document];
	RptqQueryPredicate *predicate = [self predicateInContext:context
												   leftField:left
												  rightField:nil
												  rightValue:@"42"
													operator:MADPredicateOperatorGreaterThan];

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObject:predicate]
																		andDatabase:[MADMock mockDatabase]];

	// A numeric field's value is already a valid SQL literal.
	XCTAssertEqualObjects(builder.sql, @"\nWHERE\n\t(Invoice0.Amount > 42)");
}

- (void)testMultiplePredicatesAreJoinedWithAnd {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];

	RptqQueryField *left = [self queryFieldNamed:@"Name" type:MADDataTypeString tableName:@"Invoice" context:context document:document];
	RptqQueryPredicate *first = [self predicateInContext:context
											   leftField:left
											  rightField:nil
											  rightValue:@"London"
												operator:MADPredicateOperatorEqual];
	RptqQueryPredicate *second = [self predicateInContext:context
												leftField:left
											   rightField:nil
											   rightValue:@"Paris"
												 operator:MADPredicateOperatorNotEqual];

	MADQueryPredicate *builder = [[MADQueryPredicate alloc] initWithQueryPredicates:[NSSet setWithObjects:first, second, nil]
																		andDatabase:[MADMock mockDatabase]];

	// Set iteration order is not defined, so both predicates are asserted present
	// rather than their order.
	NSString *sql = builder.sql;
	XCTAssertTrue([sql hasPrefix:@"\nWHERE\n"]);
	XCTAssertTrue([sql containsString:@"(Invoice0.Name = 'London')"]);
	XCTAssertTrue([sql containsString:@"(Invoice0.Name <> 'Paris')"]);
	XCTAssertTrue([sql containsString:@" AND \n"]);
}

@end
