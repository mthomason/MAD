//
//  RptqQuery+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery+Extras.h"
#import "MTGraph.h"
#import "MTPair.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"

@implementation RptqQuery (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQuery *lastObject = [fetchResults lastObject];
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

+ (MTGraph *)graphForQuery:(RptqQuery *)query {

    NSSet *hasQueryTables = [query hasQueryTables];
    NSMutableSet *vertices = [[NSMutableSet alloc] initWithCapacity:[hasQueryTables count]];

    MTGraph *graph = [[MTGraph alloc] init];

    // MARK: Create vertex in the graph for each query table.
    for (RptqQueryTable *table in hasQueryTables) {
        [graph addVertexWithObject:[table objectID]];
    }
    
    // MARK: Create an edge in the graph for each query link.
    NSSet *hasQueryLinks = [query hasQueryLinks];
    for (RptqQueryLinks *queryLink in hasQueryLinks) {
 
        RptqQueryTable *tableOrigin =        [[queryLink hasLeftField] inQueryTable];
        RptqQueryTable *tableDestination =   [[queryLink hasRightField] inQueryTable];

        id objectOrigin =               [tableOrigin objectID];
        id objectDestination =          [tableDestination objectID];
        id objectQueryLink =            [queryLink objectID];
        
        MTVertex *vertexOrigin =        [graph vertexForObject:objectOrigin];
        MTVertex *vertexDestination =   [graph vertexForObject:objectDestination];

        [graph addEdgeWithOrigin:vertexOrigin destination:vertexDestination object:objectQueryLink andWeight:@(1)];
        
    }
    [vertices release];
    
    return  [graph autorelease];
}

+ (NSString *)getSqlForQuery:(RptqQuery *)query {
    MTDatabase *databaseHandler = [MTDatabase databaseObjectForRptqDatabase:[query inDatabase]];
    return [databaseHandler getSqlForQuery: query];
}

- (RptqQueryGroup *)firstQueryGroup {
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == 0"];
    //NSSet *groups = [[self hasQueryGroups] filteredSetUsingPredicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"weight" ascending:YES];
    NSArray *results = [[self hasQueryGroups] sortedArrayUsingDescriptors:@[sort]];
    return ([results count] >= 1) ? [results objectAtIndex:0] : nil;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQuery *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end