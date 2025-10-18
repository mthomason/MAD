//
//  RptqDocumentElementAggregate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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

	- (void)updateAggregateFunctionWithFunctionType:(MTAggregateFunctionType)functionType
										  inputType:(MTAggregateFunctionInputType)inputType
										  groupType:(MTAggregateGroupByType)groupType
								  aggregateObjectID:(NSManagedObjectID *)aggregateObject  //RptqQueryField or MTAggregateFunctionInputTypeFormula
										groupNumber:(int32_t)groupNumber;
	- (NSString *)designerRepresentationText;

@end

#endif
