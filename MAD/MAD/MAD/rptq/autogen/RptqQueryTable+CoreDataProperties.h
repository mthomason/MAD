//
//  RptqQueryTable+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryTable_CoreDataProperties_h
#define MAD_RptqQueryTable_CoreDataProperties_h

#import "RptqQueryTable+CoreDataClass.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryTable (CoreDataProperties)

+ (NSFetchRequest<RptqQueryTable *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *alias;
@property (nullable, nonatomic, copy) NSNumber *designerInitalLayout;
@property (nullable, nonatomic, copy) NSNumber *designerOriginX;
@property (nullable, nonatomic, copy) NSNumber *designerOriginY;
@property (nullable, nonatomic, copy) NSNumber *designerSizeHeight;
@property (nullable, nonatomic, copy) NSNumber *designerSizeWidth;
@property (nullable, nonatomic, copy) NSNumber *dropIndex;
@property (nullable, nonatomic, copy) NSNumber *identifier;
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
