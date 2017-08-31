//
//  MADQuery+Extras.m
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQuery+Extras.h"

#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

#import <MADSqlite3/MADQueryCacheSelectLimitOffsetParamaters.h>
#import <MADSqlite3/MTQueryCacheDeleteAllFromTable.h>
#import <MADSqlite3/MTQueryCacheBeginTransaction.h>
#import <MADSqlite3/MTQueryCacheEndTransaction.h>
#import <MADSqlite3/MTQueryCacheSyncDefault.h>
#import <MADSqlite3/MTQueryCacheSyncOff.h>
#import <MADSqlite3/MTQueryCacheJournalModeOverride.h>
#import <MADSqlite3/MTQueryCacheSelectRowId.h>
#import <MADSqlite3/MTQueryCacheSelectRowIds.h>

#import "MTQuerySampleDataField.h"
#import "MTQuerySampleDataTable.h"
#import "MTQueryFull.h"
#import "MTQueryMaxFieldLength.h"
#import "MTQueryTest.h"
#import "MTQueryCustomNoResults.h"
#import "MTQueryCacheJournalModeDefault.h"
#import "MTQueryCacheSelectGroupKeys.h"
#import "MTQueryCacheAggregateFunction.h"

@implementation MADQuery (Extras)

@dynamic type;

- (instancetype)initWithQueryType:(MADQueryType)type object:(id)parameters {
    id query;
    
    switch (type) {
            
        case MADQueryTypeCacheAggregateFunction:
            query = [[MTQueryCacheAggregateFunction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSelectGroupKeys:
            query = [[MTQueryCacheSelectGroupKeys alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSelectRowId:
            query = [[MTQueryCacheSelectRowId alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCacheSelectRowIds:
            query = [[MTQueryCacheSelectRowIds alloc] initWithObject:parameters];
            break;

        case MADQueryTypeMaxFieldLength:
            query = [[MTQueryMaxFieldLength alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCustomSql:
            query = [[MTQueryCustomNoResults alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeFull:
            query = [[MTQueryFull alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeConnectionTest:
            query = [[MTQueryTest alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeSampleDataField:
            query = [[MTQuerySampleDataField alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeSampleDataTable:
            query = [[MTQuerySampleDataTable alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheDeleteAllFromTable:
            query = [[MTQueryCacheDeleteAllFromTable alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheBeginTransaction:
            query = [[MTQueryCacheBeginTransaction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheEndTransaction:
            query = [[MTQueryCacheEndTransaction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSyncModeOff:
            query = [[MTQueryCacheSyncOff alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSyncModeDefault:
            query = [[MTQueryCacheSyncDefault alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheJournalModeOverride:
            query = [[MTQueryCacheJournalModeOverride alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCacheJournalModeDefault:
            query = [[MTQueryCacheJournalModeDefault alloc] initWithObject:parameters];
            break;
            
        default:
            NSAssert(NO, @"Did you forget a constructor?");
            break;
    }
    return query;
}

@end
