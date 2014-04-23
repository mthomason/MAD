//
//  MTReportFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

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

#import "MTDataTableFast.h"

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

@property (nonatomic, retain, readwrite) NSArray *indexesByPage;
@property (nonatomic, retain, readwrite) NSArray *layoutByPage;

@property (nonatomic, retain, readwrite) NSDictionary *dataByGroup;

@property (nonatomic, retain) NSMutableArray *temporaryLayoutForPage;
@property (nonatomic, retain) NSMutableArray *temporaryLayoutByPage;

@property (nonatomic, retain) NSMutableIndexSet *temporaryIndexesForPage;
@property (nonatomic, retain) NSMutableArray *temporaryIndexesByPage;

@property (nonatomic, assign) NSUInteger cachedPageNumber;
@property (nonatomic, retain) NSArray *objectsForPage;

@end

@implementation MTReportFormatter

- (void)dealloc {
    [_layout release];
    [_layoutByPage release];
    [_indexesByPage release];
    [_dataByGroup release];
    [_temporaryLayoutByPage release]; _temporaryLayoutByPage = nil;
    [_temporaryLayoutForPage release]; _temporaryLayoutForPage = nil;
    [_temporaryIndexesByPage release]; _temporaryIndexesByPage = nil;
    [_temporaryIndexesForPage release]; _temporaryIndexesForPage = nil;
    [super dealloc];
}

- (id)initWithQuery:(MTQueryFull *)query andLayout:(RptqDocument *)layout {
    self = [super initWithQuery:query];
    if (self) {
        
        [self setLayout:layout];
        [self initilize];
        
    }
    return self;
}

+ (id)reportFormatterWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout {
    MTReportFormatter *result = [[MTReportFormatter alloc] initWithQuery:query andLayout:layout];
    return [result autorelease];
}

- (void)initilize {
    
    NSMutableArray *temporaryLayoutByPage = [[NSMutableArray alloc] init];
    [self setTemporaryLayoutByPage:temporaryLayoutByPage];
    [temporaryLayoutByPage release];
    
    NSMutableArray *temporaryLayoutForPage = [[NSMutableArray alloc] init];
    [self setTemporaryLayoutForPage:temporaryLayoutForPage];
    [temporaryLayoutForPage release];
    
    NSMutableArray *temporaryDataByPage = [[NSMutableArray alloc] init];
    [self setTemporaryIndexesByPage:temporaryDataByPage];
    [temporaryDataByPage release];
    
    NSMutableIndexSet *temporaryDataForPage = [[NSMutableIndexSet alloc] init];
    [self setTemporaryIndexesForPage:temporaryDataForPage];
    [temporaryDataForPage release];
    
    NSArray *layoutByPage = @[];
    [self setLayoutByPage:layoutByPage];
    
    NSArray *dataByPage = @[];
    [self setIndexesByPage:dataByPage];
    
    NSDictionary *dataByGroup = @{};
    [self setDataByGroup:dataByGroup];
    
    [self setCachedPageNumber: NSNotFound];
}

#pragma mark - Reading cached data

//  Data is cached by group, page, and report.

- (void)formatForSize:(CGSize)printableSize {
    [self formatForSize:printableSize onlyFirstPage:NO];
}

