//
//  RptqDatabase+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MAD.RptqDatabase+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabase (CoreDataProperties)

+ (NSFetchRequest<RptqDatabase *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *databaseDriverType;
@property (nullable, nonatomic, copy) NSNumber *databaseDriverTypeEnum;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, retain) NSSet<RptqQuery *> *hasQueries;
@property (nullable, nonatomic, retain) NSSet<RptqDatabaseSchemaTable *> *hasTables;
@property (nullable, nonatomic, retain) RptqDocument *ownedByQueryAsStaticResource;
@property (nullable, nonatomic, retain) RptqUserCredentals *ownedByUser;

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
