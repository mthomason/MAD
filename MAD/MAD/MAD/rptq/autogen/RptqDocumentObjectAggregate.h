//
//  RptqDocumentObjectAggregate.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

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
