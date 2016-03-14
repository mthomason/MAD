//
//  RptqQuery.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqQuery_h
#define MAD_AutoGen_RptqQuery_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQueryCache, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTable;

@interface RptqQuery : NSManagedObject

@property (nonatomic, strong) NSString * cachedText;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSNumber * override;
@property (nonatomic, strong) NSString * overrideText;
@property (nonatomic, strong) NSSet *hasFields;
@property (nonatomic, strong) RptqQueryCache *hasQueryCache;
@property (nonatomic, strong) NSSet *hasQueryGroups;
@property (nonatomic, strong) NSSet *hasQueryLinks;
@property (nonatomic, strong) NSSet *hasQueryPredicate;
@property (nonatomic, strong) RptqQuerySort *hasQuerySort;
@property (nonatomic, strong) NSSet *hasQueryTables;
@property (nonatomic, strong) RptqDatabase *inDatabase;
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

- (void)addHasQueryTablesObject:(RptqQueryTable *)value;
- (void)removeHasQueryTablesObject:(RptqQueryTable *)value;
- (void)addHasQueryTables:(NSSet *)values;
- (void)removeHasQueryTables:(NSSet *)values;

@end

#endif
