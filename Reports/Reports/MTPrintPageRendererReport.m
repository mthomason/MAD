//
//  MTPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTPrintPageRendererReport.h"

@interface MTPrintPageRendererReport ()

@property (nonatomic, assign) NSUInteger cachedNumberOfPages;

@property (nonatomic, retain) RptqDocument *document;
@property (nonatomic, retain) NSMutableArray *cachedResults;
@property (nonatomic, retain) NSMutableArray *sortedSortDescriptorsGroup;
@property (nonatomic, retain) NSMutableDictionary *resultsByRow;

@property (nonatomic, assign) CGFloat working;

@end

@implementation MTPrintPageRendererReport

- (oneway void)release {
    [_resultsByRow release];
    [_sortedSortDescriptorsGroup release];
    [_cachedResults release];
}

// ???: Why am I overriding fucking retain?

- (id)retain {
    self = [super retain];
    if (self) {
        [_resultsByRow retain];
        [_sortedSortDescriptorsGroup retain];
        [_cachedResults retain];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTPrintPageRendererReport *copy = [[MTPrintPageRendererReport alloc] initWithDocument:[self document]];
    if (copy) {
        NSMutableArray *cachedResults = [[NSMutableArray alloc] initWithArray: [self cachedResults] copyItems:YES];
        [copy setCachedResults: cachedResults];
        [cachedResults release];
        
        [copy setDocument:[self document]];
        [copy setCachedNumberOfPages:[self cachedNumberOfPages]];
    }
    return copy;
}

- (id)initWithDocument:(RptqDocument *)document {
    CGSize printableSize = CGSizeMake(CGFloatPointsForInches(8.5000f), CGFloatPointsForInches(11.0000f));
    return [self initWithDocument:document andPrintableAreaSize:printableSize];
}

- (id)initWithDocument:(RptqDocument *)document andPrintableAreaSize:(CGSize)printableAreaSize {
    self = [super init];
    if (self) {

        
        [self setPrintableSize:printableAreaSize];
        [self setDocument:document];
        
        NSMutableArray *cachedResults = [[NSMutableArray alloc] init];
        [self setCachedResults:cachedResults];
        [cachedResults release];
        
        NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
        [self setSortedSortDescriptorsGroup:sortedSortDescriptorsGroup];
        [sortedSortDescriptorsGroup release];
        
        NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] init];
        [self setResultsByRow:resultsForRow];
        [resultsForRow release];
        
        //[self cachePrintPageRenderData];
        
    }
    return self;
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    
    CGFloat originY = pageRect.origin.y;
    CGFloat originX = pageRect.origin.x;
    CGFloat sizeWidth = pageRect.size.width;

    if ([[self cachedResults] count] == 1) {
        MTPrintPageRenderReportPageData *data = [[[self cachedResults] objectAtIndex:index] retain];
        NSArray *pageSectionsToPrint = [[NSArray alloc] initWithArray:[data enumeratePageSections]];
        
        CGRect sectionRect = CGRectZero;
        
        for (NSDictionary *pageSection in pageSectionsToPrint) {
            
            NSString *pageSectionId = [[NSString alloc] initWithString:[pageSection objectForKey: MTReportSectionType]];
            id reportSectionValues = nil;
            NSLog(@"%@ (%@): %@", pageSectionId, data, NSStringFromCGRect(sectionRect));
            
            if ([MTPageDetail isEqualToString:pageSectionId]) {
                
                RptqDocumentSection *detailSection = [[self document] hasDetailSection];
                CGFloat sizeHeight = [[detailSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor whiteColor] set];
                [[UIBezierPath bezierPathWithRect:sectionRect] fill];
                
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
                [self printDocumentElementsForSection:detailSection atHeight:originY withResults:reportSectionValues];
                originY += sizeHeight;
                
            } else if ([MTPageHeader isEqualToString:pageSectionId]) {
                
                RptqDocumentSection *pageHeaderSection = [[self document] hasPageHeaderSection];
                CGFloat sizeHeight = [[pageHeaderSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor yellowColor] set];
                [[UIBezierPath bezierPathWithRect:sectionRect] fill];
                
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
                [self printDocumentElementsForSection:pageHeaderSection atHeight:originY withResults:reportSectionValues];
                originY += sizeHeight;
                
            } else if ([MTPageFooter isEqualToString:pageSectionId]) {
                
                RptqDocumentSection *pageFooterSection = [[self document] hasPageFooterSection];
                CGFloat sizeHeight = [[pageFooterSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor yellowColor] set];
                [[UIBezierPath bezierPathWithRect:sectionRect] fill];
                
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
                [self printDocumentElementsForSection:pageFooterSection atHeight:originY withResults:reportSectionValues];
                originY += sizeHeight;
                
            } else if ([MTReportHeader isEqualToString:pageSectionId]) {
                
                RptqDocumentSection *reportHeaderSection = [[self document] hasReportHeaderSection];
                CGFloat sizeHeight = [[reportHeaderSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor greenColor] set];
                [[UIBezierPath bezierPathWithRect:sectionRect] fill];
                
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
                [self printDocumentElementsForSection:reportHeaderSection atHeight:originY withResults:reportSectionValues];
                originY += [[reportHeaderSection height] floatValue];
                
            } else if ([MTReportFooter isEqualToString:pageSectionId]) {
                
                RptqDocumentSection *reportFooterSection = [[self document] hasReportFooterSection];
                CGFloat sizeHeight = [[reportFooterSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor greenColor] set];
                [[UIBezierPath bezierPathWithRect:sectionRect] fill];
                
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
                [self printDocumentElementsForSection:reportFooterSection atHeight:originY withResults:reportSectionValues];
                originY += sizeHeight;
                
            } else if ([MTReportGroupHeader isEqualToString:pageSectionId]) {
                
                NSNumber *groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                RptqQuery *query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                RptqDocumentSection *groupHeader = [RptqDocumentSection getDocumentGroupHeaderAtLevel:[groupLevel integerValue] forQuery:query];
                
                CGFloat sizeHeight = [[groupHeader height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor lightTextColor] set];
                [[UIBezierPath bezierPathWithRect:sectionRect] fill];
                
                if ([reportSectionValues isKindOfClass:[NSArray class]]) {
                    reportSectionValues = [[NSArray alloc] initWithArray:[pageSection objectForKey:MTReportSectionValues]];
                } else if ([reportSectionValues isKindOfClass:[NSDictionary class]]) {
                    reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
                }
                [self printDocumentElementsForSection:groupHeader atHeight:originY withResults:reportSectionValues];
                originY += sizeHeight;
                
            } else if ([MTReportGroupFooter isEqualToString:pageSectionId]) {
                
                NSNumber *groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                RptqQuery *query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                RptqDocumentSection *groupFooter = [RptqDocumentSection getDocumentGroupFooterAtLevel:[groupLevel integerValue] forQuery:query];
                CGFloat sizeHeight = [[groupFooter height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor lightTextColor] set];
                [[UIBezierPath bezierPathWithRect:sectionRect] fill];
                
                if ([reportSectionValues isKindOfClass:[NSArray class]]) {
                    reportSectionValues = [[NSArray alloc] initWithArray:[pageSection objectForKey:MTReportSectionValues]];
                } else if ([reportSectionValues isKindOfClass:[NSDictionary class]]) {
                    reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
                }
                
                [self printDocumentElementsForSection:groupFooter atHeight:originY withResults:reportSectionValues];
                originY += sizeHeight;
                
            }
            
            //NSLog(@"Object to print: %@", pageSectionId);
            
            [pageSectionId release];
            [reportSectionValues release];
        }
        [pageSectionsToPrint release];
        [data release];
    }

}

