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
#import "MAReportDocument.h"
#import "MTQueryFull.h"

#import "SectionEnumerator.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "MTDatabaseField.h"
#import "RptqQuery+Extras.h"
#import "MTDataTable.h"

#import "MTReportFormatterCache.h"

#import "MTArrayCached.h"

//Why the fuck!!!

#import "MTDatabaseConnection.h"
#import "MTDatabase.h"

#import "MTPageCaching.h"

#import "MTLog.h"
#import "NSData+Comparson.h"

#import "MTNotificationDidFormatPage.h"
#import "MTReportFormatterPageDefinition.h"
#import "CGGeometry+Extras.h"

NSString * const MTNullIdentifier = @"(null)";

@interface MTReportFormatterState : NSObject

    @property (nonatomic, assign) NSUInteger groupCounter;
    @property (nonatomic, assign) NSUInteger pageCounter;
    @property (nonatomic, assign) NSUInteger rowCounter;
    @property (nonatomic, assign) CGFloat counterHeightUsedCurrentPage;
    @property (nonatomic, strong) NSNumber *detailRowId;
    @property (nonatomic, strong) NSNumber *detailRowIdLast;
    @property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation MTReportFormatterState
@end

@interface MTReportFormatter ()

    @property (nonatomic, strong, readwrite) MTReportFormatterPageDefinition *page;

    @property (nonatomic, assign) MTReportFormatterOptions options;
    @property (nonatomic, strong, readwrite) RptqDocument *layout;
    @property (nonatomic, strong, readwrite) MTArrayCached *reportIndexes;
    @property (nonatomic, strong, readwrite) MTArrayCached *reportLayout;

    @property (nonatomic, strong) MTReportFormatterState *machineState; //At some point add the ability to format one page at a time.

    @property (nonatomic, strong) MTReportFormatterCache *reportFormatterCache;

    @property (nonatomic, strong) NSMutableArray *pageLayoutTemporary;
    @property (nonatomic, strong) NSMutableArray *pageIndexesTemporary;

    @property (nonatomic, strong) NSArray *lastResultRowComparsonValues;
    @property (nonatomic, strong) NSDictionary *layoutHeightsBySectionKey;

@end


@implementation MTReportFormatter

- (void)initalizeStateMachine {
    NSArray *sortDescriptors = [NSArray arrayWithArray:[[self dataDelegate] sortDescriptors]];

    self.machineState.rowCounter = 0;
    self.machineState.groupCounter = 0;
    self.machineState.pageCounter = 0;
    self.machineState.detailRowId = @(0);
    self.machineState.detailRowIdLast = @(0);
    self.machineState.sortDescriptors = sortDescriptors;
    self.machineState.counterHeightUsedCurrentPage = CGSizeZero.height;
}

- (NSArray *)keysForCachedID:(NSNumber *)rowid {
    NSDictionary *row = [[self datasource] dataForCacheId: rowid];
    return [NSArray arrayWithArray:[self keyValuesForResultRow:row]];
}

- (void)dealloc { }

- (id)initWithQuery:(MTQueryFull *)query layout:(RptqDocument *)layout options:(MTReportFormatterOptions)options  {
    self = [super initWithQuery:query];
    if (self) {
        [self setOptions:options];
        [self setLayout:layout];
    }
    return self;
}

+ (id)reportFormatterWithQuery:(MTQuery *)query layout:(RptqDocument *)layout options:(MTReportFormatterOptions)options {
    MTReportFormatter *result = [[MTReportFormatter alloc] initWithQuery:query layout:layout options:options];
    return result;
}

- (NSArray *)layoutForPage:(NSUInteger)page {
    NSArray *result = [NSArray arrayWithArray:[[self reportLayout] objectAtIndex:page]];
    return (page < [[self reportLayout] count]) ? result : nil;
}

