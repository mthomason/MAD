//
//  RptqDatabase.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDatabase_h
#define MAD_AutoGen_RptqDatabase_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabaseSchemaTable, RptqDocument, RptqQuery, RptqUserCredentals;

@interface RptqDatabase : NSManagedObject

@property (nonatomic, strong) NSString * databaseDriverType;
@property (nonatomic, strong) NSNumber * databaseDriverTypeEnum;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSSet *hasQueries;
@property (nonatomic, strong) NSSet *hasTables;
@property (nonatomic, strong) RptqDocument *ownedByQueryAsStaticResource;
@property (nonatomic, strong) RptqUserCredentals *ownedByUser;
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

#endif