- (void)printDocumentElementsForSection:(RptqDocumentSection *)section atHeight:(CGFloat)originY withResults:(NSDictionary *)results {
    CGFloat originX = CGPointZero.x;
    for (RptqDocumentObject *documentObject in [section hasObjects]) {
        NSAttributedString *attributedString = [self attributedStringFor:documentObject withResultDictionary:results];
        CGFloat sizeWidth = [[documentObject sizewidth] floatValue];
        CGFloat sizeHeight = [[documentObject sizeheight] floatValue];
        CGRect elementCanvasRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
        [attributedString drawInRect:elementCanvasRect];
        NSLog(@"Element at rect: %@", NSStringFromCGRect(elementCanvasRect));
        originX += sizeWidth;
    }
}

- (void)drawHeaderForPageAtIndex:(NSInteger)index inRect:(CGRect)headerRect {
    [super drawHeaderForPageAtIndex:index inRect:headerRect];
}

- (void)drawContentForPageAtIndex:(NSInteger)index inRect:(CGRect)contentRect {
    [super drawContentForPageAtIndex:index inRect:contentRect];
}

- (void)drawFooterForPageAtIndex:(NSInteger)index inRect:(CGRect)footerRect {
    [super drawFooterForPageAtIndex:index inRect:footerRect];
}