- (void)formatForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage {
#warning only run when sizes change... Should not depend on super... Always run users, and let super do its thing, like only running on refresh.
    if ([super format]) {
        
        [self initilize];
        
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
            [[self temporaryIndexesByPage] removeAllObjects];
            [self setPrintableSpaceUsedPageHeight:CGSizeZero.height];
            [self setTemporaryCachedDetailCounter:0];


            NSEnumerator *objectEnumerator = [[[[self query] datatable] objectEnumerator] retain];
            if (objectEnumerator != nil) {
                
                id allObjects = [objectEnumerator allObjects];
                id groupedRows = [self cachedGroupedResults:allObjects level:0];
                [self setDataByGroup: groupedRows];
                
                [self setPrintableSpaceUsedPageHeight: CGSizeZero.height];
                
                //Report Header
                RptqDocumentSection *reportHeaderSection = [[self layout] hasReportHeaderSection];
                BOOL reportHeaderIsVisable = [[reportHeaderSection visibility] boolValue];
                CGFloat reportHeaderHeight = reportHeaderIsVisable ? [[reportHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
                CGFloat printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportHeaderHeight;
                [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
                [self cacheReportHeader];
                
                //First Page Header
                RptqDocumentSection *pageHeaderSection = [[self layout] hasPageHeaderSection];
                BOOL pageHeaderIsVisable = [[pageHeaderSection visibility] boolValue];
                CGFloat pageHeaderHeight = pageHeaderIsVisable ? [[pageHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
                printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageHeaderHeight;
                [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
                [self cachePageHeader];
                
                RptqQueryGroup *firstGroup = [query firstQueryGroup];
                if (onlyFirstPage) {
                    BOOL firstPageComplete = NO;
                    [self cacheUntilFirstPageStartingWithGroup:firstGroup groupedRows:[self dataByGroup] groupedRowsLevel:0 firstPageComplete:&firstPageComplete];
                } else {
                    [self cacheGroupLevel:firstGroup groupedRows:[self dataByGroup] groupedRowsLevel:0];
                }
                
                RptqDocumentSection *reportFooter = [[self layout] hasReportFooterSection];
                BOOL reportFooterIsVisible = [[reportFooter visibility] boolValue];
                CGFloat reportFooterHeight = reportFooterIsVisible ? [[reportFooter layoutHeight] floatValue] : CGSizeZero.height;
                
                [self cachePageBreakWithNextItemHeight: reportFooterHeight];
                
                
                RptqDocumentSection *pageFooterSection = [[self layout] hasPageFooterSection];
                BOOL pageFooterIsVisible = [[pageFooterSection visibility] boolValue];
                CGFloat pageFooterHeight = pageFooterIsVisible ? [[pageFooterSection layoutHeight] floatValue] : CGSizeZero.height;
                
                printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageFooterHeight;
                [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
                [self cachePageFooter];
                
                
                printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportFooterHeight;
                [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
                [self cacheReportFooter];
                
                NSArray *tlfp = [[self temporaryLayoutForPage] retain];
                [[self temporaryLayoutByPage] addObject:tlfp];
                [tlfp release];
                
                NSIndexSet *tdfp = [[self temporaryIndexesForPage] retain];
                [[self temporaryIndexesByPage] addObject:tdfp];
                [tdfp release];
                
                NSArray *tlbp = [[self temporaryLayoutByPage] retain];
                [self setLayoutByPage: tlbp];
                [tlbp release];
                
                NSArray *tdbp = [[self temporaryIndexesByPage] retain];
                [self setIndexesByPage: tdbp];
                
                [tdbp release];
                
            }
            [objectEnumerator release];

        }
    }
}

- (id)cachedGroupedData:(NSArray *)sortedResults level:(NSUInteger)level {
    
    
    
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
                
                NSLog(@"%@", valueForField);
                
                id resultOfNextGroup = [self cachedGroupedData: resultsForGroup
                                                            level: (level + 1)];
                
                [results setObject:resultOfNextGroup forKey:lastValueForField];
                
                [resultsForGroup removeAllObjects];
                
            }
            [resultsForGroup addObject:result];
            lastValueForField = valueForField;
            groupResultIndexForLevel++;
        }
        
        id resultOfNextGroup = [self cachedGroupedData: resultsForGroup
                                                 level: (level + 1)];
        NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
        if (key == nil) {
            NSNull *n = [[NSNull alloc] init];
            key = MTNullIdentifier;
            [n release];
        }
        [results setObject:resultOfNextGroup forKey:key];
        
        [resultsForGroup release];
    }
    return [results autorelease];
}


//Roll through the groups
//Returns dictionary for group levels (level < n), and array of dictionaries for details/results (level == n-1).
- (id)cachedGroupedResults:(NSArray *)sortedResults level:(NSUInteger)level {
    
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
                
                NSMutableString *t = [[NSMutableString alloc] initWithString:@""];
                for (int i = 0; i < level; i++) {
                    [t appendString:@"\t"];
                }
                NSLog(@"%@%@", t, lastValueForField);

                id resultOfNextGroup = [self cachedGroupedResults: resultsForGroup
                                                            level: (level + 1)];
                
                [results setObject:resultOfNextGroup forKey:lastValueForField];
                
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
            [results setObject:resultOfNextGroup forKey:key];
        } else {
            id resultOfNextGroup = [self cachedGroupedResults: resultsForGroup
                                                        level: (level + 1)];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            if (key == nil) {
                NSNull *n = [[NSNull alloc] init];
                key = MTNullIdentifier;
                [n release];
            }
            [results setObject:resultOfNextGroup forKey:key];
        }
        
        //[resultsCopy release];
        
        [resultsForGroup removeAllObjects];
        [resultsForGroup release];
    }
    return [results autorelease];
}

- (void)cacheReportHeader {
    [[self temporaryLayoutForPage] removeAllObjects];
    [[self temporaryIndexesForPage] removeAllIndexes];
    NSDictionary *d = @{MTReportSectionType : MTReportHeader};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cachePageHeader {
    NSDictionary *d = @{MTReportSectionType : MTPageHeader};
    [[self temporaryLayoutForPage] addObject:  d];
}

// FIXME: Hack... this shit looks just like cacheGroupLevel
- (void)cacheUntilFirstPageStartingWithGroup:(RptqQueryGroup *)queryGroup groupedRows:(NSDictionary *)groupedRows groupedRowsLevel:(NSUInteger)groupedRowsLevel firstPageComplete:(BOOL *)firstPageComplete {
    
    NSArray *sqg = [[self query] sortedHasQueryGroups];
    [self setSortedQueryGroups:sqg];
    
    if (*firstPageComplete == NO) {
        
        if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
            
            SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
            
            NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys] copyItems:NO];
            BOOL nullGroupExist = [self nullKeyExist:allKeys];
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
                        *firstPageComplete = [self cachePageBreakWithNextItemHeight: layoutHeight];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }
                
                if (*firstPageComplete == NO) {
                    
                    [self cacheGroupHeaderAtLevel:groupedRowsLevel];
                    
                    
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
                        [self cacheUntilFirstPageStartingWithGroup: nextGroup groupedRows: obj groupedRowsLevel: groupedRowsLevel + 1 firstPageComplete:firstPageComplete];
                    } else {
                        [self cacheDetailLevelWithDetails:obj];
                    }
                    //Group footer section
                    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                        if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                            BOOL isVisible = [[documentSection visibility] boolValue];
                            CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                            [self cachePageBreakWithNextItemHeight: layoutHeight];
                            CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                            [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                            break;
                        }
                    }
                    
                    [self cacheGroupFooterAtLevel:groupedRowsLevel];
                    
                }
                
                [obj release];
                if (*firstPageComplete) {
                    break;
                }
            }
            [loopEnumerator release];
            [allKeys release];
            
        } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...
            
            [self cacheDetailLevelWithDetails:(NSArray *)groupedRows];
        }
    }
}

