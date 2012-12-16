//
//  RptqUserCredentals+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqUserCredentals+Extras.h"

@implementation RptqUserCredentals (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqUserCredentals class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqUserCredentals *lastObject = [fetchResults lastObject];
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

+ (RptqUserCredentals *)createNewUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName:NSStringFromClass([RptqUserCredentals class]) inManagedObjectContext: objectContext];
    RptqUserCredentals *userCredentals = [[RptqUserCredentals alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];
    return [userCredentals autorelease];
}

+ (NSArray *)userCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([RptqUserCredentals class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"database_driver_type" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
    NSError *error = nil;
    NSArray *results = [[NSArray alloc] initWithArray:[objectContext executeFetchRequest:request error:&error]];
    if (error) [error presentErrorToUser];
    return results;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqUserCredentals *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end