- (NSUInteger)layoutIdentifier {
    NSUInteger layoutIdentifier;
    if (self.overrideIdentifier == nil) {
        NSManagedObjectID *objid = [[self layout] objectID];
        NSURL *url = [objid URIRepresentation];
        NSString *s = [url absoluteString];
        layoutIdentifier = [s hash];
    } else {
        layoutIdentifier = [self.overrideIdentifier hash];
    }
    return layoutIdentifier;
}

- (NSString *)nameHorizontalReportLayoutCache {
    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "lh", sizeString];
}
- (NSString *)nameVirticalReportLayoutCache {
    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "lv", sizeString];
}
- (NSString *)nameHorizontalReportIndexes {
    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "ih", sizeString];
}
- (NSString *)nameVirticalReportIndexes {
    NSString *sizeString = NSStringFromCGSize(self.page.layoutSize);
    return [NSString stringWithFormat:@"%lu%s%@", (unsigned long)[self layoutIdentifier], "iv", sizeString];
}

- (NSString *)nameCurrentReportIndexes {
    if ([self isLandscape]) {
        return [self nameHorizontalReportIndexes];
    } else {
        return [self nameVirticalReportIndexes];
    }
}
- (NSString *)nameCurrentReportLayout {
    if ([self isLandscape]) {
        return [self nameHorizontalReportLayoutCache];
    } else {
        return [self nameVirticalReportLayoutCache];
    }
}

- (void)setCachedDelegate:(id<MTCacheProtocol>)cachedDelegate {
    _cachedDelegate = cachedDelegate;
    [self initalize];
}

- (void)initalize {
    
    MTReportFormatterPageDefinition *page = [MTReportFormatterPageDefinition new];
    [self setPage:page];
    
    UIEdgeInsets margin = (self.options & MTReportFormatterOptionsMargin) ?
                            UIEdgeInsetsMake(CGFloatPointsForInches(1.0000f/4.0000f), CGFloatPointsForInches(1.0000f/4.0000f),
                                             CGFloatPointsForInches(1.0000f/4.0000f), CGFloatPointsForInches(1.0000f/4.0000f)) :
    UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.height, CGSizeZero.height, CGSizeZero.height);
    
    [[self page] setMargins:margin];

    
    MTReportFormatterState *machineState = [MTReportFormatterState new];
    [self setMachineState:machineState];
    [self initalizeStateMachine];
    
    MTReportFormatterCache *reportFormatterCache = [MTReportFormatterCache new];
    [self setReportFormatterCache:reportFormatterCache];
    
    NSMutableArray *temporaryLayoutForPage = [[NSMutableArray alloc] init];
    [self setPageLayoutTemporary:temporaryLayoutForPage];
    
    NSMutableArray *temporaryDataForPage = [[NSMutableArray alloc] init];
    [self setPageIndexesTemporary:temporaryDataForPage];
    
    if ([self layout]) {
        NSDictionary *layoutHeightsBySectionKeys = [RptqDocumentSection layoutHeightsBySectionKey:[self layout]];
        [self setLayoutHeightsBySectionKey:layoutHeightsBySectionKeys];
    } else {
        [self setLayoutHeightsBySectionKey:nil];
    }
    
}

- (void)setMarginUsingPrintableRect:(CGRect)printableRect {
    CGFloat top = printableRect.origin.y - CGPointZero.y;
    CGFloat left = printableRect.origin.x - CGPointZero.x;
    CGFloat bottom = self.page.layoutSize.height - printableRect.size.height - top;
    CGFloat right = self.page.layoutSize.width - printableRect.size.width - left;
    self.page.margins = UIEdgeInsetsMake(top, left, bottom, right);
}

#pragma mark - Reading cached data

//  Data is cached by group, page, and report.

- (BOOL)cachedIndexesExist {
    return [[self reportIndexes] count] > 0 && [[self reportLayout] count] > 0;
}

- (BOOL)format {
    BOOL updatedData = NO;
    
    NSAssert([self datasource] != nil, @"We need a datatable way before here");
    
    if ([self didRefresh] ||
        [self cachedIndexesExist] == NO ||
        [[self datasource] cacheExist] == NO) {
        updatedData = YES;
    }
    return updatedData;
}

