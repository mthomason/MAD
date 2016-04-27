//
//  MTReportFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportFormatter.h"
#import <CoreData/NSManagedObjectID.h>
#import "MTReportFormatterState.h"
#import "MADocument.h"
#import "MTQueryFull.h"

#import "RptqDocumentSectionEnumerator.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqQueryGroup.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "MTDatabaseField.h"

#import "MTReportFormatterCache.h"

#import "MADArrayCaching.h"

#import "MADNotificationDidFormatPage.h"
#import "MTReportFormatterPageDefinition.h"

#import "NSData+Comparson.h"

#import "MADSectionPlist.h"

NSString * const MTNullIdentifier = @"(null)";

typedef NSMutableArray  <__kindof MADSectionPlist *>                    MADMutableSectionArray;
typedef NSMutableArray  <__kindof NSNumber *>                           MADMutableIndexArray;

typedef NSDictionary    <NSString *, NSNumber *>    MADStringNumberMap;
typedef NSArray         <RptqQueryGroup *>          MADQueryGroupArray;

static inline UIEdgeInsets MADEdgeInsetsQuarterInch();
static inline UIEdgeInsets MADEdgeInsetsQuarterInch() {
    return UIEdgeInsetsMake(fMGPointsForInches(1.0/4.0),
                            fMGPointsForInches(1.0/4.0),
                            fMGPointsForInches(1.0/4.0),
                            fMGPointsForInches(1.0/4.0));
}

static inline UIEdgeInsets MADEdgeInsetsEmpty();
static inline UIEdgeInsets MADEdgeInsetsEmpty() {
    return UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.height,
                            CGSizeZero.height, CGSizeZero.height);
}

static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect printableRect, CGSize layoutSize);
static inline UIEdgeInsets MADEdgeInsetsPrinting(CGRect printableRect, CGSize layoutSize) {
    return UIEdgeInsetsMake(printableRect.origin.y, printableRect.origin.x,
                            layoutSize.height - printableRect.size.height - printableRect.origin.y,
                            layoutSize.width - printableRect.size.width - printableRect.origin.x);
}

static inline CGFloat PrintableHeightForPage(MTReportFormatterPageDefinition *page);
static inline CGFloat PrintableHeightForPage(MTReportFormatterPageDefinition *page) {
    return page.layoutSize.height - page.margins.top - page.margins.bottom;
}

static inline CGFloat HeightWithNextItem(CGFloat heightUsedCurrentPage, CGFloat nextItemHeight, CGFloat pageFooterHeight);
static inline CGFloat HeightWithNextItem(CGFloat heightUsedCurrentPage, CGFloat nextItemHeight, CGFloat pageFooterHeight) {
    return heightUsedCurrentPage + nextItemHeight + pageFooterHeight;
}

@interface MTReportFormatter ()

    @property (nonatomic, weak, readwrite)      MADocument *layout;
    @property (nonatomic, assign)               MTReportFormatterOptions options;

    @property (nonatomic, strong, readwrite)    MTReportFormatterPageDefinition *page;

    @property (nonatomic, strong, readwrite)    MADCachingIndexes *reportIndexes;
    @property (nonatomic, strong, readwrite)    MADCachingLayout *reportLayout;

    @property (nonatomic, strong)               MTReportFormatterState *machineState;
    @property (nonatomic, strong)               MTReportFormatterCache *reportFormatterCache;

    @property (nonatomic, strong)               MADMutableSectionArray *pageLayoutTemporary;
    @property (nonatomic, strong)               MADMutableIndexArray *pageIndexesTemporary;

    @property (nonatomic, strong)               MADObjectArray      *lastComparsonValues;
    @property (nonatomic, strong)               MADStringNumberMap  *layoutHeightsBySectionKey;
    @property (nonatomic, strong, readwrite)    MADQueryGroupArray  *sortedQueryGroups;

@end


@implementation MTReportFormatter

