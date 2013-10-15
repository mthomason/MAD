//
//  MTPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerPrintPageRenderer.h"
#import <CoreText/CoreText.h>

const NSString *MTReportSectionType = @"MTReportSectionType";
const NSString *MTReportSectionValues = @"MTReportSectionValues";
const NSString *MTReportGroupLevel = @"MTReportGroupLevel";

const NSString *MTPageDetail = @"MTPageDetail";
const NSString *MTPageHeader = @"MTPageHeader";
const NSString *MTPageFooter = @"MTPageFooter";
const NSString *MTReportHeader = @"MTReportHeader";
const NSString *MTReportFooter = @"MTReportFooter";
const NSString *MTReportGroupHeader = @"MTReportGroupHeader";
const NSString *MTReportGroupFooter = @"MTReportGroupFooter";

@interface MTReportViewerPrintPageRenderer ()

@property (nonatomic, assign) CGSize printableSize;

//@property (nonatomic, assign) RptqDocument *document;
@property (nonatomic, retain) NSArray *cachedLayoutByPage;
@property (nonatomic, retain) NSArray *cachedSortedSortDescriptorsGroup;
@property (nonatomic, retain) NSArray *cachedDataByPage;
@property (nonatomic, retain) NSDictionary *cachedDataByGroup;
@property (nonatomic, retain) NSArray *cachedDataByReport;

@property (nonatomic, retain) NSMutableArray *temporaryLayoutByPage;
@property (nonatomic, retain) NSMutableArray *temporaryLayoutForPage;

@property (nonatomic, retain) NSMutableArray *temporaryDataByPage;
@property (nonatomic, retain) NSMutableArray *temporaryDataForPage;

@property (nonatomic, retain) NSMutableDictionary *temporaryDataByGroup;
@property (nonatomic, retain) NSMutableDictionary *temporaryDataByReport;

@property (nonatomic, assign) NSUInteger temporaryCachedDetailCounter;

@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;

@property (nonatomic, assign) BOOL debugMode;

@property (nonatomic, assign) CGSize cachedPageSize;
@property (nonatomic, assign) CGRect cachedPageRect;

@property (nonatomic, retain) NSArray *sortedQueryGroups;

@property (nonatomic, retain) NSInputStream *inputStream;

@end

@implementation MTReportViewerPrintPageRenderer

- (void)dealloc {
    [_inputStream release];
    [_cachedLayoutByPage release];
    [_cachedSortedSortDescriptorsGroup release];
    [_cachedDataByPage release];
    [_cachedDataByGroup release];
    [_cachedDataByReport release];
    [_temporaryLayoutByPage release];
    [_temporaryLayoutForPage release];
    [_temporaryDataByPage release];
    [_temporaryDataForPage release];
    [_temporaryDataByGroup release];
    [_temporaryDataByReport release];
    [_sortedQueryGroups release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    MTReportViewerPrintPageRenderer *copy = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:nil];
    if (copy) {
        [copy setSortedQueryGroups:[self sortedQueryGroups]];
        //[copy setDocument:[self document]];
        [copy setCachedLayoutByPage:[self cachedLayoutByPage]];
        [copy setCachedDataByGroup:[self cachedDataByGroup]];
        [copy setCachedDataByPage:[self cachedDataByPage]];
        [copy setCachedDataByReport:[self cachedDataByReport]];
        [copy setCachedSortedSortDescriptorsGroup:[self cachedSortedSortDescriptorsGroup]];

    }
    return copy;
}

- (id)init {
    self = [super init];
    if (self) {
        MTLog(@"Init");
//        RptqDocument *activeDocument = [RptqDocument activeDocument];
//        [self setDocument:activeDocument];
        [self initCommon];
    }
    return self;
}

- (void)initCommon {

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
    
    [self setDebugMode:NO];
    [self setDidRefresh:NO];

    [self setCachedPageSize:CGSizeZero];
    [self setCachedPageRect:CGRectZero];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([standardUserDefaults valueForKey:@"MTCachedSizeHorizontal"] == nil) {

        [standardUserDefaults setObject:NSStringFromCGSize(CGSizeZero) forKey:@"MTCachedSizeHorizontal"];
        [standardUserDefaults setObject:NSStringFromCGSize(CGSizeZero) forKey:@"MTCachedSizeVertical"];
        [standardUserDefaults synchronize];
    }
}

- (id)initWithDocument:(RptqDocument *)document {
    id result = [self initWithDocument:document andPrintableAreaSize:[MTPaper sizeLetter]];
    return [[result retain] autorelease];
}

- (id)initWithDocument:(RptqDocument *)document andPrintableAreaSize:(CGSize)printableAreaSize {
    self = [super init];
    if (self) {
        MTLog(@"Init");
        
        [self initCommon];
        [self setPrintableSize:printableAreaSize];
        
    }
    return self;
}

- (void)writeToPdf:(NSURL *)filepath {
    NSDictionary *options = @{(NSString *)kCGPDFContextCreator :  @"Mad Designer"};
    CGRect letterRect = [MTPaper rectLetter];
    [self cachePrintPageRenderDataForSize:letterRect.size];
    NSUInteger numberOfPages = [self numberOfPages];
    UIGraphicsBeginPDFContextToFile([filepath path], letterRect, options);
    
    for (NSUInteger i=0; i<numberOfPages; i++) {
        UIGraphicsBeginPDFPageWithInfo(letterRect, nil);
        [self drawPageAtIndex:i inRect:letterRect];
    }
    
    // Close the PDF context and write the contents out.
    UIGraphicsEndPDFContext();
}

