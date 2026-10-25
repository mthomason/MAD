//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQuerySimpleTypesTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQuerySimpleTypesTests.m: the self-contained
//  MADQuery subclasses -- those whose SQL is a constant or a small template,
//  with no store or database dependency -- plus the MADQuery (Extras) factory
//  and the formatter's counters.
//

#import "MADTestSupport.h"

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADQueryType.h>

#import <MAD/MADQuery+Extras.h>
#import <MAD/MADQueryCustomNoResults.h>
#import <MAD/MADQueryCacheJournalModeDefault.h>
#import <MAD/MADQueryCacheIndexCreateTemplate.h>
#import <MAD/MADCacheIndexType.h>
#import <MAD/MADReportFormatterState.h>

// -parameterCount is implemented on the class but declared in no header (and has no
// caller anywhere in the tree); this test-only category is the deliberate bridge.
@interface MADQueryCacheIndexCreateTemplate (TestParameterCount)
- (NSUInteger)parameterCount;
@end

#pragma mark - MADQueryCustomNoResults

static void testCustomNoResultsDefaults(void) {
	MADQueryCustomNoResults *query = [[MADQueryCustomNoResults alloc] initWithObject:@"DELETE FROM cache;"];

	MAD_PASS(!query.returnsResults, "a no-results query returns no rows");
	MAD_PASS(query.type == MADQueryTypeCustomSql, "the type is custom SQL");
	// The base class emits no SQL of its own; this type exists only to run as a
	// statement, never to produce rows.
	MAD_PASS_EQUAL([query getSql:NULL], @"", "the base class emits no SQL of its own");

	[query release];
}

#pragma mark - MADQueryCacheJournalModeDefault

static void testJournalModeDefault(void) {
	MADQueryCacheJournalModeDefault *query = [[MADQueryCacheJournalModeDefault alloc] initWithObject:nil];

	MAD_PASS_EQUAL([query getSql:NULL], @"PRAGMA journal_mode=DELETE;", "the journal-mode PRAGMA");
	MAD_PASS(!query.returnsResults, "the PRAGMA returns no rows");
	MAD_PASS(!query.partOfTransactionSet, "the PRAGMA is not part of a transaction set");
	MAD_PASS(query.type == MADQueryTypeCacheJournalModeDefault, "the type is the journal-mode default");

	[query release];
}

#pragma mark - MADQueryCacheIndexCreateTemplate

static void testIndexCreateTemplateWithGroupCount(void) {
	NSDictionary *parameters = @{ @(MADCacheIndexTypeGroupCount): @2 };
	MADQueryCacheIndexCreateTemplate *query = [[MADQueryCacheIndexCreateTemplate alloc] initWithObject:parameters];

	NSString *expected = @"CREATE INDEX IF NOT EXISTS main.? ON ? (? ?, ? ? )";
	MAD_PASS_EQUAL([query getSql:NULL], expected, "the two-group index template");
	// Two placeholders per group (value and sort direction), plus index name and table.
	MAD_PASS(query.parameterCount == (NSUInteger)6, "six parameters for two groups");
	MAD_PASS(!query.returnsResults, "the template returns no rows");
	MAD_PASS(query.type == MADQueryTypeCacheIndexCreateTemplate, "the type is the index-create template");

	[query release];
}

static void testIndexCreateTemplateWithZeroGroupCount(void) {
	NSDictionary *parameters = @{ @(MADCacheIndexTypeGroupCount): @0 };
	MADQueryCacheIndexCreateTemplate *query = [[MADQueryCacheIndexCreateTemplate alloc] initWithObject:parameters];

	// With no groups there is no statement to prepare; the template returns nil.
	MAD_PASS([query getSql:NULL] == nil, "no groups means no statement");
	MAD_PASS(query.parameterCount == (NSUInteger)2, "two parameters without groups");

	[query release];
}

static void testIndexCreateTemplateWithMissingGroupCountTreatedAsZero(void) {
	MADQueryCacheIndexCreateTemplate *query = [[MADQueryCacheIndexCreateTemplate alloc] initWithObject:@{}];

	MAD_PASS([query getSql:NULL] == nil, "a missing group count behaves as zero");
	MAD_PASS(query.parameterCount == (NSUInteger)2, "two parameters without a group count");

	[query release];
}

#pragma mark - MADQuery (Extras) factory

static void testFactoryMapsTypesToConcreteClasses(void) {
	MADQuery *journal = [[MADQuery alloc] initWithQueryType:MADQueryTypeCacheJournalModeDefault object:nil];
	MAD_PASS_EQUAL(NSStringFromClass([journal class]), @"MADQueryCacheJournalModeDefault", "the journal-mode type maps to its class");

	MADQuery *custom = [[MADQuery alloc] initWithQueryType:MADQueryTypeCustomSql object:@"SELECT 1;"];
	MAD_PASS_EQUAL(NSStringFromClass([custom class]), @"MADQueryCustomNoResults", "the custom-SQL type maps to its class");

	[journal release];
	[custom release];
}

#pragma mark - MADReportFormatterState

static void testFormatterStateInitResetsCounters(void) {
	MADReportFormatterState *state = [[MADReportFormatterState alloc] init];

	MAD_PASS(state.detailRowId == (NSUInteger)0, "the detail row starts at 0");
	MAD_PASS(state.detailRowIdLast == (NSUInteger)0, "the last detail row starts at 0");
	MAD_PASS(state.groupCounter == (NSUInteger)0, "the group counter starts at 0");
	MAD_PASS(state.pageCounter == (NSUInteger)0, "the page counter starts at 0");
	MAD_PASS(state.rowCounter == (NSUInteger)0, "the row counter starts at 0");
	MAD_PASS(state.cumulativePageHeight == 0.0, "the cumulative height starts at 0");

	[state release];
}

static void testFormatterStateResetClearsEverything(void) {
	MADReportFormatterState *state = [[MADReportFormatterState alloc] init];
	state.detailRowId = 11;
	state.detailRowIdLast = 12;
	state.groupCounter = 3;
	state.pageCounter = 4;
	state.rowCounter = 55;
	state.cumulativePageHeight = 792.5;

	[state reset];

	MAD_PASS(state.detailRowId == (NSUInteger)0, "reset clears the detail row");
	MAD_PASS(state.detailRowIdLast == (NSUInteger)0, "reset clears the last detail row");
	MAD_PASS(state.groupCounter == (NSUInteger)0, "reset clears the group counter");
	MAD_PASS(state.pageCounter == (NSUInteger)0, "reset clears the page counter");
	MAD_PASS(state.rowCounter == (NSUInteger)0, "reset clears the row counter");
	MAD_PASS(state.cumulativePageHeight == 0.0, "reset clears the cumulative height");

	[state release];
}

// MADReportFormatterCache is not tested here: its implementation file is in the MAD
// project group but in no target's Sources build phase, so it is never compiled and
// has no callers.  See BUGS.md.

MAD_TEST_MAIN("MADQuerySimpleTypesTests",
	MAD_TEST(testCustomNoResultsDefaults),
	MAD_TEST(testJournalModeDefault),
	MAD_TEST(testIndexCreateTemplateWithGroupCount),
	MAD_TEST(testIndexCreateTemplateWithZeroGroupCount),
	MAD_TEST(testIndexCreateTemplateWithMissingGroupCountTreatedAsZero),
	MAD_TEST(testFactoryMapsTypesToConcreteClasses),
	MAD_TEST(testFormatterStateInitResetsCounters),
	MAD_TEST(testFormatterStateResetClearsEverything));