- (void)cacheGroupLevel:(RptqQueryGroup *)queryGroup groupedRows:(NSDictionary *)groupedRows groupedRowsLevel:(NSUInteger)groupedRowsLevel {
    
    NSArray *sqg = [[self query] sortedHasQueryGroups];
    [self setSortedQueryGroups:sqg];
    
    if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
        
        SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];

        NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys] copyItems:NO];

        BOOL nullGroupExist = [self nullKeyExist:allKeys];
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
                    [self cachePageBreakWithNextItemHeight: layoutHeight];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                    [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                    break;
                }
            }
            
            [self cacheGroupHeaderAtLevel:groupedRowsLevel];
            
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
                [self cacheGroupLevel: nextGroup groupedRows: obj groupedRowsLevel: groupedRowsLevel + 1];
            } else {
                [self cacheDetailLevelWithDetails:obj];
            }
            
            //Group footer section
            for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                    BOOL isVisible = [[documentSection visibility] boolValue];
                    CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                    [self cachePageBreakWithNextItemHeight: layoutHeight];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                    [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                    break;
                }
            }
            
            [self cacheGroupFooterAtLevel:groupedRowsLevel];
            
            [obj release];
        }
        [loopEnumerator release];
        [allKeys release];
        
    } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...
        
        [self cacheDetailLevelWithDetails:(NSArray *)groupedRows];
    }
}

// FIXME: Make sure paper rect is passed in to the software

