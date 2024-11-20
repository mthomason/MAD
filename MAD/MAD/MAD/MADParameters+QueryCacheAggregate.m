//
//  MADParameters+QueryCacheAggregate.m
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADParameters+QueryCacheAggregate.h"

#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

#import <MADSqlite3/MADDataTableFast.h>

#import "MADQueryCacheAggregateFunctionParamaters.h"

@implementation MADParameters

+ (instancetype)newParamatersAggregateWithFieldKey:(NSString *)fieldKey
                                   andFunctionType:(MTAggregateFunctionType)functionType
                                      andDataTable:(MADDataTableFast *)dataTable
                                       groupByType:(MTAggregateGroupByType)groupByType
                                            rowIDs:(NSArray *)rowIDs
                                predicateParamters:(NSArray *)predicateParamters {

    //Group by type page must have rowIDs.
    NSAssert(!(groupByType == MTAggregateGroupByTypePage && rowIDs == nil), @"Logic error.");
    
    //Group by type page must have rowIDs.
    NSAssert(!(groupByType == MTAggregateGroupByTypeSection && predicateParamters == nil), @"Logic error.");

    
    id keyTableName, keyFieldKey, keyFunctionType, keyFieldDescriptors, keyGroupByType, keyRowIDs, keyPredicate;

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
    
    NSMutableDictionary <NSString *, MADDataColumn *> *columns = dataTable.columns;
    
    NSNumber *groupType = [[NSNumber alloc] initWithShort:groupByType];


    if (rowIDs == nil) rowIDs = [[NSArray alloc] init];
    
    if (predicateParamters == nil) predicateParamters = [[NSArray alloc] init];

    id paramaters;
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

+ (instancetype)newParametersAggregateByType:(MTAggregateGroupByType)groupBy
                                    function:(MTAggregateFunctionType)function
                                      rowids:(NSArray *)rowids
                                   groupKeys:(NSArray *)groupKeys
                                    fieldKey:(NSString *)fieldKey
                                   dataTable:(MADDataTableFast *)dataTable {
    id parameters = nil;
    NSString *columnKey = [dataTable columnKeyForColumnName:fieldKey];
    if (columnKey == nil) return nil;

    switch (groupBy) {
        case MTAggregateGroupByTypePage: {
            parameters = [MADParameters newParamatersAggregateByPageWithFieldKey: columnKey
                                                                            andRowIds: rowids
                                                                      andFunctionType: function
                                                                         andDataTable: dataTable];
            break;
        }
        case MTAggregateGroupByTypeReport:
            parameters = [MADParameters newParametersAggregateByReportWithFieldKey: columnKey
                                                                        andFunctionType: function
                                                                           andDataTable: dataTable];
            break;
            
        case MTAggregateGroupByTypeSection:
            parameters = [MADParameters newParamatersAggregateByGroupKeys: groupKeys
                                                                   andFieldKey: columnKey
                                                               andFunctionType: function
                                                                  andDataTable: dataTable];
            break;
            
        default:
            break;
    }
    return parameters;
}

+ (instancetype)newParamatersAggregateByPageWithFieldKey:(NSString *)fieldKey
                                               andRowIds:(NSArray *)rowids
                                         andFunctionType:(MTAggregateFunctionType)functionType
                                            andDataTable:(MADDataTableFast *)dataTable {
    
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
                                     andDataTable:(MADDataTableFast *)dataTable {
    
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
                                              andDataTable:(MADDataTableFast *)dataTable {
    
    id paramaters;
    paramaters = [self newParamatersAggregateWithFieldKey: fieldKey
                                          andFunctionType: functionType
                                             andDataTable: dataTable
                                              groupByType: MTAggregateGroupByTypeReport
                                                   rowIDs: nil
                                       predicateParamters: nil];

    return paramaters;

}

@end
