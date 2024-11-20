//
//  MADQueryType.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADAPI_MADQueryType_h
#define MADAPI_MADQueryType_h

typedef NS_ENUM(NSUInteger, MADQueryType) {
    MADQueryTypeUnknown = 0,
    MADQueryTypeMaxFieldLength = 1,
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
    MADQueryTypeCacheAggregateFunction,
    MADQueryTypeCacheIndexCreateTemplate
};

#endif /* MADQueryType_h */
