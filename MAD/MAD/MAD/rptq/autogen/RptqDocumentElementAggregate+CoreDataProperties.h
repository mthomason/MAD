//
//  RptqDocumentElementAggregate+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementAggregate_CoreDataProperties_h
#define MAD_RptqDocumentElementAggregate_CoreDataProperties_h

#import "RptqDocumentElementAggregate.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementAggregate (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementAggregate *> *)fetchRequest;

@property (nonatomic) int32_t groupNumber;
@property (nonatomic) int16_t groupType;
@property (nonatomic) int16_t functionType;
@property (nullable, nonatomic, retain) RptqQueryField *aggregateField;
@property (nullable, nonatomic, retain) RptqDocumentElementFormula *aggregateFunction;

@end

NS_ASSUME_NONNULL_END

#endif