- (NSInteger)numberOfPages {
//    [self cachePrintPageRenderData];
    return [self cachedNumberOfPages];
}

#pragma mark - Object methods


- (void)cachePrintPageRenderData {
    
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqQueryCache *queryCache = [query hasQueryCache];    
    
    //NSMutableDictionary *resultsByRow = [[NSMutableDictionary alloc] init];
    
    NSSet *hasQueryResults = [queryCache hasQueryResults];
    for (RptqQueryResult *queryResult in hasQueryResults) {
        
        NSMutableDictionary *resultDictionary = [[[self resultsByRow] objectForKey:[queryResult rowid]] retain];

        id results = [[self resultsByRow] objectForKey:[queryResult rowid]];
        if (results == nil) {
            [resultDictionary release];
            resultDictionary = nil;
            resultDictionary = [[NSMutableDictionary alloc] init];
        } else {
            [resultDictionary retain];
        }
        
        id queryResultValue = [[queryResult value] retain];
        NSString *fieldName = [[NSString alloc] initWithString:[queryResult fieldname]];
        
        [resultDictionary setObject:queryResultValue forKey:fieldName];
        
        [fieldName release];
        [queryResultValue release];
        
        NSNumber *rowId = [[queryResult rowid] retain];
        NSMutableDictionary *d = [resultDictionary retain];
        [[self resultsByRow] setObject:d forKey:rowId];
        [d release];
        [rowId release];
        
        [resultDictionary release];
    }
    
    NSSet *resultsByRowSet = [[NSSet setWithArray:[[self resultsByRow] allValues]] retain];
    NSSet *hasQueryGroups = [query hasQueryGroups];
    
    NSSortDescriptor *sortd = [[NSSortDescriptor alloc] initWithKey:@"weight" ascending:YES];
    //NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortd, nil];
    NSArray *sortedHasQueryGroups = [hasQueryGroups sortedArrayUsingDescriptors:@[sortd]];
    for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {

        BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
        NSString *fieldNameNice = [[NSString alloc] initWithString:[queryGroup fieldNameNice]];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: fieldNameNice
                                                                       ascending: sortAscending];
        [[self sortedSortDescriptorsGroup] addObject:sortDescriptor];
        [fieldNameNice release];
        [sortDescriptor release];
    }
    NSArray *sortedResultsByRow = [[resultsByRowSet sortedArrayUsingDescriptors:[self sortedSortDescriptorsGroup]] retain];
    
    id groupedRows = [[self groupedResults:sortedResultsByRow level:0 sortDescriptors:[self sortedSortDescriptorsGroup]] retain];
    
    CGFloat printableSpaceUsedPageHeight = 0.0000f;
    NSUInteger numberOfPagesUsed = 0;
    
    MTPrintPageRenderReportPageData *printPageRenderReportPageData  = [[MTPrintPageRenderReportPageData alloc] init];
    
    printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];
    NSLog(@"Page Header One");
    [printPageRenderReportPageData addPageHeaderWithValueDictionary:groupedRows];
    
    printableSpaceUsedPageHeight += [[[[self document] hasReportHeaderSection] height] floatValue];
    NSLog(@"Report Header");
    [printPageRenderReportPageData addReportHeaderWithValueDictionary:groupedRows];
    
    [self printGroupLevel:[query firstQueryGroup]
printableSpaceUsedPageHeight:&printableSpaceUsedPageHeight
        numberOfPagesUsed:&numberOfPagesUsed
              groupedRows:groupedRows
printPageRenderReportPageData:&printPageRenderReportPageData];
    
    printableSpaceUsedPageHeight += [[[[self document] hasReportFooterSection] height] floatValue];
    NSLog(@"Report Footer Last");
    [printPageRenderReportPageData addReportFooterWithValueDictionary:groupedRows];
    
    printableSpaceUsedPageHeight += [[[[self document] hasPageFooterSection] height] floatValue];
    NSLog(@"Page Footer Last");
    [printPageRenderReportPageData addPageFooterWithValueDictionary:groupedRows];

    [groupedRows release];
    [sortedResultsByRow release];
    [resultsByRowSet release];
