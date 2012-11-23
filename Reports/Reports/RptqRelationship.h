//
//  RptqRelationship.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqField;

@interface RptqRelationship : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) RptqDatabase *inDatabase;
@end

@interface RptqRelationship (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqField *)value;
- (void)removeHasFieldsObject:(RptqField *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

@end
