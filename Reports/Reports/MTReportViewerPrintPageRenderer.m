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

@property (nonatomic, assign) RptqDocument *document;

@property (nonatomic, retain) NSMutableArray *cachedSortedSortDescriptorsGroup;
@property (nonatomic, retain) NSMutableDictionary *cachedResultsForReport;
@property (nonatomic, assign) NSUInteger cachedNumberOfPages;

@property (nonatomic, copy) NSArray *cachedLayout;
@property (nonatomic, copy) NSDictionary *cachedDataByPage;
@property (nonatomic, copy) NSDictionary *cachedDataByGroup;
@property (nonatomic, copy) NSDictionary *cachedDataByReport;

@property (nonatomic, retain) NSMutableArray *temporaryLayout;
@property (nonatomic, retain) NSMutableArray *temporaryPageData;
@property (nonatomic, retain) NSMutableDictionary *temporaryDataByPage;
@property (nonatomic, retain) NSMutableDictionary *temporaryDataByGroup;
@property (nonatomic, retain) NSMutableDictionary *temporaryDataByReport;


@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;

@end

@implementation MTReportViewerPrintPageRenderer

- (oneway void)release {
    
    [_cachedLayout release];
    [_cachedDataByPage release];
    [_cachedDataByGroup release];
    [_cachedDataByReport release];

    [_temporaryLayout release];
    [_temporaryPageData release];
    [_temporaryDataByPage release];
    [_temporaryDataByGroup release];
    [_temporaryDataByReport release];

    [_cachedResultsForReport release];
    [_cachedSortedSortDescriptorsGroup release];
}

- (id)retain {
    self = [super retain];
    if (self) {
        [_cachedLayout retain];
        [_cachedDataByPage retain];
        [_cachedDataByGroup retain];
        [_cachedDataByReport retain];
        
        [_temporaryLayout retain];
        [_temporaryPageData retain];
        [_temporaryDataByPage retain];
        [_temporaryDataByGroup retain];
        [_temporaryDataByReport retain];

        [_cachedResultsForReport retain];
        [_cachedSortedSortDescriptorsGroup retain];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTReportViewerPrintPageRenderer *copy = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:[self document]];
    if (copy) {
        
        
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
        
        
        NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
        [self setCachedSortedSortDescriptorsGroup:sortedSortDescriptorsGroup];
        [sortedSortDescriptorsGroup release];
        
        NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] init];
        [self setCachedResultsForReport:resultsForRow];
        [resultsForRow release];

        NSMutableArray *a1 = [[NSMutableArray alloc] init];
        [self setTemporaryLayout:a1];
        [a1 release];
        NSMutableArray *a2 = [[NSMutableArray alloc] init];
        [self setTemporaryPageData:a2];
        [a2 release];
        NSMutableDictionary *d2 = [[NSMutableDictionary alloc] init];
        [self setTemporaryDataByReport:d2];
        [d2 release];
        NSMutableDictionary *d3 = [[NSMutableDictionary alloc] init];
        [self setTemporaryDataByPage:d3];
        [d3 release];
        NSMutableDictionary *d4 = [[NSMutableDictionary alloc] init];
        [self setTemporaryDataByGroup:d4];
        [d4 release];

        
    }
    return self;
}

