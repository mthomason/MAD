//
//  RptqQueryTables+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTables+Extras.h"

@implementation RptqQueryTables (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (NSArray *)namesForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *requestQt = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTables class])];
    NSSortDescriptor *sortDescriptorQt = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
    requestQt.sortDescriptors = [NSArray arrayWithObject:sortDescriptorQt];
    NSError *errorQt = nil;
    NSArray *queryTables = [objectContext executeFetchRequest:requestQt error:&errorQt];
    NSMutableArray *queryTablesName = [[NSMutableArray alloc] initWithCapacity:[queryTables count]];
    if (!errorQt) {
        for (RptqQueryTables *rqt in queryTables) {
            [queryTablesName addObject:[rqt name]];
        }
    }
    return [queryTablesName autorelease];
}

+ (void)deleteTable:(NSManagedObjectID *)objid fromManagedObjectContext:(NSManagedObjectContext *)moc {
    NSLog(@"Delete objid %@", objid);
    RptqQueryTables *result = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTables class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
    
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSError *error = nil;
    NSArray *results = [[moc executeFetchRequest:request error:&error] retain];
    if ([results count] == 1) {
        result = [[results objectAtIndex: 0] retain];
        [moc deleteObject:result];
        [result release];
    } else if ([results count] > 1) {
        NSLog(@"Error: Why is it like this? %@ in %@!", objid, moc);
        result = [[results objectAtIndex: 0] retain];
        [moc deleteObject:result];
        [result release];
    } else {
        NSLog(@"Warning: Could not find %@ in %@.", objid, moc);
    }
    [results release];
}

@end