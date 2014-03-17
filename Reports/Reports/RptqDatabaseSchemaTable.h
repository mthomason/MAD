//
//  RptqDatabaseSchemaTable.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQueryTable;

@interface RptqDatabaseSchemaTable : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * label_plural;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * queryable;
@property (nonatomic, retain) NSOrderedSet *hasFields;
@property (nonatomic, retain) RptqDatabase *inDatabase;
@property (nonatomic, retain) NSOrderedSet *inQueryTable;
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
