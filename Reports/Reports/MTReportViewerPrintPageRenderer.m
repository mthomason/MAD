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


@property (nonatomic, copy) NSArray *cachedLayoutByPage;
@property (nonatomic, copy) NSArray *cachedSortedSortDescriptorsGroup;
@property (nonatomic, copy) NSArray *cachedDataByPage;
@property (nonatomic, copy) NSDictionary *cachedDataByGroup;
@property (nonatomic, copy) NSArray *cachedDataByReport;

@property (nonatomic, retain) NSMutableArray *temporaryLayoutByPage;
@property (nonatomic, retain) NSMutableArray *temporaryLayoutForPage;

@property (nonatomic, retain) NSMutableArray *temporaryDataByPage;
@property (nonatomic, retain) NSMutableArray *temporaryDataForPage;

@property (nonatomic, retain) NSMutableDictionary *temporaryDataByGroup;
@property (nonatomic, retain) NSMutableDictionary *temporaryDataByReport;

@property (nonatomic, assign) NSUInteger temporaryCachedDetailCounter;

@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;

@end

@implementation MTReportViewerPrintPageRenderer

- (oneway void)release {
    
    [_cachedLayoutByPage release];
    [_cachedDataByPage release];
    [_cachedDataByGroup release];
    [_cachedDataByReport release];

    [_temporaryLayoutByPage release];
    [_temporaryLayoutForPage release];
    
    [_temporaryDataByPage release];
    [_temporaryDataForPage release];
    
    [_temporaryDataByGroup release];
    [_temporaryDataByReport release];

    [_cachedSortedSortDescriptorsGroup release];
    
}

- (id)retain {
    self = [super retain];
    if (self) {
        
        [_cachedLayoutByPage retain];
        [_cachedDataByPage retain];
        [_cachedDataByGroup retain];
        [_cachedDataByReport retain];
        
        [_temporaryLayoutByPage retain];
        [_temporaryLayoutForPage retain];

        [_temporaryDataByPage retain];
        [_temporaryDataForPage retain];
        
        [_temporaryDataByGroup retain];
        [_temporaryDataByReport retain];

        [_cachedSortedSortDescriptorsGroup retain];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTReportViewerPrintPageRenderer *copy = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:[self document]];
    if (copy) {
        
        [copy setDocument:[self document]];
        [copy setCachedLayoutByPage:[self cachedLayoutByPage]];
        [copy setCachedDataByGroup:[self cachedDataByGroup]];
        [copy setCachedDataByPage:[self cachedDataByPage]];
        [copy setCachedDataByReport:[self cachedDataByReport]];
        [copy setCachedSortedSortDescriptorsGroup:[self cachedSortedSortDescriptorsGroup]];

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
        
        NSMutableArray *a1 = [[NSMutableArray alloc] init];
        [self setTemporaryLayoutByPage:a1];
        [a1 release];
        
        NSMutableArray *a2 = [[NSMutableArray alloc] init];
        [self setTemporaryLayoutForPage:a2];
        [a2 release];
        
        NSMutableDictionary *d2 = [[NSMutableDictionary alloc] init];
        [self setTemporaryDataByReport:d2];
        [d2 release];
        
        NSMutableArray *d3 = [[NSMutableArray alloc] init];
        [self setTemporaryDataByPage:d3];
        [d3 release];
        
        NSMutableDictionary *d4 = [[NSMutableDictionary alloc] init];
        [self setTemporaryDataByGroup:d4];
        [d4 release];

        NSMutableArray *d5 = [[NSMutableArray alloc] init];
        [self setTemporaryDataForPage:d5];
        [d5 release];

        
    }
    return self;
}

