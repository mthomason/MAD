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

//Why the fuck!!!

#import "MTDatabaseConnection.h"
#import "MTDatabase.h"

#import "MTPageCaching.h"

#import "MTLog.h"
#import "NSData+Comparson.h"

NSString * const MTNullIdentifier = @"(null)";

@interface MTReportFormatter ()

@property (nonatomic, strong, readwrite) RptqDocument *layout;

@property (nonatomic, strong, readwrite) NSMutableArray *reportIndexes;
@property (nonatomic, strong, readwrite) NSMutableArray *reportLayout;

@property (nonatomic, strong) MTPageCaching *pageCachingVirtual;
@property (nonatomic, strong) MTReportFormatterCache *reportFormatterCache;


@property (nonatomic, assign) CGSize printableSize;
@property (nonatomic, assign) CGRect printableRect;

@property (nonatomic, assign) CGSize layoutSize;
@property (nonatomic, assign) CGFloat counterHeightUsedCurrentPage;


@property (nonatomic, strong) NSMutableArray *pageLayoutTemporary;
@property (nonatomic, strong) NSMutableIndexSet *pageIndexesTemporary;

@property (nonatomic, strong) NSArray *lastResultRowComparsonValues;

@property (nonatomic, strong) NSDictionary *layoutHeightsBySectionKey;

@property (nonatomic, assign) BOOL setFirstRowIdTemporary;
@property (nonatomic, strong) NSNumber *firstRowIdTemporary;
@property (nonatomic, strong) NSNumber *lastRowIdTemporary;

@property (nonatomic, strong) NSValue *keyReportSectionType;

@end

@implementation MTReportFormatter

- (void)dealloc {
    [[self reportFormatterCache] dumpCache];
    [[self reportIndexes] removeAllObjects];
    [[self pageCachingVirtual] dumpCache];
}

- (id)initWithQuery:(MTQueryFull *)query andLayout:(RptqDocument *)layout {
    self = [super initWithQuery:query];
    if (self) {
        [self setLayout:layout];
        [self initalize];
    }
    return self;
}

- (NSArray *)layoutForPage:(NSUInteger)page {
    return (page < [[self reportLayout] count]) ? [[self reportLayout] objectAtIndex:page] : nil;
}

+ (id)reportFormatterWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout {
    MTReportFormatter *result = [[MTReportFormatter alloc] initWithQuery:query andLayout:layout];
    return result;
}

- (void)initalize {
    
    MTReportFormatterCache *reportFormatterCache = [MTReportFormatterCache new];
    [self setReportFormatterCache:reportFormatterCache];
    
    NSMutableArray *reportLayout = [[NSMutableArray alloc] init];
    [self setReportLayout:reportLayout];
    
    NSMutableArray *temporaryLayoutForPage = [[NSMutableArray alloc] init];
    [self setPageLayoutTemporary:temporaryLayoutForPage];
    
    NSMutableArray *reportIndexes = [NSMutableArray new];
    [self setReportIndexes:reportIndexes];
    
    MTPageCaching *pageCaching = [[MTPageCaching alloc] init];
    [self setPageCachingVirtual:pageCaching];
    
    NSMutableIndexSet *temporaryDataForPage = [[NSMutableIndexSet alloc] init];
    [self setPageIndexesTemporary:temporaryDataForPage];
    
    [self setLayoutHeightsBySectionKey:nil];
    
    [self setSetFirstRowIdTemporary:NO];
    
}

#pragma mark - Reading cached data

//  Data is cached by group, page, and report.

- (BOOL)format {
    return [super format];
}

- (void)formatForSize:(CGSize)printableSize {
    [self formatForSize:printableSize options:0];
}

- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options {
    [self formatForSize:printableSize options:options contentChanged:YES];

}

- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options contentChanged:(BOOL)contextChanged {

    if ([super format]) {
        
        [self setLayoutSize:printableSize];
        [self setPrintableSize:printableSize];
        
        if (contextChanged) {
            
            [[self reportFormatterCache] dumpCache];
            [self formatDocumentForSize:printableSize options:options];
        } else {
            
            [self loadLayoutAndIndexesFromCacheForSize:printableSize andOptions:options];
            
        }
    }
}

