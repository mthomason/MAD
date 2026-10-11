//
//  MADQueryCacheAggregateFunctionTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 3 coverage for MADQueryCacheAggregateFunction -- the SQL generator the cache
//  uses to answer SUM/AVG/... requests -- and for the aggregate enum string mappers.
//
//  The generator has two WHERE strategies: a page-scoped aggregate filters by rowid,
//  everything else filters by the predicate bindings.  Both are pinned here, along
//  with the function-name mapping and the binary bindings the parameters produce.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADAPI/MADQueryType.h>
#import <MADAPI/MADDatabaseDataBinding.h>

#import "MADQuery+Extras.h"
#import "MADQueryCacheAggregateFunction.h"
#import "MADQueryCacheAggregateFunctionParamaters.h"
#import "MADAggregateFunctionType.h"
#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionInputType.h"

@interface MADQueryCacheAggregateFunctionTests : XCTestCase
@end

@implementation MADQueryCacheAggregateFunctionTests

#pragma mark - Fixture

- (NSDictionary *)parametersWithGroupBy:(MTAggregateGroupByType)groupBy
							   function:(MTAggregateFunctionType)function
							  predicates:(NSArray *)predicates
								  rowids:(NSArray *)rowids {
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

- (void)testAggregateSqlWithPredicates {
	NSArray *predicates = @[ @{ @"c": @"grp", @"v": @"A" } ];
	NSDictionary *parameters = [self parametersWithGroupBy:MTAggregateGroupByTypeReport
												  function:MTAggregateFunctionTypeSum
												predicates:predicates
													rowids:nil];
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	XCTAssertEqualObjects([query getSql:NULL], @"SELECT SUM(main.tbl.amount) FROM main.tbl WHERE grp = ?");
	// One data binding is produced per predicate.
	XCTAssertEqual(query.binaryBindings.count, (NSUInteger)1);
	MADDatabaseDataBinding *binding = query.binaryBindings.firstObject;
	XCTAssertEqualObjects(binding.value, @"A");
	XCTAssertEqual(binding.datatype, MADDataTypeString);
	XCTAssertEqual(binding.fieldIndex, (NSUInteger)0);
}

- (void)testAggregateSqlWithPageGroupingUsesRowIds {
	NSDictionary *parameters = [self parametersWithGroupBy:MTAggregateGroupByTypePage
												  function:MTAggregateFunctionTypeSum
												predicates:nil
													rowids:@[ @1, @2 ]];
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	XCTAssertEqualObjects([query getSql:NULL], @"SELECT SUM(main.tbl.amount) FROM main.tbl WHERE rowid = 1 OR rowid = 2");
	XCTAssertEqual(query.binaryBindings.count, (NSUInteger)0);
}

- (void)testAggregateSqlWithPageGroupingAndNoRows {
	NSDictionary *parameters = [self parametersWithGroupBy:MTAggregateGroupByTypePage
												  function:MTAggregateFunctionTypeSum
												predicates:nil
													rowids:@[]];
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	// An empty rowid list becomes an always-false filter, not an unfiltered scan.
	XCTAssertEqualObjects([query getSql:NULL], @"SELECT SUM(main.tbl.amount) FROM main.tbl WHERE rowid = -1 ");
}

- (void)testAggregateFunctionNameMapping {
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

	[expected enumerateKeysAndObjectsUsingBlock:^(NSNumber *type, NSString *name, BOOL *stop) {
		NSDictionary *parameters = [self parametersWithGroupBy:MTAggregateGroupByTypePage
													  function:(MTAggregateFunctionType)type.shortValue
													predicates:nil
														rowids:@[ @1 ]];
		MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];
		NSString *prefix = [[NSString alloc] initWithFormat:@"SELECT %@(", name];
		XCTAssertTrue([[query getSql:NULL] hasPrefix:prefix], @"%@ should map to %@", type, name);
	}];
}

- (void)testAggregateQueryType {
	NSDictionary *parameters = [self parametersWithGroupBy:MTAggregateGroupByTypePage
												  function:MTAggregateFunctionTypeSum
												predicates:nil
													rowids:@[ @1 ]];
	MADQueryCacheAggregateFunction *query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];

	XCTAssertEqual(query.type, MADQueryTypeCacheAggregateFunction);
	XCTAssertTrue(query.returnsResults);
}

#pragma mark - Enum string mappers

- (void)testNSStringFromMADAggregateFunctionType {
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeUnknown), @"MTAggregateFunctionTypeUnknown");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeSum), @"MTAggregateFunctionTypeSum");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeMean), @"MTAggregateFunctionTypeMean");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeFirst), @"MTAggregateFunctionTypeFirst");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeLast), @"MTAggregateFunctionTypeLast");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeCount), @"MTAggregateFunctionTypeCount");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeMin), @"MTAggregateFunctionTypeMin");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeMax), @"MTAggregateFunctionTypeMax");
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType(MTAggregateFunctionTypeNotSet), @"MTAggregateFunctionTypeNotSet");
	// The enum skips values; an unhandled one resolves to Unknown.
	XCTAssertEqualObjects(NSStringFromMADAggregateFunctionType((MTAggregateFunctionType)1), @"MTAggregateFunctionTypeUnknown");
}

- (void)testNSStringFromMADAggregateGroupByType {
	XCTAssertEqualObjects(NSStringFromMADAggregateGroupByType(MTAggregateGroupByUnknown), @"MTAggregateGroupByUnknown");
	XCTAssertEqualObjects(NSStringFromMADAggregateGroupByType(MTAggregateGroupByTypePage), @"MTAggregateGroupByTypePage");
	XCTAssertEqualObjects(NSStringFromMADAggregateGroupByType(MTAggregateGroupByTypeReport), @"MTAggregateGroupByTypeReport");
	XCTAssertEqualObjects(NSStringFromMADAggregateGroupByType(MTAggregateGroupByTypeSection), @"MTAggregateGroupByTypeSection");
}

- (void)testNSStringFromMADParametersQueryCacheAggregate {
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateUnknown), @"MADParametersQueryCacheAggregateUnknown");
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateTableName), @"MADParametersQueryCacheAggregateTableName");
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateGroupByType), @"MADParametersQueryCacheAggregateGroupByType");
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateRowids), @"MADParametersQueryCacheAggregateRowids");
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateAggregateFunctionType), @"MADParametersQueryCacheAggregateAggregateFunctionType");
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateFieldKey), @"MADParametersQueryCacheAggregateFieldKey");
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregatePredicates), @"MADParametersQueryCacheAggregatePredicates");
	XCTAssertEqualObjects(NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregateFieldDescriptors), @"MADParametersQueryCacheAggregateFieldDescriptors");
}

- (void)testAggregateFunctionInputTypeRawValues {
	XCTAssertEqual((int)MTAggregateFunctionInputTypeField, 0);
	XCTAssertEqual((int)MTAggregateFunctionInputTypeFormula, 1);
}

@end