#pragma mark - UIPrintPageRenderer Overrides

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    
    CGFloat originY = pageRect.origin.y;
    CGFloat originX = pageRect.origin.x;
    CGFloat sizeWidth = pageRect.size.width;

    NSUInteger detailRowsCounter = 0;
    NSUInteger pageNumber = 0;

    RptqQuery *query = [[[[[self document] hasDatabaseSchemas] anyObject] hasQueries] anyObject];

    NSUInteger numberOfGroups = [[query hasQueryGroups] count];
    NSUInteger groupLevelCounter[numberOfGroups];
    NSMutableDictionary *groupLevelKeys = [[NSMutableDictionary alloc] initWithCapacity:numberOfGroups];
    
    /*
    if (numberOfGroups > 1) {
        
        NSArray *groupKeys = [[self cachedDataByGroup] allKeys];
        for (id key in groupKeys) {
            
        }
        for (NSUInteger i = 0; i < numberOfGroups; i++) {
            [groupLevelKeys addObject: [self cachedDataByGroup]];
            groupLevelCounter[i] = 0;
            [[self cachedDataByGroup] obj]
        }
    }
    
    */

    
    if (index < [[self cachedLayoutByPage] count]) {

        NSArray *pageArray = [[[self cachedLayoutByPage] objectAtIndex:index] retain];
        NSArray *pageSectionsToPrint = [[NSArray alloc] initWithArray:pageArray];
        [pageArray release];
        
        CGRect sectionRect = CGRectZero;
        
        for (NSDictionary *pageSection in pageSectionsToPrint) {
            
            NSString *pageSectionId = [[NSString alloc] initWithString:[pageSection objectForKey: MTReportSectionType]];
            id reportSectionValues = nil;
            


            //NSLog(@"%@ (%@): %@", pageSectionId, data, NSStringFromCGRect(sectionRect));
            
            NSNumber *groupLevel = nil;
            
            RptqDocumentSection *documentSection = nil;
            CGFloat sizeHeight = CGSizeZero.height;
            
            if ([MTPageDetail isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasDetailSection];
                sizeHeight = [[documentSection height] floatValue];
                
                [[UIColor whiteColor] set];
                
                detailRowsCounter++;
                
            } else if ([MTPageHeader isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageHeaderSection];
                sizeHeight = [[documentSection height] floatValue];
                
                [[UIColor yellowColor] set];
                
            } else if ([MTPageFooter isEqualToString:pageSectionId]) {
                
                documentSection = [[self document] hasPageFooterSection];
                sizeHeight = [[documentSection height] floatValue];
                originY = pageRect.origin.y + pageRect.size.height - sizeHeight;

                [[UIColor yellowColor] set];
                
                pageNumber++;
                
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
                documentSection = [RptqDocumentSection getDocumentGroupHeaderAtLevel:[groupLevel integerValue] forQuery:query];
                
                sizeHeight = [[documentSection height] floatValue];
                
                [[UIColor lightGrayColor] set];
                
            } else if ([MTReportGroupFooter isEqualToString:pageSectionId]) {
                
                groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                
                //[groupLevelKeys setObject:@"" atIndexedSubscript:groupLevel];
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
            /*
             switch ([[documentSection type] integerValue]) {
             
             case MNSDocumentSectionTypeBody: {
             */
            NSUInteger detailRowToPrint = (detailRowsCounter == 0 ? detailRowsCounter : detailRowsCounter - 1);
            NSUInteger groupCounter = 0;
            NSDictionary *rowData = [self rowDataForRow: detailRowToPrint
                                                 onPage: index];

            for (NSSortDescriptor *sortDescriptor in [self cachedSortedSortDescriptorsGroup]) {

                id sortKey = [[rowData objectForKey:[sortDescriptor key]] retain];
                [groupLevelKeys setObject:sortKey forKey:@(groupCounter)];
                [sortKey release];
                groupCounter++;

            }

            for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                for (RptqDocumentObject *item in [row hasObjects]) {

                    NSString *displayString = nil;
                    switch ([item getType]) {
                        case MTDocumentObjectTypeAggregate:
                            displayString = @"Aggregate";
                            
                            RptqDocumentObjectAggregate *aggregateField = [item isAggregate];
                            RptqQueryField *queryField = [aggregateField aggregateField];
                            NSArray *dataForGroup = nil;
                            
                            switch ([[aggregateField groupType] integerValue]) {
                                    
                                case MTAggregateGroupByTypePage:
                                    
                                    dataForGroup = [[[self cachedDataByPage] objectAtIndex:pageNumber] retain];
                                    
                                    break;
                                    
                                case MTAggregateGroupByTypeSection: {
                                    
                                    NSDictionary *groupedData = [self cachedDataByGroup];
                                    for (id key in [groupLevelKeys objectEnumerator]) {
                                        groupedData = [groupedData objectForKey:key];
                                    }
                                    id value = [groupedData objectForKey:[queryField toString]];
                                    MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
                                    displayString = [MTDatabaseField formattedString:dataType
                                                                            forValue:value];


                                    //displayString = @"Group By Section";
                                    
                                    
                                    break;
                                }
                                    
                                case MTAggregateGroupByTypeReport:
                                    dataForGroup = [[self cachedDataByReport] objectAtIndex:pageNumber];
                                    displayString = @"Group By Report";
                                    break;
                                    
                                default:
                                    break;
                            }

//                            NSString *tableFieldKey = [queryField tableFieldKey];
                            
                            switch ([[aggregateField function] integerValue]) {
                                case MTAggregateFunctionTypeCount:
                                    
                                   
                                    break;
                                case MTAggregateFunctionTypeFirst:
                                    
                                    break;
                                case MTAggregateFunctionTypeLast:
                                    
                                    break;
                                case MTAggregateFunctionTypeMax:
                                    
                                    break;
                                case MTAggregateFunctionTypeMean:
                                    
                                    break;
                                case MTAggregateFunctionTypeMin:
                                    
                                    break;
                                case MTAggregateFunctionTypeSum:
                                    
                                    break;
                                default:

                                    break;
                            }
                            
                            [dataForGroup release];

                            break;
                        case MTDocumentObjectTypeImage:
                            displayString = @"Image";
                            break;
                            
                        case MTDocumentObjectTypeLabelDynamic: {
                            
                            RptqQueryField *queryField = [[item isLabelDataField] referencesQueryField];
                            NSString *tableFieldKey = [queryField tableFieldKey];
                            NSDictionary *rowData = [self rowDataForRow:detailRowToPrint onPage:index];
                            id value = [rowData objectForKey: tableFieldKey];
                            MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
                            displayString = [MTDatabaseField formattedString:dataType
                                                                    forValue:value];
                            break;
                        }
                        case MTDocumentObjectTypeLabelStatic:
                            displayString = [[item isLabel] text];
                            break;
                        default:
                            displayString = @"";
                            break;
                    }
                    
                    
                    NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: displayString
                                                                                                  attributes: [self attributesForDocumentObject:item]];
                    
                    CGFloat originPointX        = [[item dropPointX] floatValue];
                    CGFloat originPointY        = [[item dropPointY] floatValue] + originY;
                    CGFloat sizeWidth           = [[item sizewidth] floatValue];
                    CGFloat sizeHeight          = [[item sizeheight] floatValue];
                    CGRect elementCanvasRect    = CGRectMake(originPointX, originPointY, sizeWidth, sizeHeight);
                    
                    [attributedString drawInRect:elementCanvasRect];
                    
                    [attributedString release];
                }
            }
            /*
              
              break;
              }
                case MNSDocumentSectionTypePageHeader:
                case MNSDocumentSectionTypePageFooter:
                case MNSDocumentSectionTypeGroupHeader:
                case MNSDocumentSectionTypeGroupFooter:
                case MNSDocumentSectionTypeReportFooter:
                case MNSDocumentSectionTypeReportHeader: {
                    */
                    // FIXME: This is the next area to program the fuck out of... Almost working, except the data is not in correct format for page grouping yet.
                    /*
                    for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                        for (RptqDocumentObject *item in [row hasObjects]) {
                            NSString *itemToString = [self printDocumentObject: item withResultArray: reportSectionValues];
                            NSDictionary *itemAttributes = [self attributesForDocumentObject: item];
                            NSAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:itemToString
                                                                                                          attributes:itemAttributes];
                            
                            CGFloat originPointX        = [[item dropPointX] floatValue];
                            CGFloat originPointY        = [[item dropPointY] floatValue] + originY;
                            CGFloat sizeWidth           = [[item sizewidth] floatValue];
                            CGFloat sizeHeight          = [[item sizeheight] floatValue];
                            CGRect elementCanvasRect    = CGRectMake(originPointX, originPointY, sizeWidth, sizeHeight);
                            
                            [attributedString drawInRect:elementCanvasRect];
                            
                        }
                    }*//*
                    break;
                }
                default: {
                    break;
                }
            }*/
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
    return [[self cachedLayoutByPage] count];
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

- (NSDictionary *)rowDataForRow:(NSUInteger)row onPage:(NSUInteger)page {
    id rowData = nil;
    if (page < [[self cachedDataByPage] count]) {
        NSArray *pageData = [[self cachedDataByPage] objectAtIndex:page];
        if (row < [pageData count]) {
            NSUInteger cachedDataIndex = [[pageData objectAtIndex:row] integerValue];
            rowData = [[self cachedDataByReport] objectAtIndex:cachedDataIndex];
        }
    }
    return rowData;
}

- (NSString *)printDynamicDocumentLabel:(RptqDocumentObjectLabelDataField *)documentObjectDataField forRow:(NSUInteger)row onPage:(NSUInteger)page {
    NSString *result = @"";
    RptqQueryField *queryField = [documentObjectDataField referencesQueryField];
    NSString * tableFieldKey = [queryField tableFieldKey];
    NSDictionary *rowData = [self rowDataForRow:row onPage:page];
    id value = [rowData objectForKey: tableFieldKey];
    MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
    result = [[[MTDatabaseField formattedString:dataType
                                       forValue:value] retain] autorelease];
    return result;
}


- (NSString *)printDocumentObject: (RptqDocumentObject *)documentObject
             withResultDictionary: (NSDictionary *)resultDictionary {
    
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

- (NSString *)printDocumentObject: (RptqDocumentObject *)documentObject
                  withResultArray: (NSArray *)resultArray {
    
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

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize {

    if (CGSizeEqualToSize([self printableSize], printableSize) == NO) {
        [self setPrintableSize:printableSize];
        
        [self setTemporaryCachedDetailCounter:0];

        RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        RptqQueryCache *queryCache = [query hasQueryCache];
        
        NSMutableDictionary *cachedResultsForReport = [[NSMutableDictionary alloc] init];
        
        [[self temporaryLayoutByPage] removeAllObjects];
        [self setPrintableSpaceUsedPageHeight:CGSizeZero.height];
        
        for (RptqQueryResultFields *queryResultField in [queryCache hasQueryResultFields]) {
            for (RptqQueryResultValues *queryResultValue in [queryResultField hasValues]) {
        
                id results = [cachedResultsForReport objectForKey:[queryResultValue rowId]];
                
                NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] initWithDictionary:results];
                
                id queryResultCValue = [[queryResultValue cachedValue] retain];
                
                id obj1 = queryResultCValue == nil ? @"" : queryResultCValue;
                [resultDictionary setObject: obj1
                                     forKey: [queryResultField fieldname]];
                
                [cachedResultsForReport setObject: resultDictionary
                                           forKey: [queryResultValue rowId]];

                [queryResultCValue release];
                [resultDictionary release];
            }
        }
        
        NSSet *resultsByRowSet = [NSSet setWithArray:[cachedResultsForReport allValues]];
        NSSet *hasQueryGroups = [query hasQueryGroups];
        
        NSString *sortKey = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: sortKey
                                                                       ascending: YES];
        NSArray *sortedHasQueryGroups = [hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
        
        for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
            
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: [queryGroup fieldNameQuery]
                                                                           ascending: sortAscending];
            [sortedSortDescriptorsGroup addObject:sortDescriptor];
            [sortDescriptor release];
        }
        
        [self setCachedSortedSortDescriptorsGroup:[sortedSortDescriptorsGroup copy]];
        [sortedSortDescriptorsGroup release];

        NSArray *sortedResultsByRow = [resultsByRowSet sortedArrayUsingDescriptors:[self cachedSortedSortDescriptorsGroup]];
        sortedResultsByRow = [sortedResultsByRow retain];
        
        [self setCachedDataByReport:[sortedResultsByRow copy]];
        
        id groupedRows = [[self groupedResults:sortedResultsByRow
                                         level:0] retain];
        
        [self setPrintableSpaceUsedPageHeight: CGSizeZero.height];
        
        CGFloat printableSpaceUsed = [self printableSpaceUsedPageHeight] + [[[[self document] hasPageHeaderSection] height] floatValue];
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cachePageHeaderWithValueDictionary:groupedRows];

        printableSpaceUsed = [self printableSpaceUsedPageHeight] + [[[[self document] hasReportHeaderSection] height] floatValue];
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cacheReportHeaderWithValueDictionary:groupedRows];
        
        BOOL detailPrinted = NO;
        [self cacheGroupLevel:[query firstQueryGroup]
                  groupedRows:groupedRows
             groupedRowsLevel:0
                detailPrinted:&detailPrinted];
        
        
        CGFloat reportFooterHeight = [[[[self document] hasReportFooterSection] height] floatValue];
        
        [self cachePageBreakWithNextItemHeight: reportFooterHeight
                                   groupedRows: groupedRows];
        
        printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportFooterHeight;
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cacheReportFooterWithValueDictionary:groupedRows];
        
        CGFloat pageFooterHeight = [[[[self document] hasPageFooterSection] height] floatValue];
        //[self cachePageBreakWithNextItemHeight: pageFooterHeight
        //                           groupedRows: groupedRows];
        
        printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageFooterHeight;
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cachePageFooterWithValueDictionary:groupedRows];
        
        [[self temporaryLayoutByPage] addObject:[[self temporaryLayoutForPage] copy]];
        [[self temporaryDataByPage] addObject:[[self temporaryDataForPage] copy]];
        
        [self setCachedDataByGroup:[groupedRows copy]];
        [self setCachedLayoutByPage:[[self temporaryLayoutByPage] copy]];
        [self setCachedDataByPage:[[self temporaryDataByPage] copy]];
        
        [cachedResultsForReport release];
        [groupedRows release];
        [sortedResultsByRow release];
        [sortDescriptor release];

    }
}

