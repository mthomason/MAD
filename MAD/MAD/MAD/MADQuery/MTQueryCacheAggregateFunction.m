//
//  MTQueryCacheAggregateFunction.m
//  MAD
//
//  Created by Michael Thomason on 6/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheAggregateFunction.h"
#import <Foundation/NSException.h>
#import <RptqDocumentElementAggregate+Extras.h>
#import <MADQueryCacheAggregateFunctionParamaters.h>

static inline const char *functionName(MTAggregateFunctionType functionType);
static inline const char *functionName(MTAggregateFunctionType functionType) {
    
    const char *result;
    switch (functionType) {
            
        case MTAggregateFunctionTypeCount:
            result = "COUNT";
            break;
            
        case MTAggregateFunctionTypeFirst:
            result = "FIRST";
            break;
            
        case MTAggregateFunctionTypeLast:
            result = "LAST";
            break;
            
        case MTAggregateFunctionTypeMax:
            result = "MAX";
            break;
            
        case MTAggregateFunctionTypeMean:
            result = "AVG";
            break;
            
        case MTAggregateFunctionTypeMin:
            result = "MIN";
            break;
            
        case MTAggregateFunctionTypeSum:
            result = "SUM";
            break;
            
        default:
            result = "SUM";
            break;
            
    }
    return result;
}

@interface MTQueryCacheAggregateFunction ()

    @property (nonatomic, strong) NSString *tableName;
    @property (nonatomic, strong) NSString *columnKey;
    @property (nonatomic, strong) NSArray *predicateParamters;
    @property (nonatomic, strong) NSArray *rowids;
    @property (nonatomic, assign) MTAggregateGroupByType groupByType;
    @property (nonatomic, assign) MTAggregateFunctionType functionType;

@end

@implementation MTQueryCacheAggregateFunction

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *keyRowIds = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateRowids];
        NSArray *rowids = object[keyRowIds];
        self.rowids = rowids;
       
        NSNumber *keyFieldDescriptors = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldDescriptors];
        self.columns = object[keyFieldDescriptors];
        
        NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateTableName];
        self.tableName = object[keyTableName];
        
        NSNumber *keyGroupByType = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateGroupByType];
        self.groupByType = ((NSNumber *)object[keyGroupByType]).shortValue;
        
        NSNumber *keyAggregateFunctionType = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateAggregateFunctionType];
        self.functionType = ((NSNumber *)object[keyAggregateFunctionType]).shortValue;
        
        NSNumber *keyParametersFieldKey = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldKey];
        NSString *columnKey = object[keyParametersFieldKey];
        self.columnKey = columnKey;
        
        NSNumber *keyWhere = [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregatePredicates];
        self.predicateParamters = object[keyWhere];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT %s(%@) FROM %@",
                            functionName(self.functionType), self.columnKey, self.tableName];
    NSString *whereClause;
    if (self.groupByType == MTAggregateGroupByTypePage) {
        whereClause = [self whereClauseWithRowIds:self.rowids];
    } else {
        whereClause = [self whereClauseWithParameters:self.predicateParamters];
    }
    [sql appendString: whereClause];
    return sql;
}

- (MADQueryType)type {
    return MADQueryTypeCacheAggregateFunction;
}

@end
