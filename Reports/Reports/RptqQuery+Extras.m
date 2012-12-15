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
}

#pragma mark - Static

+ (MTGraph *)graphForQuery:(RptqQuery *)query {

    NSSet *hasTables = [query hasTables];
    NSMutableSet *vertices = [[NSMutableSet alloc] initWithCapacity:[hasTables count]];
    
    // MARK: Create vertex in the graph for each query table.
    for (RptqTable *table in hasTables) {
        
        MTVertex *unconnectedVertex = [[MTVertex alloc] initWithEdges:nil andObject:[table objectID]];
        [vertices addObject: unconnectedVertex];
        [unconnectedVertex release];
        
    }
    
    MTGraph *graph = [[MTGraph alloc] initWithVertices: vertices];
    
    // MARK: Create an edge in the graph for each query link.
    NSSet *hasQueryLinks = [query hasQueryLinks];
    for (RptqQueryLinks *queryLink in hasQueryLinks) {
 
        RptqTable *tableOrigin =        [[queryLink  hasLeftField] inTable];
        RptqTable *tableDestination =   [[queryLink hasRightField] inTable];
        id objectOrigin =               [tableOrigin objectID];
        id objectDestination =          [tableDestination objectID];
        
        
        if ([[objectOrigin URIRepresentation] isEqual: [objectDestination URIRepresentation]]) {
            NSLog(@"Match");
        }
        
        
        
        MTVertex *vertexOrigin =        [graph vertexForObject:objectOrigin];
        MTVertex *vertexDestination =   [graph vertexForObject:objectDestination];

        MTEdge *edge =                  [[MTEdge alloc] initWithOrigin: vertexOrigin
                                                           destination: vertexDestination
                                                             andObject: [queryLink objectID]];
        
        [graph insertEdge:edge];
        
        [edge release];
    }
    
    [graph humanReadableObjectIdentifier];
    
    [graph breadthFirstSearch:[vertices anyObject]];
    
    [vertices release];
    
    return  [graph autorelease];
}

+ (NSString *)getSqlForQuery:(RptqQuery *)query {
    MNSDatabase *databaseHandler = [MNSDatabase databaseObjectForRptqDatabase:[query inDatabase]];
    return [databaseHandler getSqlForQuery: query];
}

+ (void)cacheQueryForDatabase:(RptqDatabase *)database progress:(void (^)(NSNumber *percentage))progress completion:(void (^)(BOOL success))completion {
#warning incomplete
    BOOL success = YES;

    for (RptqQuery *query in [database hasQueries]) {
        NSString *queryString = [RptqQuery getSqlForQuery: query];

    }
    completion(success);
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqQuery *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end