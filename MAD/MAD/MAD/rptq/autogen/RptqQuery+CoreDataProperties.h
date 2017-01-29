//
//  RptqQuery+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqQuery+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQuery (CoreDataProperties)

+ (NSFetchRequest<RptqQuery *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *cachedText;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSNumber *override;
@property (nullable, nonatomic, copy) NSString *overrideText;
@property (nullable, nonatomic, retain) NSSet<RptqDatabaseSchemaField *> *hasFields;
@property (nullable, nonatomic, retain) RptqQueryCache *hasQueryCache;
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
