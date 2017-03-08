//
//  RptqQuery.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQuery_NSManagedObject_h
#define MAD_RptqQuery_NSManagedObject_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate,
       RptqQuerySort, RptqQueryTable;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQuery : NSManagedObject

@end

@interface RptqQuery (CoreDataProperties)

+ (NSFetchRequest<RptqQuery *> *)fetchRequest;
+ (NSFetchRequest *)fetchRequestTableCount:(NSNumber *)queryIdentifier
                             objectContext:(NSManagedObjectContext *)context;

@property (nullable, nonatomic, copy) NSString *cachedText;
@property (nonatomic) int64_t identifier;
@property (nonatomic) BOOL override;
@property (nullable, nonatomic, copy) NSString *overrideText;
@property (nullable, nonatomic, retain) NSSet<RptqDatabaseSchemaField *> *hasFields;
@property (nullable, nonatomic, retain) NSSet<RptqQueryGroup *> *hasQueryGroups;
@property (nullable, nonatomic, retain) NSSet<RptqQueryLinks *> *hasQueryLinks;
@property (nullable, nonatomic, retain) NSSet<RptqQueryPredicate *> *hasQueryPredicate;
@property (nullable, nonatomic, retain) RptqQuerySort *hasQuerySort;
@property (nullable, nonatomic, retain) NSSet<RptqQueryTable *> *hasQueryTables;
@property (nullable, nonatomic, retain) RptqDatabase *inDatabase;

@end

@interface RptqQuery (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)removeHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)addHasFields:(NSSet<RptqDatabaseSchemaField *> *)values;
- (void)removeHasFields:(NSSet<RptqDatabaseSchemaField *> *)values;

- (void)addHasQueryGroupsObject:(RptqQueryGroup *)value;
- (void)removeHasQueryGroupsObject:(RptqQueryGroup *)value;
- (void)addHasQueryGroups:(NSSet<RptqQueryGroup *> *)values;
- (void)removeHasQueryGroups:(NSSet<RptqQueryGroup *> *)values;

- (void)addHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)removeHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)addHasQueryLinks:(NSSet<RptqQueryLinks *> *)values;
- (void)removeHasQueryLinks:(NSSet<RptqQueryLinks *> *)values;

- (void)addHasQueryPredicateObject:(RptqQueryPredicate *)value;
- (void)removeHasQueryPredicateObject:(RptqQueryPredicate *)value;
- (void)addHasQueryPredicate:(NSSet<RptqQueryPredicate *> *)values;
- (void)removeHasQueryPredicate:(NSSet<RptqQueryPredicate *> *)values;

- (void)addHasQueryTablesObject:(RptqQueryTable *)value;
- (void)removeHasQueryTablesObject:(RptqQueryTable *)value;
- (void)addHasQueryTables:(NSSet<RptqQueryTable *> *)values;
- (void)removeHasQueryTables:(NSSet<RptqQueryTable *> *)values;

@end

NS_ASSUME_NONNULL_END
#endif
