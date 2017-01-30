//
//  RptqDatabaseSchemaTable+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaTable+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseSchemaTable (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseSchemaTable *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSString *label_plural;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *queryable;
@property (nullable, nonatomic, retain) NSOrderedSet<RptqDatabaseSchemaField *> *hasFields;
@property (nullable, nonatomic, retain) RptqDatabase *inDatabase;
@property (nullable, nonatomic, retain) NSOrderedSet<RptqQueryTable *> *inQueryTable;

@end

@interface RptqDatabaseSchemaTable (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDatabaseSchemaField *)value inHasFieldsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasFieldsAtIndex:(NSUInteger)idx;
- (void)insertHasFields:(NSArray<RptqDatabaseSchemaField *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasFieldsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasFieldsAtIndex:(NSUInteger)idx withObject:(RptqDatabaseSchemaField *)value;
- (void)replaceHasFieldsAtIndexes:(NSIndexSet *)indexes withHasFields:(NSArray<RptqDatabaseSchemaField *> *)values;
- (void)addHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)removeHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)addHasFields:(NSOrderedSet<RptqDatabaseSchemaField *> *)values;
- (void)removeHasFields:(NSOrderedSet<RptqDatabaseSchemaField *> *)values;

- (void)insertObject:(RptqQueryTable *)value inInQueryTableAtIndex:(NSUInteger)idx;
- (void)removeObjectFromInQueryTableAtIndex:(NSUInteger)idx;
- (void)insertInQueryTable:(NSArray<RptqQueryTable *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeInQueryTableAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInInQueryTableAtIndex:(NSUInteger)idx withObject:(RptqQueryTable *)value;
- (void)replaceInQueryTableAtIndexes:(NSIndexSet *)indexes withInQueryTable:(NSArray<RptqQueryTable *> *)values;
- (void)addInQueryTableObject:(RptqQueryTable *)value;
- (void)removeInQueryTableObject:(RptqQueryTable *)value;
- (void)addInQueryTable:(NSOrderedSet<RptqQueryTable *> *)values;
- (void)removeInQueryTable:(NSOrderedSet<RptqQueryTable *> *)values;

@end

NS_ASSUME_NONNULL_END
