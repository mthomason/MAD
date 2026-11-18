//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQueryCacheAggregateFunctionTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQueryCacheAggregateFunctionTests.m: the SQL
//  generator the cache uses to answer SUM/AVG/... requests, and the aggregate
//  enum string mappers.  The generator has two WHERE strategies: a page-scoped
//  aggregate filters by rowid, everything else filters by the predicate
//  bindings.  Both are pinned here, with the function-name mapping and the
//  binary bindings the parameters produce.
//

#import "MADTestSupport.h"

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADAPI/MADQueryType.h>
#import <MADAPI/MADDatabaseDataBinding.h>

#import <MAD/MADQuery+Extras.h>
#import <MAD/MADQueryCacheAggregateFunction.h>
#import <MAD/MADQueryCacheAggregateFunctionParamaters.h>
#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>
#import <MAD/MADAggregateFunctionInputType.h>

#pragma mark - Fixture

static NSDictionary *parametersWithGroupBy(MTAggregateGroupByType groupBy,
										   MTAggregateFunctionType function,
										   NSArray *predicates,
										   NSArray *rowids) {
	MADDataColumn *groupColumn = [MADDataColumn newDataColumnWithIdentifier:@"grp"];
	groupColumn.type = MADDataTypeString;

	return @{
		@(MADParametersQueryCacheAggregateTableName): @"main.tbl",
		@(MADParametersQueryCacheAggregateGroupByType): @(groupBy),
		@(MADParametersQueryCacheAggregateAggregateFunctionType): @(function),
		@(MADParametersQueryCacheAggregateFieldKey): @"main.tbl.amount",
		@(MADParametersQueryCacheAggregatePredicates): predicates ?: @[],
		@(MADParametersQueryCacheAggregateFieldDescriptors): @{ @"grp": groupColumn },
		@(MADParametersQueryCacheAggregateRowids): rowids ?: @[],
	};
}

#pragma mark - SQL generation

static void testAggregateSqlWithPredicates(void) {
	NSArray *predicates = @[ @{ @"c": @"grp", @"v": @"A" } ];
	NSDictionary *parameters = parametersWithGroupBy(MTAggregateGroupByTypeReport,
													 MTAggregateFunctionTypeSum,
													 predicates,
													 nil);
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	MAD_PASS_EQUAL([query getSql:NULL], @"SELECT SUM(main.tbl.amount) FROM main.tbl WHERE grp = ?", "the predicate-scoped aggregate SQL");
	// One data binding is produced per predicate.
	MAD_PASS(query.binaryBindings.count == (NSUInteger)1, "one binding per predicate");
	MADDatabaseDataBinding *binding = query.binaryBindings.firstObject;
	MAD_PASS_EQUAL(binding.value, @"A", "the binding carries the predicate value");
	MAD_PASS(binding.datatype == MADDataTypeString, "the binding carries the column's datatype");
	MAD_PASS(binding.fieldIndex == (NSUInteger)0, "the binding's field index is the predicate ordinal");
}

static void testAggregateSqlWithPageGroupingUsesRowIds(void) {
	NSDictionary *parameters = parametersWithGroupBy(MTAggregateGroupByTypePage,
													 MTAggregateFunctionTypeSum,
													 nil,
													 @[ @1, @2 ]);
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	MAD_PASS_EQUAL([query getSql:NULL], @"SELECT SUM(main.tbl.amount) FROM main.tbl WHERE rowid = 1 OR rowid = 2", "the page-scoped aggregate filters by rowid");
	MAD_PASS(query.binaryBindings.count == (NSUInteger)0, "a rowid filter needs no bindings");
}

static void testAggregateSqlWithPageGroupingAndNoRows(void) {
	NSDictionary *parameters = parametersWithGroupBy(MTAggregateGroupByTypePage,
													 MTAggregateFunctionTypeSum,
													 nil,
													 @[]);
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	// An empty rowid list becomes an always-false filter, not an unfiltered scan.
	MAD_PASS_EQUAL([query getSql:NULL], @"SELECT SUM(main.tbl.amount) FROM main.tbl WHERE rowid = -1 ", "an empty rowid list matches nothing");
}

static void testAggregateFunctionNameMapping(void) {
	NSDictionary<NSNumber *, NSString *> *expected = @{
		@(MTAggregateFunctionTypeCount): @"COUNT",
		@(MTAggregateFunctionTypeFirst): @"FIRST",
		@(MTAggregateFunctionTypeLast): @"LAST",
		@(MTAggregateFunctionTypeMax): @"MAX",
		@(MTAggregateFunctionTypeMean): @"AVG",
		@(MTAggregateFunctionTypeMin): @"MIN",
		@(MTAggregateFunctionTypeSum): @"SUM",
		// Unknown and unset fall through to the SUM default.
		@(MTAggregateFunctionTypeUnknown): @"SUM",
		@(MTAggregateFunctionTypeNotSet): @"SUM",
	};

	// GNUstep types the enumeration block as (id<NSCopying>, id, BOOL *), so the
	// parameters carry that signature; the values are the same NSNumber and
	// NSString the Xcode suite's block named.
	[expected enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> key, id name, __unused BOOL *stop) {
		NSDictionary *parameters = parametersWithGroupBy(MTAggregateGroupByTypePage,
														 (MTAggregateFunctionType)[(NSNumber *)key shortValue],
														 nil,
														 @[ @1 ]);
		MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];
		NSString *prefix = [[NSString alloc] initWithFormat:@"SELECT %@(", name];
		NSString *sql = [query getSql:NULL];
		MAD_PASS([sql hasPrefix:prefix], "the function maps to %s", [(NSString *)name UTF8String]);
		[prefix release];
	}];
}

