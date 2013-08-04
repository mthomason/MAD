//
//  RptqDatabaseSchemaField.h
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

@interface RptqDatabaseSchemaField : NSManagedObject

@property (nonatomic, retain) NSNumber * dataType;
@property (nonatomic, retain) NSNumber * dataTypeNative;
@property (nonatomic, retain) NSString * dataTypeNativeDescription;
@property (nonatomic, retain) NSNumber * decimals;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * primaryKey;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSSet *inQuery;
@property (nonatomic, retain) NSSet *inQueryField;
@property (nonatomic, retain) RptqDatabaseSchemaTable *inTable;
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