- (void)initalizeStateMachine {
    NSArray *sd = [self.dataDelegate sortDescriptors];
    NSArray *sortDescriptors = [NSArray arrayWithArray:sd];

    self.machineState.rowCounter = 0;
    self.machineState.groupCounter = 0;
    self.machineState.pageCounter = 0;
    self.machineState.detailRowId = @0;
    self.machineState.detailRowIdLast = @0;
    self.machineState.sortDescriptors = sortDescriptors;
    self.machineState.counterHeightUsedCurrentPage = CGSizeZero.height;
    self.machineState.document = [self.layout activeDocumentModel];
}

- (MADObjectArray *)keysForCachedID:(NSNumber *)rowid {
    NSDictionary *row = [self.datasource dataForCacheId: rowid];
    MADObjectArray *keyValues = [self keyValuesForResultRow:row];
    return [MADObjectArray arrayWithArray:keyValues];
}

- (void)dealloc { }

- (instancetype)initWithDocument: (MADocument *)layout
                         options: (MTReportFormatterOptions)options  {
    if (self = [super init]) {
        self.options = options;
        self.layout = layout;
        self.didRefresh = false;
    }
    return self;
}

+ (instancetype)newReportFormatterWithDocument: (MADocument *)layout
                                       options: (MTReportFormatterOptions)options {
    MTReportFormatter *result = [[MTReportFormatter alloc] initWithDocument:layout options:options];
    return result;
}

+ (instancetype)newReportFormatterWithLayout: (MADocument *)layout
                                     options: (MTReportFormatterOptions)options {
    MTReportFormatter *result = [[MTReportFormatter alloc] initWithDocument:layout options:options];
    return result;
}

#pragma mark - Accessors

- (MADSectionArray *)layoutForPage:(NSUInteger)page {
    MADSectionArray *result = (page < (NSUInteger)[self.reportLayout count]) ?
                                self.reportLayout[page] : nil;
    return result;
}

- (NSUInteger)layoutIdentifier {
    return self.overrideIdentifier == nil ?
                    self.layout.documentObjectID.URIRepresentation.absoluteString.hash :
                    self.overrideIdentifier.hash;
}

- (NSString *)nameCurrentReportIndexes {
    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier],
                                            "ih", sizeString];
}

- (NSString *)nameCurrentReportLayout {
    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier],
                                            "lh", sizeString];
}

- (void)initalize {
    
    MTReportFormatterPageDefinition *page = [[MTReportFormatterPageDefinition alloc] init];
    self.page = page;
    
    self.page.margins = (self.options & MTReportFormatterOptionsMargin) ?
                            MADEdgeInsetsQuarterInch() : MADEdgeInsetsEmpty();
    
    MTReportFormatterState *machineState = [[MTReportFormatterState alloc] init];
    self.machineState = machineState;

    [self initalizeStateMachine];
    
    MTReportFormatterCache *reportFormatterCache = [[MTReportFormatterCache alloc] init];
    self.reportFormatterCache = reportFormatterCache;
    
    MADMutableSectionArray *temporaryLayoutForPage = [[MADMutableSectionArray alloc] init];
    self.pageLayoutTemporary = temporaryLayoutForPage;
    
    NSMutableArray *temporaryDataForPage = [[NSMutableArray alloc] init];
    self.pageIndexesTemporary = temporaryDataForPage;
    
    if (self.layout) {
    
        [self.layout initalizeSectionLayoutManagers: self.machineState.document];
        NSDictionary *layoutHeightsBySectionKeys = [self.layout copyLayoutHeightsBySectionKey];
        [self setLayoutHeightsBySectionKey:layoutHeightsBySectionKeys];
        
    } else {
        
        [self setLayoutHeightsBySectionKey:nil];
        
    }
}

- (void)setMarginUsingPrintableRect:(CGRect)printableRect {
    self.page.margins = MADEdgeInsetsPrinting(printableRect, self.page.layoutSize);
}

#pragma mark - Reading cached data

//  Data is cached by group, page, and report.

- (bool)cachedIndexesExist {
    return self.reportIndexes.count > 0 && self.reportLayout.count > 0;
}