- (void)formatDocumentForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options {
    [[self reportIndexes] removeAllObjects];
    [[self pageCachingVirtual] dumpCache];
    
    NSDictionary *layoutHeightsBySectionKeys = [RptqDocumentSection layoutHeightsBySectionKey:[self layout]];
    [self setLayoutHeightsBySectionKey:layoutHeightsBySectionKeys];
    
    [self cleanupTemporaryReportIndexes];
    [self setCounterHeightUsedCurrentPage:CGSizeZero.height];
    
    [self setCounterHeightUsedCurrentPage: CGSizeZero.height];
    [self addReportHeaderToReportLayout];
    [self addPageHeaderToReportLayout];
    [self addDetailToReportLayout];
    [self addReportFooterToReportLayout];
    
    NSArray *tlfp = [[NSArray alloc] initWithArray:[self pageLayoutTemporary]];
    [[self reportLayout] addObject:tlfp];
    
    NSIndexSet *tdfp = [[NSIndexSet alloc] initWithIndexSet:[self pageIndexesTemporary]];
    [[self reportIndexes] addObject:tdfp];
    
    [self cleanupTemporaryReportIndexes];
    
    [[self reportFormatterCache] setLayout:[self reportLayout] andIndexes:[self reportIndexes] forSize:printableSize];
    
}

- (void)loadLayoutAndIndexesFromCacheForSize:(CGSize)size andOptions:(MTReportFormatterOptions)options {
    NSArray *indexes = [[self reportFormatterCache] indexesForSize:size];
    NSArray *layout = [[self reportFormatterCache] layoutForSize:size];
    if (indexes == nil || layout == nil) {
        [self formatDocumentForSize:size options:options];
    } else {
        NSMutableArray *reportIndexes = [NSMutableArray arrayWithArray:indexes];
        NSMutableArray *reportLayout = [NSMutableArray arrayWithArray:layout];
        [self setReportIndexes:reportIndexes];
        [self setReportLayout:reportLayout];
        [self cleanupTemporaryReportIndexes];
    }
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
    [[self pageIndexesTemporary] removeAllIndexes];
}

- (void)addReportHeader {
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypeReportHeader)};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addPageHeader {
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypePageHeader)};
    [[self pageLayoutTemporary] addObject:  d];
}

+ (NSValue *)KeyReportSectionType {
    static NSValue *value;
    if (value == nil) {
        value = [NSValue valueWithPointer:(__bridge const void *)(MTReportSectionType)];
    }
    return value;
}

- (void)addAllDetail {
    
    [self initReportLayoutContainers];

    NSInteger numberOfGroups = [[self sortDescriptorsByGroupSorted] count];
    
    RptqDocumentSection *detailSection = [[self layout] hasDetailSection];

    BOOL firstRow = YES;

    NSEnumerator *dataEnumerator = [[[self query] datatable] enumeratorForKeyObjectsSorted];

    NSArray *sqg = [[[self query] queryObject] sortedQueryGroups];
    [self setSortedQueryGroups:sqg];
    
    BOOL rowIdOnly = YES;
    BOOL calculatedRowId = NO;
    for (id resultRow in dataEnumerator) {
        
        //Get row id
        if (calculatedRowId == NO) {
            if ([resultRow isKindOfClass:[NSDictionary class]]) {
                rowIdOnly = NO;
            }
            calculatedRowId = YES;
        }
        NSNumber *rowid = rowIdOnly ? resultRow : [resultRow objectForKey:@"ROWID"];


        //Get row key values
        NSMutableArray *keyValuesForComparson = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        if (rowIdOnly == NO) {
            for (NSSortDescriptor *sortDesc in [self sortDescriptorsByGroupSorted]) {
                id predicateValue = [resultRow objectForKey:[sortDesc key]];
                [keyValuesForComparson addObject:predicateValue];
            }
        }
        
        //Display new footers if needed.
        if (!firstRow) {
            [self displayNewGroupFootersIfNeeded:keyValuesForComparson andLastValues:[self lastResultRowComparsonValues]];
        }
        
        //Display new group headers if needed.
        [self displayNewGroupHeadersIfNeeded:keyValuesForComparson andLastValues:[self lastResultRowComparsonValues]];
        [self addHeightFromDocumentSectionToReportLayout:detailSection];
        
        [self addDetail:rowid];

        
        [self setLastResultRowComparsonValues: keyValuesForComparson];

        firstRow = NO;
    }
}