- (void)formatForSize:(CGSize)printableSize {
    [self formatForSize:printableSize contentChanged:YES];
}

- (void)reformatForSize:(CGSize)printableSize {
    @synchronized(self) {
        [self format];
        [[self page] setLayoutSize:printableSize];
        [self loadLayoutAndIndexesFromCache];
        [self formatDocument];
    }
}

- (void)setLayoutSize:(CGSize)layoutSize {
    [[self page] setLayoutSize:layoutSize];
}

- (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged {

    @synchronized(self) {
        [[self page] setLayoutSize:printableSize];
        
        [self loadLayoutAndIndexesFromCache];
        
        if ([self format]) {
            
            if (contextChanged) {
                [self dropIndexes];
            }
            [self formatDocument];
        }
    }
}

- (void)formatDocument {

    [self initalizeStateMachine];
    
    self.machineState.counterHeightUsedCurrentPage += self.page.margins.top;

    NSDictionary *layoutHeightsBySectionKeys = [RptqDocumentSection layoutHeightsBySectionKey:[self layout]];
    [self setLayoutHeightsBySectionKey:layoutHeightsBySectionKeys];
    
    [self cleanupTemporaryReportIndexes];
    
    [self beginBulkInserts];
    
    [self addReportHeaderToReportLayout];
    [self addPageHeaderToReportLayout];
    [self addDetailToReportLayout];
    [self addReportFooterToReportLayout];
    
    NSArray *tlfp = [NSArray arrayWithArray:[self pageLayoutTemporary]];
    [[self reportLayout] addObject:tlfp];
    
    NSArray *tdfp = [NSArray arrayWithArray:[self pageIndexesTemporary]];
    [[self reportIndexes] addObject:tdfp];
    
    [self endBulkInserts];
    
    [self cleanupTemporaryReportIndexes];
    
    [[self reportFormatterCache] setLayout:[[self reportLayout] identifier]
                                andIndexes:[[self reportIndexes] identifier]
                                   forSize:self.page.layoutSize];
    
}

- (void)dropIndexes {
    [[self reportIndexes] removeAllObjects];
    [[self reportLayout] removeAllObjects];
}

- (void)dumpCache {
    [[self reportFormatterCache] dumpCache];
}

- (void)beginBulkInserts {
    [[self reportIndexes] beginBulkInserts];
    [[self reportLayout] beginBulkInserts];
}

- (void)endBulkInserts {
    [[self reportLayout] endBulkInserts];
    [[self reportIndexes] endBulkInserts];
}

- (void)loadLayoutAndIndexesFromCache {
    MTArrayCached *ixarray = [[MTArrayCached alloc] initWithIdentifier:[self nameCurrentReportIndexes]
                                                        cachedDelegate:self.cachedDelegate];
    [self setReportIndexes:ixarray];
    MTArrayCached *lyarray = [[MTArrayCached alloc] initWithIdentifier:[self nameCurrentReportLayout]
                                                        cachedDelegate:self.cachedDelegate];
    [self setReportLayout:lyarray];
    [self cleanupTemporaryReportIndexes];
}

- (void)initReportLayoutContainers {
    [[self reportLayout] removeAllObjects];
    [[self reportIndexes] removeAllObjects];
    [self setLastResultRowComparsonValues:nil];
}

- (void)cleanupTemporaryReportIndexes {
    [self cleanupTemporaryPageIndexes];
}

- (void)cleanupTemporaryPageIndexes {
    [[self pageLayoutTemporary] removeAllObjects];
    [[self pageIndexesTemporary] removeAllObjects];
}

+ (NSString *)KeyReportSectionType {
    return MTReportSectionType;
}

- (NSUInteger)numberOfGroups {
    return [self.machineState.sortDescriptors count];
}

- (void)displayNewGroupFootersIfNeeded:(NSArray *)currentValues  andLastValues:(NSArray *)lastValues {
    for (NSInteger groupLevel = [lastValues count] - 1; groupLevel >= 0; groupLevel--) {
        @autoreleasepool {
            NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel];
            SEL comparec = [sortDesc selector];
            NSComparisonResult comparsonResult = [self compareValue: lastValues[groupLevel]
                                                          withValue: currentValues[groupLevel]
                                                      usingSelector: comparec];
            
            BOOL newFooter = comparsonResult != NSOrderedSame;
            
            if (newFooter) {
                RptqQueryGroup *group = [[self sortedQueryGroups] objectAtIndex:groupLevel];
                [self addHeightFromGroupFooterWithQueryGroup: group];
                [self addGroupFooterAtLevel:groupLevel];
            }
        }
    }
}

