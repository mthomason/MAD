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

#import "NSDictionary+MADReportObjectRepresentation.h"

NSString * const MTNullIdentifier = @"(null)";

@interface MTReportFormatter ()

    @property (nonatomic, weak, readwrite) MADocument *layout;

    @property (nonatomic, assign) MTReportFormatterOptions options;

    @property (nonatomic, strong, readwrite) MTReportFormatterPageDefinition *page;

    @property (nonatomic, strong, readwrite) MADArrayCaching *reportIndexes;
    @property (nonatomic, strong, readwrite) MADArrayCaching *reportLayout;

    @property (nonatomic, strong) MTReportFormatterState *machineState; //At some point add the ability to format one page at a time.
    @property (nonatomic, strong) MTReportFormatterCache *reportFormatterCache;

    @property (nonatomic, strong) NSMutableArray <NSDictionary *> *pageLayoutTemporary;
    @property (nonatomic, strong) NSMutableArray *pageIndexesTemporary;

    @property (nonatomic, strong) NSArray *lastResultRowComparsonValues;
    @property (nonatomic, strong) NSDictionary *layoutHeightsBySectionKey;

    @property (nonatomic, strong, readwrite) NSArray *sortedQueryGroups;

@end


@implementation MTReportFormatter

- (void)initalizeStateMachine {
    
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSArray *sd = [self.dataDelegate sortDescriptors];
    NSArray *sortDescriptors = [NSArray arrayWithArray:sd];

    self.machineState.rowCounter = 0;
    self.machineState.groupCounter = 0;
    self.machineState.pageCounter = 0;
    self.machineState.detailRowId = @(0);
    self.machineState.detailRowIdLast = @(0);
    self.machineState.sortDescriptors = sortDescriptors;
    self.machineState.counterHeightUsedCurrentPage = CGSizeZero.height;
    self.machineState.document = [self.layout activeDocumentModel];
}

- (NSArray *)keysForCachedID:(NSNumber *)rowid {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSDictionary *row = [self.datasource dataForCacheId: rowid];
    NSArray *keyValues = [self keyValuesForResultRow:row];
    return [NSArray arrayWithArray:keyValues];
}

- (void)dealloc { }

- (instancetype)initWithDocument: (MADocument *)layout options: (MTReportFormatterOptions)options  {
    if (self = [super init]) {

        //NSLog(@"%s", __PRETTY_FUNCTION__);

        self.options = options;
        self.layout = layout;
        self.didRefresh = NO;
    }
    return self;
}

+ (instancetype)newReportFormatterWithDocument: (MADocument *)layout options: (MTReportFormatterOptions)options {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    MTReportFormatter *result = [[MTReportFormatter alloc] initWithDocument:layout options:options];
    return result;
}

- (NSArray *)layoutForPage:(NSUInteger)page {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSArray *result = [NSArray arrayWithArray:self.reportLayout[page]];
    return (page < (NSUInteger)[self.reportLayout count]) ? result : nil;
}

- (NSUInteger)layoutIdentifier {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    return self.overrideIdentifier == nil ?
                    self.layout.documentObjectID.URIRepresentation.absoluteString.hash :
                    self.overrideIdentifier.hash;
}

- (NSString *)nameCurrentReportIndexes {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "ih", sizeString];
}

- (NSString *)nameCurrentReportLayout {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "lh", sizeString];
}

- (void)setCachedDelegate:(id<MTCacheProtocol>)cachedDelegate {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    _cachedDelegate = cachedDelegate;
    [self initalize];
}

- (void)initalize {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    MTReportFormatterPageDefinition *page = [MTReportFormatterPageDefinition new];
    self.page = page;
    
    self.page.margins = (self.options & MTReportFormatterOptionsMargin) ?
                            UIEdgeInsetsMake(CGFloatPointsForInches(1.0000f/4.0000f), CGFloatPointsForInches(1.0000f/4.0000f),
                                             CGFloatPointsForInches(1.0000f/4.0000f), CGFloatPointsForInches(1.0000f/4.0000f)) :
                            UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.height, CGSizeZero.height, CGSizeZero.height);
    
    MTReportFormatterState *machineState = [MTReportFormatterState new];
    self.machineState = machineState;

    [self initalizeStateMachine];
    
    MTReportFormatterCache *reportFormatterCache = [MTReportFormatterCache new];
    self.reportFormatterCache = reportFormatterCache;
    
    NSMutableArray <NSDictionary *> *temporaryLayoutForPage = [[NSMutableArray alloc] init];
    self.pageLayoutTemporary = temporaryLayoutForPage;
    
    NSMutableArray *temporaryDataForPage = [[NSMutableArray alloc] init];
    self.pageIndexesTemporary = temporaryDataForPage;
    
    if (self.layout) {
        [self.layout initalizeSectionLayoutManagers:self.machineState.document];
        NSDictionary *layoutHeightsBySectionKeys = [self.layout layoutHeightsBySectionKey];
        [self setLayoutHeightsBySectionKey:layoutHeightsBySectionKeys];
    } else {
        [self setLayoutHeightsBySectionKey:nil];
    }
}

