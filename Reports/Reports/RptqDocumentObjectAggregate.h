//
//  RptqDocumentObjectAggregate.h
//  Reports
//
//  Created by Michael Thomason on 3/19/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaField, RptqDocumentObject, RptqDocumentObjectFormula;

@interface RptqDocumentObjectAggregate : NSManagedObject

@property (nonatomic, retain) NSNumber * function;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * groupNumber;
@property (nonatomic, retain) NSNumber * groupType;
@property (nonatomic, retain) RptqDatabaseSchemaField *aggregateField;
@property (nonatomic, retain) RptqDocumentObjectFormula *aggregateFunction;
@property (nonatomic, retain) RptqDocumentObject *parentObject;

@end
