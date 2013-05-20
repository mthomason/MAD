//
//  MTPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerPrintPageRenderer.h"

@interface MTReportViewerPrintPageRenderer ()

@property (nonatomic, assign) CGSize printableSize;

@property (nonatomic, assign) NSUInteger cachedNumberOfPages;

@property (nonatomic, assign) RptqDocument *document;
@property (nonatomic, retain) NSMutableArray *cachedResults;
@property (nonatomic, retain) NSMutableArray *sortedSortDescriptorsGroup;
@property (nonatomic, retain) NSMutableDictionary *resultsByRow;


@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;

@end

@implementation MTReportViewerPrintPageRenderer

- (oneway void)release {
    [_resultsByRow release];
    [_sortedSortDescriptorsGroup release];
    [_cachedResults release];
}

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
    MTReportViewerPrintPageRenderer *copy = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:[self document]];
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
        
    }
    return self;
}

#pragma mark - UIPrintPageRenderer Overrides

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    
    CGFloat originY = pageRect.origin.y;
    CGFloat originX = pageRect.origin.x;
    CGFloat sizeWidth = pageRect.size.width;

    if (index < [[self cachedResults] count]) {
        MTReportViewerPrintPageRenderPageData *data = [[[self cachedResults] objectAtIndex:index] retain];
        NSArray *pageSectionsToPrint = [[NSArray alloc] initWithArray:[data enumeratePageSections]];
        
        CGRect sectionRect = CGRectZero;
        
        for (NSDictionary *pageSection in pageSectionsToPrint) {
            
            NSString *pageSectionId = [[NSString alloc] initWithString:[pageSection objectForKey: MTReportSectionType]];
            id reportSectionValues = nil;

            //NSLog(@"%@ (%@): %@", pageSectionId, data, NSStringFromCGRect(sectionRect));
            
            NSNumber *groupLevel = nil;
            RptqQuery *query = nil;
            RptqDocumentSection *documentSection = nil;
            CGFloat sizeHeight = CGSizeZero.height;
            
            if ([MTPageDetail isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasDetailSection];
                sizeHeight = [[documentSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor whiteColor] set];
                
            } else if ([MTPageHeader isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageHeaderSection];
                sizeHeight = [[documentSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor yellowColor] set];
                
            } else if ([MTPageFooter isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageFooterSection];
                sizeHeight = [[documentSection height] floatValue];
//                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                sectionRect = CGRectMake(originX, pageRect.origin.y + pageRect.size.height - sizeHeight, sizeWidth, sizeHeight);
                
                [[UIColor yellowColor] set];
                
            } else if ([MTReportHeader isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasReportHeaderSection];
                sizeHeight = [[documentSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor greenColor] set];
                
            } else if ([MTReportFooter isEqualToString:pageSectionId]) {
                
                RptqDocumentSection *reportFooterSection = [[self document] hasReportFooterSection];
                CGFloat sizeHeightReportFooter = [[reportFooterSection height] floatValue];
                RptqDocumentSection *pageFooterSection = [[self document] hasPageFooterSection];
                CGFloat sizeHeightPageFooter = [[pageFooterSection height] floatValue];
                sectionRect = CGRectMake(originX, pageRect.origin.y + pageRect.size.height - sizeHeightReportFooter - sizeHeightPageFooter, sizeWidth, sizeHeightReportFooter);
                
                [[UIColor greenColor] set];
                
            } else if ([MTReportGroupHeader isEqualToString:pageSectionId]) {
                
                groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                documentSection = [RptqDocumentSection getDocumentGroupHeaderAtLevel:[groupLevel integerValue] forQuery:query];
                
                sizeHeight = [[documentSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor lightGrayColor] set];
                
            } else if ([MTReportGroupFooter isEqualToString:pageSectionId]) {
                
                groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                documentSection = [RptqDocumentSection getDocumentGroupFooterAtLevel:[groupLevel integerValue] forQuery:query];
                sizeHeight = [[documentSection height] floatValue];
                sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [[UIColor lightTextColor] set];
                
            }
            
            CGFloat sectionHeight = CGSizeZero.height;
            
            for (RptqDocumentSectionRows *row in [documentSection hasRows]) {

                CGFloat rowHeight = CGSizeZero.height;
                CGFloat objectHeight;
                
                for (RptqDocumentObject *object in [row hasObjects]) {
                    objectHeight = [object viewSize].height;
                    if (objectHeight > rowHeight) {
                        rowHeight = objectHeight;
                    }
                }
                
                if (rowHeight > sectionHeight) {
                    sectionHeight = rowHeight;
                }
                
            }
            
            [[UIBezierPath bezierPathWithRect:sectionRect] fill];
            
            id obj = [pageSection objectForKey:MTReportSectionValues];

            if ([obj isKindOfClass:[NSDictionary class]]) {
            
                reportSectionValues = [[NSDictionary alloc] initWithDictionary:obj];
            
            } else if ([obj isKindOfClass:[NSArray class]]) {
            
                reportSectionValues = [[NSArray alloc] initWithArray:obj];
            
            }

            [self printDocumentElementsForSection:documentSection atHeight:originY withResults:reportSectionValues];
            
            originY += sizeHeight;
            
            [pageSectionId release];
            [reportSectionValues release];
        }
        [pageSectionsToPrint release];
        [data release];
    }
}

