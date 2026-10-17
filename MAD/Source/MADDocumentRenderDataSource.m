//
//  MADDocumentRenderDataSource.m
//  MAD
//
//  See MADDocumentRenderDataSource.h.  The bodies are MADocument's, moved: this is a
//  relocation, not a rewrite, so the app's pages read exactly what they read before.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDocumentRenderDataSource.h"

#import "MADQuery+Extras.h"
#import "MADReportFormatter.h"
#import "MADSectionRepresentation.h"

#import <MADAPI/MADQuery.h>
#import <MADFoundation/madlog.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADArrayCaching.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADAliases.h>
#import <MAD/MADParameters+QueryCacheAggregate.h>

// The key range a group level covers: levels 0...n.  MADocument's file-static helper,
// moved with the reads that use it.
static inline NSRange MADRangeToGroup(int64_t groupNumber) {
	return NSMakeRange(0, (NSUInteger)groupNumber + 1);
}

@implementation MADDocumentRenderDataSource

- (instancetype)initWithDocument:(id <MADDocumentRenderProtocol>)document {
	if (self = [super init]) {
		_document = document;
	}
	return self;
}

#pragma mark - MADPrintPageRendererDataSourceProtocol

- (MADDatabase *)database { return self.document.database; }

- (MADDataTableFast *)dataTable { return self.document.dataTable; }

- (MADReportFormatter *)reportFormatter { return self.document.reportFormatter; }

// The protocol's formatter is readwrite; the document owns it, so a write here is a
// write there rather than a second place a formatter could live.
- (void)setReportFormatter:(MADReportFormatter *)reportFormatter {
	self.document.reportFormatter = reportFormatter;
}

- (NSDictionary *)dataForRow:(NSUInteger)rowID
					  column:(NSString *)columnKey
					   error:(NSError * __autoreleasing *)error {
	NSError * errorQ = nil;
	NSDictionary *result = [self.dataTable dataForRow:rowID column:columnKey error:&errorQ];
	if (errorQ != nil && error != NULL) {
		os_log_error(GetMadLog(), "%s Error: %@", __PRETTY_FUNCTION__, errorQ);
		*error = errorQ;
	}
	return result;
}

- (NSArray <NSString *> *)groupLevelKeyNames {
	NSMutableArray <NSString *> *groupKeys = [[NSMutableArray alloc] initWithCapacity:self.dataTable.sortDescriptors.count];
	for (NSSortDescriptor *sortDescriptor in self.dataTable.sortDescriptors) {
		NSString *key = sortDescriptor.key;
		if (key != nil) {
			[groupKeys addObject:key];
		}
	}
	return groupKeys;
}

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID {
	if (self.reportFormatter.numberOfGroups > 0) {
		NSError *error = nil;
		NSDictionary <NSString *, MADResult *> *row = [self.dataTable dataForRow: (NSUInteger)rowID error:&error];
		if (error != nil) {
			os_log_error(GetMadLog(), "%s Error: %@", __PRETTY_FUNCTION__, error);
		}
		return [self.reportFormatter newObjectArrayKeyValuesForResultRow: row];
	} else {
		return [[NSArray alloc] init];

	}
}

- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber {
	NSArray *groupKeys = nil;
	NSArray <MADResult *> *groupLevelKeys = [self groupLevelKeys:rowID];
	if (groupNumber < (int64_t)groupLevelKeys.count && groupNumber >= 0) {
		groupKeys = [groupLevelKeys subarrayWithRange:MADRangeToGroup(groupNumber)];
	}
	return groupKeys;
}

- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys
											 groupID:(int64_t)groupID {
	NSArray <__kindof NSDictionary *> *dataForGroup;
	if (groupID < (int64_t)groupKeys.count) {
		NSArray *groupKeysInRange = [groupKeys subarrayWithRange: MADRangeToGroup(groupID)];
		dataForGroup = [self.dataTable objectsForGroupKeys:groupKeysInRange];
	} else {
		dataForGroup = [[NSArray alloc] init];
	}

	return dataForGroup;
}

- (MADResult *)dataForRows:(NSArray *)rowIDs column:(NSString *)columnKey groups:(NSArray *)groupKeys
				  function:(MTAggregateFunctionType)function groupBy:(MTAggregateGroupByType)groupBy {

	if (!self.dataTable) {
		return nil;
	}

	if (!columnKey || columnKey.length == 0) {
		os_log_error(GetMadLog(), "[MADDocumentRenderDataSource dataForRows] CRITICAL - columnKey is NIL or EMPTY. Query will likely fail or return incorrect data.");
	}

	NSDictionary <NSNumber *, MADResult *> *parameters = [MADParameters paramatersAggregateByType: groupBy
																						 function: function
																						   rowids: rowIDs
																						groupKeys: groupKeys
																						 fieldKey: columnKey
																						dataTable: self.dataTable];
	if (parameters != nil) {
		__kindof MADQuery *query = [[MADQuery alloc] initWithQueryType: MADQueryTypeCacheAggregateFunction
																object: parameters];
		MADResult *result = [self.dataTable runSelectQuery:query];
		return result;
	}
	return nil;
}