- (UIImage *)thumbnail {
    CGRect letterRect = [MTPaper rectLetter];
    
    // FIXME: Don't cache data for the whole report when just printing the first page for a
    //          fucking thumbnail.
    
    [self cachePrintPageRenderDataForSize:letterRect.size onlyFirstPage:YES];
    //CGFloat scale = 128.0000 / (letterRect.size.height > letterRect.size.width > 0.0f ? letterRect.size.height : (letterRect.size.width == 0.0000f? letterRect.size.width : 1.0000f));
    UIGraphicsBeginImageContextWithOptions(letterRect.size, YES, 0.0000f);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, letterRect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, path);
    CGPathRelease(path);
    
    [[UIColor whiteColor] setFill];
    CGContextDrawPath(context, kCGPathFill);
    [self drawPageAtIndex:0 inRect:letterRect];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGFloat imageSize = [UIDevice isPad] == YES ? 124.0000f * [[UIScreen mainScreen] scale] : 64.0000f * [[UIScreen mainScreen] scale];
    
    UIImage *result;
    if ([UIDevice isLagacyOS]) {
        UIImage *i = [image thumbnailImage:imageSize interpolationQuality:kCGInterpolationLow];
        result = [[UIImage imageWithBorder:i] retain];
    } else {
        result = [[image thumbnailImage:imageSize interpolationQuality:kCGInterpolationLow] retain];
    }
    UIGraphicsEndImageContext();

    return [result autorelease];
}

