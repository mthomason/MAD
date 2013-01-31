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

- (NSInteger)numberOfPages {
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
    
    SectionEnumerator *sectionEnumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[[self document] managedObjectContext]];
    for (RptqDocumentSection *reportSection in sectionEnumerator) { //Calculate the height of one page.
        
    }
    
    
    NSMutableDictionary *displayOutline = [[NSMutableDictionary alloc] initWithCapacity:numberOfPages];
    [self setDisplayOutline:displayOutline];
    [displayOutline release];

    
    return numberOfPages;
}

- (void)prepareForDrawingPages:(NSRange)range {
    
}

@end