static void testAggregateQueryType(void) {
	NSDictionary *parameters = parametersWithGroupBy(MTAggregateGroupByTypePage,
													 MTAggregateFunctionTypeSum,
													 nil,
													 @[ @1 ]);
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	MAD_PASS(query.type == MADQueryTypeCacheAggregateFunction, "the query type is the cache aggregate function");
	MAD_PASS(query.returnsResults, "the aggregate query returns results");
}

#pragma mark - Enum string mappers

static void testNSStringFromMADAggregateFunctionType(void) {
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeUnknown), @"MTAggregateFunctionTypeUnknown", "Unknown maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeSum), @"MTAggregateFunctionTypeSum", "Sum maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeMean), @"MTAggregateFunctionTypeMean", "Mean maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeFirst), @"MTAggregateFunctionTypeFirst", "First maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeLast), @"MTAggregateFunctionTypeLast", "Last maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeCount), @"MTAggregateFunctionTypeCount", "Count maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeMin), @"MTAggregateFunctionTypeMin", "Min maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeMax), @"MTAggregateFunctionTypeMax", "Max maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeNotSet), @"MTAggregateFunctionTypeNotSet", "NotSet maps");
	// The enum skips values; an unhandled one resolves to Unknown.
	MAD_PASS_EQUAL(NSStringFromMADAggregateFunctionType((MTAggregateFunctionType)1), @"MTAggregateFunctionTypeUnknown", "an unhandled raw value resolves to Unknown");
}

static void testNSStringFromMADAggregateGroupByType(void) {
	MAD_PASS_EQUAL(NSStringFromMADAggregateGroupByType(MTAggregateGroupByUnknown), @"MTAggregateGroupByUnknown", "Unknown maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateGroupByType(MTAggregateGroupByTypePage), @"MTAggregateGroupByTypePage", "Page maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateGroupByType(MTAggregateGroupByTypeReport), @"MTAggregateGroupByTypeReport", "Report maps");
	MAD_PASS_EQUAL(NSStringFromMADAggregateGroupByType(MTAggregateGroupByTypeSection), @"MTAggregateGroupByTypeSection", "Section maps");
}

static void testNSStringFromMADParametersQueryCacheAggregate(void) {
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateUnknown), @"MADParametersQueryCacheAggregateUnknown", "Unknown maps");
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateTableName), @"MADParametersQueryCacheAggregateTableName", "TableName maps");
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateGroupByType), @"MADParametersQueryCacheAggregateGroupByType", "GroupByType maps");
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateRowids), @"MADParametersQueryCacheAggregateRowids", "Rowids maps");
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateAggregateFunctionType), @"MADParametersQueryCacheAggregateAggregateFunctionType", "AggregateFunctionType maps");
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateFieldKey), @"MADParametersQueryCacheAggregateFieldKey", "FieldKey maps");
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregatePredicates), @"MADParametersQueryCacheAggregatePredicates", "Predicates maps");
	MAD_PASS_EQUAL(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateFieldDescriptors), @"MADParametersQueryCacheAggregateFieldDescriptors", "FieldDescriptors maps");
}

static void testAggregateFunctionInputTypeRawValues(void) {
	MAD_PASS((int)MTAggregateFunctionInputTypeField == 0, "the field input type is 0");
	MAD_PASS((int)MTAggregateFunctionInputTypeFormula == 1, "the formula input type is 1");
}

MAD_TEST_MAIN("MADQueryCacheAggregateFunctionTests",
	MAD_TEST(testAggregateSqlWithPredicates),
	MAD_TEST(testAggregateSqlWithPageGroupingUsesRowIds),
	MAD_TEST(testAggregateSqlWithPageGroupingAndNoRows),
	MAD_TEST(testAggregateFunctionNameMapping),
	MAD_TEST(testAggregateQueryType),
	MAD_TEST(testNSStringFromMADAggregateFunctionType),
	MAD_TEST(testNSStringFromMADAggregateGroupByType),
	MAD_TEST(testNSStringFromMADParametersQueryCacheAggregate),
	MAD_TEST(testAggregateFunctionInputTypeRawValues));
