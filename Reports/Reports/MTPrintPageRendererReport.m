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
@property (nonatomic, retain) NSMutableDictionary *displayOutline;

@property (nonatomic, assign) NSUInteger cachedNumberOfPages;
@property (nonatomic, copy) NSArray *cachedResults;

@end

@implementation MTPrintPageRendererReport

- (oneway void)release {
    [_cachedResults release];
    [_displayOutline release];
    [super release];
}

- (id)initWithDocument:(RptqDocument *)document {
    self = [super init];
    if (self) {
        [self setDocument:document];
        
        NSMutableDictionary *displayOutline = [[NSMutableDictionary alloc] init];
        [self setDisplayOutline:displayOutline];
        [displayOutline release];
        
        NSArray *cachedResults = [[NSArray alloc] init];
        [self setCachedResults:cachedResults];
        [cachedResults release];
    }
    return self;
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    NSLog(@"Cached results: %@", [[self cachedResults] objectAtIndex:index]);
    //[self drawHeaderForPageAtIndex:index inRect:pageRect];
    //[self drawFooterForPageAtIndex:index inRect:pageRect];
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

    /*
    NSUInteger numberOfPages = 0;
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    NSSet *queryGroups = [query hasQueryGroups];
    RptqQueryCache *queryCache = [query hasQueryCache];
    RptqQueryResultFields *anyResultField = [[queryCache hasQueryResultFields] anyObject];
    
    
    NSUInteger queryResultsDetailCount = [[anyResultField hasValues] count];

    
    //Setup dictionary by result row for group sorting
    NSMutableDictionary *resultsByRow = [[NSMutableDictionary alloc] init];
    for (RptqQueryResult *queryResult in [queryCache hasQueryResults]) {
        NSMutableDictionary *resultDictionary = [[resultsByRow objectForKey:[queryResult rowid]] retain];
        if ([resultDictionary count] == 0) {
            resultDictionary = [[NSMutableDictionary alloc] init];
        }
        [resultDictionary setObject:[queryResult value] forKey:[queryResult fieldname]];

        [resultsByRow setObject:resultDictionary forKey:[queryResult rowid]];
        
        [resultDictionary release];
    }
    
    NSLog(@"resultsByRow Dictionary: %@", resultsByRow);
    
    NSSet *resultsByRowSet = [NSSet setWithArray:[resultsByRow allValues]];

    NSLog(@"resultsByRow Set: %@", resultsByRowSet);

    NSMutableArray *sortDescriptorsGroup = [[NSMutableArray alloc] initWithCapacity:[[query hasQueryGroups] count]];
    for (RptqQueryGroup *queryGroup in [query hasQueryGroups]) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:[queryGroup fieldNameNice] ascending:([[queryGroup sort] integerValue] == MNSSortOrderAccending)];
        [sortDescriptorsGroup addObject:sortDescriptor];
    }
    NSArray *sortedResultsByRow = [resultsByRowSet sortedArrayUsingDescriptors:sortDescriptorsGroup];
    
    NSLog(@"resultsByRow Sorted by groups (%@): %@", sortDescriptorsGroup, sortedResultsByRow);
    
    [sortDescriptorsGroup release];
    [resultsByRow release];
    
    CGFloat printableSpaceRequired = 0.0000f;
    
    printableSpaceRequired += [[[[self document] hasReportHeaderSection] height] floatValue];

    printableSpaceRequired += [[[[self document] hasPageHeaderSection] height] floatValue];

    //Report Document Groups
    NSUInteger groupCounter = 0;
    NSSortDescriptor *sortDescriptorWeight = [NSSortDescriptor sortDescriptorWithKey:@"weight" ascending:YES];
    NSArray *groupSorted = [[[query hasQueryGroups] allObjects] sortedArrayUsingDescriptors: @[sortDescriptorWeight]];
    for (RptqQueryGroup *queryGroup in groupSorted) {

        //Group header section
        for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
            if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                printableSpaceRequired += [[documentSection height] floatValue];
            }
            break;
        }
        
        //Group detail section
        RptqDocumentSection *detailSection = [[self document] hasDetailSection];
        for (NSDictionary *resultDictionary in sortedResultsByRow) {
            printableSpaceRequired += [[detailSection height] floatValue];
        }
        
        //Group footer section
        for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
            if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                printableSpaceRequired += [[documentSection height] floatValue];
            }
            break;
        }
        
        groupCounter++;
    }
    
    printableSpaceRequired += [[[[self document] hasPageFooterSection] height] floatValue];
    
    printableSpaceRequired += [[[[self document] hasReportFooterSection] height] floatValue];

    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self document] managedObjectContext]];
    for (RptqDocumentSection *reportSection in sectionEnumerator) {
        
        switch ([[reportSection type] integerValue]) {
            case MNSDocumentSectionTypeReportHeader:
                break;
            case MNSDocumentSectionTypeReportFooter:
                break;
            case MNSDocumentSectionTypePageHeader:
                break;
            case MNSDocumentSectionTypePageFooter:
                break;
            case MNSDocumentSectionTypeBody:
                break;
            case MNSDocumentSectionTypeGroupHeader:
                break;
            case MNSDocumentSectionTypeGroupFooter:
                break;
            default:
                break;
        }
        
    }
     */
    
    /*
    for (RptqQueryResultFields *queryResultFields in [queryCache hasQueryResultFields]) {
        NSSet *values = [queryResultFields hasValues];
        for (RptqQueryResultValues *queryResultValue in values) {
            [resultsByRow setObject:[queryResultValue value] forKey:[queryResultValue rowId]];
            
        }
        
    }
    
    
    NSSortDescriptor *groupsSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sort" ascending:YES];
    NSArray *sortedQueryGroups = [queryGroups sortedArrayUsingDescriptors:@[groupsSortDescriptor]];
    

    
    NSMutableDictionary *queryResultsGrouped = [[NSMutableDictionary alloc] initWithCapacity:[sortedQueryGroups count]];
    for (RptqQueryGroup *queryGroup in sortedQueryGroups) {
        RptqField *field = [queryGroup hasField];
        
        for (RptqQueryResultFields *queryResultFields in [queryCache hasQueryResultFields]) {
            if ([[queryResultFields fieldname] isEqualToString:[field name]]) {

                NSSet *values = [queryResultFields hasValues];
                
                NSSortDescriptor *groupByValueSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:YES];
                NSArray *sortedQueryGroups = [queryGroups sortedArrayUsingDescriptors:@[groupByValueSortDescriptor]];

                id lastValue = nil;
                
                NSMutableArray *resultsArray = [[NSMutableArray alloc] init];
                for (RptqQueryResultValues *queryResultValue in sortedQueryGroups) {
                    if (![lastValue isEqualTo:[queryResultValue value]]) {
                        
                        //[groupedResults setObject:[queryResultValue value] forKey:[queryResultValue rowId]];
                        
                        NSArray *result = [[NSArray alloc] initWithArray:resultsArray copyItems:YES];
                        [queryResultsGrouped setObject:result forKey:lastValue];
                        [result release];
                        [resultsArray removeAllObjects];
                    }
                    [resultsArray addObject:[queryResultValue rowId]];
                    lastValue = [queryResultValue value];
                }

                NSArray *result = [[NSArray alloc] initWithArray:resultsArray copyItems:YES];
                [queryResultsGrouped setObject:result forKey:lastValue];
                [result release];
                [resultsArray release];
                
            }
        }
        [queryResultsGrouped release];
        
        NSMutableArray *results = [[NSMutableArray alloc] init];
        
        
        [queryResultsGrouped setObject:nil forKey:[field identifier]];
     
    }

     */
    /*
    RptqDocumentSection *reportHeaderSection = [[self document] hasReportHeaderSection];
    RptqDocumentSection *pageHeaderSection = [[self document] hasReportHeaderSection];
    RptqDocumentSection *pageFooterSection = [[self document] hasReportFooterSection];
    RptqDocumentSection *reportFooterSection = [[self document] hasReportFooterSection];
    
    NSUInteger pageCounter = 0;
    
    for (NSUInteger detailCounter = 0; detailCounter < queryResultsDetailCount; detailCounter++) {
        
        BOOL lastPage = NO;
        
        CGFloat reportHeaderHeight = (pageCounter == 0) ? [[reportHeaderSection height] floatValue] : CGSizeZero.height;
        
        CGFloat heightForPageHeader = reportHeaderHeight + [[pageHeaderSection height] floatValue];
        CGFloat heightForPageFooter = [[pageFooterSection height] floatValue];
        
        
        if (lastPage) {
            heightForPageFooter += [[reportFooterSection height] floatValue];
        }


    }
    

    
    
    NSMutableDictionary *displayOutline = [[NSMutableDictionary alloc] initWithCapacity:numberOfPages];
    [self setDisplayOutline:displayOutline];
    [displayOutline release];

    
    return numberOfPages;
     */
    return [self cachedNumberOfPages];
}

#pragma mark - Object methods


- (void)cachePrintPageRenderData {
    
    NSMutableArray *cachedResults = [[NSMutableArray alloc] init];
    
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
    printPageRenderReportPageData:&printPageRenderReportPageData cachedResults:&cachedResults];
    
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
    
    [self setCachedNumberOfPages: numberOfPagesUsed];
    [self setCachedResults:cachedResults];
    [cachedResults release];

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
        returnValue = resultsDictionary;
    }
    [resultsForGroup release];
    [resultsDictionary autorelease];
    return returnValue;
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
        id obj = [groupedRows objectForKey:key];
        
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
        [*printPageRenderReportPageData addGroupHeaderWithValueDictionary:obj];

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
                         printPageRenderReportPageData: printPageRenderReportPageData cachedResults:cachedResults];

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
        [*printPageRenderReportPageData addGroupFooterWithValueDictionary:obj];
        
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
        
        [*cachedResults addObject:*printPageRenderReportPageData];
        
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