#pragma mark - UIPrintPageRenderer Overrides

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    
    CGFloat originY = pageRect.origin.y;
    CGFloat originX = pageRect.origin.x;
    CGFloat sizeWidth = pageRect.size.width;

    if (index < [[self cachedLayout] count]) {

        NSArray *pageArray = [[[self cachedLayout] objectAtIndex:index] retain];
        NSArray *pageSectionsToPrint = [[NSArray alloc] initWithArray:pageArray];
        [pageArray release];
        
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
                
                [[UIColor whiteColor] set];
                
            } else if ([MTPageHeader isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageHeaderSection];
                sizeHeight = [[documentSection height] floatValue];
                
                [[UIColor yellowColor] set];
                
            } else if ([MTPageFooter isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageFooterSection];
                sizeHeight = [[documentSection height] floatValue];
                originY = pageRect.origin.y + pageRect.size.height - sizeHeight;

                [[UIColor yellowColor] set];
                
            } else if ([MTReportHeader isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasReportHeaderSection];
                sizeHeight = [[documentSection height] floatValue];

                [[UIColor greenColor] set];
                
            } else if ([MTReportFooter isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasReportFooterSection];
                CGFloat sizeHeightReportFooter = [[documentSection height] floatValue];
                RptqDocumentSection *pageFooterSection = [[self document] hasPageFooterSection];
                CGFloat sizeHeightPageFooter = [[pageFooterSection height] floatValue];
                originY = pageRect.origin.y + pageRect.size.height - sizeHeightReportFooter - sizeHeightPageFooter;
                sizeHeight = sizeHeightReportFooter;
                [[UIColor greenColor] set];
                
            } else if ([MTReportGroupHeader isEqualToString:pageSectionId]) {
                
                groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                documentSection = [RptqDocumentSection getDocumentGroupHeaderAtLevel:[groupLevel integerValue] forQuery:query];
                
                sizeHeight = [[documentSection height] floatValue];
                
                [[UIColor lightGrayColor] set];
                
            } else if ([MTReportGroupFooter isEqualToString:pageSectionId]) {
                
                groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                documentSection = [RptqDocumentSection getDocumentGroupFooterAtLevel:[groupLevel integerValue] forQuery:query];
                sizeHeight = [[documentSection height] floatValue];
                
                [[UIColor lightTextColor] set];
                
            }

            sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
            
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

            // Print document elements for section
            
            switch ([[documentSection type] integerValue]) {
                    
                case MNSDocumentSectionTypeBody: {
                    
                    for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                        for (RptqDocumentObject *item in [row hasObjects]) {
                            
                            NSAttributedString *attributedString = [[NSMutableAttributedString alloc]
                                                                    initWithString:[self printDocumentObject: item
                                                                                        withResultDictionary: reportSectionValues]
                                                                    attributes:[self attributesForDocumentObject:item]];
                            
                            CGFloat originPointX        = [[item dropPointX] floatValue];
                            CGFloat originPointY        = [[item dropPointY] floatValue] + originY;
                            CGFloat sizeWidth           = [[item sizewidth] floatValue];
                            CGFloat sizeHeight          = [[item sizeheight] floatValue];
                            CGRect elementCanvasRect    = CGRectMake(originPointX, originPointY, sizeWidth, sizeHeight);
                            
                            [attributedString drawInRect:elementCanvasRect];
                            
                            [attributedString release];
                        }
                    }
                    
                    break;
                }
                case MNSDocumentSectionTypePageHeader:
                case MNSDocumentSectionTypePageFooter:
                case MNSDocumentSectionTypeGroupHeader:
                case MNSDocumentSectionTypeGroupFooter:
                case MNSDocumentSectionTypeReportFooter:
                case MNSDocumentSectionTypeReportHeader: {
                    
                    // FIXME: This is the next area to program the fuck out of... Almost working, except the data is not in correct format for page grouping yet.
                    
                    /*
                     for (RptqDocumentSectionRows *row in [section hasRows]) {
                     for (RptqDocumentObject *item in [row hasObjects]) {
                     
                     NSAttributedString *attributedString = [[NSMutableAttributedString alloc]
                     initWithString:[self printDocumentObject: item
                     withResultArray: results]
                     attributes:[self attributesForDocumentObject: item]];
                     
                     CGFloat originPointX        = [[item dropPointX] floatValue];
                     CGFloat originPointY        = [[item dropPointY] floatValue] + originY;
                     CGFloat sizeWidth           = [[item sizewidth] floatValue];
                     CGFloat sizeHeight          = [[item sizeheight] floatValue];
                     CGRect elementCanvasRect    = CGRectMake(originPointX, originPointY, sizeWidth, sizeHeight);
                     
                     [attributedString drawInRect:elementCanvasRect];
                     
                     }
                     }
                     */
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
            

            // Increment the y-origin.
            
            originY += sizeHeight;
            
            [pageSectionId release];
            [reportSectionValues release];

        }
        [pageSectionsToPrint release];
        //[data release];
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


- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize {

    if (CGSizeEqualToSize([self printableSize], printableSize) == NO) {
        [self setPrintableSize:printableSize];

        RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        RptqQueryCache *queryCache = [query hasQueryCache];
        
        [[self temporaryLayout] removeAllObjects];
        [[self cachedResultsForReport] removeAllObjects];
        [[self cachedSortedSortDescriptorsGroup] removeAllObjects];
        [self setCachedNumberOfPages: 0];
        [self setPrintableSpaceUsedPageHeight:CGSizeZero.height];
        
        for (RptqQueryResultFields *queryResultField in [queryCache hasQueryResultFields]) {


            for (RptqQueryResultValues *queryResultValue in [queryResultField hasValues]) {
        
                id results = [[self cachedResultsForReport] objectForKey:[queryResultValue rowId]];
                
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
                
                [[self cachedResultsForReport] setObject: resultDictionary
                                                  forKey: [queryResultValue rowId]];

                [fieldName release];
                [queryResultCValue release];
                
                [resultDictionary release];
                
            }
        }
        
        NSSet *resultsByRowSet = [[NSSet setWithArray:[[self cachedResultsForReport] allValues]] retain];
        NSSet *hasQueryGroups = [query hasQueryGroups];
        
        
        NSString *sortKey = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: sortKey
                                                              ascending: YES];
        NSArray *sortedHasQueryGroups = [hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
            
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            NSString *fieldNameNice = [[NSString alloc] initWithString:[queryGroup fieldNameQuery]];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: fieldNameNice
                                                                           ascending: sortAscending];
            [[self cachedSortedSortDescriptorsGroup] addObject:sortDescriptor];
            [fieldNameNice release];
            [sortDescriptor release];
        }
        NSArray *sortedResultsByRow = [resultsByRowSet sortedArrayUsingDescriptors:[self cachedSortedSortDescriptorsGroup]];
        sortedResultsByRow = [sortedResultsByRow retain];
        
        id groupedRows = [[self groupedResults:sortedResultsByRow level:0 sortDescriptors:[self cachedSortedSortDescriptorsGroup]] retain];
        
        self.printableSpaceUsedPageHeight = 0.0000f;
        [self setCachedNumberOfPages: 0];
        
        //MTReportViewerPrintPageRenderPageData *printPageRenderReportPageData  = [[MTReportViewerPrintPageRenderPageData alloc] init];
        
        self.printableSpaceUsedPageHeight += [[[[self document] hasPageHeaderSection] height] floatValue];

        //[printPageRenderReportPageData addPageHeaderWithValueDictionary:groupedRows];
        [self addPageHeaderWithValueDictionary:groupedRows];
        
        self.printableSpaceUsedPageHeight += [[[[self document] hasReportHeaderSection] height] floatValue];

        [self addReportHeaderWithValueDictionary:groupedRows];
        //[printPageRenderReportPageData addReportHeaderWithValueDictionary:groupedRows];
        
        BOOL detailPrinted = NO;
        [self printGroupLevel:[query firstQueryGroup]
                  groupedRows:groupedRows
             groupedRowsLevel:0
                detailPrinted:&detailPrinted];
        
        
        CGFloat reportFooterHeight = [[[[self document] hasReportFooterSection] height] floatValue];

        [self printPageBreakWithNextItemHeight: reportFooterHeight
                                   groupedRows: groupedRows];
        
        self.printableSpaceUsedPageHeight += reportFooterHeight;

        [self addReportFooterWithValueDictionary:groupedRows];
        
        CGFloat pageFooterHeight = [[[[self document] hasPageFooterSection] height] floatValue];
        
        [self printPageBreakWithNextItemHeight: pageFooterHeight
                                   groupedRows: groupedRows];

        self.printableSpaceUsedPageHeight += pageFooterHeight;
        
        [self addPageFooterWithValueDictionary:groupedRows];
        
        [[self temporaryLayout] addObject:[[self temporaryPageData] copy]];
        
        [self setCachedNumberOfPages:([self cachedNumberOfPages] + 1)];
        
        [groupedRows release];
        [sortedResultsByRow release];
        [resultsByRowSet release];
        [sortDescriptor release];
      
        [self setCachedLayout:[[self temporaryLayout] copy]];
    }
}

