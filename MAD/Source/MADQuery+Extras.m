//
//  MADQuery+Extras.m
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
#import "MADQuerySampleDataTableRange.h"
#import "MADQueryFull.h"
#import "MADQueryMaxFieldLength.h"
#import "MADQueryTest.h"
#import "MADQueryCustomNoResults.h"
#import "MADQueryCacheJournalModeDefault.h"
#import "MADQueryCacheSelectGroupKeys.h"
#import "MADQueryCacheAggregateFunction.h"
#import <MADFoundation/madlog.h>

@implementation MADQuery (Extras)

@dynamic type;

- (instancetype)initWithQueryType:(MADQueryType)type object:(id)parameters {
	switch (type) {
		case MADQueryTypeCacheAggregateFunction:
			return [[MADQueryCacheAggregateFunction alloc] initWithObject:parameters];
		case MADQueryTypeCacheSelectGroupKeys:
			return [[MADQueryCacheSelectGroupKeys alloc] initWithObject:parameters];
		case MADQueryTypeCacheSelectRowId:
			return [[MADQueryCacheSelectRowId alloc] initWithObject:parameters];
		case MADQueryTypeCacheSelectRowIds:
			return [[MADQueryCacheSelectRowIds alloc] initWithObject:parameters];
		case MADQueryTypeMaxFieldLength:
			return [[MADQueryMaxFieldLength alloc] initWithObject:parameters];
		case MADQueryTypeCustomSql:
			return [[MADQueryCustomNoResults alloc] initWithObject:parameters];
		case MADQueryTypeFull:
			return [[MADQueryFull alloc] initWithObject:parameters];
		case MADQueryTypeConnectionTest:
			return [[MADQueryTest alloc] initWithObject:parameters];
		case MADQueryTypeSampleDataField:
			return [[MADQuerySampleDataField alloc] initWithObject:parameters];
		case MADQueryTypeSampleDataTable:
			return [[MADQuerySampleDataTable alloc] initWithObject:parameters];
		case MADQueryTypeSampleDataTableRange:
			return [[MADQuerySampleDataTableRange alloc] initWithObject:parameters];
		case MADQueryTypeCacheDeleteAllFromTable:
			return [[MADQueryCacheDeleteAllFromTable alloc] initWithObject:parameters];
		case MADQueryTypeCacheBeginTransaction:
			return [[MADQueryCacheBeginTransaction alloc] initWithObject:parameters];
		case MADQueryTypeCacheEndTransaction:
			return [[MADQueryCacheEndTransaction alloc] initWithObject:parameters];
		case MADQueryTypeCacheSyncModeOff:
			return [[MADQueryCacheSyncOff alloc] initWithObject:parameters];
		case MADQueryTypeCacheSyncModeDefault:
			return [[MADQueryCacheSyncDefault alloc] initWithObject:parameters];
		case MADQueryTypeCacheJournalModeOverride:
			return [[MADQueryCacheJournalModeOverride alloc] initWithObject:parameters];
		case MADQueryTypeCacheJournalModeDefault:
			return [[MADQueryCacheJournalModeDefault alloc] initWithObject:parameters];
		default:
			NSAssert(NO, @"Did you forget a constructor?");
	}
	NSAssert (NO, @"Should not reach here.");
	return nil;
}

@end
