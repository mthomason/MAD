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

@class RptqDocumentElementFormula, RptqQueryField, NSFetchRequest;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementAggregate : RptqDocumentElement

@end

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
