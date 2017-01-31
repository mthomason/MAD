//
//  RptqDocumentElementAggregate+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementAggregate+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementAggregate (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementAggregate *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *groupNumber;
@property (nullable, nonatomic, copy) NSNumber *groupType;
@property (nonatomic) int64_t functionType;
@property (nullable, nonatomic, retain) RptqQueryField *aggregateField;
@property (nullable, nonatomic, retain) RptqDocumentElementFormula *aggregateFunction;

@end

NS_ASSUME_NONNULL_END
