//
//  Database.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Relationship, Table, UserCredentals;

@interface Database : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *hasRelationships;
@property (nonatomic, retain) NSSet *hasTables;
@property (nonatomic, retain) NSSet *ownedByUser;
@end

@interface Database (CoreDataGeneratedAccessors)

- (void)addHasRelationshipsObject:(Relationship *)value;
- (void)removeHasRelationshipsObject:(Relationship *)value;
- (void)addHasRelationships:(NSSet *)values;
- (void)removeHasRelationships:(NSSet *)values;

- (void)addHasTablesObject:(Table *)value;
- (void)removeHasTablesObject:(Table *)value;
- (void)addHasTables:(NSSet *)values;
- (void)removeHasTables:(NSSet *)values;

- (void)addOwnedByUserObject:(UserCredentals *)value;
- (void)removeOwnedByUserObject:(UserCredentals *)value;
- (void)addOwnedByUser:(NSSet *)values;
- (void)removeOwnedByUser:(NSSet *)values;

@end
