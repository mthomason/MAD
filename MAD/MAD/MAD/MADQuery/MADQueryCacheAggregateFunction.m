//
//  MADQueryCacheAggregateFunction.m
//  MAD
//
//  Created by Michael Thomason on 6/1/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryCacheAggregateFunction.h"
#import <Foundation/NSException.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>
#import <MAD/MADQueryCacheAggregateFunctionParamaters.h>
#import <MADSqlite3/MADQuery+Sqlite3.h>
#import <MADAPI/MADQueryType.h>

static inline const char *functionName(MTAggregateFunctionType);
static inline const char *functionName(MTAggregateFunctionType functionType) {
	switch (functionType) {
		case MTAggregateFunctionTypeCount:
			return "COUNT";
		case MTAggregateFunctionTypeFirst:
			return "FIRST";
		case MTAggregateFunctionTypeLast:
			return "LAST";
		case MTAggregateFunctionTypeMax:
			return "MAX";
		case MTAggregateFunctionTypeMean:
			return "AVG";
		case MTAggregateFunctionTypeMin:
			return "MIN";
		case MTAggregateFunctionTypeSum:
			return "SUM";
		default:
			return "SUM";
	}
}

@interface MADQueryCacheAggregateFunction ()

	@property (nonatomic, strong) NSString *tableName;
	@property (nonatomic, strong) NSString *columnKey;
	@property (nonatomic, strong) NSArray *predicateParamters;
	@property (nonatomic, strong) NSArray *rowids;
	@property (nonatomic, assign) MTAggregateGroupByType groupByType;
	@property (nonatomic, assign) MTAggregateFunctionType functionType;

@end

@implementation MADQueryCacheAggregateFunction

@synthesize binaryBindings = _binaryBindings;
@synthesize columns = _columns;

- (instancetype)initWithObject:(id)object {

	if (self = [super initWithObject:object]) {
		
		NSMutableArray *binaryBindings = [[NSMutableArray alloc] init];
		self.binaryBindings = binaryBindings;
		
		NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));

		NSDictionary *obj = object;

		NSNumber *keyRowIds = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateRowids];
		NSArray *rowids = [[obj objectForKey:keyRowIds] copy];
		self.rowids = rowids;

		NSNumber *keyFieldDescriptors = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldDescriptors];
		NSDictionary *columns = [[obj objectForKey:keyFieldDescriptors] copy];
		self.columns = columns;

		NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateTableName];
		NSString *tableName = [[obj objectForKey:keyTableName] copy];
		self.tableName = tableName;

		NSNumber *keyGroupByType = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateGroupByType];
		NSNumber *groupByType = [[obj objectForKey:keyGroupByType] copy];
		self.groupByType = groupByType.shortValue;
		
		NSNumber *keyAggregateFunctionType = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateAggregateFunctionType];
		NSNumber *functionType = [[obj objectForKey:keyAggregateFunctionType] copy];
		self.functionType = functionType.shortValue;
		
		NSNumber *keyParametersFieldKey = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldKey];
		NSString *columnKey = [[obj objectForKey: keyParametersFieldKey] copy];
		self.columnKey = columnKey;
		
		NSNumber *keyWhere = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregatePredicates];
		NSArray *predicateParamters = [[obj objectForKey:keyWhere] copy];
		self.predicateParamters = predicateParamters;
		
	}
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT %s(%@) FROM %@", functionName(self.functionType), self.columnKey, self.tableName];
	NSString *whereClause = (self.groupByType == MTAggregateGroupByTypePage) ? [self whereClauseWithRowIds:self.rowids] : [self whereClauseWithParameters:self.predicateParamters];
	return [sql stringByAppendingString: whereClause];
}

- (MADQueryType)type {
	return MADQueryTypeCacheAggregateFunction;
}

@end