- (NSUInteger)rowIDFirstOfReport {
	NSUInteger rowID = NSUIntegerMax;
	MADDocumentSectionType sectionType;
	NSArray<__kindof MADSectionRepresentation *> *pageLayout = nil;
	bool found = false;

	for (pageLayout in self.reportFormatter.reportLayout) {
		for (MADSectionRepresentation *pageSection in pageLayout) {
			sectionType = pageSection.sectionType;
			if (sectionType == MADDocumentSectionTypeBody) {
				rowID = pageSection.detailRowId;
				found = true;
				break;
			}
		}
		if (found) {
			break;
		}
	}
	return rowID;
}

- (NSUInteger)rowIDLastOfReport {
	NSUInteger rowID = NSUIntegerMax;
	MADDocumentSectionType sectionType;
	bool found = false;
	NSArray<__kindof MADSectionRepresentation *> *pageLayout = nil;
	NSUInteger reportLayoutCount = self.reportFormatter.reportLayout.count;
	for (NSUInteger i = reportLayoutCount; i > 0; i--) {
		pageLayout = self.reportFormatter.reportLayout[i - 1];
		NSEnumerator<MADSectionRepresentation *> *reverseObjectEnumerator = [pageLayout reverseObjectEnumerator];
		for (MADSectionRepresentation *pageSection in reverseObjectEnumerator) {
			sectionType = pageSection.sectionType;
			if (sectionType == MADDocumentSectionTypeBody) {
				rowID = pageSection.detailRowId;
				found = true;
				break;
			}
		}
		if (found) {
			break;
		}
	}
	return rowID;
}

- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page {
	NSUInteger rowID = NSUIntegerMax;
	MADDocumentSectionType section;
	NSArray <MADSectionRepresentation *> *pageLayout;
	pageLayout = self.reportFormatter.reportLayout[page];
	for (MADSectionRepresentation *pageSection in pageLayout) {
		section = pageSection.sectionType;
		if (section == MADDocumentSectionTypeBody) {
			rowID = pageSection.detailRowId;
			break;
		}
	}
	return rowID;
}

- (NSUInteger)rowIDLastOfPage:(NSUInteger)page {
	NSUInteger rowID = NSUIntegerMax;
	NSEnumerator <MADSectionRepresentation *> *enumerator = [self.reportFormatter.reportLayout[page] reverseObjectEnumerator];
	for (MADSectionRepresentation *pageSection in enumerator) {
		if (pageSection.sectionType == MADDocumentSectionTypeBody) {
			return pageSection.detailRowId;
			break;
		}
	}
	return rowID;
}

- (NSDictionary *)dataForRowReportFirst {
	NSUInteger firstRowID = [self rowIDFirstOfReport];
	return firstRowID != NSUIntegerMax ? [self dataForRow:firstRowID] : nil;
}

- (NSDictionary *)dataForRowReportLast {
	NSUInteger lastRowID = [self rowIDLastOfReport];
	return lastRowID != NSUIntegerMax ? [self dataForRow:lastRowID] : nil;
}

- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex {
	NSUInteger firstRowid = [self rowIDFirstOfPage:pageIndex];
	return firstRowid != NSUIntegerMax ? [self dataForRow:firstRowid] : nil;
}

- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex {
	NSUInteger lastRowid = [self rowIDLastOfPage:pageIndex];
	return lastRowid != NSUIntegerMax ? [self dataForRow:lastRowid] : nil;
}

- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex {
	return [self.reportFormatter rowIDsForPage:pageIndex];
}

- (void)updatePrintingReportFormatter {
	// The app's print dialog formatter.  There is no dialog here, and nothing that
	// prints asks this data source -- MADocument keeps its own implementation.
}

#pragma mark - MADReportFormatterDataSource

- (NSEnumerator *)enumeratorForReportData {
	return [self.dataTable enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
	NSString *path = self.document.urlDataTableCache.path;
	return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

- (NSDictionary *)dataForRow:(NSUInteger)rowID {
	return [self.dataTable dataForRow:rowID error:nil];
}

- (NSDictionary *)dataForRow:(NSUInteger)rowID error:(NSError *__autoreleasing *)outError {
	NSError *error = nil;
	NSDictionary *result = [self.dataTable dataForRow:rowID error:&error];
	if (error != nil) {
		os_log_error(GetMadLog(), "%s Error: %@", __PRETTY_FUNCTION__, error);
		if (outError != NULL) {
			*outError = error;
		}
	}
	return result;
}

@end