- (void)displayNewGroupHeadersIfNeeded:(NSArray *)currentValues andLastValues:(NSArray *)lastValues {

    for (NSInteger groupLevel = 0; groupLevel < [currentValues count]; groupLevel++) {
        @autoreleasepool {
            BOOL newHeader = [lastValues count] == 0;
            if (newHeader == NO) {
                
                id value = lastValues[groupLevel];
                id value2 = currentValues[groupLevel];
                
                NSSortDescriptor *sortDesc = self.machineState.sortDescriptors[groupLevel];
                SEL comparec = [sortDesc selector];
                NSComparisonResult comparsonResult = [self compareValue:value withValue:value2 usingSelector:comparec];
                
                newHeader = comparsonResult != NSOrderedSame;
            }
            
            if (newHeader) {
                RptqQueryGroup *gh = [[self sortedQueryGroups] objectAtIndex:groupLevel];
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

- (NSIndexSet *)rowidsForPage:(NSInteger)pageIndex {
    return _reportIndexes[pageIndex];
}

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails {
    
    for (NSInteger i=0; i<[containerDetails count]; i++) {
        @autoreleasepool {
            [self addHeightFromDocumentSectionToReportLayout:[[self layout] hasDetailSection]];
            NSNumber *rowid = containerDetails[i][@"ROWID"];
            self.machineState.detailRowId = rowid;
            [self addDetail];

        }
    }
}

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupHeaderWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
        @autoreleasepool {
            if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                [self addHeightFromDocumentSectionToReportLayout:documentSection];
                break;
            }
        }
    }
}

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupFooterWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
        @autoreleasepool {
            if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                [self addHeightFromDocumentSectionToReportLayout:documentSection];
                break;
            }
        }
    }
}

- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection {
    return [[self layoutHeightsBySectionKey][[documentSection sectionKey]] floatValue];
}

- (void)addHeightFromDocumentSectionToReportLayout:(RptqDocumentSection *)documentSection {
    CGFloat layoutHeight = [self heightForSection:documentSection];
    [self addPageBreakToReportLayoutWithNextItemHeight: layoutHeight];
    self.machineState.counterHeightUsedCurrentPage = self.machineState.counterHeightUsedCurrentPage + layoutHeight;
}

- (RptqQueryGroup *)sortGroupAtLevel:(NSInteger)level {
    RptqQueryGroup *nextGroup = nil;
    if (level < [[self sortedQueryGroups] count]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == %d", level];
        NSArray *filteredGroups = [[self sortedQueryGroups] filteredArrayUsingPredicate: predicate];
        if ([filteredGroups count] >= 1) {
            nextGroup = [filteredGroups firstObject];
        }
    }
    return nextGroup;
}

