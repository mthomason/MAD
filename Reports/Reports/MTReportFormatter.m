//
//  MTReportFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportFormatter.h"
#import "MTCache.h"
#import "MTQueryReport.h"

#import "SectionEnumerator.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"

#import "RptqQuery+Extras.h"

//Why the fuck!!!

#import "MTDatabaseConnection.h"
#import "MTDatabase.h"

NSString * const MTNullIdentifier = @"(null)";

@interface MTReportFormatter ()

@property (nonatomic, retain, readwrite) NSArray *sortedQueryGroups;

@property (nonatomic, retain, readwrite) RptqDocument *layout;
@property (nonatomic, assign) CGSize printableSize;
@property (nonatomic, assign) CGRect printableRect;

@property (nonatomic, assign) CGSize cachedPageSize;

@property (nonatomic, assign) NSUInteger temporaryCachedDetailCounter;

@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;

@property (nonatomic, retain, readwrite) NSArray *dataByPage;
@property (nonatomic, retain, readwrite) NSArray *layoutByPage;

@property (nonatomic, retain, readwrite) NSDictionary *dataByGroup;

@property (nonatomic, retain) NSMutableArray *temporaryLayoutForPage;
@property (nonatomic, retain) NSMutableArray *temporaryDataForPage;
@property (nonatomic, retain) NSMutableArray *temporaryLayoutByPage;
@property (nonatomic, retain) NSMutableArray *temporaryDataByPage;

@end

@implementation MTReportFormatter

- (void)dealloc {
    [_layout release];
    [_layoutByPage release];
    [_dataByPage release];
    [_dataByGroup release];
    [_temporaryLayoutByPage release]; _temporaryLayoutByPage = nil;
    [_temporaryLayoutForPage release]; _temporaryLayoutForPage = nil;
    [_temporaryDataByPage release]; _temporaryDataByPage = nil;
    [_temporaryDataForPage release]; _temporaryDataForPage = nil;
    [super dealloc];
}

- (id)initWithQuery:(MTQueryReport *)query andLayout:(RptqDocument *)layout {
    self = [super initWithQuery:query];
    if (self) {
        
        [self setLayout:layout];
        
        NSMutableArray *temporaryLayoutByPage = [[NSMutableArray alloc] init];
        [self setTemporaryLayoutByPage:temporaryLayoutByPage];
        [temporaryLayoutByPage release];
        
        NSMutableArray *temporaryLayoutForPage = [[NSMutableArray alloc] init];
        [self setTemporaryLayoutForPage:temporaryLayoutForPage];
        [temporaryLayoutForPage release];
        
        NSMutableArray *temporaryDataByPage = [[NSMutableArray alloc] init];
        [self setTemporaryDataByPage:temporaryDataByPage];
        [temporaryDataByPage release];
        
        NSMutableArray *temporaryDataForPage = [[NSMutableArray alloc] init];
        [self setTemporaryDataForPage:temporaryDataForPage];
        [temporaryDataForPage release];

    }
    return self;
}

+ (id)reportFormatterWithQuery:(MTQueryReport *)query andLayout:(RptqDocument *)layout {
    MTReportFormatter *result = [[MTReportFormatter alloc] initWithQuery:query andLayout:layout];
    return [result autorelease];
}

#pragma mark - Reading cached data

//  Data is cached by group, page, and report.

- (void)formatForSize:(CGSize)printableSize {
    [self formatForSize:printableSize onlyFirstPage:NO];
}

