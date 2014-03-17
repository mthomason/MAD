//
//  RptqDocumentObjectFormula.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject, RptqDocumentObjectAggregate;

@interface RptqDocumentObjectFormula : NSManagedObject

@property (nonatomic, retain) NSNumber * functionScope;
@property (nonatomic, retain) NSNumber * functionType;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * inputType;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * resultType;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) RptqDocumentObjectAggregate *includedInAggregateObject;
@property (nonatomic, retain) RptqDocumentObject *parentObjectFormula;

@end
