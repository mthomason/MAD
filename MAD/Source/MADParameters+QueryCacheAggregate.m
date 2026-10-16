//
//  MADParameters+QueryCacheAggregate.m
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryCacheAggregateFunctionParamaters.h"
#import "MADParameters+QueryCacheAggregate.h"
#import <MADFoundation/madlog.h>

#import <MADSqlite3/MADDataTableFast.h>

#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

@implementation MADParameters

+ (NSDictionary <NSNumber *, MADResult *> *)paramatersAggregateFieldKey:(NSString *)fieldKey
														andFunctionType:(MTAggregateFunctionType)functionType
														   andDataTable:(MADDataTableFast *)dataTable
															groupByType:(MTAggregateGroupByType)groupByType
																 rowIDs:(NSArray *)rowIDs
													 predicateParamters:(NSArray *)predicateParamters {

	NSAssert(!(groupByType == MTAggregateGroupByTypePage && rowIDs == nil), @"Logic error.");
	NSAssert(!(groupByType == MTAggregateGroupByTypeSection && predicateParamters == nil), @"Logic error.");
	
	NSNumber *keyTableName =          [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateTableName];
	NSNumber *keyFieldKey =           [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldKey];
	NSNumber *keyFunctionType =       [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateAggregateFunctionType];
	NSNumber *keyFieldDescriptors =   [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateFieldDescriptors];
	NSNumber *keyGroupByType =        [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateGroupByType];
	NSNumber *keyRowIDs =             [[NSNumber alloc] initWithShort: MADParametersQueryCacheAggregateRowids];
	NSNumber *objFunctionType =       [[NSNumber alloc] initWithShort: functionType];
	
	NSString *tableName =               [[dataTable tableName] copy];
	NSString *fieldKeyCopy =            [fieldKey copy];
	
	NSMutableDictionary <NSString *, MADDataColumn *> *columns = dataTable.columns;
	NSNumber *groupType = [[NSNumber alloc] initWithShort:groupByType];
	
	
	if (rowIDs == nil) rowIDs = [[NSArray alloc] init];
	
	if (predicateParamters == nil) predicateParamters = [[NSArray alloc] init];
	
	NSDictionary <NSNumber *, __kindof NSObject *> *paramaters = [[NSDictionary alloc] initWithObjectsAndKeys:
				  predicateParamters, @(MADParametersQueryCacheAggregatePredicates),
				  rowIDs,             keyRowIDs,
				  groupType,          keyGroupByType,
				  tableName,          keyTableName,
				  fieldKeyCopy,       keyFieldKey,
				  columns,            keyFieldDescriptors,
				  objFunctionType,    keyFunctionType, nil];

	return paramaters;
}

+ (NSDictionary <NSNumber *, MADResult *> *)paramatersAggregateByType:(MTAggregateGroupByType)groupBy
															 function:(MTAggregateFunctionType)function
															   rowids:(NSArray *)rowids
															groupKeys:(NSArray *)groupKeys
															 fieldKey:(NSString *)fieldKey
															dataTable:(MADDataTableFast *)dataTable {
	NSDictionary *parameters = nil;
	NSString *columnKey = [dataTable columnKeyForColumnName:fieldKey];
	if (columnKey == nil) return nil;
	
	switch (groupBy) {
		case MTAggregateGroupByTypePage: {
			parameters = [self paramatersAggregateFieldKey: columnKey
										   andFunctionType: function
											  andDataTable: dataTable
											   groupByType: MTAggregateGroupByTypePage
													rowIDs: rowids
										predicateParamters: nil];
			break;
		}
		case MTAggregateGroupByTypeReport:
			parameters = [self paramatersAggregateFieldKey: columnKey
										   andFunctionType: function
											  andDataTable: dataTable
											   groupByType: MTAggregateGroupByTypeReport
													rowIDs: nil
										predicateParamters: nil];
			break;
			
		case MTAggregateGroupByTypeSection: {
			NSArray *predicateParamters = [dataTable whereClauseForGroupKeys:groupKeys].copy;
			parameters = [self paramatersAggregateFieldKey: columnKey
										   andFunctionType: function
											  andDataTable: dataTable
											   groupByType: MTAggregateGroupByTypeSection
													rowIDs: nil
										predicateParamters: predicateParamters];
		}
			break;

		default:
			break;
	}

	return parameters;
}

@end
