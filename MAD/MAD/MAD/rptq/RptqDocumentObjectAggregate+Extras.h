//
//  RptqDocumentObjectAggregate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectAggregate_Extras_h
#define Reports_RptqDocumentObjectAggregate_Extras_h

#import <MAD/RptqDocumentObjectAggregate.h>
#import <MADFoundation/MADDataType.h>

extern NSString * const MTAggregateTypeKeyGroupType;
extern NSString * const MTAggregateTypeKeyFunctionType;
extern NSString * const MTAggregateTypeKeyGroupNumber;

typedef NS_ENUM(short, MTAggregateFunctionType) {
    MTAggregateFunctionTypeSum = 2,
    MTAggregateFunctionTypeMean = 3,
    MTAggregateFunctionTypeFirst = 5,
    MTAggregateFunctionTypeLast = 7,
    MTAggregateFunctionTypeCount = 11,
    MTAggregateFunctionTypeMin = 13,
    MTAggregateFunctionTypeMax = 17,
    MTAggregateFunctionTypeNotSet = 55,
};

typedef NS_ENUM(NSUInteger, MTAggregateFunctionInputType) {
    MTAggregateFunctionInputTypeField = 0,
    MTAggregateFunctionInputTypeFormula
};

typedef NS_ENUM(short, MTAggregateGroupByType) {
    MTAggregateGroupByTypePage = 2,
    MTAggregateGroupByTypeReport = 3,
    MTAggregateGroupByTypeSection = 5,
};

@interface RptqDocumentObjectAggregate (Extras)

+ (NSString *)displayStringForType:(MTAggregateFunctionType)aggregateFunctionType;
+ (NSString *)displayStringForGroupByType:(MTAggregateGroupByType)groupByType;

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;
- (void)updateAggregateFunctionWithFunctionType:(MTAggregateFunctionType)functionType
                                      inputType:(MTAggregateFunctionInputType)inputType
                                      groupType:(MTAggregateGroupByType)groupType
                                aggregateObject:(NSManagedObject *)aggregateObject  //RptqQueryField or MTAggregateFunctionInputTypeFormula
                                    groupNumber:(NSUInteger)groupNumber;
- (NSString *)designerRepresentationText;

@end

#endif
