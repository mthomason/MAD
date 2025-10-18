//
//  MADQueryCacheAggregateFunctionParamaters.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADQueryCacheAggregateFunctionParamaters_h
#define MADQueryCacheAggregateFunctionParamaters_h

#import <Foundation/NSObjCRuntime.h>

typedef NS_ENUM(short, MADParametersQueryCacheAggregate) {
	MADParametersQueryCacheAggregateUnknown = 0,
	MADParametersQueryCacheAggregateTableName,
	MADParametersQueryCacheAggregateGroupByType,
	MADParametersQueryCacheAggregateRowids,
	MADParametersQueryCacheAggregateAggregateFunctionType,
	MADParametersQueryCacheAggregateFieldKey,
	MADParametersQueryCacheAggregatePredicates,
	MADParametersQueryCacheAggregateFieldDescriptors,
};

static inline NSString *NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregate);
static inline NSString *NSStringFromMADParametersQueryCacheAggregate(MADParametersQueryCacheAggregate value) {
	switch (value) {
		case MADParametersQueryCacheAggregateTableName: return @"MADParametersQueryCacheAggregateTableName";
		case MADParametersQueryCacheAggregateGroupByType: return @"MADParametersQueryCacheAggregateGroupByType";
		case MADParametersQueryCacheAggregateRowids: return @"MADParametersQueryCacheAggregateRowids";
		case MADParametersQueryCacheAggregateAggregateFunctionType: return @"MADParametersQueryCacheAggregateAggregateFunctionType";
		case MADParametersQueryCacheAggregateFieldKey: return @"MADParametersQueryCacheAggregateFieldKey";
		case MADParametersQueryCacheAggregatePredicates: return @"MADParametersQueryCacheAggregatePredicates";
		case MADParametersQueryCacheAggregateFieldDescriptors: return @"MADParametersQueryCacheAggregateFieldDescriptors";
		case MADParametersQueryCacheAggregateUnknown: default: return @"MADParametersQueryCacheAggregateUnknown";
	}
}

#endif /* MADQueryCacheAggregateFunctionParamaters_h */
