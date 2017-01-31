//
//  RptqDocumentElementFormula+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementFormula_CoreDataProperties_h
#define MAD_RptqDocumentElementFormula_CoreDataProperties_h

#import "RptqDocumentElementFormula+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementFormula (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementFormula *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *functionScope;
@property (nullable, nonatomic, copy) NSNumber *functionType;
@property (nullable, nonatomic, copy) NSNumber *inputType;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *resultType;
@property (nullable, nonatomic, copy) NSString *source;
@property (nullable, nonatomic, retain) RptqDocumentElementAggregate *includedInAggregateObject;

@end

NS_ASSUME_NONNULL_END

#endif
