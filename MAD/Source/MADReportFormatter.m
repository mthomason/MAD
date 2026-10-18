//
//  MADReportFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportFormatter.h"
#import "MADReportFormatterDataSourceProtocol.h"
#import "MADSectionRepresentation.h"
#import "MADReportFormatterState.h"
#import "MADModel.h"
#import "MADModelDocument.h"
#import "MADModelDatabase.h"
#import "MADQueryFull.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "MADNotificationDidFormatPage.h"
#import "MADPageOptions.h"
#import "MADSectionRepresentation.h"
#import "MADSectionsLayout.h"
#import "MADSectionLayout.h"
#import "MADSectionGroupLayout.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADAliases.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import <MADFoundation/NSData+Comparison.h>
#import <MADFoundation/MADDataType.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADSqlite3/MADArrayCaching.h>

// The page's margins, and nothing else from UIKit: this file is in the Linux build
// too now, where the four-edge struct comes from the compat shim (Linux/Compat).
#import <UIKit/UIGeometry.h>

static inline UIEdgeInsets MADEdgeInsetsQuarterInch(void);
static inline UIEdgeInsets MADEdgeInsetsEmpty(void);
static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect, CGSize);
static inline CGFloat PrintableHeightForPage(MADPageOptions *);
static inline CGFloat HeightWithNextItem(CGFloat, CGFloat, CGFloat);

static inline UIEdgeInsets MADEdgeInsetsQuarterInch(void) { CGFloat f = fCGPointsForInches(1.0/4.0); return UIEdgeInsetsMake(f, f, f, f); }
static inline UIEdgeInsets MADEdgeInsetsEmpty(void) { return UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.height, CGSizeZero.height, CGSizeZero.height); }
static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect printableRect, CGSize layoutSize) { return UIEdgeInsetsMake(printableRect.origin.y, printableRect.origin.x, layoutSize.height - printableRect.size.height - printableRect.origin.y, layoutSize.width - printableRect.size.width - printableRect.origin.x); }
static inline CGFloat PrintableHeightForPage(MADPageOptions *page) { return page.layoutSize.height - page.margins.top - page.margins.bottom; }
static inline CGFloat HeightWithNextItem(CGFloat heightUsedCurrentPage, CGFloat nextItemHeight, CGFloat pageFooterHeight) { return heightUsedCurrentPage + nextItemHeight + pageFooterHeight; }

@interface MADReportFormatter ()

@property (nonatomic, readwrite, weak)      id <MADDocumentRenderProtocol> layout;
@property (nonatomic, readwrite, strong)    MADSectionsLayout *sections;
@property (nonatomic, readwrite, strong)    MADPageOptions *page;
@property (nonatomic, readwrite, strong)    MADReportFormatterState *machineState;

@property (nonatomic, readwrite, assign)    MADReportFormatterOptions options;

	//  These are the rowids by page.  These point to data in the cache.
	//      Once these arrays are populated, they are used by the print page render to
	//      draw the report.
	//
@property (nonatomic, readwrite, strong)    MADArrayCaching <NSArray <NSNumber *> *> *reportIndexes;
@property (nonatomic, readwrite, strong)    MADArrayCaching <NSArray <MADSectionRepresentation *> *> *reportLayout;

@property (nonatomic, readwrite, strong)    NSMutableArray <__kindof MADSectionRepresentation *> *pageLayoutTemporary;
@property (nonatomic, readwrite, strong)    NSArray <NSNumber *> *pageIndexesTemporary;

//  The previous row's positional group-key values, as returned by
//  -newObjectArrayKeyValuesForResultRow:; nil before the first row.  The elements
//  are raw cache values (NSNull, NSNumber, NSString or NSData); see
//  -compareValue:withValue:usingSelector: for how they are compared.
@property (nonatomic, readwrite, strong)    NSArray *lastComparsonValues;

@end

@implementation MADReportFormatter {
	NSUInteger _numberOfGroups;
	NSString *_filename;
}

- (void)dealloc { }