- (void)cacheGroupLevel:(RptqQueryGroup *)queryGroup
            groupedRows:(NSDictionary *)groupedRows
       groupedRowsLevel:(NSUInteger)groupedRowsLevel
          detailPrinted:(BOOL *)detailPrinted {
    
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
                        [self cachePageBreakWithNextItemHeight: [[documentSection height] floatValue]
                                                   groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection height] floatValue];
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }

                [self cacheGroupHeaderWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                RptqQueryGroup *nextGroup = [queryGroup next];
                
                
                if (nextGroup != nil) {
                    [self cacheGroupLevel: nextGroup
                              groupedRows: obj
                         groupedRowsLevel: groupedRowsLevel
                            detailPrinted: detailPrinted];
                } else {
                    [self cacheDetailLevelWithDetails:obj
                                          groupedRows:groupedRows];
                }
                
                //Group footer section
                for (RptqDocumentSection *documentSection in [[queryGroup hasSection] allObjects]) {
                    if ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                        [self cachePageBreakWithNextItemHeight: [[documentSection height] floatValue]
                                                   groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection height] floatValue];
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }

                [self cacheGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                [obj release];
            }
            [loopEnumerator release];
            [allKeysSorted release];
            [allKeys release];

        } else if ([groupedRows isKindOfClass:[NSArray class]]) {   //Details without groupings...

            [self cacheDetailLevelWithDetails:(NSArray *)groupedRows
                                  groupedRows:groupedRows];
        }
}

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails
                        groupedRows:(NSDictionary *)groupedRows {

    RptqDocumentSection *detailSection = [[self document] hasDetailSection];
    for (NSDictionary *resultDictionary in containerDetails) {
        
        [self cachePageBreakWithNextItemHeight: [[detailSection height] floatValue]
                                   groupedRows: groupedRows];
        [self cacheDetailWithValueDictionary:resultDictionary];
        CGFloat printableHeightUsed = ([self printableSpaceUsedPageHeight] + [[detailSection height] floatValue]);
        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
    }

}

