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
#import "RptqDocument+Extras.h"

@implementation RptqDatabase (Extras)

#pragma mark - Overrides

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

#pragma mark - Static

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
    [database setDatabaseDriverType: driverIdentifier];
    [database setIdentifier:connectionId];
    return database;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqDatabase *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
