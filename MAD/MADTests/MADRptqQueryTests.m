//
//  MADRptqQueryTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 4 (Core Data query domain) coverage for the MAD framework.  These tests
//  exercise the pure-logic "Extras" categories that map join types, comparison
//  operators, and key paths to their display/SQL/string forms.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import <MAD/MADPredicateOperator.h>
#import <MAD/MADQueryLinkType.h>
#import <MAD/MADSQLJoinType.h>

#import <MAD/RptqQueryPredicate.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryGroup+Extras.h>

@interface MADRptqQueryTests : XCTestCase
@end

@implementation MADRptqQueryTests

#pragma mark - Helpers

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

#pragma mark - Join-type mappings (RptqQueryLinks)

- (void)testQueryLinksReuseIdForLinkType {
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeInnerJoin], MNSJoinTypeInnerJoin);
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeEquiJoin], MNSJoinTypeEquiJoin);
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeNaturalJoin], MNSJoinTypeNaturalJoin);
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeCrossJoin], MNSJoinTypeCrossJoin);
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeLeftOuterJoin], MNSJoinTypeLeftOuterJoin);
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeRightOuterJoin], MNSJoinTypeRightOuterJoin);
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeFullOuterJoin], MNSJoinTypeFullOuterJoin);
	// Unknown (and any other) join type falls back to the left-outer-join identifier.
	XCTAssertEqualObjects([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeUnknown], MNSJoinTypeLeftOuterJoin);
}

- (void)testQueryLinksLocalizedNameForLinkType {
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeInnerJoin], @"Inner-Join");
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeEquiJoin], @"Equi-Join");
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeNaturalJoin], @"Natural Join");
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeCrossJoin], @"Cross Join");
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeLeftOuterJoin], @"Left Outer Join");
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeRightOuterJoin], @"Right Outer Join");
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeFullOuterJoin], @"Full Outer Join");
	XCTAssertEqualObjects([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeUnknown], @"Left Outer Join");
}

- (void)testQueryLinksSqlForLinkType {
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeInnerJoin], @"INNER JOIN");
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeEquiJoin], @"JOIN");
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeNaturalJoin], @"NATURAL JOIN");
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeCrossJoin], @"CROSS JOIN");
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeLeftOuterJoin], @"LEFT OUTER JOIN");
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeRightOuterJoin], @"RIGHT OUTER JOIN");
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeFullOuterJoin], @"FULL OUTER JOIN");
	XCTAssertEqualObjects([RptqQueryLinks SqlForLinkType:MADLinkTypeUnknown], @"LEFT OUTER JOIN");
}

#pragma mark - Comparison operators (RptqQueryPredicate)

- (void)testPredicateSymbolForComparson {
	RptqStoreContext *context = [self inMemoryContext];

	NSDictionary *expected = @{
		@(MADPredicateOperatorEqual): @"=",
		@(MADPredicateOperatorNotEqual): @"<>",
		@(MADPredicateOperatorGreaterThan): @">",
		@(MADPredicateOperatorGreaterThanOrEqualTo): @">=",
		@(MADPredicateOperatorLessThan): @"<",
		@(MADPredicateOperatorLessThanOrEqualTo): @"<=",
	};

	[expected enumerateKeysAndObjectsUsingBlock:^(NSNumber *op, NSString *symbol, BOOL *stop) {
		RptqQueryPredicate *predicate = [context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
		predicate.comparson = (int16_t)op.integerValue;
		XCTAssertEqualObjects([predicate symbolForComparson], symbol);
	}];
}

- (void)testPredicateSymbolForDisplay {
	RptqStoreContext *context = [self inMemoryContext];

	NSDictionary *expected = @{
		@(MADPredicateOperatorEqual): @"==",
		@(MADPredicateOperatorNotEqual): @"!=",
		@(MADPredicateOperatorGreaterThan): @">",
		@(MADPredicateOperatorGreaterThanOrEqualTo): @">=",
		@(MADPredicateOperatorLessThan): @"<",
		@(MADPredicateOperatorLessThanOrEqualTo): @"<=",
	};

	[expected enumerateKeysAndObjectsUsingBlock:^(NSNumber *op, NSString *symbol, BOOL *stop) {
		RptqQueryPredicate *predicate = [context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
		predicate.comparson = (int16_t)op.integerValue;
		XCTAssertEqualObjects([predicate symbolForDisplay], symbol);
	}];
}

#pragma mark - Query field key paths

- (void)testQueryFieldKeyConstants {
	XCTAssertEqualObjects([RptqQueryField keyInQueryTable], @"inQueryTable");
	XCTAssertEqualObjects([RptqQueryField keyTableName], @"inQueryTable.databaseSchemaTable.name");
	XCTAssertEqualObjects([RptqQueryField keyFieldName], @"databaseSchemaField.name");
	XCTAssertEqualObjects([RptqQueryField keySchemaTable], @"inQueryTable.databaseSchemaTable");
	XCTAssertEqualObjects([RptqQueryField keyQueryTableID], @"inQueryTable.identifier");
	XCTAssertEqualObjects([RptqQueryField keyQueryFieldID], @"identifier");
	XCTAssertEqualObjects([RptqQueryField keySchemaTableID], @"inQueryTable.databaseSchemaTable.identifier");
	XCTAssertEqualObjects([RptqQueryField keySchemaFieldID], @"databaseSchemaField.identifier");
	XCTAssertEqualObjects([RptqQueryField keySchemaFieldName], @"databaseSchemaField.name");
	XCTAssertEqualObjects([RptqQueryField keySchemaFieldDataType], @"databaseSchemaField.dataType");
	XCTAssertEqualObjects([RptqQueryField keyInQueryTableAlias], @"inQueryTable.alias");
}

#pragma mark - Query table alias

- (void)testQueryTableKeyConstants {
	XCTAssertEqualObjects([RptqQueryTable keyPathAlias], @"alias");
	XCTAssertEqualObjects([RptqQueryTable keyPathDropIndex], @"dropIndex");
}

- (void)testQueryTableAliasForSchemaTableName {
	XCTAssertEqualObjects([RptqQueryTable queryAliasForSchemaTableName:@"Invoice" dropIndex:1], @"Invoice1");
	XCTAssertEqualObjects([RptqQueryTable queryAliasForSchemaTableName:@"Invoice" dropIndex:12], @"Invoice12");
	// Dots in the schema-table name are stripped from the generated alias.
	XCTAssertEqualObjects([RptqQueryTable queryAliasForSchemaTableName:@"schema.table" dropIndex:2], @"schematable2");
}

#pragma mark - Query group key path

- (void)testQueryGroupKeyPathHasField {
	XCTAssertEqualObjects([RptqQueryGroup keyPathHasField], @"hasField");
}

#pragma mark - Query table equality (MTProtocolCompare)

// RptqQueryTable conforms to MTProtocolCompare, but its -isEqualTo: is degenerate: the
// first clause is the tautology [sender isEqual:sender], so any non-nil argument
// compares equal, and the fallback branch compares two nil NSNumbers.  Documented in
// docs/project/BUGS.md; no production caller reaches it today.
- (void)testQueryTableIsEqualToIsDegenerate {
	RptqStoreContext *context = [self inMemoryContext];
	RptqQueryTable *first = [context insertObjectForEntity:@"RptqQueryTable" identifier:1];
	RptqQueryTable *second = [context insertObjectForEntity:@"RptqQueryTable" identifier:2];

	XCTAssertTrue([first isEqualTo:second]);
	XCTAssertFalse([first isEqualTo:nil]);
}

@end