#pragma mark - UIPrintPageRenderer Overrides

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    [[UIColor whiteColor] setFill];

    CGContextRef ctx = UIGraphicsGetCurrentContext();


    
    
    NSMutableArray *printableStrings = [[NSMutableArray alloc] init];
    
    CGFloat originY = pageRect.origin.y;
    CGFloat originX = pageRect.origin.x;
    CGFloat sizeWidth = pageRect.size.width;
    
    NSUInteger detailRowsCounter = 0;
    NSUInteger pageNumber = 0;
    RptqDocument *document = [RptqDocument activeDocument];
    RptqDatabase *databaseSchemas = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[databaseSchemas hasQueries] anyObject];
    
    if (query) {
        NSUInteger numberOfGroups = [[query hasQueryGroups] count];
        NSMutableArray *groupLevelKeys = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        NSMutableArray *nextGroupLevelKeys = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        
        if (index < [[self cachedLayoutByPage] count]) {
            
            NSArray *pageSectionsToPrint = [[self cachedLayoutByPage] objectAtIndex:index];
            
            CGRect sectionRect = CGRectZero;
            
            UIColor *whiteColor = [[UIColor whiteColor] retain];

            for (NSDictionary *pageSection in pageSectionsToPrint) {
                
                @autoreleasepool {
                    
                    NSString *pageSectionId = [pageSection objectForKey: MTReportSectionType];
                    //id reportSectionValues = nil;
                    
                    NSNumber *groupLevel = nil;
                    
                    RptqDocumentSection *documentSection = nil;
                    
                    if ([MTPageDetail isEqualToString:pageSectionId]) {
                        
                        documentSection = [document hasDetailSection];
                        
                        [whiteColor setFill];
                        
                        detailRowsCounter++;
                        
                    } else if ([MTPageHeader isEqualToString:pageSectionId]) {
                        
                        documentSection = [document hasPageHeaderSection];
                        
                            [whiteColor setFill];
                        
                    } else if ([MTPageFooter isEqualToString:pageSectionId]) {
                        
                        documentSection = [document hasPageFooterSection];
                        CGFloat sectionHeight = [[documentSection layoutHeight] floatValue];
                        originY = pageRect.origin.y + pageRect.size.height - sectionHeight;
                        
                            [whiteColor setFill];
                        
                        pageNumber++;
                        
                    } else if ([MTReportHeader isEqualToString:pageSectionId]) {
                        
                        documentSection = [document hasReportHeaderSection];
                        
                        [whiteColor setFill];
                        
                    } else if ([MTReportFooter isEqualToString:pageSectionId]) {
                        
                        documentSection = [document hasReportFooterSection];
                        CGFloat sizeHeightReportFooter = [[documentSection layoutHeight] floatValue];
                        RptqDocumentSection *pageFooterSection = [document hasPageFooterSection];
                        CGFloat sizeHeightPageFooter = [[pageFooterSection layoutHeight] floatValue];
                        originY = pageRect.origin.y + pageRect.size.height - sizeHeightReportFooter - sizeHeightPageFooter;
                        
                        [whiteColor setFill];
                        
                    } else if ([MTReportGroupHeader isEqualToString:pageSectionId]) {
                        
                        groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                        documentSection = [RptqDocumentSection getDocumentGroupHeaderAtLevel:[groupLevel integerValue] forQuery:query];
                        
                        [whiteColor setFill];
                        
                    } else if ([MTReportGroupFooter isEqualToString:pageSectionId]) {
                        
                        groupLevel = [pageSection objectForKey:MTReportGroupLevel];
                        
                        query = [[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject];
                        documentSection = [RptqDocumentSection getDocumentGroupFooterAtLevel:[groupLevel integerValue] forQuery:query];
                        
                        [whiteColor setFill];
                        
                    }
                    CGFloat sizeHeight = [RptqDocumentSection layoutHeightForSection:documentSection];
                    sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                    
                    UIBezierPath *bezierPathForSection = [UIBezierPath bezierPathWithRect:sectionRect];
                    
                    [bezierPathForSection fill];
                    
                    NSUInteger detailRowToPrint = (detailRowsCounter == 0 ? detailRowsCounter : detailRowsCounter - 1);
                    NSDictionary *rowData = [self rowDataForRow: detailRowToPrint onPage: index];
                    
                    NSNumber *documentSectionType = [documentSection type];
                    BOOL useNextRowData = ([documentSectionType integerValue] == MNSDocumentSectionTypeGroupHeader);
                    NSInteger nextDetailRowToPrint = detailRowToPrint;
                    NSInteger nextPageIndex = index;
                    if (useNextRowData) {
                        NSArray *pageData = [[self cachedDataByPage] objectAtIndex:index];
                        NSInteger numberOfItemsOnPage = [pageData count];
                        if (nextDetailRowToPrint < numberOfItemsOnPage - 1) {
                            nextDetailRowToPrint++;
                        } else {
                            nextDetailRowToPrint = 0;
                            nextPageIndex++;
                        }
                    }
                    NSDictionary *nextRowData = [self rowDataForRow:nextDetailRowToPrint onPage:nextPageIndex];
                    
                    if (rowData != nil) {
                        
                        [groupLevelKeys removeAllObjects];
                        [nextGroupLevelKeys removeAllObjects];
                        for (NSSortDescriptor *sortDescriptor in [self cachedSortedSortDescriptorsGroup]) {
                            @autoreleasepool {
                                
                                NSString *key = [sortDescriptor key];
                                id sortKey = [rowData objectForKey:key];
                                if (sortKey == nil) {
                                    sortKey = @"(null)";
                                }
                                [groupLevelKeys addObject:sortKey];
                                if (nextRowData != nil) {
                                    id sortKeyNext = [nextRowData objectForKey:key];
                                    if (sortKeyNext == nil) {
                                        sortKeyNext = @"(null)";
                                    }
                                    if (sortKeyNext) {
                                        [nextGroupLevelKeys addObject:sortKeyNext];
                                    }
                                }
                                
                            }
                        }
                        
                        for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                            for (RptqDocumentObject *item in [row hasObjects]) {
                                
                                @autoreleasepool {
                                    
                                    
                                    NSString *displayString = nil;
                                    id drawingObject = nil;
                                    
                                    switch ([item getType]) {
                                            
                                        case MTDocumentObjectTypeAggregate: {
                                            RptqDocumentObjectAggregate *aggregateField = [item isAggregate];
                                            
                                            RptqQueryField *queryField = [aggregateField aggregateField];
                                            
                                            NSArray *dataForGroup = nil;
                                            
                                            NSNumber *aggregateFieldGroupType = [aggregateField groupType];
                                            MTAggregateGroupByType aggregateGroupType = [aggregateFieldGroupType integerValue];
                                            
                                            switch (aggregateGroupType) {
                                                    // FIXME: Check to see which ones of these are correct.
                                                case MTAggregateGroupByTypePage: {
                                                    //dataForGroup = [[[self cachedDataByPage] objectAtIndex:pageNumber] retain];
                                                    
                                                    NSArray *pageIndices = [[self cachedDataByPage] objectAtIndex:index];
                                                    dataForGroup = [[NSMutableArray alloc] initWithCapacity:[pageIndices count]];
                                                    for (NSNumber *dataIndex in pageIndices) {
                                                        NSInteger i = [dataIndex integerValue];
                                                        id objectToAdd = [[self cachedDataByReport] objectAtIndex: i];
                                                        [(NSMutableArray *)dataForGroup addObject:objectToAdd];
                                                    }
                                                    [dataForGroup autorelease];
                                                    break;
                                                }
                                                case MTAggregateGroupByTypeSection: {
                                                    BOOL useNextRowData = ([[documentSection type] integerValue] == MNSDocumentSectionTypeGroupHeader);
                                                    if (useNextRowData) {
                                                        dataForGroup = [self dataForCachedGroupData:[self cachedDataByGroup] andKeys:nextGroupLevelKeys];
                                                    } else {
                                                        dataForGroup = [self dataForCachedGroupData:[self cachedDataByGroup] andKeys:groupLevelKeys];
                                                    }
                                                    break;
                                                }
                                                case MTAggregateGroupByTypeReport:
                                                    dataForGroup = [self cachedDataByReport];
                                                    break;
                                                    
                                                default:
                                                    dataForGroup = [self cachedDataByReport];
                                                    break;
                                            }
                                            
                                            NSString *fieldKey = [queryField toString];
                                            
                                            RptqDatabaseSchemaField *databaseSchemaField = [queryField databaseSchemaField];
                                            NSNumber *databaseSchemaFieldDataType = [databaseSchemaField dataType];
                                            MTDataType aggregateType = [databaseSchemaFieldDataType integerValue];
                                            id aggregateResult = nil;
                                            switch ([[aggregateField function] integerValue]) {
                                                    
                                                case MTAggregateFunctionTypeCount:
                                                    aggregateResult = @([dataForGroup count]);
                                                    break;
                                                    
                                                case MTAggregateFunctionTypeFirst:
                                                    aggregateResult = [[dataForGroup objectAtIndex:0] objectForKey:fieldKey];
                                                    break;
                                                    
                                                case MTAggregateFunctionTypeLast:
                                                    aggregateResult = [[dataForGroup lastObject] objectForKey:fieldKey];
                                                    break;
                                                    
                                                case MTAggregateFunctionTypeMax: {
                                                    
                                                    id result = nil;
                                                    for (id object in dataForGroup) {
                                                        id n = [object objectForKey: fieldKey];
                                                        if ([n compare:result] == NSOrderedDescending) {result = n;}
                                                    }
                                                    aggregateResult = result;
                                                    
                                                    break;
                                                }
                                                    
                                                case MTAggregateFunctionTypeMean: {
                                                    
                                                    
                                                    id sum = @(0);
                                                    for (id object in dataForGroup) {
                                                        id n = [object objectForKey: fieldKey];
                                                        sum = [self sumObject:sum andObject:n forType:aggregateType];
                                                        
                                                    }
                                                    NSUInteger dataForGroupCount = [dataForGroup count];
                                                    
                                                    // FIXME: Should this sum float value be typed with a devideObject as the sumObject above?
                                                    
                                                    aggregateResult = @(dataForGroupCount > 0 ? ([sum floatValue] / dataForGroupCount) : dataForGroupCount);
                                                    
                                                    
                                                    break;
                                                }
                                                    
                                                case MTAggregateFunctionTypeMin: {
                                                    
                                                    id result = nil;
                                                    for (id object in dataForGroup) {
                                                        id n = [object objectForKey: fieldKey];
                                                        if ([n compare:result] == NSOrderedAscending) {result = n;}
                                                    }
                                                    aggregateResult = result;
                                                    
                                                    break;
                                                }
                                                case MTAggregateFunctionTypeSum: {
                                                    
                                                    id sum = @(0);
                                                    for (id object in dataForGroup) {
                                                        id n = [object objectForKey: fieldKey];
                                                        sum = [self sumObject:sum andObject:n forType:aggregateType];
                                                        
                                                    }
                                                    aggregateResult = sum;
                                                    
                                                    
                                                    break;
                                                }
                                                default:
                                                    
                                                    break;
                                            }
                                            
                                            //[dataForGroup release];
                                            
                                            displayString = [item formattedString:aggregateType
                                                                         forValue:aggregateResult];
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeImage: {
                                            drawingObject = [[[item isImage] image] retain];
                                            displayString = @"";
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeLabelDynamic: {
                                            
                                            NSInteger rowToPrint = (detailRowsCounter == 0 ? detailRowsCounter : detailRowsCounter - 1);
                                            NSInteger pageIndex = index;
                                            
                                            NSNumber *sectionType = [documentSection type];
                                            BOOL useNextRowData = ([sectionType integerValue] == MNSDocumentSectionTypeGroupHeader);
                                            if (useNextRowData) {
                                                NSArray *pageData = [[self cachedDataByPage] objectAtIndex:index];
                                                NSInteger numberOfItemsOnPage = [pageData count];
                                                if (rowToPrint < numberOfItemsOnPage - 1) {
                                                    rowToPrint++;
                                                } else {
                                                    rowToPrint = 0;
                                                    pageIndex++;
                                                }
                                            }
                                            
                                            NSDictionary *rd = useNextRowData ? nextRowData : rowData;
                                            RptqDocumentObjectLabelDataField *labelDataField = [item isLabelDataField];
                                            RptqQueryField *queryField = [labelDataField referencesQueryField];
                                            NSString *tableFieldKey = [queryField tableFieldKey];
                                            id value = [rd objectForKey: tableFieldKey];
                                            
                                            RptqDatabaseSchemaField *schemaField = [queryField databaseSchemaField];
                                            NSNumber *dataTypeNumber = [schemaField dataType];
                                            MTDataType dataType = [dataTypeNumber integerValue];
                                            displayString = [item formattedString:dataType
                                                                         forValue:value];
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeLabelStatic: {
                                            displayString = [[item isLabel] text];
                                            break;
                                        }
                                            
                                        default: {
                                            displayString = @"";
                                            break;
                                        }
                                    }
                                    
                                    CGFloat originPointX        = [[item dropPointX] floatValue] + sectionRect.origin.x;
                                    CGFloat originPointY        = [[item dropPointY] floatValue] + sectionRect.origin.y;
                                    CGRect paddingFrame = [item paddingViewFrame];
                                    CGRect elementCanvasRect    = CGRectMake(originPointX, originPointY, paddingFrame.size.width, paddingFrame.size.height);
                                    
                                    if (drawingObject == nil) {
                                        
                                        if ([UIDevice isLagacyOS]) {
                                            
                                            
                                            NSDictionary *attributes = [self attributesForDocumentObject:item];
                                            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:displayString];
                                            
                                            [attributedString setAttributes: attributes range:NSRangeFromString(displayString)];
                                            
                                            NSDictionary *psAttributes = @{
                                                                           @"s" : attributedString,
                                                                           @"r" : NSStringFromCGRect(elementCanvasRect)
                                                                           };
                                            [printableStrings addObject:psAttributes];
                                            
                                            [attributedString drawInRect:elementCanvasRect];
                                            [attributedString release];
                                        } else {
                                            NSDictionary *attributes = [self attributesForDocumentObject:item];
                                            
                                            // FIXME: This hack gets around known iOS7 bug.
                                            //          Want to draw the fucking rect without
                                            //          having to do a fucking translation.
                                            
                                            CGContextSaveGState(ctx);
                                            {
                                                CGContextTranslateCTM(ctx, elementCanvasRect.origin.x, elementCanvasRect.origin.y);
                                                [displayString drawInRect:CGRectMake(0.0000f, 0.0000f, elementCanvasRect.size.width, elementCanvasRect.size.height) withAttributes:attributes];
                                            }
                                            CGContextRestoreGState(ctx);
                                        }
                                        
                                    } else {
                                        
                                        [drawingObject drawInRect:elementCanvasRect];
                                        
                                    }
                                    
                                    [drawingObject release];
                                    drawingObject = nil;
                                    
                                    
                                }
                            }
                        }
                    }
                    
                    originY += sizeHeight;
                    
                    //[reportSectionValues release];
                    
                }
            }
        }
        
        [nextGroupLevelKeys release];
        [groupLevelKeys release];
    }
    
    
    if ([MTStoreKitController licensedUser] == NO) {

        
        UIFont *customFont = [UIFont boldSystemFontOfSize:12.0000f];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
        
        UIColor *strokeColor = [UIColor colorWithRed:170.0000f/256.0000f green:170.0000f/256.0000f blue:170.0000f/256.0000f alpha:0.8000f];
        UIColor *foregroundColor = [UIColor colorWithRed:85.0000f/256.0000f green:85.0000f/256.0000f blue:85.0000f/256.0000f alpha:0.8000f];
        
        NSDictionary *results = @{NSFontAttributeName : customFont,
                                   //NSTextEffectAttributeName : NSTextEffectLetterpressStyle,
                                   NSStrokeWidthAttributeName : @(3.0000f),
                                   NSStrokeColorAttributeName : strokeColor,
                                   NSForegroundColorAttributeName : foregroundColor,
                                   NSParagraphStyleAttributeName: paragraphStyle
                                   };
        NSString *getMadS = @"Get MAD Viewer!\nOpen and View MAD Documents";
        NSAttributedString *getMad = [[NSAttributedString alloc] initWithString: getMadS attributes:results];

        NSInteger rowCounter = 0, columnCounter = 0;
        CGSize logoSize = CGSizeMake(150.0000f, 50.0000f);
        CGSize logoMargin = CGSizeMake(25.0000f, 25.0000f);
        CGRect logoRect;
        
        do {
            columnCounter = 0;
            do {
                
                CGFloat x = ((columnCounter * 2) + 1) * logoMargin.width + columnCounter * logoSize.width;
                CGFloat y = ((rowCounter * 2) + 1) * logoMargin.height + rowCounter * logoSize.height;
                logoRect = CGRectMake(x, y, logoSize.width, logoSize.height);
                
                CGContextSaveGState(ctx);
                {
                    static CGFloat angle315Degrees = 7.0000f * M_PI / 4.0000f;
                    CGContextTranslateCTM(ctx, x, columnCounter % 2 == 0 ? y : y + ((logoRect.size.height + (logoMargin.height * 2)) / 2.0000f));
                    CGContextRotateCTM(ctx, angle315Degrees);
                    [getMad drawInRect:CGRectMake(0.0000f, 0.0000f, logoRect.size.width, logoRect.size.height)];
                }
                CGContextRestoreGState(ctx);
                columnCounter++;
            } while (logoRect.origin.x + logoRect.size.width < pageRect.size.width);
            rowCounter++;
        } while (logoRect.origin.y + logoRect.size.height < pageRect.size.height);

        [paragraphStyle release];
        [getMad release];

    }

    
    [printableStrings release];
}

- (NSDictionary *)attributesForDocumentObject:(RptqDocumentObject *)documentObject {
    MTFont *font = [[MTFont alloc] initWithFamilyName:[documentObject fontname] andPointSize:[[documentObject fontsize] floatValue] isBold:[[documentObject bold] boolValue] isItalic:[[documentObject italic] boolValue]];
    UIFont *customFont = [font font];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    switch ([[documentObject horizontalAlignment] integerValue]) {
        case MTHorizontalAlignmentLeft:
            [paragraphStyle setAlignment:NSTextAlignmentLeft];
            break;
        case MTHorizontalAlignmentRight:
            [paragraphStyle setAlignment:NSTextAlignmentRight];
            break;
        case MTHorizontalAlignmentCenter:
            [paragraphStyle setAlignment:NSTextAlignmentCenter];
            break;
        case MTHorizontalAlignmentJustified:
            [paragraphStyle setAlignment:NSTextAlignmentJustified];
            break;
        case MTHorizontalAlignmentNatrual:
            [paragraphStyle setAlignment:NSTextAlignmentNatural];
            break;
        default:
            [paragraphStyle setAlignment:NSTextAlignmentLeft];
            break;
    }
    
    NSNumber *baselineOffset = @(0.0000f);
    NSNumber *underlineStyle = [[documentObject underline] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    NSNumber *strikethroughStyle = [[documentObject strike] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    NSDictionary *results = @{
                              NSFontAttributeName : customFont,
                              NSBaselineOffsetAttributeName : baselineOffset,
                              NSUnderlineStyleAttributeName : underlineStyle,
                              NSStrikethroughStyleAttributeName : strikethroughStyle,
                              NSParagraphStyleAttributeName: paragraphStyle
                              };
    [results retain];
    [paragraphStyle release];
    [font release];
    return [results autorelease];
    
}

- (NSDictionary *)coreTextAttributesForDocumentObject:(RptqDocumentObject *)documentObject {
    //NSString *fontname = [documentObject fontname];
    //NSLog(@"%@", fontname);
    MTFont *font = [[MTFont alloc] initWithFamilyName:[documentObject fontname] andPointSize:[[documentObject fontsize] floatValue] isBold:[[documentObject bold] boolValue] isItalic:[[documentObject italic] boolValue]];
    CTFontRef customFont = [font coreTextFont];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    CTTextAlignment alignment;
    switch ([[documentObject horizontalAlignment] integerValue]) {
        case MTHorizontalAlignmentLeft:
            alignment = kCTLeftTextAlignment;
            break;
        case MTHorizontalAlignmentRight:
            alignment = kCTRightTextAlignment;
            break;
        case MTHorizontalAlignmentCenter:
            alignment = kCTCenterTextAlignment;
            break;
        case MTHorizontalAlignmentJustified:
            alignment = kCTJustifiedTextAlignment;
            break;
        case MTHorizontalAlignmentNatrual:
            alignment = kCTNaturalTextAlignment;
            break;
        default:
            alignment = kCTLeftTextAlignment;
            break;
    }
    
    CTParagraphStyleSetting altSettings[] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment},
    };
    
    CTParagraphStyleRef style;
    style = CTParagraphStyleCreate( altSettings, sizeof(altSettings) / sizeof(CTParagraphStyleSetting) );

    
    CFRelease(style);
    [font autorelease];
    NSNumber *underline = [[documentObject underline] boolValue] ? @(kCTUnderlineStyleSingle) : @(kCTUnderlineStyleNone);
    NSNumber *strikethough = [[documentObject strike] boolValue] ? @(kCTUnderlineStyleSingle) : @(kCTUnderlineStyleNone);
    NSDictionary *result = @{(NSString *)kCTFontAttributeName : (id)customFont,
                             (NSString *)kCTUnderlineStyleAttributeName : underline,
                             (NSString *)NSStrikethroughStyleAttributeName : strikethough,
                             (NSString *)kCTParagraphStyleAttributeName: [paragraphStyle autorelease]};
    CFRelease(customFont);
    return result;
    
}

- (id)sumObject:(id)obj1 andObject:(id)obj2 forType:(MTDataType)dataType {
    id result;
    switch (dataType) {
        case MTDataTypeBit:
            result = @([obj1 boolValue] + [obj2 boolValue]);
            break;
        case MTDataTypeFloat:
            result = @([obj1 floatValue] + [obj2 floatValue]);
            break;
        case MTDataTypeInteger:
            result = @([obj1 integerValue] + [obj2 integerValue]);
            break;
        case MTDataTypeNumber:
        case MTDataTypeDecimal:
        case MTDataTypeDouble:
            result = @([obj1 integerValue] + [obj2 doubleValue]);
            break;
        case MTDataTypeEnum:
        case MTDataTypeInt24:
            result = @([obj1 intValue] + [obj2 intValue]);
            break;
        case MTDataTypeLong:
            result = @([obj1 longValue] + [obj2 longValue]);
            break;
        case MTDataTypeLongLong:
            result = @([obj1 longLongValue] + [obj2 longLongValue]);
            break;
        case MTDataTypeShort:
            result = @([obj1 shortValue] + [obj2 shortValue]);
            break;
        case MTDataTypeBlob:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeString:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
        case MTDataTypeVarChar:
        default: {
            if ([obj1 isKindOfClass:[NSNumber class]]) {
                if ([obj2 isKindOfClass:[NSNumber class]]) {
                    result = @([obj2 doubleValue] + [obj1 doubleValue]);
                } else {
                    result = obj1;
                }
            } else {
                if ([obj1 isKindOfClass:[NSString class]] == NO || [obj1 length] <= 0) {
                    obj1 = @"";
                }
                if ([obj2 isKindOfClass:[NSString class]] == NO || [obj2 length] <= 0) {
                    obj2 = @"";
                }
                result = [obj1 stringByAppendingString:obj2];
            }
            break;
        }
    }
    return result;
}

- (id)divideObject:(id)obj1 andObject:(id)obj2 forType:(MTDataType)dataType {
    id result;
    switch (dataType) {
        case MTDataTypeBit:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 boolValue] / [obj2 boolValue]);
            break;
        case MTDataTypeFloat:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 floatValue] / [obj2 floatValue]);
            break;
        case MTDataTypeInteger:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 integerValue] / [obj2 integerValue]);
            break;
        case MTDataTypeNumber:
        case MTDataTypeDecimal:
        case MTDataTypeDouble:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 integerValue] / [obj2 doubleValue]);
            break;
        case MTDataTypeEnum:
        case MTDataTypeInt24:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 intValue] / [obj2 intValue]);
            break;
        case MTDataTypeLong:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 longValue] / [obj2 longValue]);
            break;
        case MTDataTypeLongLong:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 longLongValue] / [obj2 longLongValue]);
            break;
        case MTDataTypeShort:
            result = @([obj2 boolValue] == 0 ? 0 : [obj1 shortValue] / [obj2 shortValue]);
            break;
        case MTDataTypeBlob:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeString:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
        case MTDataTypeVarChar:
        default: {
            if ([obj1 isKindOfClass:[NSString class]] == NO) {
                obj1 = @"";
            }
            if ([obj2 isKindOfClass:[NSString class]]) {
                [obj1 removeCharactersInString:obj2];
                result = obj1;
            } else {
                obj1 = [NSString stringWithFormat:@"%@", obj1];
                [obj1 appendFormat:@"%@", obj2];
                result = obj1;
            }
            break;
        }
    }
    return result;
}

