//
//  RptqQueryTable.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqQueryTable_h
#define MAD_AutoGen_RptqQueryTable_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

@interface RptqQueryTable : NSManagedObject

@property (nonatomic, strong) NSString * alias;
@property (nonatomic, strong) NSNumber * designerInitalLayout;
@property (nonatomic, strong) NSNumber * designerOriginX;
@property (nonatomic, strong) NSNumber * designerOriginY;
@property (nonatomic, strong) NSNumber * designerSizeHeight;
@property (nonatomic, strong) NSNumber * designerSizeWidth;
@property (nonatomic, strong) NSNumber * dropIndex;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) RptqDatabaseSchemaTable *databaseSchemaTable;
@property (nonatomic, strong) NSSet *hasQueryFields;
@property (nonatomic, strong) RptqQuery *inQuery;
@end

@interface RptqQueryTable (CoreDataGeneratedAccessors)

- (void)addHasQueryFieldsObject:(RptqQueryField *)value;
- (void)removeHasQueryFieldsObject:(RptqQueryField *)value;
- (void)addHasQueryFields:(NSSet *)values;
- (void)removeHasQueryFields:(NSSet *)values;

@end

#endif