- (void)formatForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage {
    
    if ([super format]) {

        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
        CGSize h = CGSizeFromString([standardUserDefaults stringForKey:@"MTCachedSizeHorizontal"]);
        CGSize v = CGSizeFromString([standardUserDefaults stringForKey:@"MTCachedSizeVertical"]);
        CGSize cachedSizePortrait = v;
        CGSize cachedSizeHorizontal = h;
        BOOL cacheAgain = [self didRefresh] || (landscape ? CGSizeEqualToSize(cachedSizeHorizontal, self.cachedPageSize) == NO : CGSizeEqualToSize(cachedSizePortrait, self.cachedPageSize) == NO);
        

        if (cacheAgain) {
            
            if (landscape) {
                [standardUserDefaults setObject:NSStringFromCGSize(printableSize) forKey:@"MTCachedSizeHorizontal"];
            } else {
                [standardUserDefaults setObject:NSStringFromCGSize(printableSize) forKey:@"MTCachedSizeVertical"];
            }
            [standardUserDefaults setURL:[[self datasource] url] forKey:MTCachedFileUrl];
            [standardUserDefaults synchronize];
            
            [self setCachedPageSize:printableSize];
            [self setPrintableSize:printableSize];
            
            
            RptqDatabase *database = [[[self layout] hasDatabaseSchemas] anyObject];
            
            NSSet *hasQueries = [database hasQueries];
            RptqQuery *query = [hasQueries anyObject];
            
            SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithDocument:[self layout]];
            for (RptqDocumentSection *sec in enumerator) {
                CGFloat layoutHight = [RptqDocumentSection layoutHeightForSection:sec];
                NSNumber *lh = [[NSNumber alloc] initWithFloat:layoutHight];
                [sec setLayoutHeight:lh];
                [lh release];
            }
            [enumerator release];
            
            [[self temporaryLayoutByPage] removeAllObjects];
            [[self temporaryDataByPage] removeAllObjects];
            [self setPrintableSpaceUsedPageHeight:CGSizeZero.height];
            [self setTemporaryCachedDetailCounter:0];
            
            id groupedRows = [self cachedGroupedResults:[self records] level:0];
            
            [self setPrintableSpaceUsedPageHeight: CGSizeZero.height];
            
            //Report Header
            RptqDocumentSection *reportHeaderSection = [[self layout] hasReportHeaderSection];
            BOOL reportHeaderIsVisable = [[reportHeaderSection visibility] boolValue];
            CGFloat reportHeaderHeight = reportHeaderIsVisable ? [[reportHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
            CGFloat printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportHeaderHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cacheReportHeaderWithValueDictionary:groupedRows];
            
            //First Page Header
            RptqDocumentSection *pageHeaderSection = [[self layout] hasPageHeaderSection];
            BOOL pageHeaderIsVisable = [[pageHeaderSection visibility] boolValue];
            CGFloat pageHeaderHeight = pageHeaderIsVisable ? [[pageHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
            printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageHeaderHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cachePageHeaderWithValueDictionary:groupedRows];
            
            
            BOOL detailPrinted = NO;
            
            RptqQueryGroup *firstGroup = [query firstQueryGroup];
            if (onlyFirstPage) {
                BOOL firstPageComplete = NO;
                [self cacheUntilFirstPageStartingWithGroup:firstGroup groupedRows:groupedRows groupedRowsLevel:0 detailPrinted:&detailPrinted firstPageComplete:&firstPageComplete];
            } else {
                [self cacheGroupLevel:firstGroup groupedRows:groupedRows groupedRowsLevel:0 detailPrinted:&detailPrinted];
            }
            
            RptqDocumentSection *reportFooter = [[self layout] hasReportFooterSection];
            BOOL reportFooterIsVisible = [[reportFooter visibility] boolValue];
            CGFloat reportFooterHeight = reportFooterIsVisible ? [[reportFooter layoutHeight] floatValue] : CGSizeZero.height;
            
            [self cachePageBreakWithNextItemHeight: reportFooterHeight
                                       groupedRows: groupedRows];
            
            
            RptqDocumentSection *pageFooterSection = [[self layout] hasPageFooterSection];
            BOOL pageFooterIsVisible = [[pageFooterSection visibility] boolValue];
            CGFloat pageFooterHeight = pageFooterIsVisible ? [[pageFooterSection layoutHeight] floatValue] : CGSizeZero.height;
            
            printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageFooterHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cachePageFooterWithValueDictionary:groupedRows];
            
            
            printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportFooterHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cacheReportFooterWithValueDictionary:groupedRows];
            
            NSArray *tlfp = [[self temporaryLayoutForPage] retain];
            [[self temporaryLayoutByPage] addObject:tlfp];
            [tlfp release];
            
            NSArray *tdfp = [[self temporaryDataForPage] retain];
            [[self temporaryDataByPage] addObject:tdfp];
            [tdfp release];
            
            id gr;
            if ([groupedRows isKindOfClass:[NSDictionary class]]) {
                gr = [groupedRows retain];
            } else {
                gr = [groupedRows retain];
            }
            [self setDataByGroup: gr];
            [gr release];
            
            NSArray *tlbp = [[self temporaryLayoutByPage] retain];
            [self setLayoutByPage: tlbp];
            [tlbp release];
            
            NSArray *tdbp = [[self temporaryDataByPage] retain];
            [self setDataByPage: tdbp];
            
            [tdbp release];
        }
        

        
    }

}

