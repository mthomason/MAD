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

//Why the fuck!!!

#import "MTDatabaseConnection.h"
#import "MTDatabase.h"

#import "MTPageCaching.h"

NSString * const MTNullIdentifier = @"(null)";

@interface MTReportFormatter ()

@property (nonatomic, strong, readwrite) RptqDocument *layout;

@property (nonatomic, assign) CGSize printableSize;
@property (nonatomic, assign) CGRect printableRect;

@property (nonatomic, assign) CGSize layoutSize;

@property (nonatomic, assign) CGFloat counterHeightUsedCurrentPage;

@property (nonatomic, strong, readwrite) NSArray *reportIndexes;
@property (nonatomic, strong, readwrite) NSArray *reportLayout;

@property (nonatomic, strong) NSMutableArray *pageLayoutTemporary;
@property (nonatomic, strong) NSMutableArray *reportLayoutTemporary;

@property (nonatomic, strong) NSMutableIndexSet *pageIndexesTemporary;
@property (nonatomic, strong) NSMutableArray *reportIndexesTemporary;

@property (nonatomic, strong) MTPageCaching *pageCaching;

@property (nonatomic, strong) NSEnumerator *enumeratorForReportDetail;

@property (nonatomic, strong) NSArray *lastResultRowComparsonValues;

@end

@implementation MTReportFormatter

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
    
    NSMutableArray *temporaryLayoutByPage = [[NSMutableArray alloc] init];
    [self setReportLayoutTemporary:temporaryLayoutByPage];
    
    NSMutableArray *temporaryLayoutForPage = [[NSMutableArray alloc] init];
    [self setPageLayoutTemporary:temporaryLayoutForPage];
    
    NSMutableArray *temporaryDataByPage = [[NSMutableArray alloc] init];
    [self setReportIndexesTemporary:temporaryDataByPage];
    
    MTPageCaching *pageCaching = [[MTPageCaching alloc] init];
    [self setPageCaching:pageCaching];
    
    NSMutableIndexSet *temporaryDataForPage = [[NSMutableIndexSet alloc] init];
    [self setPageIndexesTemporary:temporaryDataForPage];
    
    NSArray *layoutByPage = @[];
    [self setReportLayout:layoutByPage];
    
    NSArray *dataByPage = @[];
    [self setReportIndexes:dataByPage];
    
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

    if ([super format]) {
        
        if ([self shouldFormatAgain:printableSize]) {
            
            [[self pageCaching] dumpCache];

            [self setLayoutSize:printableSize];
            [self setPrintableSize:printableSize];
            
            [RptqDocumentSection batchUpdateSectionLayoutHeights:[self layout]];
            
            [self cleanupTemporaryReportIndexes];
            [self setCounterHeightUsedCurrentPage:CGSizeZero.height];

            [self setCounterHeightUsedCurrentPage: CGSizeZero.height];
            [self addReportHeaderToReportLayout];
            [self addPageHeaderToReportLayout];
            [self addDetailToReportLayout];
            [self addReportFooterToReportLayout];
            
            NSArray *tlfp = [[NSArray alloc] initWithArray:[self pageLayoutTemporary]];
            [[self reportLayoutTemporary] addObject:tlfp];
            
            NSIndexSet *tdfp = [[NSIndexSet alloc] initWithIndexSet:[self pageIndexesTemporary]];
            [[self reportIndexesTemporary] addObject:tdfp];
            
            NSArray *tlbp = [[NSArray alloc] initWithArray:[self reportLayoutTemporary]];
            [self setReportLayout: tlbp];
            
            NSArray *tdbp = [[NSArray alloc] initWithArray:[self reportIndexesTemporary]];
            [self setReportIndexes: tdbp];
            
        }
    }
}

- (void)initReportLayoutContainers {
    NSArray *layoutByPage = @[];
    [self setReportLayout:layoutByPage];
    
    NSArray *dataByPage = @[];
    [self setReportIndexes:dataByPage];
    
    [self setLastResultRowComparsonValues:nil];
}

