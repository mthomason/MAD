//
//  RptqQueryTable.h
//  Reports
//
//  Created by Michael Thomason on 6/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

@interface RptqQueryTable : NSManagedObject

@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSNumber * designerInitalLayout;
@property (nonatomic, retain) NSNumber * designerOriginX;
@property (nonatomic, retain) NSNumber * designerOriginY;
@property (nonatomic, retain) NSNumber * designerSizeHeight;
@property (nonatomic, retain) NSNumber * designerSizeWidth;
@property (nonatomic, retain) NSNumber * dropIndex;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqDatabaseSchemaTable *databaseSchemaTable;
@property (nonatomic, retain) NSSet *hasQueryFields;
@property (nonatomic, retain) RptqQuery *inQuery;
@end

@interface RptqQueryTable (CoreDataGeneratedAccessors)

- (void)addHasQueryFieldsObject:(RptqQueryField *)value;
- (void)removeHasQueryFieldsObject:(RptqQueryField *)value;
- (void)addHasQueryFields:(NSSet *)values;
- (void)removeHasQueryFields:(NSSet *)values;

@end
