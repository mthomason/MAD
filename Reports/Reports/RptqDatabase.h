//
//  RptqDatabase.h
//  Reports
//
//  Created by Michael Thomason on 11/17/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqRelationship, RptqTable, RptqUserCredentals;

@interface RptqDatabase : NSManagedObject

@property (nonatomic, retain) NSNumber * connection_id;
@property (nonatomic, retain) NSString * database_driver_type;
@property (nonatomic, retain) NSSet *hasRelationships;
@property (nonatomic, retain) NSSet *hasTables;
@property (nonatomic, retain) RptqDocument *ownedByQueryAsStaticResource;
@property (nonatomic, retain) RptqUserCredentals *ownedByUser;
@end

@interface RptqDatabase (CoreDataGeneratedAccessors)

- (void)addHasRelationshipsObject:(RptqRelationship *)value;
- (void)removeHasRelationshipsObject:(RptqRelationship *)value;
- (void)addHasRelationships:(NSSet *)values;
- (void)removeHasRelationships:(NSSet *)values;

- (void)addHasTablesObject:(RptqTable *)value;
- (void)removeHasTablesObject:(RptqTable *)value;
- (void)addHasTables:(NSSet *)values;
- (void)removeHasTables:(NSSet *)values;

@end