//    [resultsByRow release];
    //[sortDescriptors release];
    [sortd release];

    [self setCachedNumberOfPages: numberOfPagesUsed];
//    [sortedSortDescriptorsGroup release];

}

//Roll through the groups
//Returns dictionary for group levels (level < n), and array of dictionaries for details/results (level == n-1).
- (id)groupedResults:(NSArray *)sortedResults level:(NSUInteger)level
     sortDescriptors:(NSArray *)sortedSortDescriptorsGroup {
    
    BOOL detailLevel = level == [sortedSortDescriptorsGroup count];
    
    id returnValue = nil;
    
    if (detailLevel) {
        //MTLog(@"Detail Level %@", sortedResults);
        returnValue = [sortedResults copy];
    } else {
        NSMutableDictionary *resultsDictionary = [[NSMutableDictionary alloc] init];
        NSMutableArray *resultsForGroup = [[NSMutableArray alloc] init];
        NSSortDescriptor *sortDescriptor = detailLevel ? nil : [sortedSortDescriptorsGroup objectAtIndex:level];
        NSString *sortFieldName =  detailLevel ? nil : [sortDescriptor key];
        id valueForField = nil, lastValueForField = nil;
        //MTLog(@"Group Level %d (%@)", level, sortFieldName);
        for (NSDictionary *result in sortedResults) {
            valueForField = detailLevel ? nil : [result objectForKey:sortFieldName];
            if (![valueForField isEqual: lastValueForField] && lastValueForField != nil) {
                //MTLog(@" -Group Level %d (%@)", level, lastValueForField);
                
                id resultOfNextGroup = [self groupedResults: resultsForGroup
                                                      level: (level + 1)
                                            sortDescriptors: sortedSortDescriptorsGroup];
                [resultsDictionary setObject:resultOfNextGroup forKey:lastValueForField];
                [resultsForGroup removeAllObjects];
            }
            [resultsForGroup addObject:result];
            lastValueForField = valueForField;
        }
        NSArray *resultsCopy = [[NSArray alloc] initWithArray: resultsForGroup];                //Last item
        if (valueForField != nil) {
            //MTLog(@" -Group Level %d (%@)", level, valueForField);
            id resultOfNextGroup = [self groupedResults: resultsForGroup
                                                  level: (level + 1)
                                        sortDescriptors: sortedSortDescriptorsGroup];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            [resultsDictionary setObject:resultOfNextGroup forKey:key];
        }
        [resultsCopy release];
        [resultsForGroup removeAllObjects];
        returnValue = [resultsDictionary retain];
        [resultsDictionary release];
        [resultsForGroup release];
    }
    return [returnValue autorelease];
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup
printableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight
      numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed
            groupedRows:(NSDictionary *)groupedRows
printPageRenderReportPageData:(MTPrintPageRenderReportPageData **)printPageRenderReportPageData {
    BOOL detailPrinted = NO;
    NSUInteger groupedRowsLevel = 0;
    [self printGroupLevel: queryGroup
printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
        numberOfPagesUsed: numberOfPagesUsed
              groupedRows: groupedRows
         groupedRowsLevel: groupedRowsLevel
            detailPrinted: &detailPrinted
printPageRenderReportPageData:printPageRenderReportPageData];
    
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup
printableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight
      numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed
            groupedRows:(NSDictionary *)groupedRows
       groupedRowsLevel:(NSUInteger)groupedRowsLevel
          detailPrinted:(BOOL *)detailPrinted
printPageRenderReportPageData:(MTPrintPageRenderReportPageData **)printPageRenderReportPageData {
    
    if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if not results are returned, and no groupings preformed.
        for (id key in [groupedRows keyEnumerator]) {
            id obj = [[groupedRows objectForKey:key] retain];
            
            //Group header section
            for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                    
                    [self printPageBreakWithNextItemHeight: [[documentSection height] floatValue]
                              printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                                         numberOfPagesUsed: numberOfPagesUsed
                                               groupedRows: groupedRows
                             printPageRenderReportPageData: printPageRenderReportPageData];
                    
                    NSMutableString *mutableStringToPrint = [[NSMutableString alloc] init];
                    NSUInteger documentObjectCounter = 0;
                    for (RptqDocumentObject *documentObject in [documentSection hasObjects]) {
                        if (documentObjectCounter > 0) {
                            [mutableStringToPrint appendString:@", "];
                        }
                        NSString *stringToPrint = [self printDocumentObject:documentObject
                                                       withResultDictionary:nil/*resultDictionary*/];
                        [mutableStringToPrint appendString:stringToPrint];
                    }
                    [mutableStringToPrint release];
                    *printableSpaceUsedPageHeight += [[documentSection height] floatValue];
                    NSUInteger groupNumber = [[queryGroup weight] integerValue];
                    NSSortDescriptor *sortDescriptor = [[self sortedSortDescriptorsGroup] objectAtIndex:groupNumber];
                    NSString *sortOrderDescription = [sortDescriptor ascending] ?
                    NSLocalizedString(@"Ascending", @"Ascending") : NSLocalizedString(@"Decending", @"Decending");
                    NSLog(@"Group Header %d (%@, %@)", groupNumber, [sortDescriptor key], sortOrderDescription);
                    break;
                }
            }
            [*printPageRenderReportPageData addGroupHeaderWithValueDictionary:obj andLevel:groupedRowsLevel];
            
            RptqQueryGroup *nextGroup = [queryGroup next];

            
            if (nextGroup != nil) {
                NSDictionary *containerDetails = [obj retain];
                [self printGroupLevel: nextGroup
         printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                    numberOfPagesUsed: numberOfPagesUsed
                          groupedRows: containerDetails
                     groupedRowsLevel: groupedRowsLevel
                        detailPrinted: detailPrinted printPageRenderReportPageData:printPageRenderReportPageData];
                [containerDetails release];
            } else {
                NSArray *containerDetails = [obj retain];
                RptqDocumentSection *detailSection = [[self document] hasDetailSection];
                for (NSDictionary *resultDictionary in containerDetails) {
                    
                    [self printPageBreakWithNextItemHeight: [[detailSection height] floatValue]
                              printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                                         numberOfPagesUsed: numberOfPagesUsed
                                               groupedRows: groupedRows
                             printPageRenderReportPageData: printPageRenderReportPageData];
                    
                    [*printPageRenderReportPageData addDetailWithValueDictionary:resultDictionary];
                    
                    *printableSpaceUsedPageHeight += [[detailSection height] floatValue];
                    NSMutableString *mutableStringToPrint = [[NSMutableString alloc] init];
                    NSUInteger documentObjectCounter = 0;
                    for (RptqDocumentObject *documentObject in [detailSection hasObjects]) {
                        if (documentObjectCounter > 0) {
                            [mutableStringToPrint appendString:@", "];
                        }
                        NSString *stringToPrint = [self printDocumentObject:documentObject
                                                       withResultDictionary:resultDictionary];
                        [mutableStringToPrint appendString:stringToPrint];
                    }
                    NSLog(@"Detail: (%@)", mutableStringToPrint);
                    [mutableStringToPrint release];
                    documentObjectCounter++;
                }
                [containerDetails release];
            }
            
            //Group footer section
            for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                    
                    [self printPageBreakWithNextItemHeight: [[documentSection height] floatValue]
                              printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                                         numberOfPagesUsed: numberOfPagesUsed
                                               groupedRows: groupedRows
                             printPageRenderReportPageData: printPageRenderReportPageData];
                    
                    *printableSpaceUsedPageHeight += [[documentSection height] floatValue];
                    NSUInteger groupNumber = [[queryGroup weight] integerValue];
                    NSSortDescriptor *sortDescriptor = [[self sortedSortDescriptorsGroup] objectAtIndex:groupNumber];
                    NSString *sortOrderDescription = [sortDescriptor ascending] ?
                    NSLocalizedString(@"Ascending", @"Ascending") : NSLocalizedString(@"Decending", @"Decending");
                    NSLog(@"Group Footer %d (%@, %@)", groupNumber, [sortDescriptor key], sortOrderDescription);
                    break;
                }
            }
            [*printPageRenderReportPageData addGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
            [obj release];
        }
    }
    
}

