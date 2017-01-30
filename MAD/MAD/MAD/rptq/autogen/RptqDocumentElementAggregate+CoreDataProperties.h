//
//  RptqDocumentElementAggregate+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementAggregate_CoreDataProperties_h
#define MAD_RptqDocumentElementAggregate_CoreDataProperties_h

#import "RptqDocumentElementAggregate+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementAggregate (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementAggregate *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *function;
@property (nullable, nonatomic, copy) NSNumber *groupNumber;
@property (nullable, nonatomic, copy) NSNumber *groupType;
@property (nullable, nonatomic, retain) RptqQueryField *aggregateField;
@property (nullable, nonatomic, retain) RptqDocumentElementFormula *aggregateFunction;

@end

NS_ASSUME_NONNULL_END

#endif
