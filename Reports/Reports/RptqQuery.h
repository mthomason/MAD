//
//  RptqQuery.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqDatabaseSchemaTable, RptqQueryCache, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTable;

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
@property (nonatomic, retain) NSOrderedSet *hasQueryTables;
@property (nonatomic, retain) NSSet *hasTables;
@property (nonatomic, retain) RptqDatabase *inDatabase;
@end

@interface RptqQuery (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)removeHasFieldsObject:(RptqDatabaseSchemaField *)value;
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

- (void)insertObject:(RptqQueryTable *)value inHasQueryTablesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasQueryTablesAtIndex:(NSUInteger)idx;
- (void)insertHasQueryTables:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasQueryTablesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasQueryTablesAtIndex:(NSUInteger)idx withObject:(RptqQueryTable *)value;
- (void)replaceHasQueryTablesAtIndexes:(NSIndexSet *)indexes withHasQueryTables:(NSArray *)values;
- (void)addHasQueryTablesObject:(RptqQueryTable *)value;
- (void)removeHasQueryTablesObject:(RptqQueryTable *)value;
- (void)addHasQueryTables:(NSOrderedSet *)values;
- (void)removeHasQueryTables:(NSOrderedSet *)values;
- (void)addHasTablesObject:(RptqDatabaseSchemaTable *)value;
- (void)removeHasTablesObject:(RptqDatabaseSchemaTable *)value;
- (void)addHasTables:(NSSet *)values;
- (void)removeHasTables:(NSSet *)values;

@end