- (NSString *)printDocumentObject:(RptqDocumentObject *)documentObject withResultDictionary:(NSDictionary *)resultDictionary {
    NSString *result = nil;
    switch ([documentObject getType]) {
        case MNSObjectTypeLabel: {
            
            break;
        }
        case MNSObjectTypeLabelDataField: {
            RptqDocumentObjectLabelDataField *documentObjectDataField = [documentObject isLabelDataField];
            RptqField *field = [documentObjectDataField referencesField];
            result = [resultDictionary objectForKey: [field display]];
            break;
        }
        case MNSObjectTypeLabelFormula: {
            break;
        }
        case MNSObjectTypeLabelLabelLink: {
            break;
        }
        default: {
            break;
        }
    }
    if (result == nil) {
        result = @"Nil";
    }
    return result;
}

- (NSAttributedString *)attributedStringFor:(RptqDocumentObject *)documentObject withResultDictionary:(NSDictionary *)resultDictionary {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    switch ([documentObject getType]) {
        case MNSObjectTypeLabel: {
            
            break;
        }
        case MNSObjectTypeLabelDataField: {
            RptqDocumentObjectLabelDataField *documentObjectDataField = [documentObject isLabelDataField];
            RptqField *field = [documentObjectDataField referencesField];
            NSString *displayText = [resultDictionary objectForKey: [field display]];
            if (displayText != nil) {
                [[result mutableString] setString:displayText];
            }
            break;
        }
        case MNSObjectTypeLabelFormula: {
            break;
        }
        case MNSObjectTypeLabelLabelLink: {
            break;
        }
        default: {
            break;
        }
    }
    NSRange wholeString = NSMakeRange(0, [[result mutableString] length]);
    UIFont *customFont = [UIFont systemFontOfSize:[[documentObject fontsize] floatValue]];
    NSDictionary *customAttributes = @{NSFontAttributeName : customFont};
    [result setAttributes:customAttributes range:wholeString];
    return [result autorelease];
}

