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

static const short errCache = 2;

@interface MADRefreshOperation ()

    @property (nonatomic, weak) MTQuery *query;
    @property (nonatomic, weak) MTDatabase *database;
    @property (nonatomic, weak) MTDataTableFast *datatable;
    @property (nonatomic, copy) NSURL *cacheUrl;

@end

@implementation MADRefreshOperation

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        _query = document.mainQuery;
        _database = document.mainDatabase;
        _datatable = document.mainDataTable;
    }
    return self;
}

- (instancetype)initQuery:(MTQuery *)query database:(MTDatabase *)database datatable:(MTDataTableFast *)datatable andCacheUrl:(NSURL *)cacheUrl {
    if (self = [super init]) {
        _query = query;
        _database = database;
        _datatable = datatable;
        _cacheUrl = cacheUrl.copy;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    
    NSError * __autoreleasing eerror = NULL;
    MTDatabase *database = _database;

    MTDatabaseConnection *connectionSettings = [database databaseConnection];
    id dbconn = [database connectWithConnection:connectionSettings credentals:nil];
    
    MTQuery *query = _query;
    NSError *sqlError = NULL;
    NSString *queryString = [query getSqlWithError:&sqlError];
    
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
