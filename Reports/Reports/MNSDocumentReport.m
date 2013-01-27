//
//  MNSDocumentReport.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDocumentReport.h"

@interface MNSDocumentReport ()

@end

@implementation MNSDocumentReport

- (void)dealloc {
    [super dealloc];
}

//Create a new file
- (id)initNewFileWithName:(NSString *)name completion:(void (^)(BOOL success))completion {
    self = [super initNewFileWithName:name extension:SCHEMA_PATH_EXTENSION managedObjectType:[UIManagedDocumentReport class] completion:^(BOOL success) {
        if (self) {
            RptqDocument *doc = [RptqDocument createMainDocumentForManagedObjectContext: [[self managedDocument] managedObjectContext]];
            [doc setName: name];
            
            [self saveContext];
            [self save:^(BOOL success) {
                completion(success);
            }];
        }
    }];
    return self;
}

//Open an existing file
- (id)initExistingExistingFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success, id document))completion {
    self = [super initExistingFileWithUrl:url managedObjectType:[UIManagedDocumentReport class] completion:^(BOOL success, id document) {
        if (self) {
            completion(success, self);
        }
    }];
    return self;
}

- (void)save:(void (^)(BOOL success))completion {
    [super save: ^(BOOL success) {
        completion(success);
    }];
}

- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion {
    [super saveToUrl:url completion:^(BOOL success){
        completion(success);
    }];
}

//Add a new connection to the report
- (void)addDatasourceToReport: (MNSDatabase *)database
                   completion: (void (^)(BOOL success))completion {
    
    [RptqDocument addDatabase:database ToMainDocumentForManagedObjectContext:[[self managedDocument] managedObjectContext] completion:^(BOOL success) {
        completion(success);
    }];
    
}

- (void)refresh {
    NSManagedObjectContext *managedObjectContext = [[self managedDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    MNSDatabase *mnsDatabase = [MNSDatabase databaseForRptqDatabase: database];
    NSString *sqlSelect = [mnsDatabase getSqlForQuery:query];
    sqlSelect = [NSString stringWithFormat:@"%@ LIMIT 500", sqlSelect];
    [mnsDatabase runQuery:sqlSelect completion:^(MNSDatabase *database, NSArray *results) {
        if (results != nil) {
            
            
            NSManagedObjectContext *managedObjectContext = [[self managedDocument] managedObjectContext];
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
            RptqQuery *query = [[database hasQueries] anyObject];
            //RptqQueryResultFields *queryResultFields = [RptqQueryResultFields newResultField:];
            
            for (NSDictionary *result in results) {
                NSLog(@"%@", result);
                //for (id obj in [result objectEnumerator]) {
                //    NSLog(@"Object %@", obj);
                //}
            }
        }
    }];
    [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)sendTo {
    [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

@end