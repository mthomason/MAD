//
//  MTQuery+Extras.m
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTQuery+Extras.h"

#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

#import "MADQueryCacheSelectLimitOffsetParamaters.h"

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
#import <MADSqlite3/MTQueryCacheDeleteAllFromTable.h>
#import "MTQueryCacheVacuum.h"
#import <MADSqlite3/MTQueryCacheBeginTransaction.h>
#import <MADSqlite3/MTQueryCacheEndTransaction.h>
#import <MADSqlite3/MTQueryCacheSyncDefault.h>
#import <MADSqlite3/MTQueryCacheSyncOff.h>
#import "MTQueryCacheJournalModeDefault.h"
#import <MADSqlite3/MTQueryCacheJournalModeOverride.h>
#import "MTQueryCacheIndexCreate.h"
#import "MTQueryCacheIndexDrop.h"
#import "MTQueryCacheSelectLimitOffset.h"
#import "MTQueryCacheSelectGroupKeys.h"
#import "MTQuerySelectItemsForGroup.h"
#import "MTQueryCacheSelectRowIds.h"
#import "MTQueryCacheAggregateFunction.h"

@implementation MTQuery (Extras)

@dynamic type;

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

+ (NSDictionary *)newQueryDefinitionSelect: (NSArray *)columnKeys
                                 tableName: (NSString *)tableName
                           sortDescriptors: (NSArray *)sortDescriptors {

    NSNumber *keyColumnKeys = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumnKeys];
    NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersTableNames];
    NSNumber *keySortDescriptors = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersSortDesc];

    id definition = [[NSDictionary alloc] initWithObjectsAndKeys: columnKeys, keyColumnKeys,
                                                                tableName, keyTableName,
                                                                sortDescriptors, keySortDescriptors,
                                                                nil];
    return definition;
}

+ (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                 withLimit:(NSUInteger)limit
                                 andOffset:(NSUInteger)offset
                                 dropRowid:(BOOL)droprowid {
    
    NSMutableDictionary *queryDefination = [[NSMutableDictionary alloc] initWithDictionary:queryDefinationSelect];
    NSNumber *limitw = [[NSNumber alloc] initWithUnsignedInteger: limit];
    NSNumber *offsetw = [[NSNumber alloc] initWithUnsignedInteger: offset];
    NSNumber *keyLimit = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersLimit];
    NSNumber *keyOffset = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersOffset];
    queryDefination[keyLimit] = limitw;
    queryDefination[keyOffset] = offsetw;
    if (droprowid) {
        NSNumber *keyDropRow = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersDropRowid];
        NSNumber *dropRowidObj = @YES;
        queryDefination[keyDropRow] = dropRowidObj;
    }
    return  queryDefination;

}

+ (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                 withLimit:(NSUInteger)limit
                                 andOffset:(NSUInteger)offset {
    return [self newQueryDefinitionSelect:queryDefinationSelect withLimit:limit
                                andOffset:offset
                                dropRowid:NO];
}

@end
