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
#import <MADFoundation/MADDataColumn.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADSqlite3/MADArrayCaching.h>
#import <MADSqlite3/MADDataTableFast.h>

#import <dispatch/dispatch.h>

#include <stdint.h>
#include <stdlib.h>

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

//  A level's comparison function: NULL never reaches one (the callers handle it
//  first, since NULL is first-class and type-independent), and the data type is
//  carried only for the fallback's log and assertion.
typedef NSComparisonResult (*MADGroupLevelComparator)(id value, id value2, MADDataType dataType);

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
//  +compareValue:withValue:forDataType: for how they are compared.
@property (nonatomic, readwrite, strong)    NSArray *lastComparsonValues;

//  The comparison type for each group level, resolved once per format from the
//  row cache's column (the schema field's type as fallback).  See -groupDataTypes.
@property (nonatomic, readwrite, strong)    NSArray <NSNumber *> *groupDataTypes;

@end

@implementation MADReportFormatter {
	NSUInteger _numberOfGroups;
	NSString *_filename;
	//  One comparator per group level, resolved once per format from the
	//  types -groupDataTypes resolves (the cache whose invalidation the
	//  table rides on), and the per-row changed flags both walks consume.
	MADGroupLevelComparator *_groupComparators;
	NSUInteger _groupComparatorsCount;
	uint8_t *_changedLevels;
	NSUInteger _changedLevelsCount;
}

- (void)dealloc {
	free(_groupComparators);
	free(_changedLevels);
}

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
//  ordered by the report's group keys, and +compareValue:withValue:forDataType:
//  answers only "is this level's key the same as the previous row's?".
//  -formatDocumentGroupFootersForChangedLevels:count: and
//  -formatDocumentGroupHeadersForChangedLevels:count:firstRow: use it to find
//  where a group ends and the next begins, and neither reads the ordering.  The
//  values are raw row-cache values: the sqlite reader maps storage class to NSNull, NSNumber,
//  NSString or NSData (+[MADDatabaseSqlite3 databaseResultValue:columnNumber:]),
//  and the bind path now stores one canonical class per declared type, so the
//  level's type and the values' classes agree on the healthy path.  See
//  BUGS.md, "MADReportFormatter compares untyped values through id".

//  The comparison family a level's declared type sorts under.  Must agree with
//  the cache's ORDER BY collation
//  (+[MADDatabaseSqlite3 sortDescriptionForColumnType:ascending:]) and with the
//  bind path's canonical classes (MADDatabaseDataBinding).
static BOOL MADDataTypeComparesAsString(MADDataType dataType) {
	switch (dataType) {
		case MADDataTypeString:
		case MADDataTypeVarChar:
		case MADDataTypeSet:
		case MADDataTypeYear:
		case MADDataTypeGeometry:
		case MADDataTypeUnknown:
			return YES;
		default:
			return NO;
	}
}

static BOOL MADDataTypeComparesAsData(MADDataType dataType) {
	return dataType == MADDataTypeBlob || dataType == MADDataTypeImage;
}

//  A total order over the reader's three typed classes, for a mixed pair from a
//  heterogeneous legacy column: same-class pairs compare by value, mixed pairs
//  order by class so homogeneous runs still group together instead of
//  collapsing into one group.
static NSUInteger MADComparisonClassRank(id value) {
	if ([value isKindOfClass:[NSNumber class]]) return 1;
	if ([value isKindOfClass:[NSString class]]) return 2;
	if ([value isKindOfClass:[NSData class]]) return 3;
	return 0;
}

//  One log line per (type, class) pair per process: a violation is worth hearing
//  about, not once per row.
static void MADComparisonLogViolation(MADDataType dataType, Class aClass, Class bClass) {
	static NSMutableSet *loggedViolations;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		loggedViolations = [[NSMutableSet alloc] init];
	});
	NSString *key = [[NSString alloc] initWithFormat:@"%d:%@:%@", (int)dataType, NSStringFromClass(aClass), NSStringFromClass(bClass)];
	@synchronized (loggedViolations) {
		if (![loggedViolations containsObject:key]) {
			[loggedViolations addObject:key];
			os_log_error(GetMadLog(), "%s: %@ and %@ values in a %@ level are not the level's canonical class; comparing by the safe fallback.",
						 __PRETTY_FUNCTION__, NSStringFromClass(aClass), NSStringFromClass(bClass), NSStringFromMADDataType(dataType));
		}
	}
}