- (NSInteger)numberOfPages {
    if ([self cachedLayoutByPage] == nil) {
        [self cachePrintPageRenderDataForSize:[self printableRect].size];
    }
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
/*
- (NSDictionary *)rowDataForRow:(NSUInteger)row {
    return [[self cachedDataByReport] objectAtIndex:row];
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
*/
- (NSString *)printDynamicDocumentLabel:(RptqDocumentObjectLabelDataField *)documentObjectDataField forRow:(NSUInteger)row onPage:(NSUInteger)page {
    NSString *result = @"";
    RptqQueryField *queryField = [documentObjectDataField referencesQueryField];
    NSString * tableFieldKey = [queryField tableFieldKey];
    NSDictionary *rowData = [self rowDataForRow:row onPage:page];
    id value = [rowData objectForKey: tableFieldKey];
    MTDataType dataType = [[[queryField databaseSchemaField] dataType] integerValue];
    result = [[documentObjectDataField formattedString:dataType
                                       forValue:value] retain];
    return [result autorelease];
}

- (id)dataForCachedGroupData:(id)data andKeys:(NSArray *)keys {
    id resultData = nil;
    if ([data isKindOfClass:[NSArray class]]) {
        resultData = [data retain];
    } else {
        id subData = [[data objectForKey:[keys objectAtIndex:0]] retain];
        NSArray *subKeys = nil;
        if ([keys count] > 1) {
            NSRange range = NSMakeRange(1, [keys count] - 1);
            subKeys = [[[keys objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] retain] autorelease];
            resultData = [[self dataForCachedGroupData:subData andKeys:subKeys] retain];
        } else if ([keys count] == 1) {
            resultData = [subData retain];
        } else {
            resultData = [subData retain];
        }
        [subData release];
    }
    return [resultData autorelease];
}

- (void)prepareForDrawingPages:(NSRange)range {
    [self cachePrintPageRenderDataForSize:[self printableRect].size];
}

#pragma mark - Routines to cache the data

//  Data is cached by group, page, and report.

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize {
    [self cachePrintPageRenderDataForSize:printableSize onlyFirstPage:NO];
}

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage {

    RptqDocument *document = [RptqDocument activeDocument];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    UIManagedDocument *activeDocument = [[MTActiveDocument sharedDocument] activeDocument];
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL landscape = (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
    CGSize cachedSizeHorizontal = CGSizeFromString([standardUserDefaults stringForKey:@"MTCachedSizeHorizontal"]);
    CGSize cachedSizePortrait   = CGSizeFromString([standardUserDefaults stringForKey:@"MTCachedSizeVertical"]);
    BOOL cacheAgain = (landscape ? CGSizeEqualToSize(cachedSizeHorizontal, printableSize) : CGSizeEqualToSize(cachedSizePortrait, printableSize)) ||
                        [[activeDocument fileURL] isEqual:[standardUserDefaults objectForKey:@"MTCachedFileUrl"]] == NO;
    
    if (cacheAgain || [self didRefresh]) {
        if (landscape) {
            [standardUserDefaults setObject:NSStringFromCGSize(printableSize) forKey:@"MTCachedSizeHorizontal"];
        } else {
            [standardUserDefaults setObject:NSStringFromCGSize(printableSize) forKey:@"MTCachedSizeVertical"];
        }
        [standardUserDefaults setURL:[activeDocument fileURL] forKey:@"MTCachedFileUrl"];
        [standardUserDefaults synchronize];
        
        [self setDidRefresh:NO];
        [self setCachedPageSize:printableSize];
        [self setCachedPageRect:[self printableRect]];
        [self setPrintableSize:printableSize];
        
        [self setTemporaryCachedDetailCounter:0];

        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        //RptqQueryCache *queryCache = [query hasQueryCache];
        
        SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[query managedObjectContext]];
        for (RptqDocumentSection *sec in enumerator) {
            CGFloat layoutHight = [RptqDocumentSection layoutHeightForSection:sec];
            NSNumber *lh = [[NSNumber alloc] initWithFloat:layoutHight];
            [sec setLayoutHeight:lh];
            [lh release];
        }
        [enumerator release];
        
        NSMutableDictionary *cachedResultsForReport = [[NSMutableDictionary alloc] init];
        
        [[self temporaryLayoutByPage] removeAllObjects];
        [[self temporaryDataByPage] removeAllObjects];
        [self setPrintableSpaceUsedPageHeight:CGSizeZero.height];
        //NSMutableDictionary *rd = [[NSMutableDictionary alloc] initWithCapacity:[[queryCache hasQueryResultFields] count]];
        
        
        NSError *error = nil;
        NSArray *cachedResultsForReportSerialized = nil;
        NSString *name = [[[MTActiveDocument sharedDocument] activeDocument] name];

    
        if (name) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cachesPath = [paths lastObject];
            NSURL *cachesUrl = [NSURL fileURLWithPath:cachesPath isDirectory:YES];
            NSURL *url = [cachesUrl URLByAppendingPathComponent:name isDirectory:NO];

            error = nil;
            NSPropertyListFormat format;
            NSString *filePath = [url path];
            NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
            [inputStream open];
            cachedResultsForReportSerialized = [NSPropertyListSerialization propertyListWithStream:inputStream options:0 format:&format error:&error];
            [self setInputStream:inputStream];
            if (error) {
                NSLog(@"error: %@", error);
            }
        }
    
        
        NSSet *hasQueryGroups = [query hasQueryGroups];
        
        NSString *sortKey = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: sortKey ascending: YES];
        NSArray *sortedHasQueryGroups = [[hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]] retain];
        [self setSortedQueryGroups:sortedHasQueryGroups];
        [sortedHasQueryGroups release];
        
        NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
        
        for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
            
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            NSString *key = [queryGroup fieldNameQuery];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                                           ascending: sortAscending];
            [sortedSortDescriptorsGroup addObject:sortDescriptor];
            [sortDescriptor release];
        }
        
        [self setCachedSortedSortDescriptorsGroup:sortedSortDescriptorsGroup];

        //Get unique, distinct, and sorted... slowly
        //NSDate *start = [NSDate date];

        NSArray *sortedArray = [cachedResultsForReportSerialized sortedArrayUsingDescriptors:[self cachedSortedSortDescriptorsGroup]];
