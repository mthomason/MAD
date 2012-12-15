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
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabase class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDatabase *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
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
        if ([[db identifier] integerValue] == [connectionId integerValue]) {
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
    [database setIdentifier:connectionId];
    return [database autorelease];
}

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
 
    return result;
}

@end