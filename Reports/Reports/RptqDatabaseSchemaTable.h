//
//  RptqDatabaseSchemaTable.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQuery, RptqQueryTable;

@interface RptqDatabaseSchemaTable : NSManagedObject

@property (nonatomic, retain) NSNumber * designerInitalLayout;
@property (nonatomic, retain) NSNumber * designerOriginX;
@property (nonatomic, retain) NSNumber * designerOriginY;
@property (nonatomic, retain) NSNumber * designerSizeHeight;
@property (nonatomic, retain) NSNumber * designerSizeWidth;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * label_plural;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * queryable;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) RptqDatabase *inDatabase;
@property (nonatomic, retain) NSSet *inQuery;
@property (nonatomic, retain) NSOrderedSet *inQueryTable;
@end

@interface RptqDatabaseSchemaTable (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)removeHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

- (void)addInQueryObject:(RptqQuery *)value;
- (void)removeInQueryObject:(RptqQuery *)value;
- (void)addInQuery:(NSSet *)values;
- (void)removeInQuery:(NSSet *)values;

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
