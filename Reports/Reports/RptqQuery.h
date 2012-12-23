//
//  RptqQuery.h
//  Reports
//
//  Created by Michael Thomason on 12/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqField, RptqQueryCache, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqTable;

@interface RptqQuery : NSManagedObject

@property (nonatomic, retain) NSString * cachedText;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) RptqQueryCache *hasQueryCache;
@property (nonatomic, retain) NSSet *hasQueryGroups;
@property (nonatomic, retain) NSSet *hasQueryLinks;
@property (nonatomic, retain) NSSet *hasQueryPredicate;
@property (nonatomic, retain) RptqQuerySort *hasQuerySort;
@property (nonatomic, retain) NSSet *hasTables;
@property (nonatomic, retain) RptqDatabase *inDatabase;
@end

@interface RptqQuery (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqField *)value;
- (void)removeHasFieldsObject:(RptqField *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

- (void)addHasQueryGroupsObject:(RptqQueryGroup *)value;
- (void)removeHasQueryGroupsObject:(RptqQueryGroup *)value;
- (void)addHasQueryGroups:(NSSet *)values;
- (void)removeHasQueryGroups:(NSSet *)values;

- (void)addHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)removeHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)addHasQueryLinks:(NSSet *)values;
- (void)removeHasQueryLinks:(NSSet *)values;

- (void)addHasQueryPredicateObject:(RptqQueryPredicate *)value;
- (void)removeHasQueryPredicateObject:(RptqQueryPredicate *)value;
- (void)addHasQueryPredicate:(NSSet *)values;
- (void)removeHasQueryPredicate:(NSSet *)values;

- (void)addHasTablesObject:(RptqTable *)value;
- (void)removeHasTablesObject:(RptqTable *)value;
- (void)addHasTables:(NSSet *)values;
- (void)removeHasTables:(NSSet *)values;

@end
