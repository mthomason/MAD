//
//  RptqQuerySort.h
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqField, RptqQuery;

@interface RptqQuerySort : NSManagedObject

@property (nonatomic, retain) NSNumber * ascending;
@property (nonatomic, retain) NSString * fields;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqField *hasField;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
