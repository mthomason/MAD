//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADRptqQueryTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADRptqQueryTests.m: the pure-logic query "Extras"
//  categories that map join types, comparison operators, and key paths to their
//  display/SQL/string forms.  The store the two predicate tests insert into is a
//  real SQLite file under a per-test temp directory, standing in for the Core
//  Data stack the Xcode suite uses.
//

#import "MADTestSupport.h"

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

#pragma mark - Helpers

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	// Testing.h's pass() carries a printf format, so the error object cannot be
	// printed with %@; the check is the same one the Xcode helper made.
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

#pragma mark - Join-type mappings (RptqQueryLinks)

static void testQueryLinksReuseIdForLinkType(void) {
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeInnerJoin], MNSJoinTypeInnerJoin, "the inner-join identifier");
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeEquiJoin], MNSJoinTypeEquiJoin, "the equi-join identifier");
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeNaturalJoin], MNSJoinTypeNaturalJoin, "the natural-join identifier");
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeCrossJoin], MNSJoinTypeCrossJoin, "the cross-join identifier");
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeLeftOuterJoin], MNSJoinTypeLeftOuterJoin, "the left-outer-join identifier");
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeRightOuterJoin], MNSJoinTypeRightOuterJoin, "the right-outer-join identifier");
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeFullOuterJoin], MNSJoinTypeFullOuterJoin, "the full-outer-join identifier");
	// Unknown (and any other) join type falls back to the left-outer-join identifier.
	MAD_PASS_EQUAL([RptqQueryLinks ReuseIdForLinkType:MADLinkTypeUnknown], MNSJoinTypeLeftOuterJoin, "an unknown join type falls back to left outer");
}

static void testQueryLinksLocalizedNameForLinkType(void) {
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeInnerJoin], @"Inner-Join", "the inner-join name");
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeEquiJoin], @"Equi-Join", "the equi-join name");
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeNaturalJoin], @"Natural Join", "the natural-join name");
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeCrossJoin], @"Cross Join", "the cross-join name");
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeLeftOuterJoin], @"Left Outer Join", "the left-outer-join name");
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeRightOuterJoin], @"Right Outer Join", "the right-outer-join name");
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeFullOuterJoin], @"Full Outer Join", "the full-outer-join name");
	MAD_PASS_EQUAL([RptqQueryLinks newLocalizedNameForLinkType:MADLinkTypeUnknown], @"Left Outer Join", "an unknown join type falls back to the left-outer name");
}

static void testQueryLinksSqlForLinkType(void) {
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeInnerJoin], @"INNER JOIN", "the inner-join SQL");
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeEquiJoin], @"JOIN", "the equi-join SQL");
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeNaturalJoin], @"NATURAL JOIN", "the natural-join SQL");
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeCrossJoin], @"CROSS JOIN", "the cross-join SQL");
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeLeftOuterJoin], @"LEFT OUTER JOIN", "the left-outer-join SQL");
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeRightOuterJoin], @"RIGHT OUTER JOIN", "the right-outer-join SQL");
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeFullOuterJoin], @"FULL OUTER JOIN", "the full-outer-join SQL");
	MAD_PASS_EQUAL([RptqQueryLinks SqlForLinkType:MADLinkTypeUnknown], @"LEFT OUTER JOIN", "an unknown join type falls back to the left-outer SQL");
}

#pragma mark - Comparison operators (RptqQueryPredicate)

static void testPredicateSymbolForComparson(void) {
	RptqStoreContext *context = inMemoryContext();

	NSDictionary *expected = @{
		@(MADPredicateOperatorEqual): @"=",
		@(MADPredicateOperatorNotEqual): @"<>",
		@(MADPredicateOperatorGreaterThan): @">",
		@(MADPredicateOperatorGreaterThanOrEqualTo): @">=",
		@(MADPredicateOperatorLessThan): @"<",
		@(MADPredicateOperatorLessThanOrEqualTo): @"<=",
	};

	// GNUstep types the enumeration block as (id<NSCopying>, id, BOOL *), so the
	// parameters carry that signature; the values are the same NSNumber and
	// NSString the Xcode suite's block named.
	[expected enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> op, id symbol, BOOL *stop) {
		RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
		predicate.comparson = (int16_t)[(NSNumber *)op integerValue];
		MAD_PASS_EQUAL([predicate symbolForComparson], symbol, "the comparison symbol follows the operator");
	}];
}

static void testPredicateSymbolForDisplay(void) {
	RptqStoreContext *context = inMemoryContext();

	NSDictionary *expected = @{
		@(MADPredicateOperatorEqual): @"==",
		@(MADPredicateOperatorNotEqual): @"!=",
		@(MADPredicateOperatorGreaterThan): @">",
		@(MADPredicateOperatorGreaterThanOrEqualTo): @">=",
		@(MADPredicateOperatorLessThan): @"<",
		@(MADPredicateOperatorLessThanOrEqualTo): @"<=",
	};

	// The block signature is GNUstep's (id<NSCopying>, id, BOOL *); see above.
	[expected enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> op, id symbol, BOOL *stop) {
		RptqQueryPredicate *predicate = (RptqQueryPredicate *)[context insertObjectForEntity:@"RptqQueryPredicate" identifier:0];
		predicate.comparson = (int16_t)[(NSNumber *)op integerValue];
		MAD_PASS_EQUAL([predicate symbolForDisplay], symbol, "the display symbol follows the operator");
	}];
}

