//
//  RptqQueryResultValues.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQueryResultFields;

@interface RptqQueryResultValues : NSManagedObject

@property (nonatomic, retain) NSNumber * rowId;
@property (nonatomic, retain) id value;
@property (nonatomic, retain) RptqQueryResultFields *valuesForField;

@end