//Roll through the groups
//Returns dictionary for group levels (level < n), and array of dictionaries for details/results (level == n-1).
- (id)cachedGroupedResults:(NSArray *)sortedResults level:(NSUInteger)level {
    
    BOOL detailLevel = level == [[self sortDescriptorsByGroupSorted] count];
    id resultsDictionary = nil;
    
    if (detailLevel) {
        resultsDictionary = [sortedResults copy];
    } else {
        resultsDictionary = [[NSMutableDictionary alloc] init];
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
                
                id resultOfNextGroup = [self cachedGroupedResults: resultsForGroup
                                                            level: (level + 1)];
                
                [resultsDictionary setObject:resultOfNextGroup forKey:lastValueForField];
                
                [resultsForGroup removeAllObjects];
                
            }
            [resultsForGroup addObject:result];
            lastValueForField = valueForField;
            groupResultIndexForLevel++;
        }
        
        //NSArray *resultsCopy = [[NSArray alloc] initWithArray: resultsForGroup];                //Last item
        if (valueForField != nil) {
            id resultOfNextGroup = [self cachedGroupedResults: resultsForGroup
                                                        level: (level + 1)];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            [resultsDictionary setObject:resultOfNextGroup forKey:key];
        } else {
            id resultOfNextGroup = [self cachedGroupedResults: resultsForGroup
                                                        level: (level + 1)];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            if (key == nil) {
                NSNull *n = [[NSNull alloc] init];
                key = MTNullIdentifier;
                [n release];
            }
            [resultsDictionary setObject:resultOfNextGroup forKey:key];
        }
        
        //[resultsCopy release];
        
        [resultsForGroup removeAllObjects];
        [resultsForGroup release];
    }
    return [resultsDictionary autorelease];
}

- (void)cacheReportHeaderWithValueDictionary:(NSDictionary *)values {
    [[self temporaryLayoutForPage] removeAllObjects];
    [[self temporaryDataForPage] removeAllObjects];
    NSDictionary *d = @{MTReportSectionType : MTReportHeader};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cachePageHeaderWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTPageHeader};
    [[self temporaryLayoutForPage] addObject:  d];
}

