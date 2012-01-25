//
//  RptqDatabase.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqRelationship, RptqTable, RptqUserCredentals;

@interface RptqDatabase : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *hasRelationships;
@property (nonatomic, retain) NSSet *hasTables;
@property (nonatomic, retain) NSSet *ownedByUser;
@property (nonatomic, retain) RptqDocument *ownedByQueryAsStaticResource;
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

- (void)addOwnedByUserObject:(RptqUserCredentals *)value;
- (void)removeOwnedByUserObject:(RptqUserCredentals *)value;
- (void)addOwnedByUser:(NSSet *)values;
- (void)removeOwnedByUser:(NSSet *)values;

@end
