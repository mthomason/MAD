//
//  RptqDocumentObjectAggregate+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectAggregate+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentObjectAggregate (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectAggregate *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *function;
@property (nullable, nonatomic, copy) NSNumber *groupNumber;
@property (nullable, nonatomic, copy) NSNumber *groupType;
@property (nullable, nonatomic, retain) RptqQueryField *aggregateField;
@property (nullable, nonatomic, retain) RptqDocumentObjectFormula *aggregateFunction;
@property (nullable, nonatomic, retain) RptqDocumentObject *parentObject;

@end

NS_ASSUME_NONNULL_END
