//
//  RptqDocumentElementAggregate.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentElementAggregate_RptqDocumentElement_h
#define MAD_RptqDocumentElementAggregate_RptqDocumentElement_h

#import <MAD/RptqDocumentElement.h>
#import <MAD/MADAggregateFunctionGroupByType.h>
#import <MAD/MADAggregateFunctionType.h>

@class RptqDocumentElementFormula, RptqQueryField, NSFetchRequest;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementAggregate : RptqDocumentElement

@end

@interface RptqDocumentElementAggregate (CoreDataProperties)

@property (nonatomic) int32_t groupNumber;
@property (nonatomic) MTAggregateGroupByType groupType;
@property (nonatomic) MTAggregateFunctionType functionType;
@property (nullable, nonatomic, retain) RptqQueryField *aggregateField;
@property (nullable, nonatomic, retain) RptqDocumentElementFormula *aggregateFunction;

@end

NS_ASSUME_NONNULL_END


#endif
