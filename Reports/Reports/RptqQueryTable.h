//
//  RptqQueryTable.h
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

@interface RptqQueryTable : NSManagedObject

@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSNumber * dropIndex;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqDatabaseSchemaTable *databaseSchemaTable;
@property (nonatomic, retain) RptqQuery *inQuery;
@property (nonatomic, retain) NSSet *hasQueryFields;
@end

@interface RptqQueryTable (CoreDataGeneratedAccessors)

- (void)addHasQueryFieldsObject:(RptqQueryField *)value;
- (void)removeHasQueryFieldsObject:(RptqQueryField *)value;
- (void)addHasQueryFields:(NSSet *)values;
- (void)removeHasQueryFields:(NSSet *)values;

@end
