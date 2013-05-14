//
//  RptqQueryCache.h
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery, RptqQueryResult, RptqQueryResultFields;

@interface RptqQueryCache : NSManagedObject

@property (nonatomic, retain) id cacheDate;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqQuery *hasQuery;
@property (nonatomic, retain) NSSet *hasQueryResultFields;
@property (nonatomic, retain) NSSet *hasQueryResults;
@end

@interface RptqQueryCache (CoreDataGeneratedAccessors)

- (void)addHasQueryResultFieldsObject:(RptqQueryResultFields *)value;
- (void)removeHasQueryResultFieldsObject:(RptqQueryResultFields *)value;
- (void)addHasQueryResultFields:(NSSet *)values;
- (void)removeHasQueryResultFields:(NSSet *)values;

- (void)addHasQueryResultsObject:(RptqQueryResult *)value;
- (void)removeHasQueryResultsObject:(RptqQueryResult *)value;
- (void)addHasQueryResults:(NSSet *)values;
- (void)removeHasQueryResults:(NSSet *)values;

@end
