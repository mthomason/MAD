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
#import <MADSqlite3/MADQueryCacheDeleteAllFromTable.h>
#import <MADSqlite3/MADQueryCacheBeginTransaction.h>
#import <MADSqlite3/MADQueryCacheEndTransaction.h>
#import <MADSqlite3/MADQueryCacheSyncDefault.h>
#import <MADSqlite3/MADQueryCacheSyncOff.h>
#import <MADSqlite3/MADQueryCacheJournalModeOverride.h>
#import <MADSqlite3/MADQueryCacheSelectRowId.h>
#import <MADSqlite3/MADQueryCacheSelectRowIds.h>

#import "MADQuerySampleDataField.h"
#import "MADQuerySampleDataTable.h"
#import "MADQueryFull.h"
#import "MADQueryMaxFieldLength.h"
#import "MADQueryTest.h"
#import "MADQueryCustomNoResults.h"
#import "MADQueryCacheJournalModeDefault.h"
#import "MADQueryCacheSelectGroupKeys.h"
#import "MADQueryCacheAggregateFunction.h"

@implementation MADQuery (Extras)

@dynamic type;

- (instancetype)initWithQueryType:(MADQueryType)type object:(id)parameters {
    id query;
    
    switch (type) {
            
        case MADQueryTypeCacheAggregateFunction:
            query = [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSelectGroupKeys:
            query = [[MADQueryCacheSelectGroupKeys alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSelectRowId:
            query = [[MADQueryCacheSelectRowId alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCacheSelectRowIds:
            query = [[MADQueryCacheSelectRowIds alloc] initWithObject:parameters];
            break;

        case MADQueryTypeMaxFieldLength:
            query = [[MADQueryMaxFieldLength alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCustomSql:
            query = [[MADQueryCustomNoResults alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeFull:
            query = [[MADQueryFull alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeConnectionTest:
            query = [[MADQueryTest alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeSampleDataField:
            query = [[MADQuerySampleDataField alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeSampleDataTable:
            query = [[MADQuerySampleDataTable alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheDeleteAllFromTable:
            query = [[MADQueryCacheDeleteAllFromTable alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheBeginTransaction:
            query = [[MADQueryCacheBeginTransaction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheEndTransaction:
            query = [[MADQueryCacheEndTransaction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSyncModeOff:
            query = [[MADQueryCacheSyncOff alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSyncModeDefault:
            query = [[MADQueryCacheSyncDefault alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheJournalModeOverride:
            query = [[MADQueryCacheJournalModeOverride alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCacheJournalModeDefault:
            query = [[MADQueryCacheJournalModeDefault alloc] initWithObject:parameters];
            break;
            
        default:
            NSAssert(NO, @"Did you forget a constructor?");
            break;
    }
    return query;
}

@end