- (BOOL)needsFormat {
    NSAssert([self datasource] != nil, @"We need a datatable way before here");
    return self.didRefresh ||
            (self.reportIndexes.count > 0 && self.reportLayout.count > 0) == NO ||
            ![self.datasource cacheExist] ? YES : NO;
}

- (void)formatForSize:(CGSize)printableSize {
    [self formatForSize:printableSize contentChanged:YES];
}

- (void)setLayoutSize:(CGSize)layoutSize {
    self.page.layoutSize = layoutSize;
}

- (void)loadFromCacheWithSize:(CGSize)printableSize {
    self.didRefresh = false;
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

    [self initalizeStateMachine];
    
    self.machineState.counterHeightUsedCurrentPage += self.page.margins.top;

    NSDictionary *layoutHeightsBySectionKeys = [self.layout copyLayoutHeightsBySectionKey];
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
    
    if (self.reportIndexes != nil) {
        [self.reportIndexes finalizeDatabase];
        self.reportIndexes = nil;
    }
    if (self.reportLayout != nil) {
        [self.reportLayout finalizeDatabase];
        self.reportLayout = nil;
    }

    MADArrayCaching *ixarray = [[MADArrayCaching alloc] initWithIdentifier: [self nameCurrentReportIndexes]
                                                            cachedDelegate: self.cachedDelegate];
    [ixarray initializeDatabase];
    self.reportIndexes = ixarray;
    
    MADArrayCaching *lyarray = [[MADArrayCaching alloc] initWithIdentifier: [self nameCurrentReportLayout]
                                                            cachedDelegate: self.cachedDelegate];
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
    [self.pageLayoutTemporary removeAllObjects];
    [self.pageIndexesTemporary removeAllObjects];
}

- (NSUInteger)numberOfGroups {
    return self.machineState.sortDescriptors.count;
}

- (void)displayNewGroupFootersIfNeeded:(NSArray *)currentValues  andLastValues:(NSArray *)lastValues {
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
            if (documentSection.type.integerValue == MNSDocumentSectionTypeGroupHeader) {
                [self addHeightFromDocumentSectionToReportLayout:documentSection];
                break;
            }
        }
    }
}

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupFooterWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in queryGroup.hasSection.allObjects) {
        @autoreleasepool {
            if (documentSection.type.integerValue == MNSDocumentSectionTypeGroupFooter) {
                [self addHeightFromDocumentSectionToReportLayout:documentSection];
                break;
            }
        }
    }
}

- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection {
    NSNumber * __weak sectionHeight = self.layoutHeightsBySectionKey[documentSection.sectionKey];
    return sectionHeight.floatValue;
}

