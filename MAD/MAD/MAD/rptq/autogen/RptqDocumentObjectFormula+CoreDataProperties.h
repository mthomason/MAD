//
//  RptqDocumentObjectFormula+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectFormula+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentObjectFormula (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectFormula *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *functionScope;
@property (nullable, nonatomic, copy) NSNumber *functionType;
@property (nullable, nonatomic, copy) NSNumber *inputType;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *resultType;
@property (nullable, nonatomic, copy) NSString *source;
@property (nullable, nonatomic, retain) RptqDocumentObjectAggregate *includedInAggregateObject;
@property (nullable, nonatomic, retain) RptqDocumentObject *parentObjectFormula;

@end

NS_ASSUME_NONNULL_END