//        NSArray *sortedResultsByRow = [[NSArray alloc] initWithArray:sortedArray];
        NSArray *sortedResultsByRow = [sortedArray retain];
        //start = [NSDate date];
        
        [self setCachedDataByReport:sortedResultsByRow];
        
        id groupedRows = [self cachedGroupedResults:sortedResultsByRow
                                         level:0];
        
        [self setPrintableSpaceUsedPageHeight: CGSizeZero.height];
        
        CGFloat printableSpaceUsed = [self printableSpaceUsedPageHeight] + [[[document hasPageHeaderSection] layoutHeight] floatValue];
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cachePageHeaderWithValueDictionary:groupedRows];

        printableSpaceUsed = [self printableSpaceUsedPageHeight] + [[[document hasReportHeaderSection] layoutHeight] floatValue];
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cacheReportHeaderWithValueDictionary:groupedRows];
        [sortedSortDescriptorsGroup release];

        BOOL detailPrinted = NO;
        
        
        RptqQueryGroup *firstGroup = [query firstQueryGroup];
        if (onlyFirstPage) {
            BOOL firstPageComplete = NO;
            [self cacheUntilFirstPageStartingWithGroup:firstGroup groupedRows:groupedRows groupedRowsLevel:0 detailPrinted:&detailPrinted firstPageComplete:&firstPageComplete];
        } else {
            [self cacheGroupLevel:firstGroup groupedRows:groupedRows groupedRowsLevel:0 detailPrinted:&detailPrinted];
        }
        
        CGFloat reportFooterHeight = [[[document hasReportFooterSection] layoutHeight] floatValue];
        
        [self cachePageBreakWithNextItemHeight: reportFooterHeight
                                   groupedRows: groupedRows];
        
        printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportFooterHeight;
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cacheReportFooterWithValueDictionary:groupedRows];
        
        CGFloat pageFooterHeight = [[[document hasPageFooterSection] layoutHeight] floatValue];
        
        printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageFooterHeight;
        [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
        [self cachePageFooterWithValueDictionary:groupedRows];
        
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
        [self setCachedDataByGroup: gr];
        [gr release];
        
        NSArray *tlbp = [[self temporaryLayoutByPage] retain];
        [self setCachedLayoutByPage: tlbp];
        [tlbp release];
        
        NSArray *tdbp = [[self temporaryDataByPage] retain];
        [self setCachedDataByPage: tdbp];
        [tdbp release];

        [cachedResultsForReport release];
        //[groupedRows release];
        [sortedResultsByRow release];
        [sortDescriptor release];

    }
    [[self inputStream] close];

}

