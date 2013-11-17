//
//  RptqDatabase.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqDocument, RptqQuery, RptqUserCredentals;

@interface RptqDatabase : NSManagedObject

@property (nonatomic, retain) NSString * databaseDriverType;
@property (nonatomic, retain) NSNumber * databaseDriverTypeEnum;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSSet *hasQueries;
@property (nonatomic, retain) NSSet *hasTables;
@property (nonatomic, retain) RptqDocument *ownedByQueryAsStaticResource;
@property (nonatomic, retain) RptqUserCredentals *ownedByUser;
@end

@interface RptqDatabase (CoreDataGeneratedAccessors)

- (void)addHasQueriesObject:(RptqQuery *)value;
- (void)removeHasQueriesObject:(RptqQuery *)value;
- (void)addHasQueries:(NSSet *)values;
- (void)removeHasQueries:(NSSet *)values;

- (void)addHasTablesObject:(RptqDatabaseSchemaTable *)value;
- (void)removeHasTablesObject:(RptqDatabaseSchemaTable *)value;
- (void)addHasTables:(NSSet *)values;
- (void)removeHasTables:(NSSet *)values;

@end
