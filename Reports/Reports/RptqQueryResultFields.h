//
//  RptqQueryResultFields.h
//  Reports
//
//  Created by Michael Thomason on 1/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery, RptqQueryResultValues;

@interface RptqQueryResultFields : NSManagedObject

@property (nonatomic, retain) NSNumber * resultOrder;
@property (nonatomic, retain) NSSet *hasValues;
@property (nonatomic, retain) RptqQuery *hasQuery;
@end

@interface RptqQueryResultFields (CoreDataGeneratedAccessors)

- (void)addHasValuesObject:(RptqQueryResultValues *)value;
- (void)removeHasValuesObject:(RptqQueryResultValues *)value;
- (void)addHasValues:(NSSet *)values;
- (void)removeHasValues:(NSSet *)values;

@end
