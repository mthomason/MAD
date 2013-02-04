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

@end

@implementation MTPrintPageRendererReport

- (oneway void)release {
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
    }
    return self;
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    [super drawPageAtIndex:index inRect:pageRect];
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

- (void)drawPrintFormatter:(UIPrintFormatter *)printFormatter forPageAtIndex:(NSInteger)index {
    [super drawPrintFormatter:printFormatter forPageAtIndex:index];
}

- (void)testPrint {

    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    NSSet *queryGroups = [query hasQueryGroups];
    RptqQueryCache *queryCache = [query hasQueryCache];
    RptqQueryResultFields *anyResultField = [[queryCache hasQueryResultFields] anyObject];
    
    
    NSUInteger queryResultsDetailCount = [[anyResultField hasValues] count];
    
    
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
    
    //NSLog(@"resultsByRow Dictionary: %@", resultsByRow);
    
    NSSet *resultsByRowSet = [NSSet setWithArray:[resultsByRow allValues]];
    
    //NSLog(@"resultsByRow Set: %@", resultsByRowSet);
    
    NSMutableArray *sortDescriptorsGroup = [[NSMutableArray alloc] init];
    NSSet *hasQueryGroups = [[query hasQueryGroups] retain];
    for (RptqQueryGroup *queryGroup in hasQueryGroups) {
        NSString *fieldNameNice = [queryGroup fieldNameNice];
        BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: fieldNameNice
                                                                       ascending: sortAscending];
        [sortDescriptorsGroup addObject:sortDescriptor];
        [sortDescriptor release];
    }
    NSArray *sortedResultsByRow = [resultsByRowSet sortedArrayUsingDescriptors:sortDescriptorsGroup];
    
    NSLog(@"resultsByRow Sorted by groups (%@): %@", sortDescriptorsGroup, sortedResultsByRow);
        
    CGFloat printableSpaceRequired = 0.0000f;
    CGFloat printableSpaceUsedPageHeight = 0.0000f;
    NSUInteger numberOfPagesUsed = 0;
    
    printableSpaceRequired += [[[[self document] hasPageHeaderSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];
    NSLog(@"Page Header One");

    printableSpaceRequired += [[[[self document] hasReportHeaderSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasReportHeaderSection] height] floatValue];
    NSLog(@"Report Header");
    
    [self printGroupLevel:[query firstQueryGroup] withSortedResults:sortedResultsByRow
   printableSpaceRequired:&printableSpaceRequired printableSpaceUsedPageHeight:&printableSpaceUsedPageHeight
        numberOfPagesUsed:&numberOfPagesUsed];
    
    printableSpaceRequired += [[[[self document] hasReportFooterSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasReportFooterSection] height] floatValue];
    NSLog(@"Report Footer Last");

    printableSpaceRequired += [[[[self document] hasPageFooterSection] height] floatValue];
    printableSpaceUsedPageHeight += [[[[self document] hasPageFooterSection] height] floatValue];
    NSLog(@"Page Footer Last");
    
    [sortDescriptorsGroup release];
    [hasQueryGroups release];
    [resultsByRow release];

    
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup withSortedResults:(NSArray *)sortedResultsByRow
 printableSpaceRequired:(CGFloat *)printableSpaceRequired printableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight
      numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed {
    
    [self printGroupHeader:queryGroup withPrintableSpaceUsedPageHeight:printableSpaceUsedPageHeight andPrintableSpaceRequired:printableSpaceRequired numberOfPagesUsed:numberOfPagesUsed];
    
    RptqQueryGroup *nextGroup = [queryGroup next];
    if (nextGroup != nil) {
        [self printGroupLevel:nextGroup withSortedResults:sortedResultsByRow printableSpaceRequired:&*printableSpaceRequired printableSpaceUsedPageHeight:&*printableSpaceUsedPageHeight numberOfPagesUsed:&*numberOfPagesUsed];
   }
    
    
    //Group detail section
    RptqDocumentSection *detailSection = [[self document] hasDetailSection];
    for (NSDictionary *resultDictionary in sortedResultsByRow) {

        [self printPageBreakWithNextItemHeight: *printableSpaceUsedPageHeight + [[detailSection height] floatValue] PrintableSpaceUsedPageHeight:&*printableSpaceUsedPageHeight andPrintableSpaceRequired:&*printableSpaceRequired numberOfPagesUsed:&*numberOfPagesUsed];

        *printableSpaceRequired += [[detailSection height] floatValue];
        *printableSpaceUsedPageHeight += [[detailSection height] floatValue];
        NSLog(@"Detail");
    }
    
    //Group footer section
    [self printGroupFooter:queryGroup withPrintableSpaceUsedPageHeight:printableSpaceUsedPageHeight andPrintableSpaceRequired:printableSpaceRequired numberOfPagesUsed:numberOfPagesUsed];
    
}

- (void)printPageBreakWithNextItemHeight:(CGFloat)nextItemHeight PrintableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight andPrintableSpaceRequired:(CGFloat *)printableSpaceRequired numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed  {
    CGRect pageRect;
    if (CGRectIsEmpty([self printableRect])) {
        pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, CGFloatPointsForInches(8.5000f), CGFloatPointsForInches(11.0000f));
    } else {
        pageRect = [self paperRect];
    }
    
    if (*printableSpaceUsedPageHeight + nextItemHeight > pageRect.size.height) {
        [self printPageFooterWithPrintableSpaceUsedPageHeight:printableSpaceUsedPageHeight andPrintableSpaceRequired:printableSpaceRequired numberOfPagesUsed:numberOfPagesUsed];
        *numberOfPagesUsed = *numberOfPagesUsed + 1;
        *printableSpaceUsedPageHeight = 0.0000f;
        [self printPageHeaderWithPrintableSpaceUsedPageHeight:printableSpaceUsedPageHeight andPrintableSpaceRequired:printableSpaceRequired numberOfPagesUsed:numberOfPagesUsed];
    }

}

- (void)printPageHeaderWithPrintableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight andPrintableSpaceRequired:(CGFloat *)printableSpaceRequired numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed {
    NSLog(@"Page Header");
    *printableSpaceRequired += [[[[self document] hasPageHeaderSection] height] floatValue];
    *printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];
}