- (void)setMarginUsingPrintableRect:(CGRect)printableRect {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.page.margins = UIEdgeInsetsMake(printableRect.origin.y, printableRect.origin.x,
                                         self.page.layoutSize.height - printableRect.size.height - printableRect.origin.y,
                                         self.page.layoutSize.width - printableRect.size.width - printableRect.origin.x);
}

#pragma mark - Reading cached data

//  Data is cached by group, page, and report.

- (BOOL)cachedIndexesExist {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, self.reportIndexes.count > 0 && self.reportLayout.count > 0 ? @"YES" : @"NO");
    return self.reportIndexes.count > 0 && self.reportLayout.count > 0;
}

- (BOOL)needsFormat {
    NSLog(@"Needs format: %s (%s)", (self.didRefresh || [self cachedIndexesExist] == NO || [self.datasource cacheExist] == NO) ? "YES" : "NO", __PRETTY_FUNCTION__);
    NSAssert([self datasource] != nil, @"We need a datatable way before here");
    return (self.didRefresh || [self cachedIndexesExist] == NO || [self.datasource cacheExist] == NO) ? YES : NO;
}

- (void)formatForSize:(CGSize)printableSize {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self formatForSize:printableSize contentChanged:YES];
}

- (void)setLayoutSize:(CGSize)layoutSize {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.page setLayoutSize:layoutSize];
}

- (void)reformatForSize:(CGSize)printableSize {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self formatForSize:printableSize contentChanged:NO];
}

- (void)loadFromCacheWithSize:(CGSize)printableSize {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self setLayoutSize:printableSize];
    [self loadLayoutAndIndexesFromCache];
}

- (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged {
    NSLog(@"%s", __PRETTY_FUNCTION__);

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
        [self reformatForSize:printableSize];
    }
}

- (void)formatDocument {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self initalizeStateMachine];
    
    self.machineState.counterHeightUsedCurrentPage += self.page.margins.top;

    NSDictionary *layoutHeightsBySectionKeys = [self.layout layoutHeightsBySectionKey];
    [self setLayoutHeightsBySectionKey:layoutHeightsBySectionKeys];
    
    [self cleanupTemporaryReportIndexes];
    
    [self beginBulkInserts];
    
    [self addReportHeaderToReportLayout];
    [self addPageHeaderToReportLayout];
    [self addDetailToReportLayout];
    [self addReportFooterToReportLayout];
    
    NSArray <__kindof NSDictionary *> *tlfp = [NSArray arrayWithArray:self.pageLayoutTemporary];
    [self.reportLayout addObject:tlfp];
    
    NSArray *tdfp = [NSArray arrayWithArray:self.pageIndexesTemporary];
    [self.reportIndexes addObject:tdfp];
    
    [self endBulkInserts];
    
    [self cleanupTemporaryReportIndexes];
    
    // FIXME: This cache is being set, but it is not being loaded.
    [self.reportFormatterCache setLayout: self.reportLayout.identifier
                              andIndexes: self.reportIndexes.identifier
                                 forSize: self.page.layoutSize];
    
}

- (void)dropIndexes {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.reportIndexes removeAllObjects];
    [self.reportLayout removeAllObjects];
}

- (void)dumpCache {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.reportFormatterCache dumpCache];
}

- (void)beginBulkInserts {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.reportIndexes beginBulkInserts];
    [self.reportLayout beginBulkInserts];
}

- (void)endBulkInserts {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.reportLayout endBulkInserts];
    [self.reportIndexes endBulkInserts];
}

- (void)loadLayoutAndIndexesFromCache {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
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
    [self setReportIndexes:ixarray];
    
    MADArrayCaching *lyarray = [[MADArrayCaching alloc] initWithIdentifier: [self nameCurrentReportLayout]
                                                            cachedDelegate: self.cachedDelegate];
    [lyarray initializeDatabase];
    [self setReportLayout:lyarray];
    
    [self cleanupTemporaryReportIndexes];
}