- (BOOL)cachePageBreakWithNextItemHeight:(CGFloat)nextItemHeight {
    
    BOOL newPageCreated = NO;
    CGRect pageRect;
    
    //MTApplicationInstance *applicationInstance = [AppDelegate app];
    //MAReportDocument *activeDocument = [applicationInstance activeDocument];
    RptqDocument *document = [self layout];
    RptqDocumentSection *pageFooterSection = [document hasPageFooterSection];
    BOOL pageFooterIsVisable = [[pageFooterSection visibility] boolValue];
    CGFloat pageFooterSectionHeight = pageFooterIsVisable ? [[pageFooterSection layoutHeight] floatValue] : CGSizeZero.height;
    
    pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    
    if ([self printableSpaceUsedPageHeight] + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        
        newPageCreated = YES;
        CGFloat newHeight = [self printableSpaceUsedPageHeight] + pageFooterSectionHeight;
        [self setPrintableSpaceUsedPageHeight:newHeight];
        [self cachePageFooter];
        
        id layoutToAdd = [[self temporaryLayoutForPage] copy];
        [[self temporaryLayoutByPage] addObject:layoutToAdd];
        [layoutToAdd release];
        
        id dataToAdd = [[self temporaryIndexesForPage] copy];
        [[self temporaryIndexesByPage] addObject:dataToAdd];
        [dataToAdd release];
        
        [[self temporaryLayoutForPage] removeAllObjects];
        [[self temporaryIndexesForPage] removeAllIndexes];
        
        RptqDocumentSection *pageHeaderSection = [document hasPageHeaderSection];
        BOOL pageHeaderIsVisable = [[pageHeaderSection visibility] boolValue];
        CGFloat pageHeaderHeight = CGPointZero.y;
        pageHeaderHeight += pageHeaderIsVisable ? [[pageHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
        [self setPrintableSpaceUsedPageHeight: pageHeaderHeight];
        [self cachePageHeader];
        
    }
    return newPageCreated;
}

- (void)cacheGroupHeaderAtLevel:(NSUInteger)groupLevel {
    NSNumber *level = @(groupLevel);
    NSDictionary *d = @{MTReportSectionType : MTReportGroupHeader,
                        MTReportGroupLevel : level};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cachePageFooter {
    NSDictionary *d = @{MTReportSectionType : MTPageFooter};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheReportFooter {
    NSDictionary *d = @{MTReportSectionType : MTReportFooter};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails {
    
    RptqDocument *document = [self layout];
    RptqDocumentSection *detailSection = [document hasDetailSection];
    BOOL isVisible = [[detailSection visibility] boolValue];
    CGFloat layoutHeight = isVisible ? [[detailSection layoutHeight] floatValue] : CGSizeZero.height;
    for (NSDictionary *resultDictionary in containerDetails) {
        [self cachePageBreakWithNextItemHeight: layoutHeight];
        [self cacheDetail];
        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
    }
    
}

- (void)cacheGroupFooterAtLevel:(NSUInteger)groupLevel {
    NSNumber *gl = [[NSNumber alloc] initWithUnsignedInteger:groupLevel];
    NSDictionary *d = @{MTReportSectionType : MTReportGroupFooter,
                        MTReportGroupLevel : gl};
    [[self temporaryLayoutForPage] addObject: d];
    [gl release];
}

- (void)cacheDetail {
    NSDictionary *detail = @{MTReportSectionType : MTPageDetail};
    [[self temporaryLayoutForPage] addObject: detail];
    NSUInteger ctr = [self temporaryCachedDetailCounter];
    [[self temporaryIndexesForPage] addIndex:ctr];
    ctr++;
    [self setTemporaryCachedDetailCounter:ctr];
}

- (NSUInteger)numberOfPages {
    NSUInteger numberOfPages = 0;
    if ([self layoutByPage] == nil) {
        [self formatForSize:[self printableRect].size];
    }
    if ([self layoutByPage] != nil) {
        numberOfPages = [[self layoutByPage] count];
    }
    return numberOfPages;
}


- (BOOL)format {
    [self setCachedPageNumber:NSNotFound];
    NSArray *emptyArray = [NSArray array];
    [self setObjectsForPage:emptyArray];
    return [super format];
}
- (NSDictionary *)dataForRow:(NSUInteger)row onPage:(NSUInteger)page {
    id rowData = nil;
    if (page < [[self indexesByPage] count]) {
        NSIndexSet *pageIndexes = [[self indexesByPage] objectAtIndex:page];
        if (row < [pageIndexes count]) {
            
            // FIXME: Filter all through MTDataTable.
            SEL objectAtRowLimit = @selector(objectAtRow:limit:);
            if ([[[self query] datatable] respondsToSelector:objectAtRowLimit]) {

                
                if (page != [self cachedPageNumber]) {
                    [self setCachedPageNumber:page];
                    NSArray *objectsForPage = nil;
                        objectsForPage = [(MTDataTableFast *)[[self query] datatable] objectAtRow:[pageIndexes firstIndex]
                                                                                            limit:[pageIndexes count]];
                    [self setObjectsForPage:objectsForPage];
                }
                NSDictionary *data = [self objectsForPage][row];
                rowData = [NSDictionary dictionaryWithDictionary:data];
                
            } else {
                rowData = [(MTDataTable *)[[self query] datatable] objectAtRow:[pageIndexes firstIndex]];
            }
        }
    }
    return rowData;
}

- (id)dataForGroupKeys:(NSArray *)keys {
    return [MTReportFormatter dataForGroupData:[self dataByGroup] andKeys:keys];
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
    return [[[self indexesByPage] objectAtIndex:pageNumber] count];
}

- (NSIndexSet *)objectEnumeratorForPage:(NSUInteger)pageIndex {
    return [self indexesByPage][pageIndex];
}

- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex {
    return [[self layoutByPage][pageIndex] objectEnumerator];
}

@end
