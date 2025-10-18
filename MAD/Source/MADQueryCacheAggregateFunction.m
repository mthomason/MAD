//
//  MADQueryCacheAggregateFunction.m
//  MAD
//
//  Created by Michael Thomason on 6/1/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryCacheAggregateFunction.h"
#import "madlog.h"

#import <MADAPI/MADQueryType.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>
#import <MAD/MADQueryCacheAggregateFunctionParamaters.h>
#import <MADSqlite3/MADQuery+Sqlite3.h>

#import <Foundation/NSException.h>
#import <Foundation/NSError.h>

static inline NSString *NSStringForAggregateFunctionType(MTAggregateFunctionType);
static inline NSString *NSStringForAggregateFunctionType(MTAggregateFunctionType functionType) {
	switch (functionType) {
		case MTAggregateFunctionTypeCount:
			return @"COUNT";
		case MTAggregateFunctionTypeFirst:
			return @"FIRST";
		case MTAggregateFunctionTypeLast:
			return @"LAST";
		case MTAggregateFunctionTypeMax:
			return @"MAX";
		case MTAggregateFunctionTypeMean:
			return @"AVG";
		case MTAggregateFunctionTypeMin:
			return @"MIN";
		case MTAggregateFunctionTypeSum:
			return @"SUM";
		default:
			return @"SUM";
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
		self.rowids = [[obj objectForKey:keyRowIds] copy];
		
		NSNumber *keyFieldDescriptors = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldDescriptors];
		self.columns = [[obj objectForKey:keyFieldDescriptors] copy];

		NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateTableName];
		self.tableName = [[obj objectForKey:keyTableName] copy];

		NSNumber *keyGroupByType = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateGroupByType];
		NSNumber *groupByType = [[obj objectForKey:keyGroupByType] copy];
		self.groupByType = groupByType.shortValue;
		
		NSNumber *keyAggregateFunctionType = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateAggregateFunctionType];
		NSNumber *functionType = [[obj objectForKey:keyAggregateFunctionType] copy];
		self.functionType = functionType.shortValue;
		
		NSNumber *keyParametersFieldKey = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldKey];
		NSString *columnKey = [[obj objectForKey: keyParametersFieldKey] copy];
		self.columnKey = columnKey;
		
		NSArray *predicateParamters = [[obj objectForKey:@(MADParametersQueryCacheAggregatePredicates)] copy];
		self.predicateParamters = predicateParamters;
	}
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	NSMutableString *sql = [[NSMutableString alloc] initWithString:@"SELECT "];
	[sql appendString:NSStringForAggregateFunctionType(self.functionType)];
	[sql appendString:@"("];
	[sql appendString:self.columnKey];
	[sql appendString:@")"];
	[sql appendString:@" FROM "];
	[sql appendString:self.tableName];
	
	NSString *whereClause = (self.groupByType == MTAggregateGroupByTypePage) ?
		[self whereClauseWithRowIds:self.rowids] :
		[self whereClauseWithParameters:self.predicateParamters];
	if (whereClause != nil) {
		[sql appendString:whereClause];
	} else {
		if (error != nil) {
			*error = [NSError errorWithDomain:NSStringFromClass([self class])
										 code:0
									 userInfo:@{NSLocalizedDescriptionKey: @"No where clause."}];
		}
	}
	return sql;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>, %@, %@, %@, %@, %@, %@",
			NSStringFromClass([self class]),
			self,
			self.rowids,
			self.columns,
			self.tableName,
			@(self.groupByType),
			@(self.functionType),
			self.columnKey];
}

- (NSString *)debugDescription {
	NSString *sql = [[self getSql:nil] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	return [NSString stringWithFormat:@"<%@: %p>, %@, %@, %@, %@, %@, %@, %@",
			NSStringFromClass([self class]),
			self,
			self.rowids,
			self.columns,
			self.tableName,
			@(self.groupByType),
			@(self.functionType),
			self.columnKey,
			sql];
}

- (MADQueryType)type { return MADQueryTypeCacheAggregateFunction; }

@end
