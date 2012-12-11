//
//  RptqQuery+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery+Extras.h"
#import "MTGraph.h"

@implementation RptqQuery (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (MTGraph *)graphForQuery:(RptqQuery *)query {
    NSSet *emptyPair = [NSSet setWithObjects:nil, nil, nil];
    MTVertex *vertex = [[MTVertex alloc] initWithEdges:[emptyPair objectAtIndex:0] andObject:[emptyPair objectAtIndex:1]];
    NSMutableSet *vertices = [[NSMutableSet alloc] init];
    MTGraph *graph = [[MTGraph alloc] initWithVertices: vertices];
    
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

@end