- (void)initReportLayoutContainers {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.reportLayout removeAllObjects];
    [self.reportIndexes removeAllObjects];
    [self setLastResultRowComparsonValues:nil];
}

- (void)cleanupTemporaryReportIndexes {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self cleanupTemporaryPageIndexes];
}

- (void)cleanupTemporaryPageIndexes {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.pageLayoutTemporary removeAllObjects];
    [self.pageIndexesTemporary removeAllObjects];
}

- (NSUInteger)numberOfGroups {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return self.machineState.sortDescriptors.count;
}

- (void)displayNewGroupFootersIfNeeded:(NSArray *)currentValues  andLastValues:(NSArray *)lastValues {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    for (NSUInteger groupLevel = lastValues.count; groupLevel > 0; groupLevel--) {
        @autoreleasepool {
            NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel - 1];
            NSComparisonResult comparsonResult = [self compareValue: lastValues[groupLevel - 1] withValue: currentValues[groupLevel - 1] usingSelector: sortDesc.selector];
            
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

    NSLog(@"%s", __PRETTY_FUNCTION__);
    for (NSUInteger groupLevel = 0; groupLevel < currentValues.count; groupLevel++) {
        @autoreleasepool {
            BOOL newHeader = lastValues.count == 0;
            if (newHeader == NO) {
                
                id value = lastValues[groupLevel];
                id value2 = currentValues[groupLevel];
                
                NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel];
                NSComparisonResult comparsonResult = [self compareValue:value withValue:value2 usingSelector:sortDesc.selector];
                
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
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
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

- (NSArray *)rowidsForPage:(NSUInteger)pageIndex {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [self.layoutHeightsBySectionKey[documentSection.sectionKey] floatValue];
}

- (void)addHeightFromDocumentSectionToReportLayout:(RptqDocumentSection *)documentSection {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    CGFloat layoutHeight = [self heightForSection:documentSection];
    if ([documentSection producesFormFeed]) {
        [self forcePageBreakWithFooterHeight:[self heightForSection:self.machineState.document.hasPageFooterSection]];
    } else {
        [self addPageBreakToReportLayoutWithNextItemHeight: layoutHeight];
    }
    self.machineState.counterHeightUsedCurrentPage = self.machineState.counterHeightUsedCurrentPage + layoutHeight;
}

- (RptqQueryGroup *)sortGroupAtLevel:(NSUInteger)level {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self initReportLayoutContainers];
    self.machineState.rowCounter = 0;
    
    RptqDocumentSection *detailSection = [self.machineState.document hasDetailSection];
    
    BOOL firstRow = YES;
        
    NSArray *sqg = [self.layout.mainQuery.queryObject sortedQueryGroups];
    [self setSortedQueryGroups:sqg];
    
    bool rowIdOnly = true;
    bool calculatedRowId = false;

    id lastResultRow = nil;

    for (id resultRow in [self.datasource enumeratorForReportData]) {

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
            if (!firstRow) {
                [self displayNewGroupFootersIfNeeded: keyValuesForComparson
                                       andLastValues: self.lastResultRowComparsonValues];
            }
            
            //Display new group headers if needed.
            [self displayNewGroupHeadersIfNeeded: keyValuesForComparson
                                   andLastValues: self.lastResultRowComparsonValues];
            
            [self addHeightFromDocumentSectionToReportLayout:detailSection];
            
            [self addDetail];
            
            [self setLastResultRowComparsonValues: keyValuesForComparson];
            
            firstRow = NO;
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

- (NSArray *)keyValuesForResultRow:(id)resultRow {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSArray *keyValues = nil;
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
        keyValues = [NSArray arrayWithArray:keyValuesForComparson];
    } else {
        keyValues = @[];
    }
    return keyValues;
}

- (CGFloat)printableHeight {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return self.page.layoutSize.height - self.page.margins.top - self.page.margins.bottom;
}

// FIXME: Make sure paper rect is passed in to the software
- (BOOL)addPageBreakToReportLayoutWithNextItemHeight:(CGFloat)nextItemHeight {
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL newPageCreated = NO;
    
    CGFloat pageFooterSectionHeight = [self heightForSection:self.machineState.document.hasPageFooterSection];
    
    if (self.machineState.counterHeightUsedCurrentPage + nextItemHeight + pageFooterSectionHeight > [self printableHeight]) {
        
        newPageCreated = YES;
        [self forcePageBreakWithFooterHeight:pageFooterSectionHeight];
    }

    return newPageCreated;
}

- (void)forcePageBreakWithFooterHeight:(CGFloat)footerHeight {

    NSLog(@"%s", __PRETTY_FUNCTION__);
    CGFloat newHeight = self.machineState.counterHeightUsedCurrentPage + footerHeight;
    self.machineState.counterHeightUsedCurrentPage = newHeight;
    [self addPageFooter];
    
    NSArray *pageInfo = self.pageLayoutTemporary != nil ? [NSArray arrayWithArray: self.pageLayoutTemporary] : @[];
    [self.reportLayout addObject:pageInfo];
    
    NSArray *rowids = self.pageIndexesTemporary != nil ? [NSArray arrayWithArray: self.pageIndexesTemporary] : @[];
    [self.reportIndexes addObject:rowids];
    
    [self cleanupTemporaryPageIndexes];
    
    self.machineState.pageCounter++;
    
    [[MADNotificationDidFormatPage sharedObject] reportFormatter: self
                                                   formattedPage: self.machineState.pageCounter];
    
    RptqDocumentSection *pageHeaderSection = [self.machineState.document hasPageHeaderSection];
    
    //Reset height of the page to zero plus the hight of the page header section
    self.machineState.counterHeightUsedCurrentPage = [self heightForSection:pageHeaderSection];
    
    [self addPageHeader];
}

- (void)addReportHeaderToReportLayout {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.machineState.counterHeightUsedCurrentPage = self.machineState.counterHeightUsedCurrentPage +
                                                        [self heightForSection:self.machineState.document.hasReportHeaderSection];
    [self addReportHeader];
}

- (void)addPageHeaderToReportLayout {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.machineState.counterHeightUsedCurrentPage = self.machineState.counterHeightUsedCurrentPage +
                                                        [self heightForSection:self.machineState.document.hasPageHeaderSection];
    [self addPageHeader];
}

- (void)addPageFooterToReportLayout {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self addHeightFromDocumentSectionToReportLayout:[self.machineState.document hasPageFooterSection]];
    [self addPageFooter];
}

- (void)addReportFooterToReportLayout {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self addHeightFromDocumentSectionToReportLayout:[self.machineState.document hasReportFooterSection]];
    [self addPageFooterToReportLayout];
    [self addReportFooter];
}

- (void)addGroupHeaderLevel:(NSUInteger)groupLevel {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *header = [NSDictionary newObjectRepresentationWithSectionType: MNSDocumentSectionTypeGroupHeader
                                                                     groupLevel: groupLevel
                                                                            row: self.machineState.detailRowId];
    if (groupLevel == [self numberOfGroups] - 1) {
        self.machineState.groupCounter++;
    }
    [self.pageLayoutTemporary addObject: header];
}

- (void)addPageFooter {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *footer = [NSDictionary newObjectRepresentationWithSectionType: MNSDocumentSectionTypePageFooter
                                                                            row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addReportFooter {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *footer = [NSDictionary newObjectRepresentationWithSectionType: MNSDocumentSectionTypeReportFooter
                                                                            row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addGroupFooterAtLevel:(NSUInteger)groupLevel {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *footer = [NSDictionary newObjectRepresentationWithSectionType: MNSDocumentSectionTypeGroupFooter
                                                                     groupLevel: groupLevel
                                                                            row: self.machineState.detailRowId];
    
    [self.pageLayoutTemporary addObject: footer];
}

- (void)addDetail {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *detail = [NSDictionary newObjectRepresentationWithSectionType: MNSDocumentSectionTypeBody
                                                                            row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: detail];
    [self.pageIndexesTemporary addObject:self.machineState.detailRowId];
}

- (void)addReportHeader {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *obj = [NSDictionary newObjectRepresentationWithSectionType: MNSDocumentSectionTypeReportHeader
                                                                         row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject: obj];
}

- (void)addPageHeader {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *obj = [NSDictionary newObjectRepresentationWithSectionType: MNSDocumentSectionTypePageHeader
                                                                         row: self.machineState.detailRowId];
    [self.pageLayoutTemporary addObject:  obj];
}

- (NSUInteger)numberOfPages {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return (NSUInteger)self.reportLayout.count;
}


/*
 // FIXME: Write function to return results for keys without having data stored in memeory.
 */

+ (instancetype)dataForGroupData:(id)data andKeys:(NSArray *)keys NS_RETURNS_RETAINED {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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

- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex {
    return [self.reportLayout[pageIndex] objectEnumerator];
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
