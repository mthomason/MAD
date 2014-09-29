//
//  MTQueryCacheAggregateFunction.m
//  MAD
//
//  Created by Michael Thomason on 6/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheAggregateFunction.h"
#import "MTAggregateFunctionType.h"
#import "MADAggregateGroupByType.h"

@interface MTQueryCacheAggregateFunction ()

@property (nonatomic, strong) NSString *tableName;
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, strong) NSString *columnKey;
@property (nonatomic, strong) NSArray *whereClause;
@property (nonatomic, strong) NSArray *rowids;
@property (nonatomic, assign) MTAggregateGroupByType groupByType;
@property (nonatomic, assign) MTAggregateFunctionType functionType;

@end

@implementation MTQueryCacheAggregateFunction

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
        
        NSNumber *keyRowIds = @(MTQueryCacheAggregateFunctionParamatersRowids);
        NSArray *rowids = object[keyRowIds];
        [self setRowids:rowids];
       
        NSNumber *keyFieldDescriptors = @(MTQueryCacheAggregateFunctionParamatersFieldDescriptors);
        NSDictionary *fieldDescriptors = [NSDictionary dictionaryWithDictionary:object[keyFieldDescriptors]];
        [self setColumns:fieldDescriptors];
        
        NSNumber *keyTableName = @(MTQueryCacheAggregateFunctionParamatersTableName);
        NSString *tableName = [NSString stringWithString:object[keyTableName]];
        [self setTableName:tableName];
        
        NSNumber *keyGroupByType = @(MTQueryCacheAggregateFunctionParamatersGroupByType);
        NSNumber *groupBy = object[keyGroupByType];
        [self setGroupByType:[groupBy integerValue]];
        
        NSNumber *keyAggregateFunctionType = @(MTQueryCacheAggregateFunctionParamatersAggregateFunctionType);
        NSNumber *functionType = object[keyAggregateFunctionType];
        [self setFunctionType:[functionType integerValue]];
        
        NSNumber *keyParametersFieldKey = @(MTQueryCacheAggregateFunctionParamatersFieldKey);
        NSString *columnKey = [NSString stringWithString:object[keyParametersFieldKey]];
        [self setColumnKey:columnKey];
        
        NSNumber *keyWhere = @(MTQueryCacheAggregateFunctionParamatersPredicates);
        NSArray *whereClause = [NSArray arrayWithArray:object[keyWhere]];
        [self setWhereClause:whereClause];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT %s(%@) FROM %@",
                            functionName([self functionType]), [self columnKey], [self tableName]];

    if ([self groupByType] == MTAggregateGroupByTypePage) {
        [sql appendString:[self whereClauseWithRowIds:[self rowids]]];
    } else {
        [sql appendString:[self whereClauseWithParameters:[self whereClause]]];
    }

    return sql;
}

const char *functionName(MTAggregateFunctionType functionType);
const char *functionName(MTAggregateFunctionType functionType) {
    
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

@end
