//
//  MADParameters+QueryCacheAggregate.m
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADParameters+QueryCacheAggregate.h"
#import "MADQueryCacheAggregateFunctionParamaters.h"

#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

@implementation NSDictionary (QueryCacheAggregate)

+ (instancetype)newParamatersAggregateWithFieldKey:(NSString *)fieldKey
                                   andFunctionType:(MTAggregateFunctionType)functionType
                                      andDataTable:(MTDataTableFast *)dataTable
                                       groupByType:(MTAggregateGroupByType)groupByType
                                            rowIDs:(NSArray *)rowIDs
                                predicateParamters:(NSArray *)predicateParamters {
    
    id keyTableName, keyFieldKey, keyFunctionType, keyFieldDescriptors,
       keyGroupByType, keyRowIDs, keyPredicate;

    // Parameter keys
    keyTableName =          [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateTableName];
    keyFieldKey =           [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldKey];
    keyFunctionType =       [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateAggregateFunctionType];
    keyFieldDescriptors =   [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldDescriptors];
    keyGroupByType =        [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateGroupByType];
    keyRowIDs =             [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateRowids];
    keyPredicate =          [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregatePredicates];
    
    // Values
    NSNumber *objFunctionType =         [[NSNumber alloc] initWithShort: functionType];
    NSString *tableName =               [dataTable tableName].copy,
             *fieldKeyCopy =            fieldKey.copy;
    MADMutableMapDataColumns *columns = dataTable.columns;
    NSNumber *groupType =               [[NSNumber alloc] initWithShort:groupByType];

    //Group by type page must have rowIDs.
    NSAssert(!(groupByType == MTAggregateGroupByTypePage && rowIDs == nil),
             @"Logic error.");
    if (rowIDs == nil) rowIDs = [[NSArray alloc] init];
    
    //Group by type page must have rowIDs.
    NSAssert(!(groupByType == MTAggregateGroupByTypeSection && predicateParamters == nil),
             @"Logic error.");
    if (predicateParamters == nil) predicateParamters = [[NSArray alloc] init];

    NSDictionary *paramaters;
    paramaters = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        predicateParamters, keyPredicate,
                                        rowIDs,             keyRowIDs,
                                        groupType,          keyGroupByType,
                                        tableName,          keyTableName,
                                        fieldKeyCopy,       keyFieldKey,
                                        columns,            keyFieldDescriptors,
                                        objFunctionType,    keyFunctionType, nil];

    return paramaters;
}

+ (instancetype)newParamatersAggregateByPageWithFieldKey:(NSString *)fieldKey
                                               andRowIds:(NSArray *)rowids
                                         andFunctionType:(MTAggregateFunctionType)functionType
                                            andDataTable:(MTDataTableFast *)dataTable {
    
    id parameters;
    parameters = [self newParamatersAggregateWithFieldKey: fieldKey
                                          andFunctionType: functionType
                                             andDataTable: dataTable
                                              groupByType: MTAggregateGroupByTypePage
                                                   rowIDs: rowids
                                       predicateParamters: nil];
    
    return parameters;
}

+ (instancetype)newParamatersAggregateByGroupKeys:(NSArray *)groupKeys
                                      andFieldKey:(NSString *)fieldKey
                                  andFunctionType:(MTAggregateFunctionType)functionType
                                     andDataTable:(MTDataTableFast *)dataTable {
    
    NSArray *predicateParamters = [dataTable whereClauseForGroupKeys:groupKeys].copy;
    
    id parameters;
    parameters = [self newParamatersAggregateWithFieldKey: fieldKey
                                          andFunctionType: functionType
                                             andDataTable: dataTable
                                              groupByType: MTAggregateGroupByTypeSection
                                                   rowIDs: nil
                                       predicateParamters: predicateParamters];
    
    return parameters;

}

+ (instancetype)newParametersAggregateByReportWithFieldKey:(NSString *)fieldKey
                                           andFunctionType:(MTAggregateFunctionType)functionType
                                              andDataTable:(MTDataTableFast *)dataTable {
    
    NSDictionary *paramaters;
    paramaters = [self newParamatersAggregateWithFieldKey: fieldKey
                                          andFunctionType: functionType
                                             andDataTable: dataTable
                                              groupByType: MTAggregateGroupByTypeReport
                                                   rowIDs: nil
                                       predicateParamters: nil];

    return paramaters;

}

@end