- (void)addDetailToReportLayout {
    [self initReportLayoutContainers];
    self.machineState.rowCounter = 0;
    
    RptqDocumentSection *detailSection = [[self layout] hasDetailSection];
    
    BOOL firstRow = YES;
        
    NSArray *sqg = [[[self query] queryObject] sortedQueryGroups];
    [self setSortedQueryGroups:sqg];
    
    BOOL rowIdOnly = YES;
    BOOL calculatedRowId = NO;

    for (id resultRow in [[self datasource] enumeratorForReportData]) {
        @autoreleasepool {
            //Get row id
            if (calculatedRowId == NO) {
                if ([resultRow isKindOfClass:[NSDictionary class]]) {
                    rowIdOnly = NO;
                }
                calculatedRowId = YES;
            }
            self.machineState.detailRowIdLast = self.machineState.detailRowId;
            self.machineState.detailRowId = rowIdOnly ? resultRow : [resultRow objectForKey:@"ROWID"];
            
            //Get row key values
            NSArray *keyValuesForComparson = [self keyValuesForResultRow:resultRow];
            
            //Display new footers if needed.
            if (!firstRow) {
                [self displayNewGroupFootersIfNeeded:keyValuesForComparson andLastValues:[self lastResultRowComparsonValues]];
            }
            
            //Display new group headers if needed.
            [self displayNewGroupHeadersIfNeeded:keyValuesForComparson andLastValues:[self lastResultRowComparsonValues]];
            [self addHeightFromDocumentSectionToReportLayout:detailSection];
            
            [self addDetail];
            
            
            [self setLastResultRowComparsonValues: keyValuesForComparson];
            
            firstRow = NO;
            self.machineState.rowCounter++;
            
        }
    }
}