- (void)printGroupLevel:(RptqQueryGroup *)queryGroup
            groupedRows:(NSDictionary *)groupedRows
       groupedRowsLevel:(NSUInteger)groupedRowsLevel
          detailPrinted:(BOOL *)detailPrinted {
    
        //NSLog(@"Group level %d %@.", groupedRowsLevel, [[self sortedSortDescriptorsGroup] objectAtIndex:groupedRowsLevel]);
        
        if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
            
            SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
            
            NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys]];
            NSSortDescriptor *desc = [[[self cachedSortedSortDescriptorsGroup] objectAtIndex:groupedRowsLevel] retain];
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
                                                   groupedRows: groupedRows];
                        
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
                        NSSortDescriptor *sortDescriptor = [[self cachedSortedSortDescriptorsGroup] objectAtIndex:groupNumber];
                        NSString *sortOrderDescription = [sortDescriptor ascending] ?
                        NSLocalizedString(@"Ascending", @"Ascending") : NSLocalizedString(@"Decending", @"Decending");
                        NSLog(@"Group Header %d (%@, %@)", groupNumber, [sortDescriptor key], sortOrderDescription);
                        break;
                    }
                }

                [self addGroupHeaderWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                RptqQueryGroup *nextGroup = [queryGroup next];
                
                
                if (nextGroup != nil) {
                    [self printGroupLevel: nextGroup
                              groupedRows: obj
                         groupedRowsLevel: groupedRowsLevel
                            detailPrinted: detailPrinted];
                } else {
                    [self printDetailLevelWithDetails:obj
                                          groupedRows:groupedRows];
                }
                
                //Group footer section
                for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                    if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                        
                        [self printPageBreakWithNextItemHeight: [[documentSection height] floatValue]
                                                   groupedRows: groupedRows];
                        
                        self.printableSpaceUsedPageHeight += [[documentSection height] floatValue];
                        //NSUInteger groupNumber = [[queryGroup weight] integerValue];
                        //NSSortDescriptor *sortDescriptor = [[self sortedSortDescriptorsGroup] objectAtIndex:groupNumber];
                        //NSString *sortOrderDescription = [sortDescriptor ascending] ?
                        //NSLocalizedString(@"Ascending", @"Ascending") : NSLocalizedString(@"Decending", @"Decending");
                        //NSLog(@"Group Footer %d (%@, %@)", groupNumber, [sortDescriptor key], sortOrderDescription);
                        break;
                    }
                }

                [self addGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                [obj release];
            }
            [loopEnumerator release];
            [allKeysSorted release];
            [allKeys release];

        } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...

            [self printDetailLevelWithDetails:(NSArray *)groupedRows
                                  groupedRows:groupedRows];
        }
}

- (void)printDetailLevelWithDetails:(NSArray *)containerDetails
                        groupedRows:(NSDictionary *)groupedRows {
    RptqDocumentSection *detailSection = [[self document] hasDetailSection];
    for (NSDictionary *resultDictionary in containerDetails) {
        
        [self printPageBreakWithNextItemHeight: [[detailSection height] floatValue]
                                   groupedRows: groupedRows];
        
        [self addDetailWithValueDictionary:resultDictionary];
        
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

            RptqDocumentObjectLabelDataField *documentObjectDataField = [documentObject isLabelDataField];
            RptqQueryField *queryField = [documentObjectDataField referencesQueryField];
            NSString * tableFieldKey = [queryField tableFieldKey];
            value = [resultDictionary objectForKey: tableFieldKey];
            MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
            result = [MTDatabaseField formattedString:dataType
                                             forValue:value];
            break;
            
        }
        case MTDocumentObjectTypeFormula: {
            result = @"";
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            /*
            RptqDocumentObjectAggregate *aggregateField = [documentObject isAggregate];
            RptqQueryField *queryField = [aggregateField aggregateField];
            NSString * tableFieldKey = [queryField tableFieldKey];
            [aggregateField aggregateFunction] set
            value = [resultDictionary objectForKey: tableFieldKey];
            MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
            result = [MTDatabaseField formattedString:dataType
                                             forValue:value];
             */

            result = @"";
            break;
        }
        case MTDocumentObjectTypeAggregateFunctionList: {
            result = @"";
            break;
        }
        case MTDocumentObjectTypeChart: {
            result = @"";
            break;
        }
        case MTDocumentObjectTypeGroupKey: {
            result = @"";
            break;
        }
        case MTDocumentObjectTypeImage: {
            result = @"";
            break;
        }
        default: {
            break;
        }
    }

    return result;
}

