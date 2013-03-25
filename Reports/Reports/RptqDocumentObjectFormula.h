//
//  RptqDocumentObjectFormula.h
//  Reports
//
//  Created by Michael Thomason on 3/24/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject, RptqDocumentObjectAggregate;

@interface RptqDocumentObjectFormula : NSManagedObject

@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) RptqDocumentObjectAggregate *includedInAggregateObject;
@property (nonatomic, retain) RptqDocumentObject *parentObjectFormula;

@end