- (id)addGroupedResults:(NSArray *)sortedResults
                     level:(NSUInteger)level {
    
    
    BOOL detailLevel = level == [[self sortDescriptorsByGroupSorted] count];
    id results = nil;
    
    if (detailLevel) {
    
        results = [sortedResults copy];

    } else {

        results = [[NSMutableDictionary alloc] init];
        NSMutableArray *resultsForGroup = [[NSMutableArray alloc] init];
        NSSortDescriptor *sortDescriptor = detailLevel ? nil : [[self sortDescriptorsByGroupSorted] objectAtIndex:level];
        NSString *sortFieldName =  detailLevel ? nil : [sortDescriptor key];
        id valueForField = nil, lastValueForField = nil;
        NSUInteger groupResultIndexForLevel = 0;
        
        for (NSDictionary *result in sortedResults) {

            valueForField = detailLevel ? nil : [result objectForKey:sortFieldName];
            if (valueForField == nil) {
                valueForField = MTNullIdentifier;
            }

            if (![valueForField isEqual: lastValueForField] && lastValueForField != nil) {

                id resultOfNextGroup = [self addGroupedResults: resultsForGroup
                                                            level: (level + 1)];
                
                [results setObject:resultOfNextGroup forKey:lastValueForField];
                
                [resultsForGroup removeAllObjects];
                
            }
            [resultsForGroup addObject:result];
            lastValueForField = valueForField;
            groupResultIndexForLevel++;
        }
        
        if (valueForField != nil) {

            id resultOfNextGroup = [self addGroupedResults: resultsForGroup
                                                     level: (level + 1)];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            [results setObject:resultOfNextGroup forKey:key];

        } else {

            id resultOfNextGroup = [self addGroupedResults: resultsForGroup
                                                     level: (level + 1)];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            if (key == nil) {
                key = MTNullIdentifier;
            }
            [results setObject:resultOfNextGroup forKey:key];

        }
        
        [resultsForGroup removeAllObjects];
    }
    return results;
}

- (void)cleanupTemporaryReportIndexes {
    [[self reportLayoutTemporary] removeAllObjects];
    [[self reportIndexesTemporary] removeAllObjects];
    [self cleanupTemporaryPageIndexes];
}

- (void)cleanupTemporaryPageIndexes {
    [[self pageLayoutTemporary] removeAllObjects];
    [[self pageIndexesTemporary] removeAllIndexes];
}

