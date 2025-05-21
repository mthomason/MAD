//
//  MADParameters+QueryCacheAggregate.h
//  MAD
//
//  Created by Michael Thomason on 6/4/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADParameters
#define MAD_MADParameters

#import "MADAggregateFunctionGroupByType.h"
#import "MADAggregateFunctionType.h"
#import <MADAPI/MADAliases.h>
#import <Foundation/NSObject.h>

@class MADDataTableFast;

typedef NS_ENUM(short, MADParametersType) {
	MADParametersTypeUnknown = 0,
	MADParametersTypeAggregateByPage = 1,
	MADParamatersTypeAggregateByGroup = 2,
	MADParametersTypeAggregateByReport = 3,
};

static inline NSString *NSStringFromMADParametersType(MADParametersType);
static inline NSString *NSStringFromMADParametersType(MADParametersType value) {
	switch (value) {
		case MADParametersTypeAggregateByPage: return @"MADParametersTypeAggregateByPage";
		case MADParamatersTypeAggregateByGroup: return @"MADParamatersTypeAggregateByGroup";
		case MADParametersTypeAggregateByReport: return @"MADParametersTypeAggregateByReport";
		case MADParametersTypeUnknown: default: return @"MADParametersTypeUnknown";
	}
}

@interface MADParameters : NSObject

+ (NSDictionary <NSNumber *, MADResult *> *)paramatersAggregateByType:(MTAggregateGroupByType)groupBy
															 function:(MTAggregateFunctionType)function
															   rowids:(NSArray *)rowids
															groupKeys:(NSArray *)groupKeys
															 fieldKey:(NSString *)fieldKey
															dataTable:(MADDataTableFast *)dataTable;
@end

#endif