- (void)addHeightFromDocumentSectionToReportLayout:(RptqDocumentSection *)documentSection {
    CGFloat layoutHeight = [self heightForSection:documentSection];
    if ([documentSection producesFormFeed]) {
        [self forcePageBreakWithFooterHeight:[self heightForSection:self.machineState.document.hasPageFooterSection]];
    } else {
        [self addPageBreakToReportLayoutWithNextItemHeight: layoutHeight];
    }
    self.machineState.counterHeightUsedCurrentPage = self.machineState.counterHeightUsedCurrentPage + layoutHeight;
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
    self.machineState.rowCounter = 0;
    
    RptqDocumentSection *detailSection = self.machineState.document.hasDetailSection;
    
    bool firstRow = true;
        
    NSArray *sqg = [self.layout.mainQuery.queryObject sortedQueryGroups];
    [self setSortedQueryGroups:sqg];
    
    bool rowIdOnly = true;
    bool calculatedRowId = false;

    id lastResultRow = nil;

    NSEnumerator *enumeratorForReportData = [self.datasource enumeratorForReportData];
    for (id resultRow in enumeratorForReportData) {

        @autoreleasepool {
            
            //Get row id
            if (!calculatedRowId) {
                if ([resultRow isKindOfClass:[NSDictionary class]]) {
                    rowIdOnly = false;
                }
                calculatedRowId = true;
            }
            self.machineState.detailRowIdLast = self.machineState.detailRowId;
            self.machineState.detailRowId = rowIdOnly ? resultRow : resultRow[MADIdentifierROWID];
            
            //Get row key values
            NSArray *keyValuesForComparson = [self keyValuesForResultRow:resultRow];
            
            //Display new footers if needed.
            if (firstRow) {
                firstRow = false;
            } else {
                [self displayNewGroupFootersIfNeeded: keyValuesForComparson
                                       andLastValues: self.lastComparsonValues];
            }
            
            //Display new group headers if needed.
            [self displayNewGroupHeadersIfNeeded: keyValuesForComparson
                                   andLastValues: self.lastComparsonValues];
            
            [self addHeightFromDocumentSectionToReportLayout:detailSection];
            
            [MTReportFormatter addDetailForRowID:self.machineState.detailRowId
                                      pageLayout:self.pageLayoutTemporary
                                     pageIndexes:self.pageIndexesTemporary];
            
            self.lastComparsonValues = keyValuesForComparson;
            
            self.machineState.rowCounter++;
            
        }
        lastResultRow = resultRow;
    }
    //Need to account for the last set of group footers.
    if (lastResultRow) {
        
        NSArray *keyValuesForComparson = [self keyValuesForResultRow:lastResultRow];
        NSUInteger groupLevel = keyValuesForComparson.count;
        while (groupLevel >= 1) {
            @autoreleasepool {
                RptqQueryGroup *group = [self sortedQueryGroups][groupLevel-1];
                [self addHeightFromGroupFooterWithQueryGroup: group];
                [self addGroupFooterAtLevel:groupLevel-1];
            }
            groupLevel--;
        }
    }
}

