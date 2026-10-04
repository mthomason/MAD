//
//  RptqDatabaseSchemaTable.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDatabaseSchemaTable_NSManagedObject_h
#define MAD_RptqDatabaseSchemaTable_NSManagedObject_h

#import <MAD/RptqObject.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQueryTable;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseSchemaTable : RptqObject

@end

@interface RptqDatabaseSchemaTable (CoreDataProperties)

@property (nonatomic) int64_t identifier;
@property (nonatomic) BOOL queryable;
@property (nullable, nonatomic, copy) NSString *name;
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

#endif