- (NSInteger)numberOfPages {
    return [self cachedNumberOfPages];
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


#pragma mark - Object methods

- (void)printDocumentElementsForSection:(RptqDocumentSection *)section atHeight:(CGFloat)originY withResults:(id)results {
    
    switch ([[section type] integerValue]) {
        case MNSDocumentSectionTypeBody: {
            
            for (RptqDocumentSectionRows *row in [section hasRows]) {
                for (RptqDocumentObject *item in [row hasObjects]) {
                    
                    NSAttributedString *attributedString = [self attributedStringFor:item
                                                                withResultDictionary:results];
                    CGFloat originPointX        = [[item dropPointX] floatValue];
                    CGFloat originPointY        = [[item dropPointY] floatValue] + originY;
                    CGFloat sizeWidth           = [[item sizewidth] floatValue];
                    CGFloat sizeHeight          = [[item sizeheight] floatValue];
                    CGRect elementCanvasRect    = CGRectMake(originPointX, originPointY, sizeWidth, sizeHeight);
                    
                    [attributedString drawInRect:elementCanvasRect];
                    
                }
            }
            break;
        }
            
        case MNSDocumentSectionTypeReportHeader: {
            break;
        }
        case MNSDocumentSectionTypeReportFooter: {
            break;
        }
        case MNSDocumentSectionTypePageHeader: {
            break;
        }
        case MNSDocumentSectionTypePageFooter: {
            break;
        }
        case MNSDocumentSectionTypeGroupHeader: {
            break;
        }
        case MNSDocumentSectionTypeGroupFooter: {
            break;
        }
        default: {
            break;
        }
    }
    /*
     if ([results isKindOfClass:[NSDictionary class]]) {
     
     
     } else if ([results isKindOfClass:[NSArray class]]) {
     
     // FIXME: Print more than  the first row.
     
     for (RptqDocumentSectionRows *row in [section hasRows]) {
     
     CGFloat originX = CGPointZero.x;
     
     for (RptqDocumentObject *item in [row hasObjects]) {
     CGFloat sizeWidth = [[item sizewidth] floatValue];
     originX += sizeWidth;
     }
     }
     }*/
}

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize {
    if (CGSizeEqualToSize([self printableSize], printableSize) == NO) {
        [self setPrintableSize:printableSize];

        RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        RptqQueryCache *queryCache = [query hasQueryCache];
        
        [[self cachedResults] removeAllObjects];
        [[self resultsByRow] removeAllObjects];
        [[self sortedSortDescriptorsGroup] removeAllObjects];
        [self setCachedNumberOfPages:0];
        [self setPrintableSpaceUsedPageHeight:CGSizeZero.height];
        
        for (RptqQueryResultFields *queryResultField in [queryCache hasQueryResultFields]) {


            for (RptqQueryResultValues *queryResultValue in [queryResultField hasValues]) {
        
                id results = [[self resultsByRow] objectForKey:[queryResultValue rowId]];
                
                NSMutableDictionary *resultDictionary = nil;
                if (results == nil || resultDictionary == nil) {
                    if (results != nil) {
                        [resultDictionary release];
                        resultDictionary = nil;
                        resultDictionary = [[NSMutableDictionary alloc] initWithDictionary:results];
                    } else {
                        [resultDictionary release];
                        resultDictionary = nil;
                        resultDictionary = [[NSMutableDictionary alloc] init];
                    }
                } else {
                    [resultDictionary retain];
                }
                
                id queryResultCValue = [[queryResultValue cachedValue] retain];
                
                NSString *fieldName = [[NSString alloc] initWithString:[queryResultField fieldname]];
                
                [resultDictionary setObject:queryResultCValue forKey:fieldName];
                
                [[self resultsByRow] setObject: resultDictionary
                                        forKey: [queryResultValue rowId]];

                [fieldName release];
                [queryResultCValue release];
                
                [resultDictionary release];
                
            }
        }
        
        NSSet *resultsByRowSet = [[NSSet setWithArray:[[self resultsByRow] allValues]] retain];
        NSSet *hasQueryGroups = [query hasQueryGroups];
        
        NSSortDescriptor *sortd = [[NSSortDescriptor alloc] initWithKey:@"weight" ascending:YES];
        NSArray *sortedHasQueryGroups = [hasQueryGroups sortedArrayUsingDescriptors:@[sortd]];
        for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
            
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            NSString *fieldNameNice = [[NSString alloc] initWithString:[queryGroup fieldNameQuery]];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: fieldNameNice
                                                                           ascending: sortAscending];
            [[self sortedSortDescriptorsGroup] addObject:sortDescriptor];
            [fieldNameNice release];
            [sortDescriptor release];
        }
        NSArray *sortedResultsByRow = [resultsByRowSet sortedArrayUsingDescriptors:[self sortedSortDescriptorsGroup]];
        sortedResultsByRow = [sortedResultsByRow retain];
        
        id groupedRows = [[self groupedResults:sortedResultsByRow level:0 sortDescriptors:[self sortedSortDescriptorsGroup]] retain];
        
        self.printableSpaceUsedPageHeight = 0.0000f;
        [self setCachedNumberOfPages: 0];
        
        MTReportViewerPrintPageRenderPageData *printPageRenderReportPageData  = [[MTReportViewerPrintPageRenderPageData alloc] init];
        
        self.printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];
        //NSLog(@"Page Header One");
        [printPageRenderReportPageData addPageHeaderWithValueDictionary:groupedRows];
        
        self.printableSpaceUsedPageHeight += [[[[self document] hasReportHeaderSection] height] floatValue];
        //NSLog(@"Report Header");
        [printPageRenderReportPageData addReportHeaderWithValueDictionary:groupedRows];
        
        [self printGroupLevel:[query firstQueryGroup]
                  groupedRows:groupedRows
printPageRenderReportPageData:&printPageRenderReportPageData];

        
        
        CGFloat reportFooterHeight = [[[[self document] hasReportFooterSection] height] floatValue];

        [self printPageBreakWithNextItemHeight: reportFooterHeight
                                   groupedRows: groupedRows
                 printPageRenderReportPageData: &printPageRenderReportPageData];
        
        self.printableSpaceUsedPageHeight += reportFooterHeight;
        [printPageRenderReportPageData addReportFooterWithValueDictionary:groupedRows];
        
        CGFloat pageFooterHeight = [[[[self document] hasPageFooterSection] height] floatValue];
        
        [self printPageBreakWithNextItemHeight: pageFooterHeight
                                   groupedRows: groupedRows
                 printPageRenderReportPageData: &printPageRenderReportPageData];

        self.printableSpaceUsedPageHeight += pageFooterHeight;
        [printPageRenderReportPageData addPageFooterWithValueDictionary:groupedRows];
        
        MTReportViewerPrintPageRenderPageData *pageData = [printPageRenderReportPageData copy];
        [[self cachedResults] addObject:pageData];
        [pageData release];

        [self setCachedNumberOfPages:([self cachedNumberOfPages] + 1)];
        
        //[printPageRenderReportPageData addReportFooterWithValueDictionary:groupedRows];
        
        [groupedRows release];
        [sortedResultsByRow release];
        [resultsByRowSet release];
        [sortd release];
        
    }
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup
            groupedRows:(NSDictionary *)groupedRows
