//
//  RptqQueryResultFields.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQueryCache, RptqQueryResultValues;

@interface RptqQueryResultFields : NSManagedObject

@property (nonatomic, retain) NSString * fieldname;
@property (nonatomic, retain) NSNumber * resultOrder;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *hasValues;
@property (nonatomic, retain) RptqQueryCache *inQueryCache;
@end

@interface RptqQueryResultFields (CoreDataGeneratedAccessors)

- (void)addHasValuesObject:(RptqQueryResultValues *)value;
- (void)removeHasValuesObject:(RptqQueryResultValues *)value;
- (void)addHasValues:(NSSet *)values;
- (void)removeHasValues:(NSSet *)values;

@end