// FIXME: Hack... this shit looks just like cacheGroupLevel
- (void)cacheUntilFirstPageStartingWithGroup:(RptqQueryGroup *)queryGroup groupedRows:(NSDictionary *)groupedRows groupedRowsLevel:(NSUInteger)groupedRowsLevel detailPrinted:(BOOL *)detailPrinted firstPageComplete:(BOOL *)firstPageComplete {
    
    if ([self sortedQueryGroups] == nil) {
        NSArray *sqg = [[self query] sortedHasQueryGroups];
        [self setSortedQueryGroups:sqg];
    }
    
    if (*firstPageComplete == NO) {
        
        if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
            
            SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
            
            BOOL nullGroupExist = NO;
            NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys] copyItems:NO];
            for (id obj in allKeys) {
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *str = (NSString *)obj;
                    if ([str isEqualToString: MTNullIdentifier]) {
                        nullGroupExist = YES;
                        break;
                    }
                }
            }
            if (nullGroupExist) {
                [allKeys removeObject:MTNullIdentifier];
            }
            NSSortDescriptor *desc = [[[self sortDescriptorsByGroupSorted] objectAtIndex:groupedRowsLevel] retain];
            
            
            NSEnumerator *loopEnumerator = nil;
            
            if (sortSelector != nil) {
                NSMutableArray *allKeysSorted = [[NSMutableArray alloc] initWithArray:[allKeys sortedArrayUsingSelector:sortSelector] copyItems:NO];
                if (nullGroupExist) {
                    [allKeysSorted insertObject:MTNullIdentifier atIndex:0];
                }
                
                if ([desc ascending] == NO) {
                    loopEnumerator = [[allKeysSorted reverseObjectEnumerator] retain];
                } else {
                    loopEnumerator = [[allKeysSorted objectEnumerator] retain];
                }
                [allKeysSorted release];
            } else {
                loopEnumerator = [[allKeys objectEnumerator] retain];
            }
            
            [desc release];
            
            
            for (id key in loopEnumerator) {
                id obj = [[groupedRows objectForKey:key] retain];
                
                //Group header section
                for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                    if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                        BOOL isVisible = [[documentSection visibility] boolValue];
                        CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                        *firstPageComplete = [self cachePageBreakWithNextItemHeight: layoutHeight
                                                                        groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }
                
                if (*firstPageComplete == NO) {
                    
                    [self cacheGroupHeaderWithValueDictionary:obj andLevel:groupedRowsLevel];
                    
                    
                    RptqQueryGroup *nextGroup = nil;
                    if ([[self sortedQueryGroups] count] > groupedRowsLevel + 1) {  //Is there a next group?  Short ciruit
                        if (queryGroup != nil) {
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == %d", ([[queryGroup weight] integerValue] + 1)];
                            NSArray *filteredGroups = [[self sortedQueryGroups] filteredArrayUsingPredicate:predicate];
                            if ([filteredGroups count] >= 1) {
                                nextGroup = [filteredGroups objectAtIndex:0];
                            }
                        }
                    }
                    if (nextGroup != nil) {
                        [self cacheUntilFirstPageStartingWithGroup: nextGroup groupedRows: obj groupedRowsLevel: groupedRowsLevel + 1 detailPrinted: detailPrinted firstPageComplete:firstPageComplete];
                    } else {
                        [self cacheDetailLevelWithDetails:obj groupedRows:groupedRows];
                    }
                    //Group footer section
                    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                        if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                            BOOL isVisible = [[documentSection visibility] boolValue];
                            CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                            [self cachePageBreakWithNextItemHeight: layoutHeight groupedRows: groupedRows];
                            CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                            [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                            break;
                        }
                    }
                    
                    [self cacheGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
                    
                }
                
                [obj release];
                if (*firstPageComplete) {
                    break;
                }
            }
            [loopEnumerator release];
            [allKeys release];
            
        } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...
            
            [self cacheDetailLevelWithDetails:(NSArray *)groupedRows
                                  groupedRows:groupedRows];
        }
    }
}

