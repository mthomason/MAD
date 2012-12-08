//
//  RptqDatabase+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabase+Extras.h"

@implementation RptqDatabase (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (RptqDatabase *)getDatabaseFromDocument:(RptqDocument *)document
                         withConnecitonId:(NSNumber *)connectionId {
    
    RptqDatabase *currentDatabase = nil;
    for (RptqDatabase *db in [document hasDatabaseSchemas]) {
        if ([[db connection_id] integerValue] == [connectionId integerValue]) {
            currentDatabase = db;
            break;
        }
    }

    return currentDatabase;
}

+ (RptqDatabase *)createNewDatabaseForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                driverType:(NSString *)driverIdentifier
                                              connectionId:(NSNumber *)connectionId {

    NSString *entityName = NSStringFromClass([RptqDatabase class]);
    NSEntityDescription *databaseEntity = [NSEntityDescription entityForName: entityName
                                                      inManagedObjectContext: objectContext];

    RptqDatabase *database = [[RptqDatabase alloc] initWithEntity:databaseEntity
                                   insertIntoManagedObjectContext:objectContext];
    [database setDatabase_driver_type: driverIdentifier];
    [database setConnection_id:connectionId];
    return [database autorelease];
}

@end