- (instancetype)initWithDocument: (id <MADDocumentRenderProtocol>)layout
						 options: (MADReportFormatterOptions)options  {
	if (self = [super init]) {
		
		self.cachedDelegate = layout;
		self.dataDelegate = layout;
		self.datasource = layout;
		self.layout = layout;
		
		_filename = layout.filename.copy;
		
		MADPageOptions *page = [[MADPageOptions alloc] init];
		self.page = page;
		
		self.page.margins = (options & MADReportFormatterOptionsMargin) ?
		MADEdgeInsetsQuarterInch() :
		MADEdgeInsetsEmpty();
		
		MADReportFormatterState *machineState = [[MADReportFormatterState alloc] init];
		self.machineState = machineState;
		
		NSMutableArray <__kindof MADSectionRepresentation *> *temporaryLayoutForPage = [[NSMutableArray alloc] init];
		self.pageLayoutTemporary = temporaryLayoutForPage;
		
		NSArray *temporaryDataForPage = [[NSArray alloc] init];
		self.pageIndexesTemporary = temporaryDataForPage;
		self.options = options;
		self.didRefresh = NO;
		
	}
	return self;
}

+ (instancetype)newReportFormatterWithLayout: (id <MADDocumentRenderProtocol>)layout
									 options: (MADReportFormatterOptions)options {
	MADReportFormatter *result = [[MADReportFormatter alloc] initWithDocument: layout
																	  options: options];
	return result;
}

#pragma mark -
#pragma mark Helpers

+ (id)dataForGroupData:(id)data andKeys:(NSArray *)keys NS_RETURNS_RETAINED {
	id resultData = nil;
	if ([data isKindOfClass:[NSArray class]]) {
		resultData = [[NSArray alloc] initWithArray:data];
	} else {
		if (keys.count > 0) {
			id subData = data[keys[0]];
			NSArray *subKeys = nil;
			if (keys.count > 1) {
				NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, keys.count - 1)];
				subKeys = [keys objectsAtIndexes:set];
				resultData = [MADReportFormatter dataForGroupData:subData andKeys:subKeys];
			} else if (keys.count == 1) {
				resultData = subData;
			} else {
				resultData = subData;
			}
		} else {
			resultData = @[];
		}
	}
	return resultData;
}

- (NSEnumerator <__kindof MADSectionRepresentation *> *)layoutEnumerator:(NSUInteger)pageIndex {
	NSArray <MADSectionRepresentation *> *pageLayout = self.reportLayout[pageIndex];
	return pageLayout.objectEnumerator;
}

- (NSString *)newStringNameCurrentReportIndexes:(CGSize)size andHash:(unsigned long)hash {
	return [[NSString alloc] initWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "ih", NSStringFromCGSize(_page.layoutSize)];
}

- (NSString *)newStringNameCurrentReportLayout:(CGSize)size andHash:(unsigned long)hash {
	return [[NSString alloc] initWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "lh", NSStringFromCGSize(_page.layoutSize)];
}

- (NSUInteger)layoutIdentifier {
	return _overrideIdentifier == nil ? _filename.hash : _overrideIdentifier.hash;
}