- (NSDictionary *)firstObjectOnReport {
    return [self firstObjectOnPageAtIndex:0];
}

- (NSDictionary *)lastObjectOnReport {
    return [self lastObjectOnPageAtIndex:[self numberOfPages] - 1];
}

- (NSDictionary *)firstObjectOnPageAtIndex:(NSInteger)pageIndex {
    NSNumber *firstRowid = nil;
    for (NSDictionary *pageSection in [self reportLayout][pageIndex]) {
        MNSDocumentSectionType typeDocumentSection = [[pageSection objectForKey: [MTReportFormatter KeyReportSectionType]] integerValue];
        if (typeDocumentSection == MNSDocumentSectionTypeBody) {
            firstRowid = pageSection[MTReportDetailRowId];
            break;
        }
    }
    return firstRowid != nil ? [self dataForCacheId:firstRowid] : nil;
}

- (NSDictionary *)lastObjectOnPageAtIndex:(NSInteger)pageIndex {
    NSNumber *lastRowid = nil;
    for (NSDictionary *pageSection in [[self reportLayout][pageIndex] reverseObjectEnumerator]) {
        MNSDocumentSectionType typeDocumentSection = [[pageSection objectForKey: [MTReportFormatter KeyReportSectionType]] integerValue];
        if (typeDocumentSection == MNSDocumentSectionTypeBody) {
            lastRowid = pageSection[MTReportDetailRowId];
            break;
        }
    }
    return lastRowid != nil ? [self dataForCacheId:lastRowid] : nil;
}

- (void)displayNewGroupFootersIfNeeded:(NSArray *)currentValues  andLastValues:(NSArray *)lastValues {
    for (NSInteger groupLevel = [lastValues count] - 1; groupLevel >= 0; groupLevel--) {

        NSSortDescriptor *sortDesc = [self sortDescriptorsByGroupSorted][groupLevel];
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

- (void)displayNewGroupHeadersIfNeeded:(NSArray *)currentValues andLastValues:(NSArray *)lastValues {

    for (NSInteger groupLevel = 0; groupLevel < [currentValues count]; groupLevel++) {

        BOOL newHeader = [lastValues count] == 0;
        if (newHeader == NO) {

            id value = lastValues[groupLevel];
            id value2 = currentValues[groupLevel];
            
            NSSortDescriptor *sortDesc = [self sortDescriptorsByGroupSorted][groupLevel];
            SEL comparec = [sortDesc selector];
            NSComparisonResult comparsonResult = [self compareValue:value withValue:value2 usingSelector:comparec];
            
            newHeader = comparsonResult != NSOrderedSame;
        }
        
        
        if (newHeader) {
            RptqQueryGroup *gh = [[self sortedQueryGroups] objectAtIndex:groupLevel];
            [self addHeightFromGroupHeaderWithQueryGroup: gh];
            
            NSRange range = NSMakeRange(0, groupLevel + 1);
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
            NSArray *currentKeys = [currentValues objectsAtIndexes:indexSet];

            [self addGroupHeaderLevel:groupLevel withKeys:currentKeys];
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

- (NSEnumerator *)dataForPageIndex:(NSInteger)pageIndex {
    return [[[self query] datatable] enumeratorForRowIds: [self rowidsForPage:pageIndex]];
}

- (NSDictionary *)resultsForPageIndex:(NSInteger)pageIndex {
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    for (NSDictionary *rowdata in [self dataForPageIndex:pageIndex]) {
        [results setObject:rowdata forKey:rowdata[@"ROWID"]];
    }
    return results;
}

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails {
    
    for (NSInteger i=0; i<[containerDetails count]; i++) {
        @autoreleasepool {

            [self addHeightFromDocumentSectionToReportLayout:[[self layout] hasDetailSection]];
            NSNumber *rowid = containerDetails[i][@"ROWID"];
            [self addDetail:rowid];

        }
    }
}

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupHeaderWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
        if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
            [self addHeightFromDocumentSectionToReportLayout:documentSection];
            break;
        }
    }
}

// !!!: Is this getting the height correctly?
- (void)addHeightFromGroupFooterWithQueryGroup:(RptqQueryGroup *)queryGroup {
    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
        if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
            [self addHeightFromDocumentSectionToReportLayout:documentSection];
            break;
        }
    }
}

- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection {
    return [[self layoutHeightsBySectionKey][[documentSection sectionKey]] floatValue];
}

- (void)addHeightFromDocumentSectionToReportLayout:(RptqDocumentSection *)documentSection {
    CGFloat layoutHeight = [self heightForSection:documentSection];
    [self addPageBreakToReportLayoutWithNextItemHeight: layoutHeight];
    self.counterHeightUsedCurrentPage = ([self counterHeightUsedCurrentPage] + layoutHeight);
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
    [self addAllDetail];
}

// FIXME: Make sure paper rect is passed in to the software
- (BOOL)addPageBreakToReportLayoutWithNextItemHeight:(CGFloat)nextItemHeight {
    
    BOOL newPageCreated = NO;
    CGRect pageRect;
    RptqDocument *document = [self layout];
    RptqDocumentSection *pageFooterSection = [document hasPageFooterSection];
    CGFloat pageFooterSectionHeight = [self heightForSection:pageFooterSection];
    
    pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    
    if ([self counterHeightUsedCurrentPage] + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        
        //MTLog(@"Page Break");
        
        newPageCreated = YES;
        CGFloat newHeight = [self counterHeightUsedCurrentPage] + pageFooterSectionHeight;
        [self setCounterHeightUsedCurrentPage:newHeight];
        [self addPageFooter];
        
        NSArray *pageInfo = [NSArray arrayWithArray: [self pageLayoutTemporary]];
        [[self reportLayout] addObject:pageInfo];
        
        NSIndexSet *rowids = [[NSIndexSet alloc] initWithIndexSet:[self pageIndexesTemporary]];
        [[self reportIndexes] addObject:rowids];
        
        [self cleanupTemporaryPageIndexes];
        
        RptqDocumentSection *pageHeaderSection = [document hasPageHeaderSection];
        CGFloat pageHeaderHeight = CGPointZero.y;
        pageHeaderHeight += [self heightForSection:pageHeaderSection];
        [self setCounterHeightUsedCurrentPage: pageHeaderHeight];
        
        [self addPageHeader];
        
        [self setFirstRowIdTemporary:NO];
    }
    return newPageCreated;
}

- (void)addReportHeaderToReportLayout {
    RptqDocumentSection *reportHeaderSection = [[self layout] hasReportHeaderSection];
    CGFloat reportHeaderHeight = [self heightForSection:reportHeaderSection];
    CGFloat printableSpaceUsed = [self counterHeightUsedCurrentPage] + reportHeaderHeight;
    [self setCounterHeightUsedCurrentPage: printableSpaceUsed];
    [self addReportHeader];
}

