//
//  MADParameters+QueryCacheAggregate.h
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADParameters_QueryCacheAggregate_h
#define MADParameters_QueryCacheAggregate_h

//#import "MADParameters.h"
#import <Foundation/NSDictionary.h>
#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionType.h"
#import "MTDataTableFast.h"

typedef NSDictionary MADParameters;

@interface NSDictionary (QueryCacheAggregate)

+ (instancetype)newParamatersAggregateByPageWithFieldKey:(NSString *)fieldKey
                                               andRowIds:(NSArray *)rowids
                                         andFunctionType:(MTAggregateFunctionType)functionType
                                            andDataTable:(MTDataTableFast *)dataTable;

+ (instancetype)newParamatersAggregateByGroupKeys:(NSArray *)groupKeys
                                      andFieldKey:(NSString *)fieldKey
                                  andFunctionType:(MTAggregateFunctionType)functionType
                                     andDataTable:(MTDataTableFast *)dataTable;

+ (instancetype)newParametersAggregateByReportWithFieldKey:(NSString *)fieldKey
                                             andFunctionType:(MTAggregateFunctionType)functionType
                                                andDataTable:(MTDataTableFast *)dataTable;

@end

#endif
