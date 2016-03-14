//
//  RptqDatabaseSchemaTable.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDatabaseSchemaTable_h
#define MAD_AutoGen_RptqDatabaseSchemaTable_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQueryTable;

@interface RptqDatabaseSchemaTable : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSString * label_plural;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * queryable;
@property (nonatomic, strong) NSOrderedSet *hasFields;
@property (nonatomic, strong) RptqDatabase *inDatabase;
@property (nonatomic, strong) NSOrderedSet *inQueryTable;
@end

@interface RptqDatabaseSchemaTable (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDatabaseSchemaField *)value inHasFieldsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasFieldsAtIndex:(NSUInteger)idx;
- (void)insertHasFields:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasFieldsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasFieldsAtIndex:(NSUInteger)idx withObject:(RptqDatabaseSchemaField *)value;
- (void)replaceHasFieldsAtIndexes:(NSIndexSet *)indexes withHasFields:(NSArray *)values;
- (void)addHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)removeHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)addHasFields:(NSOrderedSet *)values;
- (void)removeHasFields:(NSOrderedSet *)values;
- (void)insertObject:(RptqQueryTable *)value inInQueryTableAtIndex:(NSUInteger)idx;
- (void)removeObjectFromInQueryTableAtIndex:(NSUInteger)idx;
- (void)insertInQueryTable:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeInQueryTableAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInInQueryTableAtIndex:(NSUInteger)idx withObject:(RptqQueryTable *)value;
- (void)replaceInQueryTableAtIndexes:(NSIndexSet *)indexes withInQueryTable:(NSArray *)values;
- (void)addInQueryTableObject:(RptqQueryTable *)value;
- (void)removeInQueryTableObject:(RptqQueryTable *)value;
- (void)addInQueryTable:(NSOrderedSet *)values;
- (void)removeInQueryTable:(NSOrderedSet *)values;
@end

#endif
