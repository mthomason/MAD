//
//  MADReportFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportFormatter.h"
#import <UIKit/UIPrintInteractionController.h>
#import <CoreData/NSManagedObjectID.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADReportFormatterDataSourceProtocol.h"

#import "MADSectionRepresentation.h"

#import "MADReportFormatterState.h"
#import "MADocument.h"

#import "MADModel.h"
#import "MADModelDocument.h"
#import "MADModelDatabase.h"

#import "MTQueryFull.h"

#import "RptqDocument+Extras.h"

#import "RptqQueryGroup.h"

#import "RptqQuery+Extras.h"

#import "RptqDocumentSection+Extras.h"

#import "MTDatabaseField.h"

#import "MADReportFormatterCache.h"

#import "MADArrayCaching.h"

#import "MADNotificationDidFormatPage.h"
#import "MADPageOptions.h"

#import "NSData+Comparson.h"

#import "MADSectionRepresentation.h"

static inline UIEdgeInsets MADEdgeInsetsQuarterInch();
static inline UIEdgeInsets MADEdgeInsetsQuarterInch() {
    return UIEdgeInsetsMake(fCGPointsForInches(1.0/4.0),
                            fCGPointsForInches(1.0/4.0),
                            fCGPointsForInches(1.0/4.0),
                            fCGPointsForInches(1.0/4.0));
}

static inline UIEdgeInsets MADEdgeInsetsEmpty();
static inline UIEdgeInsets MADEdgeInsetsEmpty() {
    return UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.height,
                            CGSizeZero.height, CGSizeZero.height);
}

static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect, CGSize);
static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect printableRect, CGSize layoutSize) {
    return UIEdgeInsetsMake(printableRect.origin.y, printableRect.origin.x,
                            layoutSize.height - printableRect.size.height - printableRect.origin.y,
                            layoutSize.width - printableRect.size.width - printableRect.origin.x);
}

static inline CGFloat PrintableHeightForPage(MADPageOptions *);
static inline CGFloat PrintableHeightForPage(MADPageOptions *page) {
    return page.layoutSize.height - page.margins.top - page.margins.bottom;
}

static inline CGFloat HeightWithNextItem(CGFloat, CGFloat, CGFloat);
static inline CGFloat HeightWithNextItem(CGFloat heightUsedCurrentPage, CGFloat
                                         nextItemHeight, CGFloat pageFooterHeight) {
    return heightUsedCurrentPage + nextItemHeight + pageFooterHeight;
}

typedef NSMutableArray  <__kindof MADSectionRepresentation *> MADMutableSectionArray;
typedef NSMutableArray  <__kindof NSNumber *>                 MADMutableIndexArray;

typedef NSDictionary    <NSManagedObjectID *, NSNumber *>     MADNumberMapByObjectID;

typedef NSDictionary    <NSString *, NSNumber *>              MADStringNumberMap;

@interface MADReportFormatter ()

    @property (nonatomic, readwrite, weak)      MADocument *layout;
    @property (nonatomic, readwrite, assign)    MADReportFormatterOptions options;

    @property (nonatomic, readwrite, strong)    MADPageOptions *page;

    //  These are the rowids by page.  These point to data in the cache.
    //      Once these arrays are populated, they are used by the print page render to
    //      draw the report.
    //
    @property (nonatomic, readwrite, strong)    MADCachingIndexes *reportIndexes;
    @property (nonatomic, readwrite, strong)    MADCachingLayout *reportLayout;

    @property (nonatomic, readwrite, strong)    MADReportFormatterState *machineState;
    @property (nonatomic, readwrite, strong)    MADReportFormatterCache *reportFormatterCache;

    @property (nonatomic, readwrite, strong)    MADMutableSectionArray *pageLayoutTemporary;
    @property (nonatomic, readwrite, strong)    MADMutableIndexArray *pageIndexesTemporary;

    @property (nonatomic, readwrite, strong)    MADObjectArray      *lastComparsonValues;
    @property (nonatomic, readwrite, strong)    MADNumberMapByObjectID  *layoutHeightsBySectionKey;
    @property (nonatomic, readwrite, strong)    NSArray <RptqQueryGroup *> *sortedQueryGroups;