//Roll through the groups
//Returns dictionary for group levels (level < n), and array of dictionaries for details/results (level == n-1).
- (id)groupedResults:(NSArray *)sortedResults level:(NSUInteger)level {
    
    BOOL detailLevel = level == [[self cachedSortedSortDescriptorsGroup] count];
    id resultsDictionary = nil;
    
    if (detailLevel) {
        resultsDictionary = [sortedResults copy];
    } else {
        resultsDictionary = [[NSMutableDictionary alloc] init];
        NSMutableArray *resultsForGroup = [[NSMutableArray alloc] init];
        
        NSSortDescriptor *sortDescriptor = detailLevel ? nil : [[self cachedSortedSortDescriptorsGroup] objectAtIndex:level];
        
        NSString *sortFieldName =  detailLevel ? nil : [sortDescriptor key];

        id valueForField = nil, lastValueForField = nil;
        
        NSUInteger groupResultIndexForLevel = 0;
        
        for (NSDictionary *result in sortedResults) {
            valueForField = detailLevel ? nil : [result objectForKey:sortFieldName];
            
            if (![valueForField isEqual: lastValueForField] && lastValueForField != nil) {

                id resultOfNextGroup = [self groupedResults: resultsForGroup
                                                      level: (level + 1)];
                
                [resultsDictionary setObject:resultOfNextGroup forKey:lastValueForField];
                //[resultsDictionary setObject:resultOfNextGroup forKey:@(groupResultIndexForLevel)];
                
                
                [resultsForGroup removeAllObjects];
                
            }
            [resultsForGroup addObject:result];
            lastValueForField = valueForField;
            groupResultIndexForLevel++;
        }

        NSArray *resultsCopy = [[NSArray alloc] initWithArray: resultsForGroup];                //Last item
        if (valueForField != nil) {
            id resultOfNextGroup = [self groupedResults: resultsForGroup
                                                  level: (level + 1)];
            NSString *key = lastValueForField == nil ? valueForField : lastValueForField;
            [resultsDictionary setObject:resultOfNextGroup forKey:key];
        }
        
        [resultsCopy release];
        
        [resultsForGroup removeAllObjects];
        [resultsForGroup release];
    }
    return [resultsDictionary autorelease];
}