//  Group-boundary comparison.  The formatter does not sort: the cache is already
//  ordered by the report's group keys.  -MADDataTableFast
//  -enumeratorForKeyObjectsSorted: emits ORDER BY for them.  Text keys are meant
//  to sort under the LSASC collation, which is exactly
//  -localizedCaseInsensitiveCompare: (MADDatabaseSqlite3), but that enumerator
//  currently passes columns:nil and gets plain binary ASC; equality and row order
//  disagree for case variants until that is fixed (BUGS.md, "The cache's ORDER BY
//  ignores column types").  This method answers only "is this level's key the
//  same as the previous row's?"; -formatDocumentGroupFooters:andLastValues: and
//  -formatDocumentGroupHeaders:andLastValues: use it to find where a group ends
//  and the next begins, and neither reads the ordering.
//
//  `value` and `value2` are raw row-cache values.  `MADResult` is an erased alias
//  (MADAliases.h), so they arrive as `id`; the object's class is the only runtime
//  tag the cache carries: the sqlite reader maps storage class to NSNull,
//  NSNumber, NSString or NSData (+[MADDatabaseSqlite3 databaseResultValue:
//  columnNumber:]).  NSDate never comes from that reader.
//
//  `selector` is the schema-side type hint for the level, from the group's
//  NSSortDescriptor: MADDataTypeSelectorForSorting maps string fields to
//  -localizedCaseInsensitiveCompare:, blob fields to -compareData:, and the rest
//  to -compare:.  Hint and value class agree in the normal cache path, but
//  nothing enforces it: the cache column's declared type is a schema hint, while
//  the stored class is SQLite's per-value storage class.  Blob columns are the
//  loose case -- the insert bind accepts both NSString and NSData for one,
//  writing TEXT and BLOB respectively, so a driver that produces both will mix
//  them -- and a non-sqlite datasource can supply anything.  A mismatch raises:
//  either the selector is sent to a class that does not implement it, or a
//  Foundation comparison is handed an argument of the wrong class.  It does not
//  mis-sort.  See BUGS.md, "MADReportFormatter compares untyped values through id".
//
//  The two -compare: sends below are what -Wstrict-selector-match reports:
//  Foundation declares `compare:` on several classes with different argument
//  types, and the receiver is `id`, so the compiler cannot bind one.  Dispatch
//  is by the receiver's class at runtime; the warning is a compile-time
//  ambiguity.
//
//  The agreed fix is upstream, not here (BUGS.md): the cache's insert path must
//  store one canonical class per declared column type, and each group level gets
//  a comparator chosen once from the cache column's type (the schema field's
//  type as fallback).  This method can then call that comparator without a
//  per-value class test.  A mismatch is a contract violation: assert in debug;
//  in release, log once and take a cold, safe class-checked fallback, because an
//  offline open can still use a pre-contract cache.  The duplicated comparison
//  -- both walks, the same pair, every level -- is a later optimization, not
//  the reason for the change.
- (NSComparisonResult)compareValue:(id)value
						 withValue:(id)value2
					 usingSelector:(SEL)selector {
	
	NSComparisonResult comparsonResult;
	if (value == [NSNull null]) {
		
		if (value2 == [NSNull null]) {
			comparsonResult = NSOrderedSame;
			
		} else {
			comparsonResult = NSOrderedAscending;
			
		}
	} else if (value2 == [NSNull null]) {
		
		comparsonResult = NSOrderedDescending;
		
	} else {
		if (selector == @selector(localizedCaseInsensitiveCompare:)) {
			comparsonResult = [value localizedCaseInsensitiveCompare:value2];
		} else if (selector == @selector(compareData:)) {
			if ([value respondsToSelector:@selector(compareData:)]) {
				comparsonResult = [value compareData:value2];
			} else if ([value respondsToSelector:@selector(localizedCaseInsensitiveCompare:)]) {
				comparsonResult = [value caseInsensitiveCompare:value2];
			} else {
				comparsonResult = [value compare:value2];
			}
		} else {
			comparsonResult = [value compare:value2];
		}
	}
	return comparsonResult;
}

- (void)clearReportLayoutContainers {
	[self.reportLayout removeAllObjects];
	[self.reportIndexes removeAllObjects];
	self.lastComparsonValues = nil;
}

- (void)cleanupTemporaryIndexes {
	[self.pageLayoutTemporary removeAllObjects];
	NSArray *pageIndexesTemporary = [[NSArray alloc] init];
	self.pageIndexesTemporary = pageIndexesTemporary;
}

#pragma mark -
#pragma mark Accessors

- (NSArray <MADSectionRepresentation *> *)layoutForPage:(NSUInteger)page {
	NSArray <MADSectionRepresentation *> *result;
	result = page < (NSUInteger)_reportLayout.count ? _reportLayout[page] : nil;
	return result;
}

- (void)setMarginUsingPrintableRect:(CGRect)printableRect {
	self.page.margins = MADEdgeInsetsPrinting(printableRect, self.page.layoutSize);
}