@end

@implementation MADReportFormatter {
    NSString *_filename;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithDocument: (MADocument *)layout
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
        MADEdgeInsetsQuarterInch() : MADEdgeInsetsEmpty();
        
        MADReportFormatterState *machineState = [[MADReportFormatterState alloc] init];
        self.machineState = machineState;
        
        [self initializeStateMachine];
        
        MADReportFormatterCache *reportFormatterCache = [[MADReportFormatterCache alloc] init];
        self.reportFormatterCache = reportFormatterCache;
        
        MADMutableSectionArray *temporaryLayoutForPage = [[MADMutableSectionArray alloc] init];
        self.pageLayoutTemporary = temporaryLayoutForPage;
        
        NSMutableArray *temporaryDataForPage = [[NSMutableArray alloc] init];
        self.pageIndexesTemporary = temporaryDataForPage;
        
        MADNumberMapByObjectID *layoutHeightsBySectionKeys = [layout layoutHeightsBySectionKey];
        self.layoutHeightsBySectionKey = layoutHeightsBySectionKeys;
    
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

#pragma mark - Accessors

- (MADSectionArray *)layoutForPage:(NSUInteger)page {
    MADSectionArray *result = page < (NSUInteger)_reportLayout.count ?
                                                _reportLayout[page] : nil;
    return result;
}

- (NSUInteger)layoutIdentifier {
    return _overrideIdentifier == nil ?
                    _filename.hash :
                    _overrideIdentifier.hash;
}

- (NSString *)newStringNameCurrentReportIndexes:(CGSize)size andHash:(unsigned long)hash {
    NSString *sizeString = NSStringFromCGSize(_page.layoutSize);
    NSString *name;
    name = [[NSString alloc] initWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier],
                                                        "ih", sizeString];
    return name;
}

- (NSString *)newStringNameCurrentReportLayout:(CGSize)size andHash:(unsigned long)hash {
    NSString *sizeString = NSStringFromCGSize(_page.layoutSize);
    NSString *name;
    name = [[NSString alloc] initWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier],
                                                        "lh", sizeString];
    return name;
}

- (void)initializeStateMachine {
    NSArray *sd = [self.dataDelegate sortDescriptors];
    NSArray *sortDescriptors = [[NSArray alloc] initWithArray:sd];
    
    _machineState.rowCounter = 0;
    _machineState.groupCounter = 0;
    _machineState.pageCounter = 0;
    _machineState.detailRowId = 0;
    _machineState.detailRowIdLast = 0;
    _machineState.sortDescriptors = sortDescriptors;
    _machineState.counterHeightUsedCurrentPage = CGSizeZero.height;
    _machineState.document = (self.layout).activeDocumentModel;
}

- (void)setMarginUsingPrintableRect:(CGRect)printableRect {
    self.page.margins = MADEdgeInsetsPrinting(printableRect, self.page.layoutSize);
}

#pragma mark - Reading cached data

- (BOOL)cachedIndexesExist {
    return _reportIndexes.count > 0 && _reportLayout.count > 0;
}

- (BOOL)needsFormat {
    id <MADReportFormatterDataSource> datasource = self.datasource;
    NSAssert(datasource != nil, @"We need a datatable way before here");
    return self.didRefresh ||
            (self.reportIndexes.count > 0 && self.reportLayout.count > 0) == NO ||
                ![datasource cacheExist];
}

- (void)formatForSize:(CGSize)printableSize {
    [self formatForSize:printableSize contentChanged:YES];
}

- (void)setLayoutSize:(CGSize)layoutSize {
    self.page.layoutSize = layoutSize;
}

- (void)loadFromCacheWithSize:(CGSize)printableSize {
    self.didRefresh = NO;
    self.page.layoutSize = printableSize;
    [self loadLayoutAndIndexesFromCache];
}

- (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged {

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
        [self formatForSize:printableSize contentChanged:NO];
    }
}

