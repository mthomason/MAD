//
//  MNSDocumentReport.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDocument.h"

@interface MTReportDocument ()

@end

@implementation MTReportDocument

- (void)dealloc {
    [super dealloc];
}

+ (NSString *)persistentStoreName {
    return MTPersistentStoreAliasMad;
}

//Add a new connection to the report
- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success, NSError *error))completion {
    
    [RptqDocument addDatabase:database toManagedObjectContext:[self managedObjectContext] completion:^(BOOL success, NSError *error) {
        completion(success, error);
        if (success) {
            [self saveToURL:[self fileURL] forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {

            }];
        }
    }];
}

- (void)refresh:(void (^)(BOOL success))completion {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *sqlSelect = [mnsDatabase getSqlForQuery:query];
    if ([sqlSelect length] > 0) {
        sqlSelect = [NSString stringWithFormat:@"%@ LIMIT 100000", sqlSelect];
        [mnsDatabase cacheReportQueryForManagedObjectContext: managedObjectContext completion: ^(MTDatabase *database, RptqQueryCache *cache) {
            
            //[self save: ^(BOOL success) {
                completion(YES);
            //}];
            
        }];
    } else {
        completion(NO);
    }
}

- (BOOL)hasCachedData {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    return [query hasQueryCache] != nil;
}

- (void)sendTo {
    [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

@end
