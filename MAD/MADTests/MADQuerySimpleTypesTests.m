//
//  MADQuerySimpleTypesTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 1 coverage for the self-contained MADQuery subclasses: the ones whose SQL is
//  a constant or a small template, with no store or database dependency.  Also pins the
//  MADQuery (Extras) factory that maps a MADQueryType to its concrete class.
//
//    * MADQueryCustomNoResults      -- a query that never returns rows.
//    * MADQueryCacheJournalModeDefault -- the PRAGMA that resets the cache journal mode.
//    * MADQueryCacheIndexCreateTemplate -- the parameterised CREATE INDEX template.
//    * MADReportFormatterState / MADReportFormatterCache -- the formatter's counters
//      and its size-keyed layout cache.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADQueryType.h>

#import "MADQuery+Extras.h"
#import "MADQueryCustomNoResults.h"
#import "MADQueryCacheJournalModeDefault.h"
#import "MADQueryCacheIndexCreateTemplate.h"
#import "MADCacheIndexType.h"
#import "MADReportFormatterState.h"

// -parameterCount is implemented on the class but declared in no header (and has no
// caller anywhere in the tree); this test-only category is the deliberate bridge.
@interface MADQueryCacheIndexCreateTemplate (TestParameterCount)
- (NSUInteger)parameterCount;
@end

@interface MADQuerySimpleTypesTests : XCTestCase
@end

@implementation MADQuerySimpleTypesTests

#pragma mark - MADQueryCustomNoResults

- (void)testCustomNoResultsDefaults {
	MADQueryCustomNoResults *query = [[MADQueryCustomNoResults alloc] initWithObject:@"DELETE FROM cache;"];

	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual(query.type, MADQueryTypeCustomSql);
	// The base class emits no SQL of its own; this type exists only to run as a
	// statement, never to produce rows.
	XCTAssertEqualObjects([query getSql:NULL], @"");
}

#pragma mark - MADQueryCacheJournalModeDefault

- (void)testJournalModeDefault {
	MADQueryCacheJournalModeDefault *query = [[MADQueryCacheJournalModeDefault alloc] initWithObject:nil];

	XCTAssertEqualObjects([query getSql:NULL], @"PRAGMA journal_mode=DELETE;");
	XCTAssertFalse(query.returnsResults);
	XCTAssertFalse(query.partOfTransactionSet);
	XCTAssertEqual(query.type, MADQueryTypeCacheJournalModeDefault);
}

#pragma mark - MADQueryCacheIndexCreateTemplate

- (void)testIndexCreateTemplateWithGroupCount {
	NSDictionary *parameters = @{ @(MADCacheIndexTypeGroupCount): @2 };
	MADQueryCacheIndexCreateTemplate *query = [[MADQueryCacheIndexCreateTemplate alloc] initWithObject:parameters];

	NSString *expected = @"CREATE INDEX IF NOT EXISTS main.? ON ? (? ?, ? ? )";
	XCTAssertEqualObjects([query getSql:NULL], expected);
	// Two placeholders per group (value and sort direction), plus index name and table.
	XCTAssertEqual(query.parameterCount, (NSUInteger)6);
	XCTAssertFalse(query.returnsResults);
	XCTAssertEqual(query.type, MADQueryTypeCacheIndexCreateTemplate);
}

- (void)testIndexCreateTemplateWithZeroGroupCount {
	NSDictionary *parameters = @{ @(MADCacheIndexTypeGroupCount): @0 };
	MADQueryCacheIndexCreateTemplate *query = [[MADQueryCacheIndexCreateTemplate alloc] initWithObject:parameters];

	// With no groups there is no statement to prepare; the template returns nil.
	XCTAssertNil([query getSql:NULL]);
	XCTAssertEqual(query.parameterCount, (NSUInteger)2);
}

- (void)testIndexCreateTemplateWithMissingGroupCountTreatedAsZero {
	MADQueryCacheIndexCreateTemplate *query = [[MADQueryCacheIndexCreateTemplate alloc] initWithObject:@{}];

	XCTAssertNil([query getSql:NULL]);
	XCTAssertEqual(query.parameterCount, (NSUInteger)2);
}

#pragma mark - MADQuery (Extras) factory

- (void)testFactoryMapsTypesToConcreteClasses {
	MADQuery *journal = [[MADQuery alloc] initWithQueryType:MADQueryTypeCacheJournalModeDefault object:nil];
	XCTAssertEqualObjects(NSStringFromClass([journal class]), @"MADQueryCacheJournalModeDefault");

	MADQuery *custom = [[MADQuery alloc] initWithQueryType:MADQueryTypeCustomSql object:@"SELECT 1;"];
	XCTAssertEqualObjects(NSStringFromClass([custom class]), @"MADQueryCustomNoResults");
}

#pragma mark - MADReportFormatterState

- (void)testFormatterStateInitResetsCounters {
	MADReportFormatterState *state = [[MADReportFormatterState alloc] init];

	XCTAssertEqual(state.detailRowId, (NSUInteger)0);
	XCTAssertEqual(state.detailRowIdLast, (NSUInteger)0);
	XCTAssertEqual(state.groupCounter, (NSUInteger)0);
	XCTAssertEqual(state.pageCounter, (NSUInteger)0);
	XCTAssertEqual(state.rowCounter, (NSUInteger)0);
	XCTAssertEqual(state.cumulativePageHeight, 0.0);
}

- (void)testFormatterStateResetClearsEverything {
	MADReportFormatterState *state = [[MADReportFormatterState alloc] init];
	state.detailRowId = 11;
	state.detailRowIdLast = 12;
	state.groupCounter = 3;
	state.pageCounter = 4;
	state.rowCounter = 55;
	state.cumulativePageHeight = 792.5;

	[state reset];

	XCTAssertEqual(state.detailRowId, (NSUInteger)0);
	XCTAssertEqual(state.detailRowIdLast, (NSUInteger)0);
	XCTAssertEqual(state.groupCounter, (NSUInteger)0);
	XCTAssertEqual(state.pageCounter, (NSUInteger)0);
	XCTAssertEqual(state.rowCounter, (NSUInteger)0);
	XCTAssertEqual(state.cumulativePageHeight, 0.0);
}

#pragma mark - MADReportFormatterCache

// MADReportFormatterCache is not tested here: its implementation file is in the MAD
// project group but in no target's Sources build phase, so it is never compiled and
// has no callers.  See BUGS.md.

@end