// FIXME: Hack... this shit looks just like cacheGroupLevel
- (void)cacheUntilFirstPageStartingWithGroup:(RptqQueryGroup *)queryGroup groupedRows:(NSDictionary *)groupedRows groupedRowsLevel:(NSUInteger)groupedRowsLevel detailPrinted:(BOOL *)detailPrinted firstPageComplete:(BOOL *)firstPageComplete {
    
    if (*firstPageComplete == NO) {
        
        if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
            
            SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
            
            BOOL nullGroupExist = NO;
            NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys] copyItems:NO];
            for (id obj in allKeys) {
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *str = (NSString *)obj;
                    if ([str isEqualToString: @"(null)"]) {
                        nullGroupExist = YES;
                        break;
                    }
                }
            }
            if (nullGroupExist) {
                [allKeys removeObject:@"(null)"];
            }
            NSSortDescriptor *desc = [[[self cachedSortedSortDescriptorsGroup] objectAtIndex:groupedRowsLevel] retain];
            
            
            NSEnumerator *loopEnumerator = nil;
            
            if (sortSelector != nil) {
                NSMutableArray *allKeysSorted = [[NSMutableArray alloc] initWithArray:[allKeys sortedArrayUsingSelector:sortSelector] copyItems:NO];
                if (nullGroupExist) {
                    [allKeysSorted insertObject:@"(null)" atIndex:0];
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
                        *firstPageComplete = [self cachePageBreakWithNextItemHeight: [[documentSection layoutHeight] floatValue]
                                                                        groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection layoutHeight] floatValue];
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }
                
                //if (*firstPageComplete == NO) {
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
                        [self cachePageBreakWithNextItemHeight: [[documentSection layoutHeight] floatValue]
                                                   groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection layoutHeight] floatValue];
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }
                
                [self cacheGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                }
                //}
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
    
    if ([groupedRows isKindOfClass:[NSDictionary class]]) {     //May not be a dictionary if no results are returned or no groupings preformed... otherwise, detail
        
        SEL sortSelector = [[[queryGroup hasField] databaseSchemaField] selectorForSorting];
        
        BOOL nullGroupExist = NO;
        NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray: [groupedRows allKeys] copyItems:NO];
        for (id obj in allKeys) {
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *str = (NSString *)obj;
                if ([str isEqualToString: @"(null)"]) {
                    nullGroupExist = YES;
                    break;
                }
            }
        }
        if (nullGroupExist) {
            [allKeys removeObject:@"(null)"];
        }
        NSSortDescriptor *desc = [[[self cachedSortedSortDescriptorsGroup] objectAtIndex:groupedRowsLevel] retain];
        
        
        NSEnumerator *loopEnumerator = nil;
        
        if (sortSelector != nil) {
            NSMutableArray *allKeysSorted = [[NSMutableArray alloc] initWithArray:[allKeys sortedArrayUsingSelector:sortSelector] copyItems:NO];
            if (nullGroupExist) {
                [allKeysSorted insertObject:@"(null)" atIndex:0];
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
                    [self cachePageBreakWithNextItemHeight: [[documentSection layoutHeight] floatValue]
                                               groupedRows: groupedRows];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection layoutHeight] floatValue];
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
                    [self cachePageBreakWithNextItemHeight: [[documentSection layoutHeight] floatValue]
                                               groupedRows: groupedRows];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + [[documentSection layoutHeight] floatValue];
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