//  The class-checked fallback for a pair outside the level's canonical class,
//  shared by every family so the legacy-pair semantics live in one place: the
//  bind path cannot produce this, but a pre-contract cache can -- and the reader
//  answers only NSNull, NSNumber, NSString and NSData, so any pair of the other
//  three is tolerated: logged once and compared by the safe class-checked
//  fallback, and an offline open of a pre-contract cache still formats.
//  Same-class pairs compare by value; mixed pairs order by class rank so
//  homogeneous runs in a heterogeneous legacy column still group together
//  instead of collapsing into one group; a class outside the reader's four
//  asserts in debug and answers Same in release.  See
//  +compareValue:withValue:forDataType:.
static NSComparisonResult MADComparisonFallback(id value, id value2, MADDataType dataType) {
	MADComparisonLogViolation(dataType, [value class], [value2 class]);

	BOOL valueIsKnown = [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSData class]];
	BOOL value2IsKnown = [value2 isKindOfClass:[NSString class]] || [value2 isKindOfClass:[NSNumber class]] || [value2 isKindOfClass:[NSData class]];
	if (valueIsKnown && value2IsKnown) {
		if ([value isKindOfClass:[NSString class]] && [value2 isKindOfClass:[NSString class]]) {
			return [(NSString *)value caseInsensitiveCompare:(NSString *)value2];
		}
		if ([value isKindOfClass:[NSNumber class]] && [value2 isKindOfClass:[NSNumber class]]) {
			return [(NSNumber *)value compare:(NSNumber *)value2];
		}
		if ([value isKindOfClass:[NSData class]] && [value2 isKindOfClass:[NSData class]]) {
			return [(NSData *)value compareData:(NSData *)value2];
		}
		NSUInteger valueRank = MADComparisonClassRank(value);
		NSUInteger value2Rank = MADComparisonClassRank(value2);
		return valueRank < value2Rank ? NSOrderedAscending : NSOrderedDescending;
	}
	NSCAssert(NO, @"A group key's class does not match its level's type: %@ and %@ in a %@ level.",
			  NSStringFromClass([value class]), NSStringFromClass([value2 class]), NSStringFromMADDataType(dataType));
	return NSOrderedSame;
}

//  The comparison families a level's declared type sorts under: the typed pair
//  on the fast path, the shared fallback for anything outside the level's
//  canonical class.
static NSComparisonResult MADCompareValuesAsString(id value, id value2, MADDataType dataType) {
	if ([value isKindOfClass:[NSString class]] && [value2 isKindOfClass:[NSString class]]) {
		return [(NSString *)value localizedCaseInsensitiveCompare:(NSString *)value2];
	}
	return MADComparisonFallback(value, value2, dataType);
}

static NSComparisonResult MADCompareValuesAsNumber(id value, id value2, MADDataType dataType) {
	if ([value isKindOfClass:[NSNumber class]] && [value2 isKindOfClass:[NSNumber class]]) {
		return [(NSNumber *)value compare:(NSNumber *)value2];
	}
	return MADComparisonFallback(value, value2, dataType);
}

static NSComparisonResult MADCompareValuesAsData(id value, id value2, MADDataType dataType) {
	if ([value isKindOfClass:[NSData class]] && [value2 isKindOfClass:[NSData class]]) {
		return [(NSData *)value compareData:(NSData *)value2];
	}
	return MADComparisonFallback(value, value2, dataType);
}

static MADGroupLevelComparator MADComparisonFunctionForDataType(MADDataType dataType) {
	if (MADDataTypeComparesAsString(dataType)) return MADCompareValuesAsString;
	if (MADDataTypeComparesAsData(dataType)) return MADCompareValuesAsData;
	return MADCompareValuesAsNumber;
}

+ (NSComparisonResult)compareValue:(id)value
						 withValue:(id)value2
					   forDataType:(MADDataType)dataType {

	//  NULL is first-class: NSNull implements no comparison, and a NULL key sits
	//  below every real one -- the same place the cache's ORDER BY puts it.
	if (value == [NSNull null]) {
		return (value2 == [NSNull null]) ? NSOrderedSame : NSOrderedAscending;
	}
	if (value2 == [NSNull null]) {
		return NSOrderedDescending;
	}

	//  The one-per-call form: resolve the level's family and compare through it.
	//  The row loop resolves each family once per format instead (-groupDataTypes)
	//  and calls it through the stored pointer; both routes share the families,
	//  the fallback, and the log-once rule.
	return MADComparisonFunctionForDataType(dataType)(value, value2, dataType);
}

