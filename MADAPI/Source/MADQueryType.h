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
	MADQueryTypeCustomSql = 3,
	MADQueryTypeFull = 4,
	MADQueryTypeConnectionTest = 5,
	MADQueryTypeSampleDataField = 6,
	MADQueryTypeSampleDataTable = 7,
	MADQueryTypeCacheAddColumn = 8,
	MADQueryTypeCacheAddRow = 9,
	MADQueryTypeCacheDeleteAllFromTable = 10,
	MADQueryTypeCacheDropTable = 11,
	MADQueryTypeCacheVacuum = 12,
	MADQueryTypeCacheBeginTransaction = 13,
	MADQueryTypeCacheEndTransaction = 14,
	MADQueryTypeCacheSyncModeOff = 15,
	MADQueryTypeCacheSyncModeDefault = 16,
	MADQueryTypeCacheJournalModeOverride = 17,
	MADQueryTypeCacheJournalModeDefault = 18,
	MADQueryTypeCacheIndexCreateParameters = 19,
	MADQueryTypeCacheIndexDropParameters = 20,
	MADQueryTypeCacheSelectLimitOffset = 21,
	MADQueryTypeCacheSelectRowId = 22,
	MADQueryTypeCacheSelectRowIds = 23,
	MADQueryTypeCacheSelectGroupKeys = 24,
	MADQueryTypeCacheSelectItemsForGroupKeys = 25,
	MADQueryTypeCacheAggregateFunction = 26,
	MADQueryTypeCacheIndexCreateTemplate = 27,
	MADQueryTypeSampleDataTableRange = 28
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
		case MADQueryTypeCacheIndexDropParameters: return @"MADQueryTypeCacheIndexDropParameters";
		case MADQueryTypeCacheSelectLimitOffset: return @"MADQueryTypeCacheSelectLimitOffset";
		case MADQueryTypeCacheSelectRowId: return @"MADQueryTypeCacheSelectRowId";
		case MADQueryTypeCacheSelectRowIds: return @"MADQueryTypeCacheSelectRowIds";
		case MADQueryTypeCacheSelectGroupKeys: return @"MADQueryTypeCacheSelectGroupKeys";
		case MADQueryTypeCacheSelectItemsForGroupKeys: return @"MADQueryTypeCacheSelectItemsForGroupKeys";
		case MADQueryTypeCacheAggregateFunction: return @"MADQueryTypeCacheAggregateFunction";
		case MADQueryTypeCacheIndexCreateTemplate: return @"MADQueryTypeCacheIndexCreateTemplate";
		case MADQueryTypeSampleDataTableRange: return @"MADQueryTypeSampleDataTableRange";
		case MADQueryTypeUnknown: default: return @"MADQueryTypeUnknown";
	}
}

#endif /* MADQueryType_h */
