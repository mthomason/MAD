//
//  RptqDatabase.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_RptqDatabase_NSManagedObject_h
#define MAD_RptqDatabase_NSManagedObject_h

#import <MAD/RptqObject.h>

@class RptqDatabaseSchemaTable, RptqDocument, RptqQuery, RptqDatabaseCredentals;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabase : RptqObject

@end

@interface RptqDatabase (CoreDataProperties)

@property (nullable, nonatomic, copy) NSString *databaseDriverType;
@property (nonatomic) int16_t databaseDriverTypeEnum;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, retain) NSSet<RptqQuery *> *hasQueries;
@property (nullable, nonatomic, retain) NSSet<RptqDatabaseSchemaTable *> *hasTables;
@property (nullable, nonatomic, retain) RptqDocument *ownedByQueryAsStaticResource;
@property (nullable, nonatomic, retain) RptqDatabaseCredentals *ownedByUser;

@end

@interface RptqDatabase (CoreDataGeneratedAccessors)

- (void)addHasQueriesObject:(RptqQuery *)value;
- (void)removeHasQueriesObject:(RptqQuery *)value;
- (void)addHasQueries:(NSSet<RptqQuery *> *)values;
- (void)removeHasQueries:(NSSet<RptqQuery *> *)values;

- (void)addHasTablesObject:(RptqDatabaseSchemaTable *)value;
- (void)removeHasTablesObject:(RptqDatabaseSchemaTable *)value;
- (void)addHasTables:(NSSet<RptqDatabaseSchemaTable *> *)values;
- (void)removeHasTables:(NSSet<RptqDatabaseSchemaTable *> *)values;

@end

NS_ASSUME_NONNULL_END

#endif
