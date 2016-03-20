//
//  MADRefreshOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADRefreshOperation.h"
#import <MADFoundation/MTDataTable.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTQuery.h>
#import <MAD/MADConstants.h>
#import <Foundation/NSError.h>
#import <Foundation/NSURL.h>

static const short errCache = 2;

@interface MADRefreshOperation ()

    @property (nonatomic, weak) MTQuery *query;
    @property (nonatomic, weak) MTDatabase *database;
    @property (nonatomic, weak) MTDataTable *datatable;
    @property (nonatomic, copy) NSURL *cacheUrl;

@end

@implementation MADRefreshOperation

- (instancetype)initQuery:(MTQuery *)query database:(MTDatabase *)database datatable:(MTDataTable *)datatable andCacheUrl:(NSURL *)cacheUrl {
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
    bool success = [_database executeQuery:_query withError:&eerror];

    if (!success) {
        NSError *error = eerror;
        [self finishWithError:error];
        return;
    }
    
    success = [_datatable cacheWithUrl:self.cacheUrl];
    
    if (!success) {
        NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil];
        [self finishWithError:error];
        return;
    }

    [self finish];
}

@end
