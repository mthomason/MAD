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
#import "MADocument.h"
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
#import "madlog.h"

#import <MADAPI/MADAliases.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import <MADFoundation/NSData+Comparison.h>
#import <MADFoundation/MADDataType.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADSqlite3/MADArrayCaching.h>

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectModel.h>
#import <CoreData/NSPropertyDescription.h>
#import <CoreData/NSEntityDescription.h>

#import <UIKit/UIPrintInteractionController.h>

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

@property (nonatomic, readwrite, weak)      MADocument *layout;
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

@property (nonatomic, readwrite, strong)    NSArray *lastComparsonValues;

@end

@implementation MADReportFormatter {
	NSUInteger _numberOfGroups;
	NSString *_filename;
}

- (void)dealloc { }

- (instancetype)initWithDocument: (MADocument *)layout
						 options: (MADReportFormatterOptions)options  {
	if (self = [super init]) {
		
		self.cachedDelegate = layout;
		self.dataDelegate = layout;
		self.datasource = layout;
		self.layout = layout;
		
		/*for (NSString *entityName in layout.managedObjectModel.entitiesByName) {
			NSEntityDescription *entityDescription = layout.managedObjectModel.entitiesByName[entityName];
			NSLog(@"%@\n%@\n\n", entityName, entityDescription);
			for (NSPropertyDescription *propertyDescription in entityDescription.properties) {
				NSLog(@"Property: %@", propertyDescription);
			}
		}*/
		
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

+ (instancetype)newReportFormatterWithLayout: (MADocument *)layout
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
	return self.didRefresh || (self.reportIndexes.count > 0 && self.reportLayout.count > 0) == NO || ![datasource cacheExist];
}

- (void)format:(CGSize)printableSize {
	[self format:printableSize contentChanged:YES];
}

- (void)format:(CGSize)printableSize contentChanged:(BOOL)contextChanged {

	if (contextChanged == NO || self.needsFormat) {
		@synchronized(self) {
			[self setLayoutSize:printableSize];
			[self loadLayoutAndIndexesFromCache];
			if (self.needsFormat) {
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
		MADocument *layout = _layout;
		if (layout != nil) {
			MADDatabase *database = layout.database;
			MADSectionsLayout *sections;
			sections = [[MADSectionsLayout alloc] initWithManagedObjectContext: layout.managedObjectContext
																 databaseClass: [database class]];
			_sections = sections;
		}
	}
	return _sections;
}

- (void)formatDocument {
	
	MADocument *layout = _layout;
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
	
}

- (void)formatDocumentAddDetail {
	[self clearReportLayoutContainers];
	_machineState.rowCounter = 0;
	
	BOOL firstRow = YES, rowIdOnly = YES, calculatedRowId = NO;

	id lastResultRow = nil;

	NSEnumerator *enumeratorForReportData = [self.datasource enumeratorForReportData];
	NSArray *keyValuesForComparson;
	
	for (id resultRow in enumeratorForReportData) {
		
		//@autoreleasepool {
		
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
		
		//}
		lastResultRow = resultRow;
	}
	//Need to account for the last set of group footers.
	if (!lastResultRow) return;
		
	keyValuesForComparson = [self newObjectArrayKeyValuesForResultRow:lastResultRow];
	NSUInteger groupLevel = keyValuesForComparson.count;
	while (groupLevel >= 1) {
		//@autoreleasepool {
			NSLog(@"Group: %@", self.sections.groupFooters[groupLevel - 1]);
			MADSectionGroupLayout *section = self.sections.groupFooters[groupLevel - 1];
			[self formatDocumentAddHeightFromSection: section];
			[self layoutAddGroupFooterAtLevel:groupLevel-1];
		//}
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
				[self layoutAddGroupFooterAtLevel:groupLevel - 1];
			}
		//}
	}
}

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

- (void)layoutAddGroupFooterAtLevel:(NSUInteger)groupLevel {
	MADSectionRepresentation *footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeGroupFooter
																			   groupLevel: groupLevel
																					  row: _machineState.detailRowId];
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
