//
//  MADQuery.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQuery.h"

#import <Foundation/NSException.h>

#import "MTQueryCacheSelectRowId.h"
#import "MTQuerySampleDataField.h"
#import "MTQuerySampleDataTable.h"
#import "MTQueryFull.h"
#import "MTQueryMaxFieldLength.h"
#import "MTQueryTest.h"
#import "MTQueryCustomNoResults.h"
#import "MTQueryCacheDropTable.h"
#import "MTQueryCacheAddColumn.h"
#import "MTQueryCacheAddRow.h"
#import "MTQueryCacheDeleteAllFromTable.h"
#import "MTQueryCacheVacuum.h"
#import "MTQueryCacheBeginTransaction.h"
#import "MTQueryCacheEndTransaction.h"
#import "MTQueryCacheSyncDefault.h"
#import "MTQueryCacheSyncOff.h"
#import "MTQueryCacheJournalModeDefault.h"
#import "MTQueryCacheJournalModeOverride.h"
#import "MTQueryCacheIndexCreate.h"
#import "MTQueryCacheIndexDrop.h"
#import "MTQueryCacheSelectLimitOffset.h"
#import "MTQueryCacheSelectGroupKeys.h"
#import "MTQuerySelectItemsForGroup.h"
#import "MTQueryCacheSelectRowIds.h"
#import "MTQueryCacheAggregateFunction.h"

@implementation MADQuery

- (instancetype)initWithQueryType:(MADQueryType)type object:(id)parameters {
    id query;
    
    switch (type) {
            
        case MADQueryTypeCacheSelectRowIds:
            query = [[MTQueryCacheSelectRowIds alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSelectItemsForGroupKeys:
            query = [[MADQuerySelectItemsForGroup alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheAggregateFunction:
            query = [[MTQueryCacheAggregateFunction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSelectGroupKeys:
            query = [[MTQueryCacheSelectGroupKeys alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSelectRowId:
            query = [[MTQueryCacheSelectRowId alloc] initWithObject:parameters];
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
        
        case MADQueryTypeCacheAddColumn:
            query = [[MTQueryCacheAddColumn alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheAddRow:
            query = [[MTQueryCacheAddRow alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheDropTable:
            query = [[MTQueryCacheDropTable alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheDeleteAllFromTable:
            query = [[MTQueryCacheDeleteAllFromTable alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheVacuum:
            query = [[MTQueryCacheVacuum alloc] initWithObject:parameters];
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
            
        case MADQueryTypeCacheIndexCreateParameters:
            query = [[MTQueryCacheIndexCreate alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheIndexDropParameters:
            query = [[MTQueryCacheIndexDrop alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSelectLimitOffset:
            query = [[MTQueryCacheSelectLimitOffset alloc] initWithObject:parameters];
            break;
            
        default:
            NSAssert(NO, @"Did you forget a constructor?");
            break;
    }
    return query;
}

@end