- (NSArray *)keyValuesForResultRow:(id)resultRow {
    NSArray *keyValues = nil;
    if ([resultRow isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *keyValuesForComparson = [[NSMutableArray alloc] initWithCapacity:[self numberOfGroups]];
        for (NSSortDescriptor *sortDesc in self.machineState.sortDescriptors) {
            id predicateValue = [resultRow objectForKey:[sortDesc key]];
            if (predicateValue != nil) {
                [keyValuesForComparson addObject:predicateValue];
            } else {
                [keyValuesForComparson addObject:[NSNull null]];
            }
        }
        keyValues = [NSArray arrayWithArray:keyValuesForComparson];
    } else {
        keyValues = [NSArray array];
    }
    return keyValues;
}

- (CGFloat)printableHeight {
    return self.page.layoutSize.height - self.page.margins.top - self.page.margins.bottom;
}
// FIXME: Make sure paper rect is passed in to the software
- (BOOL)addPageBreakToReportLayoutWithNextItemHeight:(CGFloat)nextItemHeight {
    
    BOOL newPageCreated = NO;
    
//    @autoreleasepool {
        CGFloat pageFooterSectionHeight = [self heightForSection:self.layout.hasPageFooterSection];
        
        if (self.machineState.counterHeightUsedCurrentPage + nextItemHeight + pageFooterSectionHeight > [self printableHeight]) {
            
            newPageCreated = YES;
            CGFloat newHeight = self.machineState.counterHeightUsedCurrentPage + pageFooterSectionHeight;
            self.machineState.counterHeightUsedCurrentPage = newHeight;
            [self addPageFooter];
            
            NSArray *pageInfo = [self pageLayoutTemporary] != nil ? [NSArray arrayWithArray: [self pageLayoutTemporary]] : @[];
            [[self reportLayout] addObject:pageInfo];
            
            //NSIndexSet *rowids = [self pageIndexesTemporary] != nil ? [[NSIndexSet alloc] initWithIndexSet:[self pageIndexesTemporary]] : [NSIndexSet indexSet];
            NSArray *rowids = [self pageIndexesTemporary] != nil ? [NSArray arrayWithArray: [self pageIndexesTemporary]] : [NSArray array];
            [[self reportIndexes] addObject:rowids];
            
            [self cleanupTemporaryPageIndexes];
            
            self.machineState.pageCounter++;
            [[MTNotificationDidFormatPage sharedObject] reportFormatter:self formattedPage:self.machineState.pageCounter];
            RptqDocumentSection *pageHeaderSection = [[self layout] hasPageHeaderSection];
            CGFloat pageHeaderHeight = CGPointZero.y;
            pageHeaderHeight += [self heightForSection:pageHeaderSection];
            self.machineState.counterHeightUsedCurrentPage = pageHeaderHeight;
            
            [self addPageHeader];
            
        }
//    }

    return newPageCreated;
}

- (void)addReportHeaderToReportLayout {
    RptqDocumentSection *reportHeaderSection = [[self layout] hasReportHeaderSection];
    CGFloat reportHeaderHeight = [self heightForSection:reportHeaderSection];
    CGFloat printableSpaceUsed = self.machineState.counterHeightUsedCurrentPage + reportHeaderHeight;
    self.machineState.counterHeightUsedCurrentPage = printableSpaceUsed;
    [self addReportHeader];
}

- (void)addPageHeaderToReportLayout {
    RptqDocumentSection *pageHeaderSection = [[self layout] hasPageHeaderSection];
    CGFloat pageHeaderHeight = [self heightForSection:pageHeaderSection];
    CGFloat printableSpaceUsed = self.machineState.counterHeightUsedCurrentPage + pageHeaderHeight;
    self.machineState.counterHeightUsedCurrentPage = printableSpaceUsed;
    [self addPageHeader];
}

- (void)addPageFooterToReportLayout {
    [self addHeightFromDocumentSectionToReportLayout:[[self layout] hasPageFooterSection]];
    [self addPageFooter];
}

- (void)addReportFooterToReportLayout {
    [self addHeightFromDocumentSectionToReportLayout:[[self layout] hasReportFooterSection]];
    [self addPageFooterToReportLayout];
    [self addReportFooter];
}

- (void)addGroupHeaderLevel:(NSUInteger)groupLevel {
    NSNumber *level = @(groupLevel);
    NSNumber *type = @(MNSDocumentSectionTypeGroupHeader);
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : type,
                        MTReportGroupLevel : level,
                        MTReportDetailRowId : self.machineState.detailRowId};
    if (groupLevel == [self numberOfGroups] - 1) {
        self.machineState.groupCounter++;
    }
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addPageFooter {
    NSNumber *section = @(MNSDocumentSectionTypePageFooter);
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : section,
                        MTReportDetailRowId : self.machineState.detailRowId};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addReportFooter {
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypeReportFooter),
                        MTReportDetailRowId : self.machineState.detailRowId};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addGroupFooterAtLevel:(NSUInteger)groupLevel {
    NSNumber *gl = [[NSNumber alloc] initWithUnsignedInteger:groupLevel];
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypeGroupFooter),
                        MTReportGroupLevel : gl,
                        MTReportDetailRowId : self.machineState.detailRowIdLast};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addDetail {
    NSNumber *type = @(MNSDocumentSectionTypeBody);
    NSDictionary *detail = @{[MTReportFormatter KeyReportSectionType] : type,
                             MTReportDetailRowId : self.machineState.detailRowId};
    [[self pageLayoutTemporary] addObject: detail];

    [[self pageIndexesTemporary] addObject:self.machineState.detailRowId];
    //[[self pageIndexesTemporary] addIndex:[self.machineState.detailRowId integerValue]];
}


- (void)addReportHeader {
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypeReportHeader),
                        MTReportDetailRowId : self.machineState.detailRowId};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addPageHeader {
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypePageHeader),
                        MTReportDetailRowId : self.machineState.detailRowId};
    [[self pageLayoutTemporary] addObject:  d];
}

- (NSUInteger)numberOfPages {
    return [[self reportLayout] count];
}


/*
 // FIXME: Write function to return results for keys without having data stored in memeory.
 */

+ (id)dataForGroupData:(id)data andKeys:(NSArray *)keys {
    id resultData = nil;
    if ([data isKindOfClass:[NSArray class]]) {
        resultData = [[NSArray alloc] initWithArray:data];
    } else {
        if ([keys count] > 0) {
            id subData = [data objectForKey:[keys objectAtIndex:0]];
            NSArray *subKeys = nil;
            if ([keys count] > 1) {
                NSRange range = NSMakeRange(1, [keys count] - 1);
                subKeys = [keys objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
                resultData = [MTReportFormatter dataForGroupData:subData andKeys:subKeys];
            } else if ([keys count] == 1) {
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
    return [[self reportLayout][pageIndex] objectEnumerator];
}

#pragma mark - Help functions

- (BOOL)isLandscape {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