- (void)formatDocument {

    MADocument *layout = _layout;

    [self.machineState resetWithDocument:(layout).activeDocumentModel
                         andDataDelegate:self.dataDelegate];

    NSLog(@"%s", __PRETTY_FUNCTION__);
    [layout resetSectionLayoutManagers];
    
    self.machineState.counterHeightUsedCurrentPage += self.page.margins.top;

    MADNumberMapByObjectID *layoutHeightsBySectionKeys;
    layoutHeightsBySectionKeys = [layout layoutHeightsBySectionKey];
    
    self.layoutHeightsBySectionKey = layoutHeightsBySectionKeys;
    [self cleanupTemporaryIndexes];
    
    [self beginBulkInserts];
    
    [self addReportHeaderToReportLayout];
    [self addPageHeaderToReportLayout];
    [self addDetailToReportLayout];
    [self addReportFooterToReportLayout];
    
    MADSectionArray *tlfp = [MADMutableSectionArray arrayWithArray:self.pageLayoutTemporary];
    [self.reportLayout addObject:tlfp];
    
    MADIndexArray *tdfp = [MADIndexArray arrayWithArray:self.pageIndexesTemporary];
    [self.reportIndexes addObject:tdfp];
    
    [self endBulkInserts];
    
    [self cleanupTemporaryIndexes];
    
    // FIXME: This cache is being set, but it is not being loaded.
    [self.reportFormatterCache setLayout: self.reportLayout.identifier
                              andIndexes: self.reportIndexes.identifier
                                 forSize: self.page.layoutSize];
    
}

- (void)dropIndexes {
    [self.reportIndexes removeAllObjects];
    [self.reportLayout removeAllObjects];
}

- (void)dumpCache {
    [self.reportFormatterCache dumpCache];
}

- (void)beginBulkInserts {
    [self.reportIndexes beginBulkInserts];
    [self.reportLayout beginBulkInserts];
}

- (void)endBulkInserts {
    [self.reportLayout endBulkInserts];
    [self.reportIndexes endBulkInserts];
}

- (void)loadLayoutAndIndexesFromCache {

    [self.reportIndexes finalizeDatabase];
    [self.reportLayout finalizeDatabase];

    id <MTCacheProtocol> cachedDelegate = self.cachedDelegate;
    
    NSString *nixarray;
    nixarray = [self newStringNameCurrentReportIndexes: _page.layoutSize
                                               andHash: (unsigned long)[self layoutIdentifier]];

    MADArrayCaching *ixarray;
    ixarray = [[MADArrayCaching alloc] initWithIdentifier: nixarray
                                           cachedDelegate: cachedDelegate];
    [ixarray initializeDatabase];
    
    self.reportIndexes = ixarray;
    
    NSString *nlyarray;
    nlyarray = [self newStringNameCurrentReportLayout: _page.layoutSize
                                              andHash: (unsigned long)[self layoutIdentifier]];
    
    MADArrayCaching *lyarray = [[MADArrayCaching alloc] initWithIdentifier: nlyarray
                                                            cachedDelegate: cachedDelegate];
    [lyarray initializeDatabase];
    self.reportLayout = lyarray;
    
    [self cleanupTemporaryIndexes];
}

- (void)initReportLayoutContainers {
    [self.reportLayout removeAllObjects];
    [self.reportIndexes removeAllObjects];
    self.lastComparsonValues = nil;
}

- (void)cleanupTemporaryIndexes {
    [_pageLayoutTemporary removeAllObjects];
    [_pageIndexesTemporary removeAllObjects];
}

- (NSUInteger)numberOfGroups {
    return self.machineState.sortDescriptors.count;
}

