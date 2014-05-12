//
//  RptqRelationship.h
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqDatabaseSchemaField;

@interface RptqRelationship : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSSet *hasFields;
@property (nonatomic, strong) RptqDatabase *inDatabase;
@end

@interface RptqRelationship (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)removeHasFieldsObject:(RptqDatabaseSchemaField *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

@end