printPageRenderReportPageData:(MTReportViewerPrintPageRenderPageData **)printPageRenderReportPageData {
    
    BOOL detailPrinted = NO;
    NSUInteger groupedRowsLevel = 0;
    
    [self printGroupLevel: queryGroup
              groupedRows: groupedRows
         groupedRowsLevel: groupedRowsLevel
            detailPrinted: &detailPrinted
printPageRenderReportPageData:printPageRenderReportPageData];
    
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup
            groupedRows:(NSDictionary *)groupedRows
       groupedRowsLevel:(NSUInteger)groupedRowsLevel
          detailPrinted:(BOOL *)detailPrinted
printPageRenderReportPageData:(MTReportViewerPrintPageRenderPageData **)printPageRenderReportPageData {

    
        //NSLog(@"Group level %d %@.", groupedRowsLevel, [[self sortedSortDescriptorsGroup] objectAtIndex:groupedRowsLevel]);
        
        if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
            
            SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
            
            NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys]];
            NSSortDescriptor *desc = [[[self sortedSortDescriptorsGroup] objectAtIndex:groupedRowsLevel] retain];
            NSArray *allKeysSorted = [[allKeys sortedArrayUsingSelector:sortSelector] retain];
            NSEnumerator *loopEnumerator;
            if ([desc ascending] == NO) {
                loopEnumerator = [[allKeysSorted reverseObjectEnumerator] retain];
            } else {
                loopEnumerator = [[allKeysSorted objectEnumerator] retain];
            }
            [desc release];
            for (id key in loopEnumerator) {
                id obj = [[groupedRows objectForKey:key] retain];
                
                //Group header section
                for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                    if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                        
                        [self printPageBreakWithNextItemHeight: [[documentSection height] floatValue]
                                                   groupedRows: groupedRows
                                 printPageRenderReportPageData: printPageRenderReportPageData];
                        
                        NSMutableString *mutableStringToPrint = [[NSMutableString alloc] init];
                        NSUInteger documentObjectCounter = 0;
                        // FIXME: Print more than  the first row.

                        for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                            for (RptqDocumentObject *item in [row hasObjects]) {
                                if (documentObjectCounter > 0) {
                                    [mutableStringToPrint appendString:@", "];
                                }
                                NSString *stringToPrint = [self printDocumentObject:item
                                                               withResultDictionary:nil/*resultDictionary*/];
                                [mutableStringToPrint appendString:stringToPrint];
                            }
                        }
                        
                        [mutableStringToPrint release];
                        self.printableSpaceUsedPageHeight += [[documentSection height] floatValue];
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
                    [self printGroupLevel: nextGroup
                              groupedRows: obj
                         groupedRowsLevel: groupedRowsLevel
                            detailPrinted: detailPrinted printPageRenderReportPageData:printPageRenderReportPageData];
                } else {
                    [self printDetailLevelWithDetails:obj
                                          groupedRows:groupedRows
                        printPageRenderReportPageData:printPageRenderReportPageData];
                }
                
                //Group footer section
                for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                    if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                        
                        [self printPageBreakWithNextItemHeight: [[documentSection height] floatValue]
                                                   groupedRows: groupedRows
                                 printPageRenderReportPageData: printPageRenderReportPageData];
                        
                        self.printableSpaceUsedPageHeight += [[documentSection height] floatValue];
                        //NSUInteger groupNumber = [[queryGroup weight] integerValue];
                        //NSSortDescriptor *sortDescriptor = [[self sortedSortDescriptorsGroup] objectAtIndex:groupNumber];
                        //NSString *sortOrderDescription = [sortDescriptor ascending] ?
                        //NSLocalizedString(@"Ascending", @"Ascending") : NSLocalizedString(@"Decending", @"Decending");
                        //NSLog(@"Group Footer %d (%@, %@)", groupNumber, [sortDescriptor key], sortOrderDescription);
                        break;
                    }
                }
                [*printPageRenderReportPageData addGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                
                [obj release];
            }
            [loopEnumerator release];
            [allKeysSorted release];
            [allKeys release];

        } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...

            [self printDetailLevelWithDetails:(NSArray *)groupedRows
                                  groupedRows:groupedRows
                printPageRenderReportPageData:printPageRenderReportPageData];

        }
}