- (void)addPageHeaderToReportLayout {
    RptqDocumentSection *pageHeaderSection = [[self layout] hasPageHeaderSection];
    CGFloat pageHeaderHeight = [self heightForSection:pageHeaderSection];
    CGFloat printableSpaceUsed = [self counterHeightUsedCurrentPage] + pageHeaderHeight;
    [self setCounterHeightUsedCurrentPage: printableSpaceUsed];
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

- (void)addGroupHeaderLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys {
    NSNumber *level = @(groupLevel);
    NSArray *newKeys = [NSArray arrayWithArray:keys];
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType]     : @(MNSDocumentSectionTypeGroupHeader),
                        MTReportGroupLevelKeys  : newKeys,
                        MTReportGroupLevel      : level};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addPageFooter {
    NSNumber *section = @(MNSDocumentSectionTypePageFooter);
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : section,
                        //MTReportPageFirstRowId : [self firstRowIdTemporary],
                        //MTReportPageLastRowId : [self lastRowIdTemporary],
                        };
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addReportFooter {
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypeReportFooter)};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addGroupFooterAtLevel:(NSUInteger)groupLevel {
    NSNumber *gl = [[NSNumber alloc] initWithUnsignedInteger:groupLevel];
    NSDictionary *d = @{[MTReportFormatter KeyReportSectionType] : @(MNSDocumentSectionTypeGroupFooter),
                        MTReportGroupLevel : gl};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addDetail:(NSNumber *)detailRowId {
    NSNumber *type = @(MNSDocumentSectionTypeBody);
    NSDictionary *detail = @{[MTReportFormatter KeyReportSectionType] : type,
                             MTReportDetailRowId : detailRowId};
    [[self pageLayoutTemporary] addObject: detail];
    [[self pageIndexesTemporary] addIndex:[detailRowId integerValue]];
}

- (NSUInteger)numberOfPages {
    NSUInteger numberOfPages = 0;
    if ([self reportLayout] == nil) {
        [self formatForSize:[self printableRect].size];
    }
    if ([self reportLayout] != nil) {
        numberOfPages = [[self reportLayout] count];
    }
    return numberOfPages;
}

// Uses sqlite3 rowid
- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId {
    return [[[self query] datatable] dataForCacheId:cacheId];
}

- (id)dataForGroupKeys:(NSArray *)keys {
    return [NSArray arrayWithArray:[[[self query] datatable] objectsForGroupKeys:keys]];
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

- (BOOL)nullKeyExist:(NSArray *)keys {
    BOOL nullGroupExist = NO;
    for (id keyObj in keys) {
        if ([keyObj isKindOfClass:[NSString class]]) {
            if ([keyObj isEqualToString: MTNullIdentifier]) {
                nullGroupExist = YES;
                break;
            }
        }
    }
    return nullGroupExist;
}

- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex {
    return [[self reportLayout][pageIndex] objectEnumerator];
}

#pragma mark - Help functions

- (BOOL)isLandscape {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (CGSize)sizeLastCachedPageLayoutPortrate {
    return CGSizeFromString([[NSUserDefaults standardUserDefaults] stringForKey:@"MTCachedSizeVertical"]);
}

- (CGSize)sizeLastCachedPageLayoutLandscape {
    return CGSizeFromString([[NSUserDefaults standardUserDefaults] stringForKey:@"MTCachedSizeHorizontal"]);
}

- (void)setPageLayoutSizeForCachePortrate:(CGSize)size {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:NSStringFromCGSize(size) forKey:@"MTCachedSizeVertical"];
    [standardUserDefaults synchronize];
}

- (void)setPageLayoutSizeForCacheLandscape:(CGSize)size {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:NSStringFromCGSize(size) forKey:@"MTCachedSizeHorizontal"];
    [standardUserDefaults synchronize];
}

// !!!: Broke, in such a way that it says it should fucking format every fucking time.

- (BOOL)shouldFormatAgain:(CGSize)printableSize options:(MTReportFormatterOptions)options {
    return YES;
        /*
    BOOL landscape = [self isLandscape];
    CGSize lastCachedPageSizeForOrientation = landscape ? [self sizeLastCachedPageLayoutLandscape]:
    [self sizeLastCachedPageLayoutPortrate];
    
    BOOL formatAgain = [self didRefresh] || (CGSizeEqualToSize(lastCachedPageSizeForOrientation, self.layoutSize) == NO);
    if (formatAgain) {
        if (landscape) {
            [self setPageLayoutSizeForCacheLandscape:printableSize];
        } else {
            [self setPageLayoutSizeForCachePortrate:printableSize];
        }
    }
    return formatAgain;*/
}

- (RptqQueryGroup *)firstQueryGroup {
    
    RptqDatabase *database = [[[self layout] hasDatabaseSchemas] anyObject];
    NSSet *hasQueries = [database hasQueries];
    RptqQuery *query = [hasQueries anyObject];
    return [query firstQueryGroup];
    
}

@end
