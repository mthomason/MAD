//
//  RptqDatabaseSchemaField.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDatabaseSchemaField_NSManagedObject_h
#define MAD_RptqDatabaseSchemaField_NSManagedObject_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseSchemaField : NSManagedObject

@end

@interface RptqDatabaseSchemaField (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseSchemaField *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) BOOL primaryKey;
@property (nonatomic) int16_t dataType;
@property (nonatomic) int16_t dataTypeNative;
@property (nonatomic) int16_t decimals;
@property (nonatomic) int64_t width;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, retain) NSSet<RptqQuery *> *inQuery;
@property (nullable, nonatomic, retain) NSSet<RptqQueryField *> *inQueryField;
@property (nullable, nonatomic, retain) RptqDatabaseSchemaTable *inTable;

@end

@interface RptqDatabaseSchemaField (CoreDataGeneratedAccessors)

- (void)addInQueryObject:(RptqQuery *)value;
- (void)removeInQueryObject:(RptqQuery *)value;
- (void)addInQuery:(NSSet<RptqQuery *> *)values;
- (void)removeInQuery:(NSSet<RptqQuery *> *)values;

- (void)addInQueryFieldObject:(RptqQueryField *)value;
- (void)removeInQueryFieldObject:(RptqQueryField *)value;
- (void)addInQueryField:(NSSet<RptqQueryField *> *)values;
- (void)removeInQueryField:(NSSet<RptqQueryField *> *)values;

@end

NS_ASSUME_NONNULL_END

#endif