#pragma mark - Query field key paths

static void testQueryFieldKeyConstants(void) {
	MAD_PASS_EQUAL([RptqQueryField keyInQueryTable], @"inQueryTable", "the in-query-table key");
	MAD_PASS_EQUAL([RptqQueryField keyTableName], @"inQueryTable.databaseSchemaTable.name", "the table-name key");
	MAD_PASS_EQUAL([RptqQueryField keyFieldName], @"databaseSchemaField.name", "the field-name key");
	MAD_PASS_EQUAL([RptqQueryField keySchemaTable], @"inQueryTable.databaseSchemaTable", "the schema-table key");
	MAD_PASS_EQUAL([RptqQueryField keyQueryTableID], @"inQueryTable.identifier", "the query-table id key");
	MAD_PASS_EQUAL([RptqQueryField keyQueryFieldID], @"identifier", "the query-field id key");
	MAD_PASS_EQUAL([RptqQueryField keySchemaTableID], @"inQueryTable.databaseSchemaTable.identifier", "the schema-table id key");
	MAD_PASS_EQUAL([RptqQueryField keySchemaFieldID], @"databaseSchemaField.identifier", "the schema-field id key");
	MAD_PASS_EQUAL([RptqQueryField keySchemaFieldName], @"databaseSchemaField.name", "the schema-field name key");
	MAD_PASS_EQUAL([RptqQueryField keySchemaFieldDataType], @"databaseSchemaField.dataType", "the schema-field data-type key");
	MAD_PASS_EQUAL([RptqQueryField keyInQueryTableAlias], @"inQueryTable.alias", "the query-table alias key");
}

#pragma mark - Query table alias

static void testQueryTableKeyConstants(void) {
	MAD_PASS_EQUAL([RptqQueryTable keyPathAlias], @"alias", "the alias key path");
	MAD_PASS_EQUAL([RptqQueryTable keyPathDropIndex], @"dropIndex", "the drop-index key path");
}

static void testQueryTableAliasForSchemaTableName(void) {
	MAD_PASS_EQUAL([RptqQueryTable queryAliasForSchemaTableName:@"Invoice" dropIndex:1], @"Invoice1", "the alias appends a one-digit drop index");
	MAD_PASS_EQUAL([RptqQueryTable queryAliasForSchemaTableName:@"Invoice" dropIndex:12], @"Invoice12", "the alias appends a two-digit drop index");
	// Dots in the schema-table name are stripped from the generated alias.
	MAD_PASS_EQUAL([RptqQueryTable queryAliasForSchemaTableName:@"schema.table" dropIndex:2], @"schematable2", "dots are stripped from the alias");
}

#pragma mark - Query group key path

static void testQueryGroupKeyPathHasField(void) {
	MAD_PASS_EQUAL([RptqQueryGroup keyPathHasField], @"hasField", "the has-field key path");
}

#pragma mark - Query table equality (MTProtocolCompare)

// RptqQueryTable conforms to MTProtocolCompare, but its -isEqualTo: is degenerate: the
// first clause is the tautology [sender isEqual:sender], so any non-nil argument
// compares equal, and the fallback branch compares two nil NSNumbers.  Documented in
// docs/project/BUGS.md; no production caller reaches it today.
static void testQueryTableIsEqualToIsDegenerate(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqQueryTable *first = (RptqQueryTable *)[context insertObjectForEntity:@"RptqQueryTable" identifier:1];
	RptqQueryTable *second = (RptqQueryTable *)[context insertObjectForEntity:@"RptqQueryTable" identifier:2];

	MAD_PASS([first isEqualTo:second], "any non-nil argument compares equal (pinned defect)");
	MAD_PASS(![first isEqualTo:nil], "nil does not compare equal");
}

MAD_TEST_MAIN("MADRptqQueryTests",
	MAD_TEST(testQueryLinksReuseIdForLinkType),
	MAD_TEST(testQueryLinksLocalizedNameForLinkType),
	MAD_TEST(testQueryLinksSqlForLinkType),
	MAD_TEST(testPredicateSymbolForComparson),
	MAD_TEST(testPredicateSymbolForDisplay),
	MAD_TEST(testQueryFieldKeyConstants),
	MAD_TEST(testQueryTableKeyConstants),
	MAD_TEST(testQueryTableAliasForSchemaTableName),
	MAD_TEST(testQueryGroupKeyPathHasField),
	MAD_TEST(testQueryTableIsEqualToIsDegenerate));
