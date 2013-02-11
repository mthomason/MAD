//
//  MTPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTPrintPageRendererReport.h"

@interface MTPrintPageRendererReport ()

@property (nonatomic, retain) RptqDocument *document;

@property (nonatomic, assign) NSUInteger cachedNumberOfPages;
@property (nonatomic, retain) NSArray *cachedResults;

@end

@implementation MTPrintPageRendererReport

- (id)copyWithZone:(NSZone *)zone {
    MTPrintPageRendererReport *copy = [[MTPrintPageRendererReport alloc] initWithDocument:[self document]];
    if (copy) {
        NSArray *cachedResults = [[[self cachedResults] copyWithZone:zone] retain];
        NSLog(@"Retain count: %d", [cachedResults retainCount]);
        [copy setCachedResults: cachedResults];
        [cachedResults release];
        
        [copy setDocument:[self document]];
        [copy setCachedNumberOfPages:[self cachedNumberOfPages]];
    }
    return copy;
}

- (oneway void)release {
    //NSLog(@"Retain count: %d", [[self cachedResults] retainCount]);
    NSLog(@"Retain count: %d", [_cachedResults retainCount]);
    [_cachedResults release];
    [super release];
}

- (id)initWithDocument:(RptqDocument *)document {
    self = [super init];
    if (self) {
        [self setDocument:document];
        
        NSArray *cachedResults = [[NSArray alloc] init];
        [self setCachedResults:cachedResults];
        [cachedResults release];
    }
    return self;
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    
    CGFloat originY = 0.0000f;
    MTPrintPageRenderReportPageData *data = [[[self cachedResults] objectAtIndex:index] retain];
    NSArray *pageSectionsToPrint = [[NSArray alloc] initWithArray:[data enumeratePageSections]];
 
    for (NSDictionary *pageSection in pageSectionsToPrint) {

        NSString *pageSectionId = [[NSString alloc] initWithString:[pageSection objectForKey: MTReportSectionType]];
        id reportSectionValues = nil;

        if ([MTPageDetail isEqualToString:pageSectionId]) {

            reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
            RptqDocumentSection *detailSection = [[self document] hasDetailSection];
            [self printDocumentElementsForSection:detailSection atHeight:originY withResults:reportSectionValues];
            originY += [[detailSection height] floatValue];
            NSLog(@"Detail (%@): %@", data, detailSection);
        
        } else if ([MTPageHeader isEqualToString:pageSectionId]) {

            reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
            RptqDocumentSection *pageHeaderSection = [[self document] hasPageHeaderSection];
            [self printDocumentElementsForSection:pageHeaderSection atHeight:originY withResults:reportSectionValues];
            originY += [[pageHeaderSection height] floatValue];
            NSLog(@"Page Header (%@): %@", data, pageHeaderSection);

        } else if ([MTPageFooter isEqualToString:pageSectionId]) {

            reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
            RptqDocumentSection *pageFooterSection = [[self document] hasPageFooterSection];
            [self printDocumentElementsForSection:pageFooterSection atHeight:originY withResults:reportSectionValues];
            originY += [[pageFooterSection height] floatValue];
            NSLog(@"Page Footer (%@): %@", data, pageFooterSection);

        } else if ([MTReportHeader isEqualToString:pageSectionId]) {

            reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
            RptqDocumentSection *reportHeaderSection = [[self document] hasReportHeaderSection];
            [self printDocumentElementsForSection:reportHeaderSection atHeight:originY withResults:reportSectionValues];
            originY += [[reportHeaderSection height] floatValue];
            NSLog(@"Report Header (%@): %@", data, reportHeaderSection);

        } else if ([MTReportFooter isEqualToString:pageSectionId]) {

            reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
            RptqDocumentSection *reportFooterSection = [[self document] hasReportFooterSection];
            [self printDocumentElementsForSection:reportFooterSection atHeight:originY withResults:reportSectionValues];
            originY += [[reportFooterSection height] floatValue];
            NSLog(@"Report Footer (%@): %@", data, reportFooterSection);

        } else if ([MTReportGroupHeader isEqualToString:pageSectionId]) {

            if ([reportSectionValues isKindOfClass:[NSArray class]]) {
                reportSectionValues = [[NSArray alloc] initWithArray:[pageSection objectForKey:MTReportSectionValues]];
            } else if ([reportSectionValues isKindOfClass:[NSDictionary class]]) {
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
            }
            NSNumber *groupLevel = [pageSection objectForKey:MTReportGroupLevel];
            RptqQuery *query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
            RptqDocumentSection *groupHeader = [RptqDocumentSection getDocumentGroupHeaderAtLevel:[groupLevel integerValue] forQuery:query];
            [self printDocumentElementsForSection:groupHeader atHeight:originY withResults:reportSectionValues];
            originY += [[groupHeader height] floatValue];
            NSLog(@"Group Header (%@): %@", data, groupHeader);

        } else if ([MTReportGroupFooter isEqualToString:pageSectionId]) {

            if ([reportSectionValues isKindOfClass:[NSArray class]]) {
                reportSectionValues = [[NSArray alloc] initWithArray:[pageSection objectForKey:MTReportSectionValues]];
            } else if ([reportSectionValues isKindOfClass:[NSDictionary class]]) {
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:[pageSection objectForKey:MTReportSectionValues]];
            }
            reportSectionValues = [[NSArray alloc] initWithArray:[pageSection objectForKey:MTReportSectionValues]];
            NSNumber *groupLevel = [pageSection objectForKey:MTReportGroupLevel];
            RptqQuery *query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
            RptqDocumentSection *groupFooter = [RptqDocumentSection getDocumentGroupFooterAtLevel:[groupLevel integerValue] forQuery:query];
            [self printDocumentElementsForSection:groupFooter atHeight:originY withResults:reportSectionValues];
            originY += [[groupFooter height] floatValue];
            NSLog(@"Group Footer (%@): %@", data, groupFooter);

        }
    
        NSLog(@"Object to print: %@", pageSectionId);

        [pageSectionId release];
        [reportSectionValues release];
    }
    [pageSectionsToPrint release];
    [data release];
}

