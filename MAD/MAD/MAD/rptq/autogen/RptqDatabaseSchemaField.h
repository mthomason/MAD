//
//  RptqDatabaseSchemaField.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

@interface RptqDatabaseSchemaField : NSManagedObject

@property (nonatomic, strong) NSNumber * dataType;
@property (nonatomic, strong) NSNumber * dataTypeNative;
@property (nonatomic, strong) NSString * dataTypeNativeDescription;
@property (nonatomic, strong) NSNumber * decimals;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * primaryKey;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, strong) NSSet *inQuery;
@property (nonatomic, strong) NSSet *inQueryField;
@property (nonatomic, strong) RptqDatabaseSchemaTable *inTable;
@end

@interface RptqDatabaseSchemaField (CoreDataGeneratedAccessors)

- (void)addInQueryObject:(RptqQuery *)value;
- (void)removeInQueryObject:(RptqQuery *)value;
- (void)addInQuery:(NSSet *)values;
- (void)removeInQuery:(NSSet *)values;

- (void)addInQueryFieldObject:(RptqQueryField *)value;
- (void)removeInQueryFieldObject:(RptqQueryField *)value;
- (void)addInQueryField:(NSSet *)values;
- (void)removeInQueryField:(NSSet *)values;

@end