- (void)printPageFooterWithPrintableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight andPrintableSpaceRequired:(CGFloat *)printableSpaceRequired numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed {
    NSLog(@"Page Footer");
    *printableSpaceRequired += [[[[self document] hasReportFooterSection] height] floatValue];
    *printableSpaceUsedPageHeight += [[[[self document] hasReportFooterSection] height] floatValue];
}

- (void)printGroupHeader:(RptqQueryGroup *)queryGroup withPrintableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight andPrintableSpaceRequired:(CGFloat *)printableSpaceRequired numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed {
    NSLog(@"Page Header");
    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
        if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
            
            [self printPageBreakWithNextItemHeight: *printableSpaceUsedPageHeight + [[documentSection height] floatValue] PrintableSpaceUsedPageHeight:&*printableSpaceUsedPageHeight andPrintableSpaceRequired:&*printableSpaceRequired numberOfPagesUsed:&*numberOfPagesUsed];
            
            *printableSpaceRequired += [[documentSection height] floatValue];
            *printableSpaceUsedPageHeight += [[documentSection height] floatValue];
            NSLog(@"Group Header %d", [[queryGroup weight] integerValue]);
            break;
        }
    }
}

- (void)printGroupFooter:(RptqQueryGroup *)queryGroup withPrintableSpaceUsedPageHeight:(CGFloat *)printableSpaceUsedPageHeight andPrintableSpaceRequired:(CGFloat *)printableSpaceRequired numberOfPagesUsed:(NSUInteger *)numberOfPagesUsed {
    NSLog(@"Page Header");
    for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
        if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
            
            [self printPageBreakWithNextItemHeight: *printableSpaceUsedPageHeight + [[documentSection height] floatValue] PrintableSpaceUsedPageHeight:&*printableSpaceUsedPageHeight andPrintableSpaceRequired:&*printableSpaceRequired numberOfPagesUsed:&*numberOfPagesUsed];
            
            *printableSpaceRequired += [[documentSection height] floatValue];
            *printableSpaceUsedPageHeight += [[documentSection height] floatValue];
            NSLog(@"Group Footer %d", [[queryGroup weight] integerValue]);
            break;
        }
    }
}

- (NSInteger)numberOfPages {
    [self testPrint];
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
    return 0;
}

- (void)prepareForDrawingPages:(NSRange)range {
    
}

@end