- (void)setLayoutSize:(CGSize)layoutSize {
	self.page.layoutSize = layoutSize;
}

- (NSUInteger)numberOfGroups {
	return self.sections.groupHeaders.count;
}

- (NSUInteger)numberOfPages {
	return (NSUInteger)self.reportLayout.count;
}

- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex {
	return _reportIndexes[pageIndex];
}

- (CGFloat)heightSection:(NSNumber *)objectID {
	NSNumber *sectionHeight = self.sections.heightForSectionID[objectID];
	return sectionHeight.floatValue;
}

- (NSString *)groupKeyAtIndex:(NSUInteger)index {
	return self.sections.groupSortDescriptors[index].key;
}

//  The keyed sibling of -newObjectArrayKeyValuesForResultRow: one entry per group
//  sort key, NSNull when the row has none.  Nothing in this tree calls it today;
//  the formatter compares levels positionally and uses the array form below.
- (NSDictionary <NSString *, MADResult *> *)newObjectDictionaryForResultRow:(id)resultRow {
	NSMutableDictionary *keyValues = [[NSMutableDictionary alloc] initWithCapacity:self.numberOfGroups];
	if ([resultRow isKindOfClass:[NSDictionary class]]) {
		id predicateValue;
		for (NSSortDescriptor *sortDesc in self.sections.groupSortDescriptors) {
			NSString *key = sortDesc.key;
			if (key) {
				predicateValue = resultRow[key];
				if (predicateValue != nil) {
					keyValues[key] = predicateValue;
				} else {
					keyValues[key] = [NSNull null];
				}
				predicateValue = nil;
			}
		}
	}
	return keyValues;
}

//  One value per query group, in group order (level 0 first): for each group sort
//  descriptor, the row's value at that key, or NSNull when the row has none.
//  This is the array -formatDocumentAddDetail compares across rows.
//
//  The element type is erased: `MADResult` is
//  NSObject <NSCopying, NSSecureCoding>, so the method says nothing about which
//  class a value is, and the values are deliberately not converted or tagged
//  here.  Each stays what the row cache produced, and the class is the only tag
//  the cache carries: NSNull, NSNumber, NSString or NSData.
//
//  -MADDocumentRenderDataSource -groupLevelKeys: calls this too and passes the
//  same values to the aggregate WHERE clause, so wrapping or coercing them would
//  change query results, not just the comparison.  A type tag must therefore
//  travel beside this array, not inside it.
- (NSArray <MADResult *> *)newObjectArrayKeyValuesForResultRow:(id)resultRow {
	NSMutableArray *keyValues = [[NSMutableArray alloc] initWithCapacity:self.numberOfGroups];
	if ([resultRow isKindOfClass:[NSDictionary class]]) {
		id predicateValue;
		for (NSSortDescriptor *sortDesc in self.sections.groupSortDescriptors) {
			NSString *key = sortDesc.key;
			if (key) {
				predicateValue = resultRow[key];
				if (predicateValue != nil) {
					[keyValues addObject:predicateValue];
				} else {
					[keyValues addObject:[NSNull null]];
				}
				predicateValue = nil;
			}
		}
	}
	return keyValues;
}

#pragma mark -
#pragma mark Reading cached data

- (BOOL)cachedIndexesExist {
	return _reportIndexes.count > 0 && _reportLayout.count > 0;
}

- (void)dropIndexes {
	[self.reportIndexes removeAllObjects];
	[self.reportLayout removeAllObjects];
}