//  The comparison type for each group level, resolved once per format: the row
//  cache column's own MADDataType, with the schema field's as the fallback for a
//  cache that has no column to consult.  The cache's is the type the bind path
//  stores under, so it is the one the values' classes agree with (BUGS.md).
- (NSArray <NSNumber *> *)groupDataTypes {
	if (_groupDataTypes == nil) {
		NSArray <NSSortDescriptor *> *sortDescriptors = self.sections.groupSortDescriptors;
		NSMutableArray <NSNumber *> *dataTypes = [[NSMutableArray alloc] initWithCapacity:sortDescriptors.count];
		NSDictionary <NSString *, MADDataColumn *> *columns = self.layout.dataTable.columns;
		NSUInteger groupLevel = 0;
		for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
			MADDataType dataType = MADDataTypeUnknown;
			BOOL found = NO;
			for (MADDataColumn *column in columns.allValues) {
				if ([column.fieldName isEqualToString:sortDescriptor.key] ||
					[column.identifier isEqualToString:sortDescriptor.key]) {
					dataType = column.type;
					found = YES;
					break;
				}
			}
			// Only a column the cache does not hold falls back to the schema
			// type: a present column keeps its own type, Unknown included,
			// because that is what the bind path stored under.
			if (!found) {
				dataType = self.sections.groupHeaders[groupLevel].dataType;
			}
			[dataTypes addObject:@(dataType)];
			groupLevel++;
		}
		_groupDataTypes = dataTypes;

		//  One comparator per level, resolved from the same types: the walks
		//  compare through these pointers, so a format pays the family dispatch
		//  once per level instead of once per comparison.
		NSUInteger levelCount = dataTypes.count;
		if (_groupComparatorsCount != levelCount) {
			free(_groupComparators);
			_groupComparators = levelCount == 0 ? NULL : malloc(sizeof(MADGroupLevelComparator) * levelCount);
			_groupComparatorsCount = levelCount;
		}
		for (NSUInteger level = 0; level < levelCount; level++) {
			_groupComparators[level] = MADComparisonFunctionForDataType((MADDataType)[dataTypes[level] shortValue]);
		}
	}
	return _groupDataTypes;
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
	self.groupDataTypes = nil;
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
	self.groupDataTypes = nil;

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
//  and compares each level once with `self.lastComparsonValues`, the previous
//  row's array, storing a changed flag per level:
//    - the footer walk consumes the flags deepest to shallowest, closing the
//      groups that ended at this row;
//    - the header walk consumes them shallowest to deepest, opening the groups
//      that start at this row.
//  The first row has no previous values: no footers, and every level opens.
//  Each level was once compared by each walk separately, twice per row; the
//  flags compare it once (see +compareValue:withValue:forDataType:).  The loop
//  can never see the last group end, so after it every level's footer is laid
//  out directly, with no further comparison.
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

	//  The per-level comparison types and comparators, resolved once per format;
	//  the row loop compares through the stored pointers.
	NSArray <NSNumber *> *groupDataTypes = self.groupDataTypes;

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

			//  One comparison per level for this row, and one changed flag each;
			//  the footer and header walks below both consume the same flags.
			//  NULL stays first-class: a NULL key sorts below every real one, so
			//  any non-equal NULL pair has changed.
			NSUInteger groupLevelCount = keyValuesForComparson.count;
			if (_changedLevelsCount != groupLevelCount) {
				free(_changedLevels);
				_changedLevels = groupLevelCount == 0 ? NULL : malloc(sizeof(uint8_t) * groupLevelCount);
				_changedLevelsCount = groupLevelCount;
			}

			BOOL firstRowNow = firstRow;
			if (firstRowNow) {
				firstRow = NO;
			} else {
				NSArray *lastValues = self.lastComparsonValues;
				for (NSUInteger groupLevel = 0; groupLevel < groupLevelCount; groupLevel++) {
					id lastValue = lastValues[groupLevel];
					id currentValue = keyValuesForComparson[groupLevel];
					BOOL changed;
					if (lastValue == [NSNull null]) {
						changed = currentValue != [NSNull null];
					} else if (currentValue == [NSNull null]) {
						changed = YES;
					} else {
						changed = _groupComparators[groupLevel](lastValue, currentValue, (MADDataType)groupDataTypes[groupLevel].shortValue) != NSOrderedSame;
					}
					_changedLevels[groupLevel] = changed;
				}

				//Display new footers if needed.
				[self formatDocumentGroupFootersForChangedLevels: _changedLevels
															count: groupLevelCount];
			}

			//Display new group headers if needed.
			[self formatDocumentGroupHeadersForChangedLevels: _changedLevels
														count: groupLevelCount
													 firstRow: firstRowNow];
			
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
//  first, so a footer is emitted inner before outer; each flag was set by the
//  row loop's one comparison per level.  Called for every row except the first
//  (which has no previous values).
- (void)formatDocumentGroupFootersForChangedLevels:(const uint8_t *)changedLevels
											 count:(NSUInteger)levelCount {
	for (NSUInteger groupLevel = levelCount; groupLevel > 0; groupLevel--) {
		if (changedLevels[groupLevel - 1]) {
			MADSectionGroupLayout *section = self.sections.groupFooters[groupLevel - 1];
			[self formatDocumentAddHeightFromSection: section];
			[self layoutAddGroupFooterAtLevel:groupLevel - 1 withRowId:self.machineState.detailRowIdLast];//[self layoutAddGroupFooterAtLevel:groupLevel - 1];
		}
	}
}

//  Open the groups that start at this row.  The levels are walked shallowest
//  first, so a header is emitted outer before inner.  With no previous row every
//  level is new; otherwise a level is new when its flag is set.
- (void)formatDocumentGroupHeadersForChangedLevels:(const uint8_t *)changedLevels
											 count:(NSUInteger)levelCount
										  firstRow:(BOOL)firstRow {
	for (NSUInteger groupLevel = 0; groupLevel < levelCount; groupLevel++) {
		BOOL newHeader = firstRow || changedLevels[groupLevel];
		if (newHeader) {
			MADSectionGroupLayout *layout = self.sections.groupHeaders[groupLevel];
			[self formatDocumentAddHeightFromSection:layout];
			[self layoutAddGroupHeaderLevel:groupLevel];
		}
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