- (void)addReportHeader {
    NSDictionary *d = @{MTReportSectionType : @(MNSDocumentSectionTypeReportHeader)};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addPageHeader {
    NSDictionary *d = @{MTReportSectionType : @(MNSDocumentSectionTypePageHeader)};
    [[self pageLayoutTemporary] addObject:  d];
}



- (void)addAllDetail {
    
    [self initReportLayoutContainers];

    NSInteger numberOfGroups = [[self sortDescriptorsByGroupSorted] count];
    
    NSEnumerator *testEnumerator = [[[self query] datatable] enumeratorForAllObjectsSorted];
    RptqDocumentSection *detailSection = [[self layout] hasDetailSection];

    BOOL firstRow = YES;
    for (NSDictionary *resultRow in testEnumerator) {
        
        //Get row id
        NSNumber *rowid = [resultRow objectForKey:@"ROWID"];

        //Get row key values
        NSMutableArray *keyValuesForComparson = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        for (NSSortDescriptor *sortDesc in [self sortDescriptorsByGroupSorted]) {
            id predicateValue = [resultRow objectForKey:[sortDesc key]];
            [keyValuesForComparson addObject:predicateValue];
        }
        
        //Display new footers if needed.
        if (!firstRow) {
            [self displayNewGroupFootersIfNeeded:keyValuesForComparson andLastValues:[self lastResultRowComparsonValues]];
        }
        
        //Display new group headers if needed.
        [self displayNewGroupHeadersIfNeeded:keyValuesForComparson andLastValues:[self lastResultRowComparsonValues]];
        [self addHeightFromDocumentSectionToReportLayout:detailSection];
        
        [self cacheDetail:rowid];
        
        [self setLastResultRowComparsonValues: keyValuesForComparson];

        firstRow = NO;
    }
}

- (void)displayNewGroupFootersIfNeeded:(NSArray *)currentValues  andLastValues:(NSArray *)lastValues {
    for (NSInteger groupLevel = [lastValues count] - 1; groupLevel >= 0; groupLevel--) {
        id value = lastValues[groupLevel];
        id value2 = currentValues[groupLevel];
        if (value == [NSNull null]) {
            value = @"";
        }
        if (value2 == [NSNull null]) {
            value2 = @"";
        }
        NSSortDescriptor *sortDesc = [self sortDescriptorsByGroupSorted][groupLevel];
        SEL comparec = [sortDesc selector];
        NSComparisonResult comparsonResult;
        if (comparec == @selector(localizedCaseInsensitiveCompare:)) {
            comparsonResult = [value localizedCaseInsensitiveCompare:value2];
        } else {
            comparsonResult = [value compare:value];
        }
        BOOL newFooter = comparsonResult != NSOrderedSame;
        
        if (newFooter) {
            RptqQueryGroup *group = [[self sortedQueryGroups] objectAtIndex:groupLevel];
            [self addHeightFromGroupFooterWithQueryGroup: group];
            [self cacheGroupFooterAtLevel:groupLevel];
            //NSLog(@"GF%d:\t%@", groupLevel, currentValues);
        }
    }
}

- (void)displayNewGroupHeadersIfNeeded:(NSArray *)currentValues andLastValues:(NSArray *)lastValues {
    
    for (NSInteger groupLevel = 0; groupLevel < [currentValues count]; groupLevel++) {

        BOOL newHeader = [lastValues count] == 0;
        if (newHeader == NO) {
            id value = lastValues[groupLevel];
            id value2 = currentValues[groupLevel];
            if (value == [NSNull null]) {
                value = @"";
            }
            if (value2 == [NSNull null]) {
                value2 = @"";
            }
            NSSortDescriptor *sortDesc = [self sortDescriptorsByGroupSorted][groupLevel];
            SEL comparec = [sortDesc selector];
            NSComparisonResult comparsonResult;
            if (comparec == @selector(localizedCaseInsensitiveCompare:)) {
                comparsonResult = [value localizedCaseInsensitiveCompare:value2];
            } else {
                comparsonResult = [value compare:value2];
            }
            newHeader = comparsonResult != NSOrderedSame;
        }
        
        if (newHeader) {
            RptqQueryGroup *gh = [[self sortedQueryGroups] objectAtIndex:groupLevel];
            [self addHeightFromGroupHeaderWithQueryGroup: gh];
            
            NSRange range = NSMakeRange(0, groupLevel + 1);
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
            NSArray *currentKeys = [currentValues objectsAtIndexes:indexSet];
            [self addGroupHeaderLevel:groupLevel withKeys:currentKeys];
            //NSLog(@"GH%d:\t%@", groupLevel, currentKeys);
        }
    }
}

- (void)addGroupLevel:(NSInteger)groupLevel groupKeys:(NSArray *)keys enumerator:(NSEnumerator *)enumerator {
/*
    RptqQueryGroup *groupHeader = [[self sortedQueryGroups] objectAtIndex:groupLevel];
    [self addHeightFromGroupHeaderWithQueryGroup: groupHeader];
    [self addGroupHeaderLevel:0 withKeys:keys];

    BOOL nextGroup;
    if (nextGroup) {
        [self addGroupLevel:groupLevel groupKeys:keys enumerator:enumerator];
    } else {
        [self cacheDetailLevelWithDetails:];
    }
    
    RptqQueryGroup *groupFooter = [[self sortedQueryGroups] objectAtIndex:groupLevel];
    [self addHeightFromGroupFooterWithQueryGroup:groupFooter];
    [self cacheGroupFooterAtLevel:groupLevel];
  */
}

- (NSEnumerator *)dataForPageIndex:(NSInteger)pageIndex {
    return [[[self query] datatable] enumeratorForRowIds: [self reportIndexes][pageIndex]];
}

- (void)addGroupLevel:(RptqQueryGroup *)queryGroup groupedRows:(NSDictionary *)groupedRows groupedRowsLevel:(NSUInteger)groupedRowsLevel andKeys:(NSArray *)passedkeys andAllKeys:(NSMutableArray *)allKeysForLevel {
    
    NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:passedkeys];
    
    NSArray *sqg = [[self query] sortedHasQueryGroups];
    [self setSortedQueryGroups:sqg];
    
    if (groupedRowsLevel == [[self sortDescriptorsByGroupSorted] count]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
        
        NSArray *results = [NSArray arrayWithArray:[[[self query] datatable] objectsForGroupKeys:allKeysForLevel]];
        [self cacheDetailLevelWithDetails:results];

    } else {
        NSSortDescriptor *desc = [[self sortDescriptorsByGroupSorted] objectAtIndex:groupedRowsLevel];
        NSEnumerator *loopEnumerator = [[[self query] datatable] enumeratorForGroupLevel: groupedRowsLevel
                                                                                withKeys: passedkeys
                                                                               accending: [desc ascending]];
        
        for (id key in loopEnumerator) {
            
            @autoreleasepool {
                
                [keys addObject:key];
                [allKeysForLevel addObject:key];
                
                [self addHeightFromGroupHeaderWithQueryGroup:queryGroup];
                [self addGroupHeaderLevel:groupedRowsLevel withKeys:keys];
                
                NSInteger indexNextGroup = [[queryGroup weight] integerValue] + 1;
                RptqQueryGroup *nextGroup = [self sortGroupAtLevel:indexNextGroup];
                if (nextGroup != nil) {
                    [self addGroupLevel: nextGroup groupedRows: nil groupedRowsLevel: groupedRowsLevel + 1 andKeys:keys andAllKeys:allKeysForLevel];
                } else {
                    NSArray *results = [NSArray arrayWithArray:[[[self query] datatable] objectsForGroupKeys:allKeysForLevel]];
                    [self cacheDetailLevelWithDetails:results];
                }
                
                [allKeysForLevel removeLastObject];
                
                [self addHeightFromGroupFooterWithQueryGroup:queryGroup];
                [self cacheGroupFooterAtLevel:groupedRowsLevel];
                
                [keys removeLastObject];
            }
        }
    }
}

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails {
    
    for (NSInteger i=0; i<[containerDetails count]; i++) {
        @autoreleasepool {
            
            

            [self addHeightFromDocumentSectionToReportLayout:[[self layout] hasDetailSection]];
            NSNumber *rowid = containerDetails[i][@"ROWID"];
            [self cacheDetail:rowid];
            
            //id nextObject = [[[[self query] datatable] enumeratorForAllObjectsSortedRowIdOnly] nextObject];
            ///NSLog(@"Next Object %@ == %@", nextObject, rowid);

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

- (void)addHeightFromDocumentSectionToReportLayout:(RptqDocumentSection *)documentSection {
    CGFloat layoutHeight = [[documentSection layoutHeight] floatValue];
    [self addPageBreakToReportLayoutWithNextItemHeight: layoutHeight];
    CGFloat printableHeightUsed = [self counterHeightUsedCurrentPage] + layoutHeight;
    [self setCounterHeightUsedCurrentPage: printableHeightUsed];
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
   // NSArray *emptyArray = @[];
   // NSMutableArray *emptyMutableArray = [[NSMutableArray alloc] init];
    
    NSEnumerator *enumeratorForAllObjectsSorted = [[[self query] datatable] enumeratorForAllObjectsSorted];
    [self setEnumeratorForReportDetail: enumeratorForAllObjectsSorted];
    
    [self addAllDetail];
    /*
    [self addGroupLevel: [self firstQueryGroup]
            groupedRows: nil
       groupedRowsLevel: 0 andKeys: emptyArray andAllKeys:emptyMutableArray];
     */
}

// FIXME: Make sure paper rect is passed in to the software
- (BOOL)addPageBreakToReportLayoutWithNextItemHeight:(CGFloat)nextItemHeight {
    
    BOOL newPageCreated = NO;
    CGRect pageRect;
    RptqDocument *document = [self layout];
    RptqDocumentSection *pageFooterSection = [document hasPageFooterSection];
    CGFloat pageFooterSectionHeight = [[pageFooterSection layoutHeight] floatValue];
    
    pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    
    if ([self counterHeightUsedCurrentPage] + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        
        newPageCreated = YES;
        CGFloat newHeight = [self counterHeightUsedCurrentPage] + pageFooterSectionHeight;
        [self setCounterHeightUsedCurrentPage:newHeight];
        [self addPageFooter];
        
        id layoutToAdd = [[self pageLayoutTemporary] copy];
        [[self reportLayoutTemporary] addObject:layoutToAdd];
        
        id dataToAdd = [[self pageIndexesTemporary] copy];
        [[self reportIndexesTemporary] addObject:dataToAdd];
        
        [self cleanupTemporaryPageIndexes];
        
        RptqDocumentSection *pageHeaderSection = [document hasPageHeaderSection];
        CGFloat pageHeaderHeight = CGPointZero.y;
        pageHeaderHeight += [[pageHeaderSection layoutHeight] floatValue];
        [self setCounterHeightUsedCurrentPage: pageHeaderHeight];
        
        [self addPageHeader];
    }
    return newPageCreated;
}

- (void)addReportHeaderToReportLayout {
    RptqDocumentSection *reportHeaderSection = [[self layout] hasReportHeaderSection];
    CGFloat reportHeaderHeight = [[reportHeaderSection layoutHeight] floatValue];
    CGFloat printableSpaceUsed = [self counterHeightUsedCurrentPage] + reportHeaderHeight;
    [self setCounterHeightUsedCurrentPage: printableSpaceUsed];
    [self addReportHeader];
}

- (void)addPageHeaderToReportLayout {
    RptqDocumentSection *pageHeaderSection = [[self layout] hasPageHeaderSection];
    CGFloat pageHeaderHeight = [[pageHeaderSection layoutHeight] floatValue];
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
    [self addPageFooter];
    [self cacheReportFooter];
}

- (void)addGroupHeaderLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys {
    NSNumber *level = @(groupLevel);
    NSArray *newKeys = [NSArray arrayWithArray:keys];
    NSDictionary *d = @{MTReportSectionType     : @(MNSDocumentSectionTypeGroupHeader),
                        MTReportGroupLevelKeys  : newKeys,
                        MTReportGroupLevel      : level};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)addPageFooter {
    NSDictionary *d = @{MTReportSectionType : @(MNSDocumentSectionTypePageFooter)};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)cacheReportFooter {
    NSDictionary *d = @{MTReportSectionType : @(MNSDocumentSectionTypeReportFooter)};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)cacheGroupFooterAtLevel:(NSUInteger)groupLevel {
    NSNumber *gl = [[NSNumber alloc] initWithUnsignedInteger:groupLevel];
    NSDictionary *d = @{MTReportSectionType : @(MNSDocumentSectionTypeGroupFooter),
                        MTReportGroupLevel : gl};
    [[self pageLayoutTemporary] addObject: d];
}

- (void)cacheDetail:(NSNumber *)detailRowId {
    NSNumber *type = @(MNSDocumentSectionTypeBody);
    NSDictionary *detail = @{MTReportSectionType : type,
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

- (NSDictionary *)dataForRow:(NSUInteger)row onPage:(NSUInteger)page {
    id rowData = nil;
    if (page < [[self reportIndexes] count]) {
        
        NSIndexSet *pageIndexes = [[NSIndexSet alloc] initWithIndexSet:[[self reportIndexes] objectAtIndex:page]];

        if (row < [pageIndexes count]) {
            
            // FIXME: Filter all through MTDataTable.
            SEL objectAtRowLimit = @selector(objectAtRow:limit:);
            if ([[[self query] datatable] respondsToSelector:objectAtRowLimit]) {

                NSArray *pageCache = [[self pageCaching] objectsForPage:page];
                if (pageCache == nil) {
                    
                    NSArray *objectsForPage = [[[self query] datatable] objectAtRow: [pageIndexes firstIndex]
                                                                              limit: [pageIndexes count]];

                    [[self pageCaching] cacheObjects:objectsForPage forPage:page];
                    pageCache = [[self pageCaching] objectsForPage:page];
                }
                if ([pageCache count] > row) {
                    NSDictionary *data = pageCache[row];
                    rowData = [NSDictionary dictionaryWithDictionary:data];
                }
                pageCache = nil;
            } else {
                rowData = [(MTDataTable *)[[self query] datatable] objectAtRow:[pageIndexes firstIndex]];
            }
        }
    }
    return rowData;
}

- (id)dataForGroupKeys:(NSArray *)keys {
    return [[[self query] datatable] objectsForGroupKeys:keys];
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

- (NSUInteger)countOnPageIndex:(NSUInteger)pageNumber {
    return [[[self reportIndexes] objectAtIndex:pageNumber] count];
}

- (NSIndexSet *)objectEnumeratorForPage:(NSUInteger)pageIndex {
    return [self reportIndexes][pageIndex];
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

- (BOOL)shouldFormatAgain:(CGSize)printableSize {
    
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
    return formatAgain;
}

- (RptqQueryGroup *)firstQueryGroup {
    
    RptqDatabase *database = [[[self layout] hasDatabaseSchemas] anyObject];
    NSSet *hasQueries = [database hasQueries];
    RptqQuery *query = [hasQueries anyObject];
    return [query firstQueryGroup];
    
}

@end