- (void)printPageBreakWithNextItemHeight:(CGFloat)nextItemHeight
            printableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight
                       numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed
                             groupedRows:(NSDictionary *)groupedRows
printPageRenderReportPageData:(MTPrintPageRenderReportPageData **)printPageRenderReportPageData {
    CGRect pageRect;
    CGFloat pageFooterSectionHeight = [[[[self document] hasPageFooterSection] height] floatValue];
    if (CGRectIsEmpty([self printableRect])) {
        pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    } else {
        pageRect = [self paperRect];
    }
    
    if (*printableSpaceUsedPageHeight + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        NSLog(@"Page Footer");
        *printableSpaceUsedPageHeight += pageFooterSectionHeight;
        [*printPageRenderReportPageData addPageFooterWithValueDictionary:groupedRows];
        
        MTPrintPageRenderReportPageData *pageData = [*printPageRenderReportPageData copy];
        [[self cachedResults] addObject:pageData];
        [pageData release];
        
        [*printPageRenderReportPageData release];
        *printPageRenderReportPageData = nil;
        *printPageRenderReportPageData  = [[MTPrintPageRenderReportPageData alloc] init];
        
        *numberOfPagesUsed = *numberOfPagesUsed + 1;
        *printableSpaceUsedPageHeight = 0.0000f;
        NSLog(@"Page Header");
        *printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];
        [*printPageRenderReportPageData addPageHeaderWithValueDictionary:groupedRows];
    }
    
}

@end