- (void)printDocumentElementsForSection:(RptqDocumentSection *)section atHeight:(CGFloat)originY withResults:(NSDictionary *)results {
    for (RptqDocumentObject *documentObject in [section hasObjects]) {
        NSAttributedString *attributedString = [self attributedStringFor:documentObject withResultDictionary:results];
        CGFloat originX = [[documentObject originx] floatValue];
        CGFloat sizeWidth = [[documentObject sizewidth] floatValue];
        CGFloat sizeHeight = [[documentObject sizeheight] floatValue];
        CGRect elementCanvasRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
        [attributedString drawInRect:elementCanvasRect];
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
    [self cachePrintPageRenderData];
    return [self cachedNumberOfPages];
}

#pragma mark - Object methods


- (void)cachePrintPageRenderData {
    
    NSMutableArray *mutableCachedResults = [[NSMutableArray alloc] init];
    
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqQueryCache *queryCache = [query hasQueryCache];    
    
    //Setup dictionary by result row for group sorting
    NSMutableDictionary *resultsByRow = [[NSMutableDictionary alloc] init];
    NSSet *hasQueryResults = [queryCache hasQueryResults];
    for (RptqQueryResult *queryResult in hasQueryResults) {
        NSMutableDictionary *resultDictionary = [[resultsByRow objectForKey:[queryResult rowid]] retain];
        if ([resultDictionary count] == 0) {
            [resultDictionary release];
            resultDictionary = nil;
            resultDictionary = [[NSMutableDictionary alloc] init];
        }
        id queryResultValue = [[queryResult value] retain];
        [resultDictionary setObject:queryResultValue forKey:[queryResult fieldname]];
        [queryResultValue release];
        
        [resultsByRow setObject:resultDictionary forKey:[queryResult rowid]];
        
        [resultDictionary release];
    }
    
    NSSet *resultsByRowSet = [NSSet setWithArray:[resultsByRow allValues]];
    
    NSMutableArray *sortDescriptorsGroup = [[NSMutableArray alloc] init];
    NSSet *hasQueryGroups = [[query hasQueryGroups] retain];
    NSArray *sortedHasQueryGroups = [hasQueryGroups sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"weight" ascending:YES]]];
    for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
        NSString *fieldNameNice = [queryGroup fieldNameNice];
        BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: fieldNameNice
                                                                       ascending: sortAscending];
        [sortDescriptorsGroup addObject:sortDescriptor];
        [sortDescriptor release];
    }
    NSArray *sortedSortDescriptorsGroup = sortDescriptorsGroup;
    NSArray *sortedResultsByRow = [resultsByRowSet sortedArrayUsingDescriptors:sortedSortDescriptorsGroup];
    
    NSDictionary *groupedRows = [[self groupedResults:sortedResultsByRow level:0 sortDescriptors:sortedSortDescriptorsGroup] retain];
    
    CGFloat printableSpaceRequired = 0.0000f;
    CGFloat printableSpaceUsedPageHeight = 0.0000f;
    NSUInteger numberOfPagesUsed = 0;
    
    MTPrintPageRenderReportPageData *printPageRenderReportPageData  = [[MTPrintPageRenderReportPageData alloc] init];
    
    printableSpaceRequired += [[[[self document] hasPageHeaderSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];
    NSLog(@"Page Header One");
    [printPageRenderReportPageData addPageHeaderWithValueDictionary:groupedRows];
    
    printableSpaceRequired += [[[[self document] hasReportHeaderSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasReportHeaderSection] height] floatValue];
    NSLog(@"Report Header");
    [printPageRenderReportPageData addReportHeaderWithValueDictionary:groupedRows];
    
    [self printGroupLevel:[query firstQueryGroup] withSortedResults:sortedResultsByRow
   printableSpaceRequired:&printableSpaceRequired printableSpaceUsedPageHeight:&printableSpaceUsedPageHeight
        numberOfPagesUsed:&numberOfPagesUsed withSortDescriptors:sortedSortDescriptorsGroup groupedRows:groupedRows
    printPageRenderReportPageData:&printPageRenderReportPageData cachedResults:&mutableCachedResults];
    
    printableSpaceRequired += [[[[self document] hasReportFooterSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasReportFooterSection] height] floatValue];
    NSLog(@"Report Footer Last");
    [printPageRenderReportPageData addReportFooterWithValueDictionary:groupedRows];
    
    printableSpaceRequired += [[[[self document] hasPageFooterSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasPageFooterSection] height] floatValue];
    NSLog(@"Page Footer Last");
    [printPageRenderReportPageData addPageFooterWithValueDictionary:groupedRows];

    [sortDescriptorsGroup release];
    [hasQueryGroups release];
    [resultsByRow release];
    [groupedRows release];
    
    NSArray *newCachedResuls = [[NSArray alloc] initWithArray:mutableCachedResults];
    [self setCachedNumberOfPages: numberOfPagesUsed];
    [self setCachedResults:newCachedResuls];
    [mutableCachedResults release];
    [newCachedResuls release];

}

//Roll through the groups
//Returns dictionary for group levels (level < n), and array of dictionaries for details/results (level == n-1).
- (id)groupedResults:(NSArray *)sortedResults level:(NSUInteger)level
     sortDescriptors:(NSArray *)sortedSortDescriptorsGroup {
    
    NSMutableDictionary *resultsDictionary = [[NSMutableDictionary alloc] init];
    BOOL detailLevel = level == [sortedSortDescriptorsGroup count];
    id valueForField, lastValueForField = nil;
    NSMutableArray *resultsForGroup = [[NSMutableArray alloc] init];
    NSSortDescriptor *sortDescriptor = detailLevel ? nil : [sortedSortDescriptorsGroup objectAtIndex:level];
    NSString *sortFieldName =  detailLevel ? nil : [sortDescriptor key];
    
    id returnValue = nil;
    
    if (detailLevel) {
        //MTLog(@"Detail Level %@", sortedResults);
        returnValue = [sortedResults copy];
    } else {
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
        [resultsDictionary autorelease];
    }
    [resultsForGroup release];
    return [returnValue autorelease];
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup
      withSortedResults:(NSArray *)sortedResultsByRow
 printableSpaceRequired:(CGFloat *)printableSpaceRequired
printableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight
      numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed
    withSortDescriptors:(NSArray *)sortDescriptorsGroup
            groupedRows:(NSDictionary *)groupedRows
printPageRenderReportPageData:(MTPrintPageRenderReportPageData **)printPageRenderReportPageData
          cachedResults:(NSMutableArray **)cachedResults {
    BOOL detailPrinted = NO;
    NSUInteger groupedRowsLevel = 0;
    [self printGroupLevel: queryGroup
        withSortedResults: sortedResultsByRow
   printableSpaceRequired: printableSpaceRequired
printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
        numberOfPagesUsed: numberOfPagesUsed
      withSortDescriptors: sortDescriptorsGroup
              groupedRows: groupedRows
         groupedRowsLevel: groupedRowsLevel
            detailPrinted: &detailPrinted
printPageRenderReportPageData:printPageRenderReportPageData cachedResults:cachedResults];
    
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup
      withSortedResults:(NSArray *)sortedResultsByRow
 printableSpaceRequired:(CGFloat *)printableSpaceRequired
printableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight
      numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed
    withSortDescriptors:(NSArray *)sortDescriptorsGroup
            groupedRows:(NSDictionary *)groupedRows
       groupedRowsLevel:(NSUInteger)groupedRowsLevel
          detailPrinted:(BOOL *)detailPrinted
printPageRenderReportPageData:(MTPrintPageRenderReportPageData **)printPageRenderReportPageData cachedResults:(NSMutableArray **)cachedResults {
    
    for (id key in [groupedRows keyEnumerator]) {
        id obj = [[groupedRows objectForKey:key] retain];
        
        //Group header section
        for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
            if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                
                [self printPageBreakWithNextItemHeight: *printableSpaceUsedPageHeight + [[documentSection height] floatValue]
                          printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                                printableSpaceRequired: printableSpaceRequired
                                     numberOfPagesUsed: numberOfPagesUsed
                                           groupedRows: groupedRows
                         printPageRenderReportPageData: printPageRenderReportPageData cachedResults:cachedResults];
                
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
                
                *printableSpaceRequired += [[documentSection height] floatValue];
                *printableSpaceUsedPageHeight += [[documentSection height] floatValue];
                NSUInteger groupNumber = [[queryGroup weight] integerValue];
                NSSortDescriptor *sortDescriptor = [sortDescriptorsGroup objectAtIndex:groupNumber];
                NSString *sortOrderDescription = [sortDescriptor ascending] ?
                    NSLocalizedString(@"Ascending", @"Ascending") : NSLocalizedString(@"Decending", @"Decending");
                NSLog(@"Group Header %d (%@, %@)", groupNumber, [sortDescriptor key], sortOrderDescription);
                break;
            }
        }
        [*printPageRenderReportPageData addGroupHeaderWithValueDictionary:obj andLevel:groupedRowsLevel];

        RptqQueryGroup *nextGroup = [queryGroup next];
                
        if (nextGroup != nil) {
            NSDictionary *containerDetails = obj;
            [self printGroupLevel: nextGroup
                withSortedResults: sortedResultsByRow
           printableSpaceRequired: printableSpaceRequired
     printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                numberOfPagesUsed: numberOfPagesUsed
              withSortDescriptors: sortDescriptorsGroup
                      groupedRows: containerDetails
                 groupedRowsLevel: groupedRowsLevel
                    detailPrinted: detailPrinted printPageRenderReportPageData:printPageRenderReportPageData cachedResults:cachedResults];
        } else {
            NSArray *containerDetails = obj;
            RptqDocumentSection *detailSection = [[self document] hasDetailSection];
            for (NSDictionary *resultDictionary in containerDetails) {
                
                [self printPageBreakWithNextItemHeight: *printableSpaceUsedPageHeight + [[detailSection height] floatValue]
                          printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                                printableSpaceRequired: printableSpaceRequired
                                     numberOfPagesUsed: numberOfPagesUsed
                                           groupedRows: groupedRows
                         printPageRenderReportPageData: printPageRenderReportPageData
                                         cachedResults: cachedResults];

                [*printPageRenderReportPageData addDetailWithValueDictionary:resultDictionary];

                *printableSpaceRequired += [[detailSection height] floatValue];
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
        }
        
        //Group footer section
        for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
            if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                
                [self printPageBreakWithNextItemHeight: *printableSpaceUsedPageHeight + [[documentSection height] floatValue]
                          printableSpaceUsedPageHeight: printableSpaceUsedPageHeight
                                printableSpaceRequired: printableSpaceRequired
                                     numberOfPagesUsed: numberOfPagesUsed
                                           groupedRows: groupedRows
                         printPageRenderReportPageData: printPageRenderReportPageData cachedResults:cachedResults];
                
                *printableSpaceRequired += [[documentSection height] floatValue];
                *printableSpaceUsedPageHeight += [[documentSection height] floatValue];
                NSUInteger groupNumber = [[queryGroup weight] integerValue];
                NSSortDescriptor *sortDescriptor = [sortDescriptorsGroup objectAtIndex:groupNumber];
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
            [displayText release];
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
                  printableSpaceRequired:(CGFloat *)printableSpaceRequired
                       numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed
                             groupedRows:(NSDictionary *)groupedRows
printPageRenderReportPageData:(MTPrintPageRenderReportPageData **)printPageRenderReportPageData cachedResults:(NSMutableArray **)cachedResults {
    CGRect pageRect;
    if (CGRectIsEmpty([self printableRect])) {
        pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, CGFloatPointsForInches(8.5000f), CGFloatPointsForInches(11.0000f));
    } else {
        pageRect = [self paperRect];
    }
    
    if (*printableSpaceUsedPageHeight + nextItemHeight > pageRect.size.height) {
        NSLog(@"Page Footer");
        *printableSpaceRequired += [[[[self document] hasReportFooterSection] height] floatValue];
        *printableSpaceUsedPageHeight += [[[[self document] hasReportFooterSection] height] floatValue];
        [*printPageRenderReportPageData addPageFooterWithValueDictionary:groupedRows];
        
        MTPrintPageRenderReportPageData *pageData = [*printPageRenderReportPageData copy];
        [*cachedResults addObject:pageData];
        [pageData release];
        
        [*printPageRenderReportPageData release];
        *printPageRenderReportPageData = nil;
        *printPageRenderReportPageData  = [[MTPrintPageRenderReportPageData alloc] init];
        
        *numberOfPagesUsed = *numberOfPagesUsed + 1;
        *printableSpaceUsedPageHeight = 0.0000f;
        NSLog(@"Page Header");
        *printableSpaceRequired += [[[[self document] hasPageHeaderSection] height] floatValue];
        *printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];
        [*printPageRenderReportPageData addPageHeaderWithValueDictionary:groupedRows];
    }
    
}

@end