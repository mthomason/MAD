//
//  RptqQuery+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery+Extras.h"

@implementation RptqQuery (Extras)

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