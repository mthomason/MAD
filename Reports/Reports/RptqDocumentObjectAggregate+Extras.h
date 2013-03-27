//
//  RptqDocumentObjectAggregate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectAggregate.h"
#import "RptqDocument.h"
#import "RptqDocumentObject+Extras.h"

typedef NS_ENUM(NSUInteger, MTAggregateGroupType) {
	MTAggregateGroupTypeField = 1,
	MTAggregateGroupTypeFormula = 2
};

typedef NS_ENUM(NSUInteger, MTAggregateFunctionType) {
    MTAggregateFunctionTypeSum = 2,
    MTAggregateFunctionTypeMean = 3,
    MTAggregateFunctionTypeFirst = 5,
    MTAggregateFunctionTypeLast = 7,
    MTAggregateFunctionTypeCount = 11,
    MTAggregateFunctionTypeMin = 13,
    MTAggregateFunctionTypeMax = 17,
};

typedef NS_ENUM(NSUInteger, MTGroupByType) {
    MTGroupByTypePage = 2,
    MTGroupByTypeReport = 3,
    MTGroupByTypeSection = 5,
};

extern NSString * const MTAggregateTypeKeyGroupType;
extern NSString * const MTAggregateTypeKeyFunctionType;
extern NSString * const MTAggregateTypeKeyGroupNumber;

@interface RptqDocumentObjectAggregate (Extras)

+ (NSString *)displayStringForType:(MTAggregateFunctionType)aggregateFunctionType;
+ (NSString *)displayStringForGroupByType:(MTGroupByType)groupByType;

@end