- (MADObjectArray *)keyValuesForResultRow:(id)resultRow {

    MADObjectArray *keyValues = nil;

    if ([resultRow isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *keyValuesForComparson = [[NSMutableArray alloc] initWithCapacity:self.numberOfGroups];

        for (NSSortDescriptor *sortDesc in self.machineState.sortDescriptors) {
            id predicateValue = resultRow[sortDesc.key];
            if (predicateValue != nil) {
                [keyValuesForComparson addObject:predicateValue];
            } else {
                [keyValuesForComparson addObject:[NSNull null]];
            }
        }
        keyValues = [MADObjectArray arrayWithArray:keyValuesForComparson];
        
    } else {
        keyValues = @[];
    }
    return keyValues;
}

// FIXME: Make sure paper rect is passed in to the software
- (bool)addPageBreakToReportLayoutWithNextItemHeight:(CGFloat)nextItemHeight {
    
    bool newPageCreated = false;
    
    CGFloat pageFooterSectionHeight = [self heightForSection:self.machineState.document.hasPageFooterSection];
    
    if (HeightWithNextItem(self.machineState.counterHeightUsedCurrentPage, nextItemHeight, pageFooterSectionHeight) >
        PrintableHeightForPage(self.page)) {
        
        newPageCreated = true;
        [self forcePageBreakWithFooterHeight:pageFooterSectionHeight];
    }

    return newPageCreated;
}

- (void)forcePageBreakWithFooterHeight:(CGFloat)footerHeight {

    CGFloat newHeight = self.machineState.counterHeightUsedCurrentPage + footerHeight;
    self.machineState.counterHeightUsedCurrentPage = newHeight;
    [self addPageFooter];
    
    id pageInfo = self.pageLayoutTemporary != nil ?
                            [MADMutableSectionArray arrayWithArray: self.pageLayoutTemporary] :
                            @[];
    [self.reportLayout addObject:pageInfo];
    
    MADIndexArray *rowids = self.pageIndexesTemporary != nil ?
                                [MADIndexArray arrayWithArray: self.pageIndexesTemporary] : @[];
    [self.reportIndexes addObject:rowids];
    
    [self cleanupTemporaryIndexes];
    
    self.machineState.pageCounter++;
    
    [[MADNotificationDidFormatPage sharedObject] reportFormatter: self
                                                   formattedPage: self.machineState.pageCounter];
    
    RptqDocumentSection *pageHeaderSection = [self.machineState.document hasPageHeaderSection];
    
    //Reset height of the page to zero plus the hight of the page header section
    self.machineState.counterHeightUsedCurrentPage = [self heightForSection:pageHeaderSection];
    
    [self addPageHeader];
}

- (void)addReportHeaderToReportLayout {
    self.machineState.counterHeightUsedCurrentPage = self.machineState.counterHeightUsedCurrentPage +
                                                        [self heightForSection:self.machineState.document.hasReportHeaderSection];
    [self addReportHeader];
}

- (void)addPageHeaderToReportLayout {
    self.machineState.counterHeightUsedCurrentPage = self.machineState.counterHeightUsedCurrentPage +
                                                        [self heightForSection:self.machineState.document.hasPageHeaderSection];
    [self addPageHeader];
}

- (void)addPageFooterToReportLayout {
    [self addHeightFromDocumentSectionToReportLayout:[self.machineState.document hasPageFooterSection]];
    [self addPageFooter];
}

- (void)addReportFooterToReportLayout {
    [self addHeightFromDocumentSectionToReportLayout:[self.machineState.document hasReportFooterSection]];
    [self addPageFooterToReportLayout];
    [self addReportFooter];
}

- (void)addGroupHeaderLevel:(NSUInteger)groupLevel {
    MADSectionPlist *header = [MADSectionPlist newSectionRepresentationWithType: MNSDocumentSectionTypeGroupHeader
                                                                     groupLevel: groupLevel
                                                                            row: self.machineState.detailRowId];
    if (groupLevel == [self numberOfGroups] - 1) {
        self.machineState.groupCounter++;
    }
    [self.pageLayoutTemporary addObject: header];
}

- (void)addPageFooter {
    MADSectionPlist *footer = [MADSectionPlist newSectionRepresentationWithType: MNSDocumentSectionTypePageFooter
                                                                            row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addReportFooter {
    MADSectionPlist *footer = [MADSectionPlist newSectionRepresentationWithType: MNSDocumentSectionTypeReportFooter
                                                                            row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addGroupFooterAtLevel:(NSUInteger)groupLevel {
    MADSectionPlist *footer = [MADSectionPlist newSectionRepresentationWithType: MNSDocumentSectionTypeGroupFooter
                                                                     groupLevel: groupLevel
                                                                            row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

+ (void)addDetailForRowID:(NSNumber *)rowID
               pageLayout:(byref inout MADMutableSectionArray *)pageLayout
              pageIndexes:(byref inout MADMutableIndexArray *)pageIndexes {
    MADSectionPlist *detail = [MADSectionPlist newSectionRepresentationWithType: MNSDocumentSectionTypeBody
                                                                            row: rowID];
    [pageLayout     addObject: detail];
    [pageIndexes    addObject: rowID];
}

- (void)addReportHeader {
    MADSectionPlist *obj = [MADSectionPlist newSectionRepresentationWithType: MNSDocumentSectionTypeReportHeader
                                                                         row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: obj];
}

- (void)addPageHeader {
    MADSectionPlist *obj = [MADSectionPlist newSectionRepresentationWithType: MNSDocumentSectionTypePageHeader
                                                                         row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject:  obj];
}

- (NSUInteger)numberOfPages {
    return (NSUInteger)self.reportLayout.count;
}

/*
 // FIXME: Write function to return results for keys without having data stored in memeory.
 */

+ (instancetype)dataForGroupData:(id)data andKeys:(NSArray *)keys NS_RETURNS_RETAINED {
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
                resultData = [MTReportFormatter dataForGroupData:subData andKeys:subKeys];
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

- (NSEnumerator <__kindof MADSectionPlist *> *)layoutEnumeratorForPage:(NSUInteger)pageIndex {
    MADSectionArray *pageLayout = self.reportLayout[pageIndex];
    return pageLayout.objectEnumerator;
}

#pragma mark - Help functions

- (BOOL)isLandscape {
#ifdef MADWATCHKIT
    return NO;
#else
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
#endif
}

@end