- (void)cacheGroupLevel:(RptqQueryGroup *)queryGroup groupedRows:(NSDictionary *)groupedRows groupedRowsLevel:(NSUInteger)groupedRowsLevel detailPrinted:(BOOL *)detailPrinted {
    
    if ([self sortedQueryGroups] == nil) {
        NSArray *sqg = [[self query] sortedHasQueryGroups];
        [self setSortedQueryGroups:sqg];
    }
    
    if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
        
        SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
        
        BOOL nullGroupExist = NO;
        NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys] copyItems:NO];
        for (id obj in allKeys) {
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *str = (NSString *)obj;
                if ([str isEqualToString: MTNullIdentifier]) {
                    nullGroupExist = YES;
                    break;
                }
            }
        }
        if (nullGroupExist) {
            [allKeys removeObject:MTNullIdentifier];
        }
        NSSortDescriptor *desc = [[[self sortDescriptorsByGroupSorted] objectAtIndex:groupedRowsLevel] retain];
        
        
        NSEnumerator *loopEnumerator = nil;
        
        if (sortSelector != nil) {
            NSMutableArray *allKeysSorted = [[NSMutableArray alloc] initWithArray:[allKeys sortedArrayUsingSelector:sortSelector] copyItems:NO];
            if (nullGroupExist) {
                [allKeysSorted insertObject:MTNullIdentifier atIndex:0];
            }
            
            if ([desc ascending] == NO) {
                loopEnumerator = [[allKeysSorted reverseObjectEnumerator] retain];
            } else {
                loopEnumerator = [[allKeysSorted objectEnumerator] retain];
            }
            [allKeysSorted release];
        } else {
            loopEnumerator = [[allKeys objectEnumerator] retain];
        }
        
        [desc release];
        
        
        for (id key in loopEnumerator) {
            id obj = [[groupedRows objectForKey:key] retain];
            
            //Group header section
            for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                    BOOL isVisible = [[documentSection visibility] boolValue];
                    CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                    [self cachePageBreakWithNextItemHeight: layoutHeight
                                               groupedRows: groupedRows];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                    [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                    break;
                }
            }
            
            [self cacheGroupHeaderWithValueDictionary:obj andLevel:groupedRowsLevel];
            
            
            RptqQueryGroup *nextGroup = nil;
            if ([[self sortedQueryGroups] count] > groupedRowsLevel + 1) {  //Is there a next group?  Short ciruit
                if (queryGroup != nil) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == %d", ([[queryGroup weight] integerValue] + 1)];
                    NSArray *filteredGroups = [[self sortedQueryGroups] filteredArrayUsingPredicate:predicate];
                    if ([filteredGroups count] >= 1) {
                        nextGroup = [filteredGroups objectAtIndex:0];
                    }
                }
            }
            
            //This old method was SLOW!!!!
            //RptqQueryGroup *nextGroup = [queryGroup next];
            
            
            if (nextGroup != nil) {
                [self cacheGroupLevel: nextGroup
                          groupedRows: obj
                     groupedRowsLevel: groupedRowsLevel + 1
                        detailPrinted: detailPrinted];
            } else {
                [self cacheDetailLevelWithDetails:obj
                                      groupedRows:groupedRows];
            }
            
            //Group footer section
            for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                    BOOL isVisible = [[documentSection visibility] boolValue];
                    CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                    [self cachePageBreakWithNextItemHeight: layoutHeight groupedRows: groupedRows];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                    [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                    break;
                }
            }
            
            [self cacheGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
            
            [obj release];
        }
        [loopEnumerator release];
        [allKeys release];
        
    } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...
        
        [self cacheDetailLevelWithDetails:(NSArray *)groupedRows
                              groupedRows:groupedRows];
    }
}

// FIXME: Make sure paper rect is passed in to the software

