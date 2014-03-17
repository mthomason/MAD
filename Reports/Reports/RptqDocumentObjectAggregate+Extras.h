//
//  RptqDocumentObjectAggregate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectAggregate.h"
#import "RptqDocument.h"
#import "RptqDocumentObject+Extras.h"

extern NSString * const MTAggregateTypeKeyGroupType;
extern NSString * const MTAggregateTypeKeyFunctionType;
extern NSString * const MTAggregateTypeKeyGroupNumber;

@interface RptqDocumentObjectAggregate (Extras)

+ (NSString *)displayStringForType:(MTAggregateFunctionType)aggregateFunctionType;
+ (NSString *)displayStringForGroupByType:(MTAggregateGroupByType)groupByType;

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;
- (void)updateAggregateFunctionWithFunctionType:(MTAggregateFunctionType)functionType
                                      inputType:(MTAggregateFunctionInputType)inputType
                                      groupType:(MTAggregateGroupByType)groupType
                                aggregateObject:(NSManagedObject *)aggregateObject  //RptqQueryField or MTAggregateFunctionInputTypeFormula
                                    groupNumber:(NSUInteger)groupNumber;

@end