- (BOOL)cachePageBreakWithNextItemHeight:(CGFloat)nextItemHeight
                             groupedRows:(NSDictionary *)groupedRows {

    BOOL newPageCreated = NO;
    CGRect pageRect;
    CGFloat pageFooterSectionHeight = [[[[self document] hasPageFooterSection] height] floatValue];
    
    if (CGRectIsEmpty([self printableRect])) {
        pageRect = CGRectMake(CGPointZero.x, CGPointZero.y, self.printableSize.width, self.printableSize.height);
    } else {
        pageRect = [self paperRect];
    }
    
    if ([self printableSpaceUsedPageHeight] + nextItemHeight + pageFooterSectionHeight > pageRect.size.height) {
        newPageCreated = YES;
        CGFloat newHeight = [self printableSpaceUsedPageHeight] + pageFooterSectionHeight;
        [self setPrintableSpaceUsedPageHeight:newHeight];
        [self cachePageFooterWithValueDictionary:groupedRows];
        
        [[self temporaryLayoutByPage] addObject:[[self temporaryLayoutForPage] copy]];
        [[self temporaryDataByPage] addObject:[[self temporaryDataForPage] copy]];
        
        [self setPrintableSpaceUsedPageHeight: (CGPointZero.y + [[[[self document] hasPageHeaderSection] height] floatValue])];

        [self cachePageHeaderWithValueDictionary:groupedRows];
        
    }
    return newPageCreated;
}

- (void)cachePageHeaderWithValueDictionary:(NSDictionary *)values {
    [[self temporaryLayoutForPage] removeAllObjects];
    [[self temporaryDataForPage] removeAllObjects];
    
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageHeader forKey:MTReportSectionType];
    if (newValue != nil) {
        [sectionData setObject:newValue forKey:MTReportSectionValues];
    }
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cachePageFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheReportHeaderWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheReportFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheGroupHeaderWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheGroupFooterWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)cacheDetailWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageDetail forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self temporaryLayoutForPage] addObject: sectionData];
    [[self temporaryDataForPage] addObject:@([self temporaryCachedDetailCounter])];
    self.temporaryCachedDetailCounter++;
    [sectionData release];
    [newValue release];
}

@end