- (NSString *)printDocumentObject:(RptqDocumentObject *)documentObject withResultArray:(NSArray *)resultArray {
    
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
            
            RptqDocumentObjectLabelDataField *documentObjectDataField = [documentObject isLabelDataField];
            RptqQueryField *queryField = [documentObjectDataField referencesQueryField];
            NSString * tableFieldKey = [queryField tableFieldKey];
            NSDictionary *resultDictionary = [resultArray objectAtIndex:0];
            value = [resultDictionary objectForKey: tableFieldKey];
            MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
            result = [MTDatabaseField formattedString:dataType
                                             forValue:value];
            break;
            
        }
        case MTDocumentObjectTypeFormula: {
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            RptqDocumentObjectAggregate *aggregateField = [documentObject isAggregate];
            RptqQueryField *queryField = [aggregateField aggregateField];
            NSString * tableFieldKey = [queryField tableFieldKey];
            value = nil;
            
            switch ([[aggregateField function] integerValue]) {
                case MTAggregateFunctionTypeCount:
                    value = @([resultArray count]);
                    break;
                case MTAggregateFunctionTypeFirst:
                    value = [[resultArray objectAtIndex:0] objectForKey: tableFieldKey];
                    break;
                case MTAggregateFunctionTypeLast:
                    value = [[resultArray lastObject] objectForKey: tableFieldKey];
                    break;
                case MTAggregateFunctionTypeMax: {

                    long long max = 0;
                    for (NSDictionary *resultDictionary in resultArray) {
                        long long sumValue = [[resultDictionary objectForKey: tableFieldKey] longLongValue];
                        max = max > sumValue ? max : sumValue;
                    }
                    value = @(max);
                    
                    break;
                }
                case MTAggregateFunctionTypeMean: {
                    
                    long long sum = 0;
                    for (NSDictionary *resultDictionary in resultArray) {
                        long long sumValue = [[resultDictionary objectForKey: tableFieldKey] longLongValue];
                        sum = sum + sumValue;
                    }
                    value = @(sum / [resultArray count]);
                    
                    break;
                }
                case MTAggregateFunctionTypeMin: {
                    
                    long long min = 0;
                    for (NSDictionary *resultDictionary in resultArray) {
                        long long sumValue = [[resultDictionary objectForKey: tableFieldKey] longLongValue];
                        min = min < sumValue ?
                                min : sumValue;
                    }
                    value = @(min);
                    
                    break;
                }
                case MTAggregateFunctionTypeSum: {

                    long long sum = 0;
                    for (NSDictionary *resultDictionary in resultArray) {
                        long long sumValue = [[resultDictionary objectForKey: tableFieldKey] longLongValue];
                        sum = sum + sumValue;
                    }
                    value = @(sum);
                    
                    break;
                }
                default:
                    break;
            }

            MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
            result = [MTDatabaseField formattedString:dataType
                                             forValue:value];

            break;
        }
        case MTDocumentObjectTypeAggregateFunctionList: {
            break;
        }
        case MTDocumentObjectTypeChart: {
            break;
        }
        case MTDocumentObjectTypeGroupKey: {
            break;
        }
        case MTDocumentObjectTypeImage: {
            break;
        }
        default: {
            break;
        }
    }
    
    return result;
}

- (NSDictionary *)attributesForDocumentObject:(RptqDocumentObject *)documentObject {

    UIFont *customFont = [UIFont systemFontOfSize:[[documentObject fontsize] floatValue]];
    return @{NSFontAttributeName : customFont};
}

/*
- (NSAttributedString *)attributedStringFor:(RptqDocumentObject *)documentObject
                       withResultDictionary:(NSDictionary *)resultDictionary {
    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    
    NSString *displayText = [[self printDocumentObject:documentObject withResultDictionary:resultDictionary] retain];
    [[result mutableString] setString:displayText];
    [displayText release];
    
    NSRange wholeString = NSMakeRange(0, [[result mutableString] length]);

    [result setAttributes: [self attributesForDocumentObject:documentObject]
                    range: wholeString];
    return [result autorelease];
}*/

- (void)printPageBreakWithNextItemHeight:(CGFloat)nextItemHeight
                             groupedRows:(NSDictionary *)groupedRows {

    CGRect pageRect;
    CGFloat pageFooterSectionHeight = [[[[self document] hasPageFooterSection] height] floatValue];
    
    if (CGRectIsEmpty([self printableRect])) {
        pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    } else {
        pageRect = [self paperRect];
    }
    
    if (self.printableSpaceUsedPageHeight + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        self.printableSpaceUsedPageHeight += pageFooterSectionHeight;
        
        [self addPageFooterWithValueDictionary:groupedRows];
        
        [[self temporaryLayout] addObject:[[self temporaryPageData] copy]];
        
        [self setCachedNumberOfPages:[self cachedNumberOfPages] + 1];
        [self setPrintableSpaceUsedPageHeight: (CGPointZero.y + [[[[self document] hasPageHeaderSection] height] floatValue])];

        [self addPageHeaderWithValueDictionary:groupedRows];
        
    }
    
}



- (void)addPageHeaderWithValueDictionary:(NSDictionary *)values {
    [[self temporaryPageData] removeAllObjects];
    
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addPageFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addReportHeaderWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addReportFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addGroupHeaderWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self temporaryPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addGroupFooterWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self temporaryPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addDetailWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageDetail forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

@end