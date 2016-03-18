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

static const short errCache = 2;

@interface MADRefreshOperation ()
    @property (nonatomic, weak) MTQuery *query;
    @property (nonatomic, weak) MTDatabase *database;
    @property (nonatomic, weak) MTDataTable *datatable;
@end

@implementation MADRefreshOperation

- (instancetype)initQuery:(MTQuery *)query database:(MTDatabase *)database andDatatable:(MTDataTable *)datatable {
    if (self = [super init]) {
        _query = query;
        _database = database;
        _datatable = datatable;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)start {
    
    if ([self isCancelled]) {
        [self setStateCanceled];
        return;
    }
    
    [self setStateExecuting];
    
    NSError * __autoreleasing eerror = NULL;
    bool success = [_database executeQuery:_query withError:&eerror];
    
    if ([self isCancelled]) {
        [self setStateCanceled];
        return;
    }

    if (!success) {
        NSError *error = eerror;
        [self finishWithError:error];
        return;
    }
    
    success = [_datatable cacheForGroupIdentifier:MADIdentifierGroup];
    
    if ([self isCancelled]) {
        [self setStateCanceled];
        return;
    }

    if (!success) {
        NSError *error = [NSError errorWithDomain:@"MADCache" code:errCache userInfo:nil];
        [self finishWithError:error];
        return;
    }

    [self finish];
}

@end
