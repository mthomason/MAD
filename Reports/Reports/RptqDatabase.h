//
//  RptqDatabase.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqQuery, RptqRelationship, RptqTable, RptqUserCredentals;

@interface RptqDatabase : NSManagedObject

@property (nonatomic, retain) NSString * database_driver_type;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSSet *hasQueries;
@property (nonatomic, retain) NSSet *hasRelationships;
@property (nonatomic, retain) NSSet *hasTables;
@property (nonatomic, retain) RptqDocument *ownedByQueryAsStaticResource;
@property (nonatomic, retain) RptqUserCredentals *ownedByUser;
@end

@interface RptqDatabase (CoreDataGeneratedAccessors)

- (void)addHasQueriesObject:(RptqQuery *)value;
- (void)removeHasQueriesObject:(RptqQuery *)value;
- (void)addHasQueries:(NSSet *)values;
- (void)removeHasQueries:(NSSet *)values;

- (void)addHasRelationshipsObject:(RptqRelationship *)value;
- (void)removeHasRelationshipsObject:(RptqRelationship *)value;
- (void)addHasRelationships:(NSSet *)values;
- (void)removeHasRelationships:(NSSet *)values;

- (void)addHasTablesObject:(RptqTable *)value;
- (void)removeHasTablesObject:(RptqTable *)value;
- (void)addHasTables:(NSSet *)values;
- (void)removeHasTables:(NSSet *)values;

@end
