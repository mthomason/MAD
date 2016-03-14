//
//  RptqDocumentObjectAggregate.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDocumentObjectAggregate_h
#define MAD_AutoGen_RptqDocumentObjectAggregate_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentObject, RptqDocumentObjectFormula, RptqQueryField;

@interface RptqDocumentObjectAggregate : NSManagedObject

@property (nonatomic, strong) NSNumber * function;
@property (nonatomic, strong) NSNumber * groupNumber;
@property (nonatomic, strong) NSNumber * groupType;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) RptqQueryField *aggregateField;
@property (nonatomic, strong) RptqDocumentObjectFormula *aggregateFunction;
@property (nonatomic, strong) RptqDocumentObject *parentObject;

@end

#endif
