//
//  RptqDocumentElementFormula.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementFormula_RptqDocumentElement_h
#define MAD_RptqDocumentElementFormula_RptqDocumentElement_h

#import "RptqDocumentElement.h"
#import <CoreData/NSFetchRequest.h>

@class RptqDocumentElementAggregate;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementFormula : RptqDocumentElement

@end

@interface RptqDocumentElementFormula (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementFormula *> *)fetchRequest;

@property (nonatomic) int16_t functionScope;
@property (nonatomic) int16_t functionType;
@property (nonatomic) int16_t inputType;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int16_t resultType;
@property (nullable, nonatomic, copy) NSString *source;
@property (nullable, nonatomic, retain) RptqDocumentElementAggregate *includedInAggregateObject;

@end

NS_ASSUME_NONNULL_END

#endif