- (void)cacheDetailLevelWithDetails:(NSArray *)containerDetails
                        groupedRows:(NSDictionary *)groupedRows {

    RptqDocument *document = [RptqDocument activeDocument];
    RptqDocumentSection *detailSection = [document hasDetailSection];
    for (NSDictionary *resultDictionary in containerDetails) {
        
        [self cachePageBreakWithNextItemHeight: [[detailSection layoutHeight] floatValue]
                                   groupedRows: groupedRows];
        [self cacheDetailWithValueDictionary:resultDictionary];
        CGFloat printableHeightUsed = ([self printableSpaceUsedPageHeight] + [[detailSection layoutHeight] floatValue]);
        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
    }

}

//Roll through the groups
//Returns dictionary for group levels (level < n), and array of dictionaries for details/results (level == n-1).
- (id)cachedGroupedResults:(NSArray *)sortedResults level:(NSUInteger)level {
    
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
            if (valueForField == nil) {
                valueForField = @"(null)";
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
                key = @"(null)";
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

- (BOOL)cachePageBreakWithNextItemHeight:(CGFloat)nextItemHeight
                             groupedRows:(NSDictionary *)groupedRows {

    BOOL newPageCreated = NO;
    CGRect pageRect;
    RptqDocument *document = [RptqDocument activeDocument];
    CGFloat pageFooterSectionHeight = [[[document hasPageFooterSection] layoutHeight] floatValue];
    
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
        
        id layoutToAdd = [[self temporaryLayoutForPage] copy];
        [[self temporaryLayoutByPage] addObject:layoutToAdd];
        [layoutToAdd release];

        id dataToAdd = [[self temporaryDataForPage] copy];
        [[self temporaryDataByPage] addObject:dataToAdd];
        [dataToAdd release];
        
        [self setPrintableSpaceUsedPageHeight: (CGPointZero.y + [[[document hasPageHeaderSection] layoutHeight] floatValue])];

        [self cachePageHeaderWithValueDictionary:groupedRows];
        
    }
    return newPageCreated;
}

- (void)cachePageHeaderWithValueDictionary:(NSDictionary *)values {
    [[self temporaryLayoutForPage] removeAllObjects];
    [[self temporaryDataForPage] removeAllObjects];
    NSDictionary *d = @{MTReportSectionType : MTPageHeader};
    [[self temporaryLayoutForPage] addObject:  d];
}

- (void)cachePageFooterWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTPageFooter};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheReportHeaderWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTReportHeader};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheReportFooterWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTReportFooter};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheGroupHeaderWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    NSNumber *level = @(groupLevel);
    NSDictionary *d = @{MTReportSectionType : MTReportGroupHeader,
                        MTReportGroupLevel : level};
    [[self temporaryLayoutForPage] addObject: d];
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

@end
