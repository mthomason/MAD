//
//  RptqDocumentElementAggregate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElementAggregate_Extras_h
#define Reports_RptqDocumentElementAggregate_Extras_h

#import <MAD/RptqDocumentElementAggregate.h>

#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionInputType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>

#import <MADFoundation/MADDataType.h>

extern NSString * const MTAggregateTypeKeyGroupType;
extern NSString * const MTAggregateTypeKeyFunctionType;
extern NSString * const MTAggregateTypeKeyGroupNumber;

@interface RptqDocumentElementAggregate (Extras)

    + (NSString *)newStringDisplayForType:(MTAggregateFunctionType)aggregateFunctionType;
    + (NSString *)newStringDisplayForGroupByType:(MTAggregateGroupByType)groupByType;

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;
    - (void)updateAggregateFunctionWithFunctionType:(MTAggregateFunctionType)functionType
                                          inputType:(MTAggregateFunctionInputType)inputType
                                          groupType:(MTAggregateGroupByType)groupType
                                    aggregateObject:(NSManagedObject *)aggregateObject  //RptqQueryField or MTAggregateFunctionInputTypeFormula
                                        groupNumber:(int64_t)groupNumber;
    - (NSString *)copyDesignerRepresentationText;

@end

#endif
