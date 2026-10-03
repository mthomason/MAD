//
//  RptqQueryTable.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqQueryTable_NSManagedObject_h
#define MAD_RptqQueryTable_NSManagedObject_h

#import "RptqObject.h"

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryTable : RptqObject

@end

@interface RptqQueryTable (CoreDataProperties)

@property (nullable, nonatomic, copy) NSString *alias;
@property (nonatomic) int64_t dropIndex;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, retain) RptqDatabaseSchemaTable *databaseSchemaTable;
@property (nullable, nonatomic, retain) NSSet<RptqQueryField *> *hasQueryFields;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

@interface RptqQueryTable (CoreDataGeneratedAccessors)

- (void)addHasQueryFieldsObject:(RptqQueryField *)value;
- (void)removeHasQueryFieldsObject:(RptqQueryField *)value;
- (void)addHasQueryFields:(NSSet<RptqQueryField *> *)values;
- (void)removeHasQueryFields:(NSSet<RptqQueryField *> *)values;

@end

NS_ASSUME_NONNULL_END

#endif
