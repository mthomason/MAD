//
//  MADRefreshOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperation.h"
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDataTableFast.h>
#import <MAD/MTQuery.h>
#import <MAD/MADConstants.h>
#import <Foundation/NSError.h>
#import <Foundation/NSURL.h>
#import <CoreData/NSManagedObjectContext.h>
#import "MADRefreshOperationInitalize.h"
#import <MAD/MADCredential.h>

static const short errCache = 2;

@interface MADRefreshOperation ()

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, weak) MTQueryFull *query;
    @property (nonatomic, weak) MTDatabase *database;
    @property (nonatomic, weak) MTDataTableFast *datatable;
    @property (nonatomic, copy) NSURL *cacheUrl;

@end

@implementation MADRefreshOperation

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithDocument:(MADocument *)document {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self = [super init]) {
        _document = document;
        _query = document.mainQuery;
        _database = document.mainDatabase;
        _datatable = document.mainDataTable;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    MADCredential *credientals = nil;
    for (NSOperation *dependency in self.dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)] &&
            ((id <MADOperationHoldsCredentialsProtocol>)dependency).gotCredentials) {
            credientals = ((id <MADOperationHoldsCredentialsProtocol>)dependency).credentials;
        }
    }
    
    if (credientals == nil) {
        NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache + 1 userInfo:nil];
        [self finishWithError:error];
        return;
    }
    
    NSError * __autoreleasing eerror = NULL;
    MTDatabase *database = _database;

    MTDatabaseConnection *connectionSettings = [database databaseConnection];
    id dbconn = [database connectWithConnection:connectionSettings credentals:credientals];
    
    MTQueryFull *query = _query;
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
    private.parentContext = _document.managedObjectContext;
    
    __block NSString *queryString = nil;
    [private performBlockAndWait:^{
        NSError *sqlError = NULL;
        queryString = [query getSqlWithManagedObjectContext:private error:&sqlError];
    }];
    
    NSError *executeError = NULL;
    MTDataTableFast *datatable = _datatable;
    BOOL success = [database executeSql:queryString fieldKeys:query.fieldKeys onConnection:dbconn intoResultTable:datatable withError:&executeError];

    if (!success) {
        NSError *error = eerror;
        [self finishWithError:error];
        return;
    }
    
    success = [datatable cacheWithUrl:self.cacheUrl];
    
    if (!success) {
        NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil];
        [self finishWithError:error];
        return;
    }

    [self finish];
}

@end