- (void)displayNewGroupFootersIfNeeded:(NSArray *)currentValues
                         andLastValues:(NSArray *)lastValues {
    for (NSUInteger groupLevel = lastValues.count; groupLevel > 0; groupLevel--) {
        @autoreleasepool {
            NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel - 1];
            NSComparisonResult comparsonResult = [self compareValue: lastValues[groupLevel - 1]
                                                          withValue: currentValues[groupLevel - 1]
                                                      usingSelector: sortDesc.selector];
            
            if (comparsonResult != NSOrderedSame) {
                RptqQueryGroup *group = self.sortedQueryGroups[groupLevel - 1];
                [self addHeightFromGroupFooterWithQueryGroup: group];
                [self addGroupFooterAtLevel:groupLevel - 1];
            }
        }
    }
}

- (void)displayNewGroupHeadersIfNeeded:(NSArray *)currentValues
                         andLastValues:(NSArray *)lastValues {

    for (NSUInteger groupLevel = 0; groupLevel < currentValues.count; groupLevel++) {
        @autoreleasepool {
            BOOL newHeader = lastValues.count == 0;
            if (newHeader == NO) {
                
                id value = lastValues[groupLevel];
                id value2 = currentValues[groupLevel];
                
                NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel];
                NSComparisonResult comparsonResult = [self compareValue:value
                                                              withValue:value2
                                                          usingSelector:sortDesc.selector];
                
                newHeader = comparsonResult != NSOrderedSame;
            }
            
            if (newHeader) {
                RptqQueryGroup *gh = self.sortedQueryGroups[groupLevel];
                [self addHeightFromGroupHeaderWithQueryGroup: gh];
                [self addGroupHeaderLevel:groupLevel];
            }
        }
    }
}

- (NSComparisonResult)compareValue:(id)value withValue:(id)value2 usingSelector:(SEL)selector {
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

- (MADIndexArray *)rowidsForPage:(NSUInteger)pageIndex {
    return _reportIndexes[pageIndex];
}

/*- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails {
    for (NSInteger i=0; i<[containerDetails count]; i++) {
        @autoreleasepool {
            [self addHeightFromDocumentSectionToReportLayout: self.layout.document.hasDetailSection];
            NSNumber *rowid = containerDetails[i][MADIdentifierROWID];
            self.machineState.detailRowId = rowid;
            [self addDetail];

        }
    }
}*/

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupHeaderWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in queryGroup.hasSection.allObjects) {
        @autoreleasepool {
            if (documentSection.type == MADDocumentSectionTypeGroupHeader) {
                [self addHeightFromDocumentSectionToReportLayout:documentSection.objectID
                                                producesFormFeed:documentSection.producesFormFeed];
                break;
            }
        }
    }
}

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupFooterWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in queryGroup.hasSection.allObjects) {
        @autoreleasepool {
            if (documentSection.type == MADDocumentSectionTypeGroupFooter) {
                [self addHeightFromDocumentSectionToReportLayout:documentSection.objectID
                                                producesFormFeed:documentSection.producesFormFeed];
                break;
            }
        }
    }
}

//  ObjectID from RptqDocumentSection *
- (CGFloat)heightForSectionWithObjectID:(NSManagedObjectID *)objectID {
    NSNumber *sectionHeight = _layoutHeightsBySectionKey[objectID];
    return sectionHeight.floatValue;
}

- (void)addHeightFromDocumentSectionToReportLayout:(NSManagedObjectID *)objectID
                                  producesFormFeed:(BOOL)producesFormFeed {
    CGFloat layoutHeight = [self heightForSectionWithObjectID:objectID];
    if (producesFormFeed) {
        [self forcePageBreakWithFooterHeight:
         [self heightForSectionWithObjectID: _machineState.document.hasPageFooterSection.objectID]
         ];
    } else {
        [self addPageBreakToReportLayoutWithNextItemHeight: layoutHeight];
    }
    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage + layoutHeight;
}

- (RptqQueryGroup *)sortGroupAtLevel:(NSUInteger)level {
    RptqQueryGroup *nextGroup = nil;
    if (level < self.sortedQueryGroups.count) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == %d", level];
        NSArray *filteredGroups = [self.sortedQueryGroups filteredArrayUsingPredicate: predicate];
        if (filteredGroups.count >= 1) {
            nextGroup = filteredGroups.firstObject;
        }
    }
    return nextGroup;
}

