//
//  MADQueryType.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryType_h
#define MADQueryType_h

typedef NS_ENUM(NSUInteger, MADQueryType) {
    MADQueryTypeMaxFieldLength,
    MADQueryTypeCustomSql,
    MADQueryTypeFull,
    MADQueryTypeConnectionTest,
    MADQueryTypeSampleDataField,
    MADQueryTypeSampleDataTable,
    MADQueryTypeCacheAddColumn,
    MADQueryTypeCacheAddRow,
    MADQueryTypeCacheDeleteAllFromTable,
    MADQueryTypeCacheDropTable,
    MADQueryTypeCacheVacuum,
    MADQueryTypeCacheBeginTransaction,
    MADQueryTypeCacheEndTransaction,
    MADQueryTypeCacheSyncModeOff,
    MADQueryTypeCacheSyncModeDefault,
    MADQueryTypeCacheJournalModeOverride,
    MADQueryTypeCacheJournalModeDefault,
    MADQueryTypeCacheIndexCreateParameters,
    MADQueryTypeCacheIndexDropParameters,
    MADQueryTypeCacheSelectLimitOffset,
    MADQueryTypeCacheSelectRowId,
    MADQueryTypeCacheSelectRowIds,
    MADQueryTypeCacheSelectGroupKeys,
    MADQueryTypeCacheSelectItemsForGroupKeys,
    MADQueryTypeCacheAggregateFunction
};

#endif /* MADQueryType_h */