- (void)loadLayoutAndIndexesFromCache {
	
	[self.reportIndexes finalizeDatabase];
	[self.reportLayout finalizeDatabase];
	
	id <MADCacheProtocol> cachedDelegate = self.cachedDelegate;
	
	NSString *nixarray = [self newStringNameCurrentReportIndexes: _page.layoutSize
														 andHash: (unsigned long)[self layoutIdentifier]];
	
	NSSet <Class> *ixClasses = [[NSSet alloc] initWithObjects: [NSArray class], [NSNumber class], nil];
	MADArrayCaching <NSArray <NSNumber *> *> *ixarray = [[MADArrayCaching alloc] initWithIdentifier: nixarray
																					 cachedDelegate: cachedDelegate
																							  types: ixClasses];
	[ixarray initializeDatabase];
	self.reportIndexes = ixarray;
	
	NSSet <Class> *nlClasses = [[NSSet alloc] initWithObjects:[NSArray class], [MADSectionRepresentation class], nil];
	NSString *nlyarray = [self newStringNameCurrentReportLayout: _page.layoutSize
														andHash: (unsigned long)[self layoutIdentifier]];
	MADArrayCaching *lyarray = [[MADArrayCaching alloc] initWithIdentifier: nlyarray
															cachedDelegate: cachedDelegate
																	 types:nlClasses];
	[lyarray initializeDatabase];
	self.reportLayout = lyarray;
	
	[self cleanupTemporaryIndexes];
	self.sections = nil;
}

- (void)loadFromCache:(CGSize)printableSize {
	self.didRefresh = NO;
	[self setLayoutSize: printableSize];
	[self loadLayoutAndIndexesFromCache];
}

#pragma mark -
#pragma mark Formatting

- (BOOL)needsFormat {
	id <MADReportFormatterDataSource> datasource = self.datasource;
	NSAssert(datasource != nil, @"We need a datatable way before here");
	BOOL didRefresh = self.didRefresh;
	BOOL cachesEmpty = (self.reportIndexes.count > 0 && self.reportLayout.count > 0) == NO;
	BOOL cacheMissing = ![datasource cacheExist];
	os_log_debug(OS_LOG_DEFAULT, "%s: didRefresh=%d cachesEmpty=%d cacheMissing=%d",
				 __PRETTY_FUNCTION__, didRefresh, cachesEmpty, cacheMissing);
	return didRefresh || cachesEmpty || cacheMissing;
}

- (void)format:(CGSize)printableSize {
	[self format:printableSize contentChanged:YES];
}

- (void)format:(CGSize)printableSize contentChanged:(BOOL)contextChanged {

	if (contextChanged == NO || self.needsFormat) {
		@synchronized(self) {
			[self setLayoutSize:printableSize];
			[self loadLayoutAndIndexesFromCache];
			BOOL needsFormatNow = self.needsFormat;
			os_log_debug(OS_LOG_DEFAULT, "%s: contextChanged=%d needsFormatNow=%d -> %@",
						 __PRETTY_FUNCTION__, contextChanged, needsFormatNow,
						 needsFormatNow ? @"formatDocument" : @"SKIP (no format)");
			if (needsFormatNow) {
				if (contextChanged) {
					[self dropIndexes];
				}
				[self formatDocument];
			}
		}
	} else {
		[self format:printableSize contentChanged:NO];
	}
}

- (MADSectionsLayout *)sections {
	if (_sections == nil) {
		id <MADDocumentRenderProtocol> layout = _layout;
		if (layout != nil) {
			MADDatabase *database = layout.database;
			MADSectionsLayout *sections;
			// The store context is the protocol's own (it used to be read through
			// -managedObjectContext, which only MADocument spells that way).
			sections = [[MADSectionsLayout alloc] initWithManagedObjectContext: layout.storeContext
																 databaseClass: [database class]];
			_sections = sections;
		}
	}
	return _sections;
}