- (BOOL)cachePageBreakWithNextItemHeight:(CGFloat)nextItemHeight
                             groupedRows:(NSDictionary *)groupedRows {
    
    BOOL newPageCreated = NO;
    CGRect pageRect;
    
    //MTApplicationInstance *applicationInstance = [AppDelegate app];
    //MAReportDocument *activeDocument = [applicationInstance activeDocument];
    RptqDocument *document = [self layout];
    RptqDocumentSection *pageFooterSection = [document hasPageFooterSection];
    BOOL pageFooterIsVisable = [[pageFooterSection visibility] boolValue];
    CGFloat pageFooterSectionHeight = pageFooterIsVisable ? [[pageFooterSection layoutHeight] floatValue] : CGSizeZero.height;
    
    //if (CGRectIsEmpty([self printableRect])) {
    pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    //} else {
    //    pageRect = [self paperRect];
    //}
    
    if ([self printableSpaceUsedPageHeight] + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        
        newPageCreated = YES;
        CGFloat newHeight = [self printableSpaceUsedPageHeight] + pageFooterSectionHeight;
        [self setPrintableSpaceUsedPageHeight:newHeight];
        [self cachePageFooterWithValueDictionary:groupedRows];
        
        id layoutToAdd = [[self temporaryLayoutForPage] copy];
        [[self temporaryLayoutByPage] addObject:layoutToAdd];
        [layoutToAdd release];
        
        id dataToAdd = [[self temporaryDataForPage] copy];
        [[self temporaryDataByPage] addObject:dataToAdd];
        [dataToAdd release];
        
        [[self temporaryLayoutForPage] removeAllObjects];
        [[self temporaryDataForPage] removeAllObjects];
        
        RptqDocumentSection *pageHeaderSection = [document hasPageHeaderSection];
        BOOL pageHeaderIsVisable = [[pageHeaderSection visibility] boolValue];
        CGFloat pageHeaderHeight = CGPointZero.y;
        pageHeaderHeight += pageHeaderIsVisable ? [[pageHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
        [self setPrintableSpaceUsedPageHeight: pageHeaderHeight];
        [self cachePageHeaderWithValueDictionary:groupedRows];
        
    }
    return newPageCreated;
}

- (void)cacheGroupHeaderWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    NSNumber *level = @(groupLevel);
    NSDictionary *d = @{MTReportSectionType : MTReportGroupHeader,
                        MTReportGroupLevel : level};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cachePageFooterWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTPageFooter};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheReportFooterWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTReportFooter};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails
                        groupedRows:(NSDictionary *)groupedRows {
    
    RptqDocument *document = [self layout];
    RptqDocumentSection *detailSection = [document hasDetailSection];
    BOOL isVisible = [[detailSection visibility] boolValue];
    CGFloat layoutHeight = isVisible ? [[detailSection layoutHeight] floatValue] : CGSizeZero.height;
    for (NSDictionary *resultDictionary in containerDetails) {
        [self cachePageBreakWithNextItemHeight: layoutHeight groupedRows: groupedRows];
        [self cacheDetailWithValueDictionary:resultDictionary];
        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
    }
    
}

- (void)cacheGroupFooterWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    NSNumber *gl = [[NSNumber alloc] initWithUnsignedInteger:groupLevel];
    NSDictionary *d = @{MTReportSectionType : MTReportGroupFooter,
                        MTReportGroupLevel : gl};
    [[self temporaryLayoutForPage] addObject: d];
    [gl release];
}

- (void)cacheDetailWithValueDictionary:(NSDictionary *)values {
    NSDictionary *detail = @{MTReportSectionType : MTPageDetail};
    [[self temporaryLayoutForPage] addObject: detail];
    NSUInteger ctr = [self temporaryCachedDetailCounter];
    NSNumber *counter = @(ctr);
    [[self temporaryDataForPage] addObject:counter];
    ctr++;
    [self setTemporaryCachedDetailCounter:ctr];
}

- (NSUInteger)numberOfPages {
    if ([self layoutByPage] == nil) {
        [self formatForSize:[self printableRect].size];
    }
    return [[self layoutByPage] count];
}

- (NSDictionary *)dataForRow:(NSUInteger)row onPage:(NSUInteger)page {
    id rowData = nil;
    if (page < [[self dataByPage] count]) {
        NSArray *pageData = [[self dataByPage] objectAtIndex:page];
        if (row < [pageData count]) {
            NSUInteger cachedDataIndex = [[pageData objectAtIndex:row] integerValue];
            if (cachedDataIndex < [[self records] count]) {
                rowData = [[self records] objectAtIndex:cachedDataIndex];
            }
        }
    }
    return rowData;
}

+ (id)dataForGroupData:(id)data andKeys:(NSArray *)keys {
    id resultData = nil;
    if ([data isKindOfClass:[NSArray class]]) {
        resultData = [data retain];
    } else {
        if ([keys count] > 0) {
            id subData = [[data objectForKey:[keys objectAtIndex:0]] retain];
            NSArray *subKeys = nil;
            if ([keys count] > 1) {
                NSRange range = NSMakeRange(1, [keys count] - 1);
                subKeys = [[[keys objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] retain] autorelease];
                resultData = [[MTReportFormatter dataForGroupData:subData andKeys:subKeys] retain];
            } else if ([keys count] == 1) {
                resultData = [subData retain];
            } else {
                resultData = [subData retain];
            }
            [subData release];
        } else {
            resultData = @[];
            [resultData retain];
        }
    }
    return [resultData autorelease];
}

@end
