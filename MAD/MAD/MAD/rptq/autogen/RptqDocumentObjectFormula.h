//
//  RptqDocumentObjectFormula.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDocumentObjectFormula_h
#define MAD_AutoGen_RptqDocumentObjectFormula_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentObject, RptqDocumentObjectAggregate;

@interface RptqDocumentObjectFormula : NSManagedObject

@property (nonatomic, strong) NSNumber * functionScope;
@property (nonatomic, strong) NSNumber * functionType;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSNumber * inputType;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * resultType;
@property (nonatomic, strong) NSString * source;
@property (nonatomic, strong) RptqDocumentObjectAggregate *includedInAggregateObject;
@property (nonatomic, strong) RptqDocumentObject *parentObjectFormula;

@end

#endif