- (void)formatDocument {

	os_log_debug(OS_LOG_DEFAULT, "%s: BEGIN", __PRETTY_FUNCTION__);
	id <MADDocumentRenderProtocol> layout = _layout;
	self.sections = nil;

	[layout resetSectionLayoutManagers];
	
	[self.machineState reset];
	self.machineState.cumulativePageHeight += self.page.margins.top;
	
	[self cleanupTemporaryIndexes];
	[self.reportIndexes beginBulkInserts];
	[self.reportLayout beginBulkInserts];
	
	[self formatDocumentAddReportHeader];
	[self formatDocumentAddPageHeader];
	[self formatDocumentAddDetail];
	[self formatDocumentAddReportFooter];
	
	NSArray <MADSectionRepresentation *> *tlfp = [[NSMutableArray alloc] initWithArray:self.pageLayoutTemporary];
	[self.reportLayout addObject:tlfp];
	
	NSArray <NSNumber *> *tdfp = [[NSArray alloc] initWithArray:self.pageIndexesTemporary];
	[self.reportIndexes addObject:tdfp];
	
	[self.reportLayout endBulkInserts];
	[self.reportIndexes endBulkInserts];

	[self cleanupTemporaryIndexes];
	os_log_debug(OS_LOG_DEFAULT, "%s: END pageCounter=%lu", __PRETTY_FUNCTION__,
				 (unsigned long)self.machineState.pageCounter);
}

