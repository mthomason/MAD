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

static inline NSString *NSStringFromMADQueryType(MADQueryType);
static inline NSString *NSStringFromMADQueryType(MADQueryType value) {
	switch (value) {
		case MADQueryTypeMaxFieldLength: return @"MADQueryTypeMaxFieldLength";
		case MADQueryTypeCustomSql: return @"MADQueryTypeCustomSql";
		case MADQueryTypeFull: return @"MADQueryTypeFull";
		case MADQueryTypeConnectionTest: return @"MADQueryTypeConnectionTest";
		case MADQueryTypeSampleDataField: return @"MADQueryTypeSampleDataField";
		case MADQueryTypeSampleDataTable: return @"MADQueryTypeSampleDataTable";
		case MADQueryTypeCacheAddColumn: return @"MADQueryTypeCacheAddColumn";
		case MADQueryTypeCacheAddRow: return @"MADQueryTypeCacheAddRow";
		case MADQueryTypeCacheDeleteAllFromTable: return @"MADQueryTypeCacheDeleteAllFromTable";
		case MADQueryTypeCacheDropTable: return @"MADQueryTypeCacheDropTable";
		case MADQueryTypeCacheVacuum: return @"MADQueryTypeCacheVacuum";
		case MADQueryTypeCacheBeginTransaction: return @"MADQueryTypeCacheBeginTransaction";
		case MADQueryTypeCacheEndTransaction: return @"MADQueryTypeCacheEndTransaction";
		case MADQueryTypeCacheSyncModeOff: return @"MADQueryTypeCacheSyncModeOff";
		case MADQueryTypeCacheSyncModeDefault: return @"MADQueryTypeCacheSyncModeDefault";
		case MADQueryTypeCacheJournalModeOverride: return @"MADQueryTypeCacheJournalModeOverride";
		case MADQueryTypeCacheJournalModeDefault: return @"MADQueryTypeCacheJournalModeDefault";
		case MADQueryTypeCacheIndexCreateParameters: return @"MADQueryTypeCacheIndexCreateParameters";
		case MADQueryTypeCacheIndexDropParameters: return @"MADQueryIndexDropParameters";
		case MADQueryTypeCacheSelectLimitOffset: return @"MADQueryTypeCacheSelectLimitOffset";
		case MADQueryTypeCacheSelectRowId: return @"MADQueryTypeCacheSelectRowId";
		case MADQueryTypeCacheSelectRowIds: return @"MADQueryTypeCacheSelectRowIds";
		case MADQueryTypeCacheSelectGroupKeys: return @"MADQueryTypeCacheSelectGroupKeys";
		case MADQueryTypeCacheSelectItemsForGroupKeys: return @"MADQueryTypeCacheSelectItemsForGroupKeys";
		case MADQueryTypeCacheAggregateFunction: return @"MADQueryTypeCacheAggregateFunction";
		case MADQueryTypeCacheIndexCreateTemplate: return @"MADQueryTypeCacheIndexCreateTemplate";
		case MADQueryTypeUnknown: default: return @"MADQueryTypeUnknown";
	}
}

#endif /* MADQueryType_h */
