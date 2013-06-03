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

/*
- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {
        
    }
    return self;
}
*/
/*- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"Auto-Saving Document");
    id result = [super contentsForType:typeName error:outError];
    return result;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL result = [super loadFromContents:contents ofType:typeName error:outError];
    return result;
}*/
/*
- (BOOL)readAdditionalContentFromURL:(NSURL *)absoluteURL error:(NSError **)error
{
    NSURL *myURL = [absoluteURL URLByAppendingPathComponent:@"AdditionalInformation.plist"];
    self.extraInfo = [NSDictionary dictionaryWithContentsOfURL:myURL];
    return YES;
}

- (id)additionalContentForURL:(NSURL *)absoluteURL error:(NSError **)error
{
    if (!self.extraInfo) {
        return [NSDictionary dictionaryWithObjectsAndKeys: @"Picard", @"Captain", [[NSDate date] description], @"RightNow", nil];
    } else {
        NSMutableDictionary *updatedFriendInfo = [self.extraInfo mutableCopy];
        [updatedFriendInfo setObject:[[NSDate date] description] forKey:@"RightNow"];
        [updatedFriendInfo setObject:@"YES" forKey:@"Updated"];
        
        return updatedFriendInfo;
    }
}

- (BOOL)writeAdditionalContent:(id)content toURL:(NSURL *)absoluteURL originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error
{
    if (content) {
        NSURL *myURL = [absoluteURL URLByAppendingPathComponent:@"AdditionalInformation.plist"];
        [(NSDictionary *)content writeToURL:myURL atomically:NO];
    }
    
    return YES;
}
*/
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

- (void)refresh {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *sqlSelect = [mnsDatabase getSqlForQuery:query];
    sqlSelect = [NSString stringWithFormat:@"%@ LIMIT 220", sqlSelect];
    [mnsDatabase cacheReportQueryForManagedObjectContext: managedObjectContext
               completion: ^(MTDatabase *database, RptqQueryCache *cache) {
                   [self save: ^(BOOL success) {
                       
                   }];
                   
    }];
//    [NSException exceptionWithName: NSInternalInconsistencyException
//                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
//                                 userInfo: nil];
}

- (void)refresh:(void (^)(BOOL success))completion {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *sqlSelect = [mnsDatabase getSqlForQuery:query];
    sqlSelect = [NSString stringWithFormat:@"%@ LIMIT 220", sqlSelect];
    [mnsDatabase cacheReportQueryForManagedObjectContext: managedObjectContext
               completion: ^(MTDatabase *database, RptqQueryCache *cache) {
                   [self save: ^(BOOL success) {
                       completion(YES);
                   }];
               }];
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