//  The row loop, and where report groups are discovered.  Rows arrive already
//  sorted by the cache on the report's group keys.  For each row this builds
//  `keyValuesForComparson`, one raw cache value per query group in level order,
//  and compares it with `self.lastComparsonValues`, the previous row's array:
//    - a level that differs closes the group at that level (its footer), and the
//      walk runs deepest to shallowest;
//    - a level that differs opens a group at that level (its header), and the
//      walk runs shallowest to deepest.
//  The first row has no previous values and opens every level.  The same pair of
//  arrays is handed to both walks, so each level is compared twice per row (see
//  -compareValue:withValue:usingSelector:).  The loop can never see the last
//  group end, so after it every level's footer is laid out directly, with no
//  further comparison.
//
//  `resultRow` is either a dictionary of the group keys plus MADIdentifierROWID
//  (the sqlite cache's enumerator, which only projects the key columns) or, when
//  the query has no groups, a bare row-id NSNumber from the rowid-only
//  enumerator; `rowIdOnly` caches which form this report uses.
- (void)formatDocumentAddDetail {
	[self clearReportLayoutContainers];
	_machineState.rowCounter = 0;
	
	BOOL firstRow = YES, rowIdOnly = YES, calculatedRowId = NO;
	
	id lastResultRow = nil;
	
	NSEnumerator *enumeratorForReportData = [self.datasource enumeratorForReportData];
	NSArray *keyValuesForComparson;
	
	for (id resultRow in enumeratorForReportData) {
		
		// This `autoreleasepool` is important to prevent memory spike durning large page renders.
		//    without it, an 8k page report is spiking 100 MB after render.  With this, it runs
		//    smooth.  The core issue might be with `arrayByAddingObject:`.  It's intended as speed hack
		//    to do this with the array instead of using a mutable array, but it may be creating the issue,
		//    because the array may not be autoreleased until the loop finishes all report data.
		//    The `autoreleasepool` gives it a chance to get rid of that array, and other stuff, early.
		@autoreleasepool {
			
			//Get row id
			if (!calculatedRowId) {
				if ([resultRow isKindOfClass:[NSDictionary class]]) {
					rowIdOnly = NO;
				}
				calculatedRowId = YES;
			}
			
			self.machineState.detailRowIdLast = self.machineState.detailRowId;
			self.machineState.detailRowId = rowIdOnly ? ((NSNumber *)resultRow).unsignedIntegerValue :
			((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
			
			//Get row key values
			keyValuesForComparson = [self newObjectArrayKeyValuesForResultRow:resultRow];
			
			//Display new footers if needed.
			if (firstRow) {
				firstRow = NO;
			} else {
				[self formatDocumentGroupFooters: keyValuesForComparson
								   andLastValues: self.lastComparsonValues];
			}
			
			//Display new group headers if needed.
			[self formatDocumentGroupHeaders: keyValuesForComparson
							   andLastValues: self.lastComparsonValues];
			
			[self formatDocumentAddHeightFromSection: self.sections.detail];
			
			MADSectionRepresentation *detail = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeBody
																							  row: self.machineState.detailRowId];
			[self.pageLayoutTemporary addObject: detail];
			NSNumber *rowIDObject = @(self.machineState.detailRowId);
			self.pageIndexesTemporary = [self.pageIndexesTemporary arrayByAddingObject:rowIDObject];
			
			self.lastComparsonValues = keyValuesForComparson;
			
			self.machineState.rowCounter++;
		}
		lastResultRow = resultRow;
	}
	//Need to account for the last set of group footers.
	if (!lastResultRow) return;
	
	keyValuesForComparson = [self newObjectArrayKeyValuesForResultRow:lastResultRow];
	NSUInteger groupLevel = keyValuesForComparson.count;
	while (groupLevel >= 1) {
		MADSectionGroupLayout *section = self.sections.groupFooters[groupLevel - 1];
		[self formatDocumentAddHeightFromSection: section];
		[self layoutAddGroupFooterAtLevel:groupLevel-1 withRowId:self.machineState.detailRowId];//[self layoutAddGroupFooterAtLevel:groupLevel-1];
		groupLevel--;
	}
}

- (void)formatDocumentAddReportHeader {
	_machineState.cumulativePageHeight = _machineState.cumulativePageHeight + self.sections.reportHeader.displayHeight;
	[self layoutAddReportHeader];
}

- (void)formatDocumentAddPageHeader {
	_machineState.cumulativePageHeight = _machineState.cumulativePageHeight + self.sections.pageHeader.displayHeight;
	[self layoutAddPageHeader];
}

- (void)formatDocumentAddPageFooter {
	[self formatDocumentAddHeightFromSection:self.sections.pageFooter];
	[self layoutAddPageFooter];
}

- (void)formatDocumentAddReportFooter {
	[self formatDocumentAddHeightFromSection:self.sections.reportFooter];
	[self formatDocumentAddPageFooter];
	[self layoutAddReportFooter];
}

//  Close the groups that ended at this row.  The levels are walked deepest
//  first, so a footer is emitted inner before outer.  At each level the previous
//  row's value is compared with the current row's using that level's sort
//  selector; a difference means the group at that level closed.  Called for
//  every row except the first (which has no previous values).
- (void)formatDocumentGroupFooters:(NSArray *)currentValues
					 andLastValues:(NSArray *)lastValues {
	for (NSUInteger groupLevel = lastValues.count; groupLevel > 0; groupLevel--) {
		//@autoreleasepool {
		NSSortDescriptor *sortDesc = self.sections.groupSortDescriptors[groupLevel - 1];
		NSComparisonResult comparsonResult = [self compareValue: lastValues[groupLevel - 1]
													  withValue: currentValues[groupLevel - 1]
												  usingSelector: sortDesc.selector];
		
		if (comparsonResult != NSOrderedSame) {
			MADSectionGroupLayout *section = self.sections.groupFooters[groupLevel - 1];
			[self formatDocumentAddHeightFromSection: section];
			[self layoutAddGroupFooterAtLevel:groupLevel - 1 withRowId:self.machineState.detailRowIdLast];//[self layoutAddGroupFooterAtLevel:groupLevel - 1];
		}
		//}
	}
}

//  Open the groups that start at this row.  The levels are walked shallowest
//  first, so a header is emitted outer before inner.  With no previous row every
//  level is new; otherwise a level is new when its value differs from the
//  previous row's under that level's selector.  This is the same pair of arrays
//  and the same comparison the footer walk just made, at every level.
- (void)formatDocumentGroupHeaders:(NSArray *)currentValues
					 andLastValues:(NSArray *)lastValues {
	
	for (NSUInteger groupLevel = 0; groupLevel < currentValues.count; groupLevel++) {
		//@autoreleasepool {
		BOOL newHeader = lastValues.count == 0;
		if (newHeader == NO) {
			
			NSSortDescriptor *sortDesc = self.sections.groupSortDescriptors[groupLevel];
			newHeader = [self compareValue:lastValues[groupLevel]
								 withValue:currentValues[groupLevel]
							 usingSelector:sortDesc.selector] != NSOrderedSame;
		}
		
		if (newHeader) {
			MADSectionGroupLayout *layout = self.sections.groupHeaders[groupLevel];
			[self formatDocumentAddHeightFromSection:layout];
			[self layoutAddGroupHeaderLevel:groupLevel];
		}
		//}
	}
}

- (void)formatDocumentAddHeightFromSection:(__kindof MADSectionLayout *)section {
	if (section.producesFormFeed) {
		[self formatDocumentForcePageBreakWithFooterHeight: self.sections.pageFooter.displayHeight];
	} else {
		[self formatDocumentAddPageBreakWithNextItemHeight: section.displayHeight];
	}
	_machineState.cumulativePageHeight = _machineState.cumulativePageHeight + section.displayHeight;
}

- (BOOL)formatDocumentAddPageBreakWithNextItemHeight:(CGFloat)nextItemHeight {
	BOOL newPageCreated = NO;
	if (HeightWithNextItem(self.machineState.cumulativePageHeight,
						   nextItemHeight,
						   self.sections.pageFooter.displayHeight) > PrintableHeightForPage(self.page)) {
		
		newPageCreated = YES;
		[self formatDocumentForcePageBreakWithFooterHeight: self.sections.pageFooter.displayHeight];
	}
	
	return newPageCreated;
}

- (void)formatDocumentForcePageBreakWithFooterHeight:(CGFloat)footerHeight {
	
	_machineState.cumulativePageHeight = _machineState.cumulativePageHeight + footerHeight;
	[self layoutAddPageFooter];
	
	id pageInfo = self.pageLayoutTemporary != nil ?
	[[NSMutableArray alloc] initWithArray: self.pageLayoutTemporary] :
	[[NSArray alloc] init];
	
	[self.reportLayout addObject:pageInfo];
	
	if (self.pageIndexesTemporary != nil) {
		[self.reportIndexes addObject:self.pageIndexesTemporary];
	} else {
		NSArray *emptyArray = [[NSArray alloc] init];
		[self.reportIndexes addObject:emptyArray];
	}
	
	[self cleanupTemporaryIndexes];
	
	_machineState.pageCounter++;
	
	[[MADNotificationDidFormatPage sharedObject] reportFormatter: self
												   formattedPage: self.machineState.pageCounter];
	
	//Reset height of the page to zero plus the hight of the page header section
	_machineState.cumulativePageHeight = self.sections.pageHeader.displayHeight;
	[self layoutAddPageHeader];
}

- (void)layoutAddGroupHeaderLevel:(NSUInteger)groupLevel {
	MADSectionRepresentation *header = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeGroupHeader
																			   groupLevel: groupLevel
																					  row: _machineState.detailRowId];
	if (groupLevel == self.numberOfGroups - 1) {
		self.machineState.groupCounter++;
	}
	[self.pageLayoutTemporary addObject: header];
}

- (void)layoutAddGroupFooterAtLevel:(NSUInteger)groupLevel withRowId:(NSUInteger)rowId { //- (void)layoutAddGroupFooterAtLevel:(NSUInteger)groupLevel {
	MADSectionRepresentation *footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeGroupFooter
																			   groupLevel: groupLevel
																					  row: rowId];//row: _machineState.detailRowId];
	[self.pageLayoutTemporary addObject: footer];
}

- (void)layoutAddPageFooter {
	MADSectionRepresentation *footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypePageFooter
																					  row: _machineState.detailRowId];
	[self.pageLayoutTemporary addObject: footer];
}

- (void)layoutAddReportFooter {
	MADSectionRepresentation *footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeReportFooter
																					  row: _machineState.detailRowId];
	[self.pageLayoutTemporary addObject: footer];
}

- (void)layoutAddReportHeader {
	MADSectionRepresentation *obj  = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeReportHeader
																					row: _machineState.detailRowId];
	[self.pageLayoutTemporary addObject: obj];
}

- (void)layoutAddPageHeader {
	MADSectionRepresentation *obj = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypePageHeader
																				   row: _machineState.detailRowId];
	[self.pageLayoutTemporary addObject:  obj];
}

@end