- (void)addDetailToReportLayout {
    [self initReportLayoutContainers];
    _machineState.rowCounter = 0;
    
    RptqDocumentSection *detailSection = self.machineState.document.hasDetailSection;
    
    BOOL firstRow = YES;
    
    NSArray *sortedQueryGroups = [self.layout.mainQuery.queryObject sortedQueryGroups];
    self.sortedQueryGroups = sortedQueryGroups.copy;
    
    BOOL rowIdOnly = YES;
    BOOL calculatedRowId = NO;

    id lastResultRow = nil;

    NSEnumerator *enumeratorForReportData = [self.datasource enumeratorForReportData];
    MADObjectArray *keyValuesForComparson;
    
    for (id resultRow in enumeratorForReportData) {

        @autoreleasepool {
            
            //Get row id
            if (!calculatedRowId) {
                if ([resultRow isKindOfClass:[NSDictionary class]]) {
                    rowIdOnly = NO;
                }
                calculatedRowId = YES;
            }
            
            self.machineState.detailRowIdLast = self.machineState.detailRowId;
            
            self.machineState.detailRowId = rowIdOnly ? ((NSNumber *)resultRow).unsignedIntegerValue : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
            
            //Get row key values
            keyValuesForComparson = [self newObjectArrayKeyValuesForResultRow:resultRow];
            
            //Display new footers if needed.
            if (firstRow) {
                firstRow = NO;
            } else {
                [self displayNewGroupFootersIfNeeded: keyValuesForComparson
                                       andLastValues: self.lastComparsonValues];
            }
            
            //Display new group headers if needed.
            [self displayNewGroupHeadersIfNeeded: keyValuesForComparson
                                   andLastValues: self.lastComparsonValues];
            
            [self addHeightFromDocumentSectionToReportLayout: detailSection.objectID
                                            producesFormFeed: detailSection.producesFormFeed];
            
            [MADReportFormatter addDetailForRowID:self.machineState.detailRowId
                                      pageLayout:self.pageLayoutTemporary
                                     pageIndexes:self.pageIndexesTemporary];
            
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
        @autoreleasepool {
            RptqQueryGroup *group = _sortedQueryGroups[groupLevel - 1];
            [self addHeightFromGroupFooterWithQueryGroup: group];
            [self addGroupFooterAtLevel:groupLevel-1];
        }
        groupLevel--;
    }
}

- (MADObjectArray *)newObjectArrayKeyValuesForResultRow:(id)resultRow {


    NSMutableArray *keyValues;
    keyValues = [[NSMutableArray alloc] initWithCapacity:self.numberOfGroups];
    
    if ([resultRow isKindOfClass:[NSDictionary class]]) {

        id predicateValue;
        for (NSSortDescriptor *sortDesc in self.machineState.sortDescriptors) {
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

// FIXME: Make sure paper rect is passed in to the software
- (BOOL)addPageBreakToReportLayoutWithNextItemHeight:(CGFloat)nextItemHeight {
    
    BOOL newPageCreated = NO;
    
    CGFloat pageFooterSectionHeight = [self heightForSectionWithObjectID:self.machineState.document.hasPageFooterSection.objectID];
    
    if (HeightWithNextItem(self.machineState.counterHeightUsedCurrentPage, nextItemHeight, pageFooterSectionHeight) >
        PrintableHeightForPage(self.page)) {
        
        newPageCreated = YES;
        [self forcePageBreakWithFooterHeight:pageFooterSectionHeight];
    }

    return newPageCreated;
}

- (void)forcePageBreakWithFooterHeight:(CGFloat)footerHeight {

    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage +
                                                 footerHeight;
    [self addPageFooter];
    
    id pageInfo = self.pageLayoutTemporary != nil ?
                            [MADMutableSectionArray arrayWithArray: self.pageLayoutTemporary] :
                            [[NSArray alloc] init];
    
    [self.reportLayout addObject:pageInfo];
    
    MADIndexArray *rowids = self.pageIndexesTemporary != nil ?
                                [MADIndexArray arrayWithArray: self.pageIndexesTemporary] : @[];
    [self.reportIndexes addObject:rowids];
    
    [self cleanupTemporaryIndexes];
    
    _machineState.pageCounter++;
    
    [[MADNotificationDidFormatPage sharedObject] reportFormatter: self
                                                   formattedPage: self.machineState.pageCounter];
    
    RptqDocumentSection *pageHeaderSection = (self.machineState.document).hasPageHeaderSection;
    
    //Reset height of the page to zero plus the hight of the page header section
    _machineState.counterHeightUsedCurrentPage = [self heightForSectionWithObjectID:pageHeaderSection.objectID];
    
    [self addPageHeader];
}

- (void)addReportHeaderToReportLayout {
    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage +
                                                        [self heightForSectionWithObjectID: _machineState.document.hasReportHeaderSection.objectID];
    [self addReportHeader];
}

- (void)addPageHeaderToReportLayout {
    CGFloat heightForSection = [self heightForSectionWithObjectID: _machineState.document.hasPageHeaderSection.objectID];
    _machineState.counterHeightUsedCurrentPage = _machineState.counterHeightUsedCurrentPage + heightForSection;
    [self addPageHeader];
}

- (void)addPageFooterToReportLayout {
    [self addHeightFromDocumentSectionToReportLayout: _machineState.document.hasPageFooterSection.objectID
                                    producesFormFeed: _machineState.document.hasPageFooterSection.producesFormFeed];
    [self addPageFooter];
}

- (void)addReportFooterToReportLayout {
    [self addHeightFromDocumentSectionToReportLayout: _machineState.document.hasReportFooterSection.objectID
                                    producesFormFeed: _machineState.document.hasReportFooterSection.producesFormFeed];
    [self addPageFooterToReportLayout];
    [self addReportFooter];
}

- (void)addGroupHeaderLevel:(NSUInteger)groupLevel {
    MADSectionRepresentation *header;
    header = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeGroupHeader
                                                     groupLevel: groupLevel
                                                            row: _machineState.detailRowId];
    if (groupLevel == self.numberOfGroups - 1) {
        self.machineState.groupCounter++;
    }
    [self.pageLayoutTemporary addObject: header];
}

- (void)addPageFooter {
    MADSectionRepresentation *footer;
    footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypePageFooter
                                                            row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addReportFooter {
    MADSectionRepresentation *footer;
    footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeReportFooter
                                                            row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addGroupFooterAtLevel:(NSUInteger)groupLevel {
    MADSectionRepresentation *footer;
    footer = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeGroupFooter
                                                     groupLevel: groupLevel
                                                            row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

+ (void)addDetailForRowID:(NSUInteger)rowID
               pageLayout:(byref inout MADMutableSectionArray *)pageLayout
              pageIndexes:(byref inout MADMutableIndexArray *)pageIndexes {
    MADSectionRepresentation *detail;
    detail = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeBody
                                                            row: rowID];
    [pageLayout     addObject: detail];
    [pageIndexes    addObject: @(rowID)];
}

- (void)addReportHeader {
    MADSectionRepresentation *obj;
    obj = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypeReportHeader
                                                        row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject: obj];
}

- (void)addPageHeader {
    MADSectionRepresentation *obj;
    obj = [MADSectionRepresentation newSectionRepresentation: MADDocumentSectionTypePageHeader
                                                         row: _machineState.detailRowId];
    [self.pageLayoutTemporary addObject:  obj];
}

- (NSUInteger)numberOfPages {
    return (NSUInteger)self.reportLayout.count;
}

/*
 // FIXME: Write function to return results for keys without having data stored in memeory.
 */

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

- (NSEnumerator <__kindof MADSectionRepresentation *> *)layoutEnumeratorForPage:(NSUInteger)pageIndex {
    MADSectionArray *pageLayout = self.reportLayout[pageIndex];
    return pageLayout.objectEnumerator;
}

#pragma mark - Help functions

- (BOOL)isLandscape {
#ifdef MADWATCHKIT
    return NO;
#else
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
#endif
}

@end
