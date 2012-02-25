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

@end