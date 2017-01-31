//
//  RptqDatabase+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDatabase+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"

#import "RptqDataHelper.h"

@implementation RptqDatabase (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

- (RptqQuery *)defaultQuery { return self.hasQueries.anyObject; }

- (RptqDatabaseSchemaTable *)getTableWithName:(NSString *)name {
    RptqDatabaseSchemaTable *result = nil;
    for (RptqDatabaseSchemaTable *table in self.hasTables) {
        if ([table.name isEqualToString:name]) {
            result = table;
            break;
        }
    }
    return result;
}

- (MADDatabaseType)databaseType {
    return self.databaseDriverTypeEnum;
}

#pragma mark - Static

+ (RptqDatabase *)databaseForDocument:(RptqDocument *)document
                      andConnecitonId:(int64_t)connectionId {
    
    RptqDatabase *currentDatabase = nil;
    for (RptqDatabase *db in document.hasDatabaseSchemas) {
        if (db.identifier == connectionId) {
            currentDatabase = db;
            break;
        }
    }

    return currentDatabase;
}

+ (instancetype)newDatabaseFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               driverType:(NSString *)driverIdentifier
                                             connectionId:(int64_t)identifier NS_RETURNS_RETAINED {

    NSString *entityName = NSStringFromClass([self class]);
    NSEntityDescription *databaseEntity = [NSEntityDescription entityForName: entityName
                                                      inManagedObjectContext: objectContext];
    
    RptqDatabase *database = [[self alloc] initWithEntity: databaseEntity
                           insertIntoManagedObjectContext: objectContext];

    NSString *databaseDriverType = [[NSString alloc] initWithString: driverIdentifier];
    database.databaseDriverType = databaseDriverType;
    
    database.identifier = identifier;
    
    return database;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Driver type:        %@\n", self.databaseDriverType];
    [description appendFormat:@"Driver type id:     %hd\n", self.databaseDriverTypeEnum];
    [description appendFormat:@"Identifier:         %lld\n", self.identifier];
    [description appendFormat:@"Tables:             %@\n", self.hasTables];
    [description appendFormat:@"Queries:            %@\n", self.hasQueries];
    [description appendFormat:@"Owned by query:     %@\n", self.ownedByQueryAsStaticResource];
    [description appendFormat:@"Owned by user:      %@\n", self.ownedByUser];
    [description appendFormat:@"*********"];
    return description;
}

@end