- (void)printDetailLevelWithDetails:(NSArray *)containerDetails
                        groupedRows:(NSDictionary *)groupedRows
      printPageRenderReportPageData:(MTReportViewerPrintPageRenderPageData **)printPageRenderReportPageData {
    RptqDocumentSection *detailSection = [[self document] hasDetailSection];
    for (NSDictionary *resultDictionary in containerDetails) {
        
        [self printPageBreakWithNextItemHeight: [[detailSection height] floatValue]
                                   groupedRows: groupedRows
                 printPageRenderReportPageData: printPageRenderReportPageData];
        
        [*printPageRenderReportPageData addDetailWithValueDictionary:resultDictionary];
        
        self.printableSpaceUsedPageHeight += [[detailSection height] floatValue];
        NSMutableString *mutableStringToPrint = [[NSMutableString alloc] init];
        NSUInteger documentObjectCounter = 0;
        // FIXME: Print more than  the first row.

        for (RptqDocumentSectionRows *row in [detailSection hasRows]) {
            for (RptqDocumentObject *item in [row hasObjects]) {
                if (documentObjectCounter > 0) {
                    [mutableStringToPrint appendString:@", "];
                }
                NSString *stringToPrint = [self printDocumentObject: item
                                               withResultDictionary: resultDictionary];
                if (stringToPrint == nil) {
                    [mutableStringToPrint appendString:@"<Null>"];
                } else {
                    [mutableStringToPrint appendString:stringToPrint];
                }
            }
        }

        //NSLog(@"Detail: (%@)", mutableStringToPrint);
        [mutableStringToPrint release];
        documentObjectCounter++;
    }
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

- (NSString *)printDocumentObject:(RptqDocumentObject *)documentObject withResultDictionary:(NSDictionary *)resultDictionary {

    NSString *result = nil;
    id value = nil;
    
    switch ([documentObject getType]) {
        
        case MTDocumentObjectTypeLabelStatic: {
            
            RptqDocumentObjectLabel *documentObjectLabel = [documentObject isLabel];
            value = [documentObjectLabel text];
            result = [documentObjectLabel text];
            
            break;
        }

        case MTDocumentObjectTypeLabelDynamic: {
            switch ([[[[documentObject inSectionRow] inSection] type] integerValue]) {

                case MNSDocumentSectionTypeBody: {
                    RptqDocumentObjectLabelDataField *documentObjectDataField = [documentObject isLabelDataField];
                    RptqQueryField *queryField = [documentObjectDataField referencesQueryField];
                    NSString * tableFieldKey = [queryField tableFieldKey];
                    value = [resultDictionary objectForKey: tableFieldKey];
                    MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
                    result = [MTDatabaseField formattedString:dataType
                                                     forValue:value];
                    break;

                } case MNSDocumentSectionTypeGroupHeader: {
                    break;

                } case MNSDocumentSectionTypeGroupFooter: {
                    break;

                } default: {

                    RptqDocumentObjectLabelDataField *documentObjectDataField = [documentObject isLabelDataField];
                    RptqQueryField *queryField = [documentObjectDataField referencesQueryField];
                    NSString *tableFieldKey = [queryField tableFieldKey];
                    value = [resultDictionary objectForKey: tableFieldKey];
                    break;
                    
                }
            }
    
            
        }
        case MTDocumentObjectTypeFormula: {
            break;
        }
        default: {
            break;
        }
    }
    /*
    if ([value isKindOfClass:[NSString class]]) {
        
        result = [[NSString alloc] initWithString:value];

    } else if ([value isKindOfClass:[NSNumber class]]) {
    
        result = [[NSString alloc] initWithFormat:@"%f", [value floatValue]];

    } else {

        result = [[NSString alloc] initWithString: @"<Unknown type>"];

    }
    
    if (value == nil) {
        
        result = [[NSString alloc] initWithString:@"<null>"];

    }*/
    return result;
}

- (NSAttributedString *)attributedStringFor:(RptqDocumentObject *)documentObject
                       withResultDictionary:(NSDictionary *)resultDictionary {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    
    NSString *displayText = [[self printDocumentObject:documentObject withResultDictionary:resultDictionary] retain];
    [[result mutableString] setString:displayText];
    [displayText release];
    
    NSRange wholeString = NSMakeRange(0, [[result mutableString] length]);
    UIFont *customFont = [UIFont systemFontOfSize:[[documentObject fontsize] floatValue]];
    NSDictionary *customAttributes = @{NSFontAttributeName : customFont};
    [result setAttributes:customAttributes range:wholeString];
    return [result autorelease];
}

- (void)printPageBreakWithNextItemHeight:(CGFloat)nextItemHeight
                             groupedRows:(NSDictionary *)groupedRows
printPageRenderReportPageData:(MTReportViewerPrintPageRenderPageData **)printPageRenderReportPageData {

    CGRect pageRect;
    CGFloat pageFooterSectionHeight = [[[[self document] hasPageFooterSection] height] floatValue];
    
    if (CGRectIsEmpty([self printableRect])) {
        pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    } else {
        pageRect = [self paperRect];
    }
    
    if (self.printableSpaceUsedPageHeight + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        self.printableSpaceUsedPageHeight += pageFooterSectionHeight;
        [*printPageRenderReportPageData addPageFooterWithValueDictionary:groupedRows];
        
        MTReportViewerPrintPageRenderPageData *pageData = [*printPageRenderReportPageData copy];
        [[self cachedResults] addObject:pageData];
        [pageData release];
        
        [*printPageRenderReportPageData release];
        *printPageRenderReportPageData = nil;
        *printPageRenderReportPageData  = [[MTReportViewerPrintPageRenderPageData alloc] init];
        
        [self setCachedNumberOfPages:[self cachedNumberOfPages] + 1];
        [self setPrintableSpaceUsedPageHeight: (CGPointZero.y + [[[[self document] hasPageHeaderSection] height] floatValue])];
        [*printPageRenderReportPageData addPageHeaderWithValueDictionary:groupedRows];
    }
    
}

@end