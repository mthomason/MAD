//
//  RptqField.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqRelationship, RptqTable;

@interface RptqField : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * datatype;
@property (nonatomic, retain) NSSet *inRelationships;
@property (nonatomic, retain) RptqTable *inTable;
@end

@interface RptqField (CoreDataGeneratedAccessors)

- (void)addInRelationshipsObject:(RptqRelationship *)value;
- (void)removeInRelationshipsObject:(RptqRelationship *)value;
- (void)addInRelationships:(NSSet *)values;
- (void)removeInRelationships:(NSSet *)values;

@end
