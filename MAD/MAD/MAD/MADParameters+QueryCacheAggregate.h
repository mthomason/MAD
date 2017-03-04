//
//  MADParameters+QueryCacheAggregate.h
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADParameters
#define MAD_MADParameters

#import <Foundation/NSObject.h>
#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionType.h"

@class MADDataTableFast;

typedef NS_ENUM(short, MADParametersType) {
    MADParametersTypeAggregateByPage,
    MADParamatersTypeAggregateByGroup,
    MADParametersTypeAggregateByReport,
};

@interface MADParameters : NSObject

    + (instancetype)newParamatersAggregateByPageWithFieldKey:(NSString *)fieldKey
                                                   andRowIds:(NSArray *)rowids
                                             andFunctionType:(MTAggregateFunctionType)functionType
                                                andDataTable:(MADDataTableFast *)dataTable;

    + (instancetype)newParamatersAggregateByGroupKeys:(NSArray *)groupKeys
                                          andFieldKey:(NSString *)fieldKey
                                      andFunctionType:(MTAggregateFunctionType)functionType
                                         andDataTable:(MADDataTableFast *)dataTable;

    + (instancetype)newParametersAggregateByReportWithFieldKey:(NSString *)fieldKey
                                               andFunctionType:(MTAggregateFunctionType)functionType
                                                  andDataTable:(MADDataTableFast *)dataTable;

@end

#endif
