//
//  Field.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Relationship, Table;

@interface Field : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *inRelationships;
@property (nonatomic, retain) Table *inTable;
@end

@interface Field (CoreDataGeneratedAccessors)

- (void)addInRelationshipsObject:(Relationship *)value;
- (void)removeInRelationshipsObject:(Relationship *)value;
- (void)addInRelationships:(NSSet *)values;
- (void)removeInRelationships:(NSSet *)values;

@end
