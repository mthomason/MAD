//
//  RptqDatabaseSchemaField+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#ifndef Reports_RptqDatabaseSchemaField_CoreDataProperties_h
#define Reports_RptqDatabaseSchemaField_CoreDataProperties_h

#import "RptqDatabaseSchemaField+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseSchemaField (CoreDataProperties)

+ (NSFetchRequest<RptqDatabaseSchemaField *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *dataType;
@property (nullable, nonatomic, copy) NSNumber *dataTypeNative;
@property (nullable, nonatomic, copy) NSString *dataTypeNativeDescription;
@property (nullable, nonatomic, copy) NSNumber *decimals;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *primaryKey;
@property (nullable, nonatomic, copy) NSNumber *width;
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
