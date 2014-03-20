//
//  MTPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerPrintPageRenderer.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "MTApplicationInstance.h"
#import "MAReportDocument.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "UIDevice+Hack.h"
#import "MTPaper.h"
#import "MTCache.h"
#import "RptqQuery+Extras.h"

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

//@property (nonatomic, assign) MAReportDocument *activeDocument;
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

@property (nonatomic, assign) BOOL showWaterMark;

@end

@implementation MTReportViewerPrintPageRenderer

- (void)dealloc {
    [_cachedLayoutByPage release];
    [_cachedSortedSortDescriptorsGroup release];
    [_cachedDataByPage release];
    [_cachedDataByGroup release];
    [_cachedDataByReport release];
    [_temporaryLayoutByPage release]; _temporaryLayoutByPage = nil;
    [_temporaryLayoutForPage release]; _temporaryLayoutForPage = nil;
    [_temporaryDataByPage release]; _temporaryDataByPage = nil;
    [_temporaryDataForPage release]; _temporaryDataForPage = nil;
    [_temporaryDataByGroup release]; _temporaryDataByGroup = nil;
    [_temporaryDataByReport release]; _temporaryDataByReport = nil;
    [_sortedQueryGroups release]; _sortedQueryGroups = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    MTReportViewerPrintPageRenderer *copy = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:nil];
    if (copy) {
        [copy setSortedQueryGroups:[self sortedQueryGroups]];
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
        [self initCommon];
    }
    return self;
}

- (void)initCommon {
    
    BOOL showWatermark = [MTStoreKitController licensedUser] == NO;
    [self setShowWaterMark: showWatermark];

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

- (id)initWithDocument:(MAReportDocument *)document {
    id result = [self initWithDocument:document andPrintableAreaSize:[MTPaper sizeLetter]];
    return [[result retain] autorelease];
}

- (id)initWithDocument:(MAReportDocument *)document andPrintableAreaSize:(CGSize)printableAreaSize {
    self = [super init];
    if (self) {
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

- (int)getRandomNumberBetween:(int)from to:(int)to {
    return (int)from + arc4random() % (to-from+1);
}

- (UIImage *)thumbnail {
    
    CGRect letterRect = [MTPaper rectLetter];
    CGFloat scale = [[UIScreen mainScreen] scale];
    BOOL isPad =[UIDevice isPad] ;
    CGFloat imageSizeTrue = isPad == YES ? 256.0000f * scale :
                                                        128.0000f * scale;
    
    CGFloat imageSizeWidth = (imageSizeTrue * 8.5000f) / 11.0000f;
    CGSize trueSize = CGSizeMake(imageSizeWidth, imageSizeTrue);
    CGRect zoomRect = CGRectMake(0.0000f, 0.0000f, trueSize.width, trueSize.height);
    CGRect pathRect = CGRectMake(zoomRect.origin.x, zoomRect.origin.y, zoomRect.size.width/scale, zoomRect.size.height/scale);
    // FIXME: Don't cache data for the whole report when just printing the first page for a
    //          fucking thumbnail.
    CGFloat startPointY = pathRect.origin.y + pathRect.size.height;
    CGPoint startPoint = CGPointMake(pathRect.origin.x, startPointY);
    CGFloat topRightPointX = pathRect.origin.x + pathRect.size.width;
    CGPoint topRightPoint = CGPointMake(topRightPointX, pathRect.origin.y);
    CGPoint bottomRightPoint = CGPointMake(topRightPointX, startPointY);
    
    [self cachePrintPageRenderDataForSize:letterRect.size onlyFirstPage:YES];
    UIGraphicsBeginImageContextWithOptions(letterRect.size, NO, 0.0000f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat cornerSize = (isPad ? 10.0000f : 5.0000f) * scale;
    CGMutablePathRef cornerPath = CGPathCreateMutable();
    CGPathMoveToPoint(cornerPath, NULL, startPoint.x, startPoint.y);
    CGPathAddLineToPoint(cornerPath, NULL, pathRect.origin.x, pathRect.origin.y);
    CGPathAddLineToPoint(cornerPath, NULL, topRightPoint.x, topRightPoint.y);
    CGPathAddLineToPoint(cornerPath, NULL, bottomRightPoint.x, bottomRightPoint.y - cornerSize);
    CGPathAddLineToPoint(cornerPath, NULL, bottomRightPoint.x - cornerSize, bottomRightPoint.y);
    CGPathAddLineToPoint(cornerPath, NULL, startPoint.x, startPoint.y);
    CGContextAddPath(context, cornerPath);
    CGContextClosePath (context);
    CGContextClip(context);
    CGPathRelease(cornerPath);

    CGMutablePathRef zigPath = CGPathCreateMutable();
    CGPathMoveToPoint(zigPath, NULL, startPoint.x, startPoint.y);
    CGPathAddLineToPoint(zigPath, NULL, pathRect.origin.x, pathRect.origin.y);
    CGPathAddLineToPoint(zigPath, NULL, topRightPoint.x, topRightPoint.y);
    //zig
    CGFloat zigDivisor = 4.0000f;
    int topRandNumber = 4;

    NSInteger numberOfZigs = pathRect.size.height / zigDivisor;
    for (NSInteger zigCounter = 0; zigCounter <= numberOfZigs; zigCounter++) {
        int zigNumber = [self getRandomNumberBetween: 0 to: topRandNumber];
        CGFloat zigReal = zigNumber / scale;
        CGFloat zigDistance = pow(zigNumber, 1.0001) + zigReal;
        CGFloat zigX = topRightPoint.x - zigDistance;
        CGFloat zigY = topRightPoint.y + (zigCounter * zigDivisor);
        CGPoint zigPoint = CGPointMake(zigX, zigY);
        CGPathAddLineToPoint(zigPath, NULL, zigPoint.x, zigPoint.y);
    }
    CGPathAddLineToPoint(zigPath, NULL, startPoint.x, startPoint.y);
    //CGContextClosePath (context);
    CGContextAddPath(context, zigPath);
    CGContextClip(context);
    CGPathRelease(zigPath);
    

    CGMutablePathRef zagPath = CGPathCreateMutable();
    CGPathMoveToPoint(zagPath, NULL, startPoint.x, startPoint.y);
    CGPathAddLineToPoint(zagPath, NULL, pathRect.origin.x, pathRect.origin.y);
    CGPathAddLineToPoint(zagPath, NULL, topRightPoint.x, topRightPoint.y);
    CGPathAddLineToPoint(zagPath, NULL, bottomRightPoint.x, bottomRightPoint.y);

    //zag
    CGFloat zagDivisor = 4.0000f;
    NSInteger numberOfZags = pathRect.size.height / zagDivisor;
    for (NSInteger zagCounter = 0; zagCounter <= numberOfZags; zagCounter++) {
        
        int zagNumber = [self getRandomNumberBetween: 0 to: topRandNumber];
        CGFloat zagReal = zagNumber / scale;
        CGFloat zagX = bottomRightPoint.x - (zagCounter * zagDivisor);
        CGFloat zagDistance = pow(zagNumber, 1.0001) + zagReal;
        CGFloat zagY = bottomRightPoint.y - zagDistance;
        CGPoint zagPoint = CGPointMake(zagX, zagY);
        CGPathAddLineToPoint(zagPath, NULL, zagPoint.x, zagPoint.y);
    }
    CGPathAddLineToPoint(zagPath, NULL, startPoint.x, startPoint.y);
    CGContextAddPath(context, zagPath);
    CGContextClip(context);
    CGPathRelease(zagPath);
    
    CGContextSaveGState(context);
    
    [self drawPageAtIndex:0 inRect:letterRect withTransparentBackground:YES];
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], zoomRect);

    UIImage *croppedImage = [[UIImage imageWithCGImage:imageRef] retain];
    CGImageRelease(imageRef);
    UIGraphicsEndImageContext();
    return [croppedImage autorelease];
}

#pragma mark - UIPrintPageRenderer Overrides


- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    [self drawPageAtIndex:index inRect:pageRect withTransparentBackground:NO];
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect withTransparentBackground:(BOOL)transparentBackground {
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setFill];
    CGPathRef path = CGPathCreateWithRect(pageRect, NULL);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);
    
    NSMutableArray *printableStrings = [[NSMutableArray alloc] init];
    
    CGFloat originY = pageRect.origin.y;
    CGFloat originX = pageRect.origin.x;
    CGFloat sizeWidth = pageRect.size.width;
    
    NSUInteger detailRowsCounter = 0;
    NSUInteger pageNumber = 0;
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *activeDocument = [applicationInstance activeDocument];
    RptqDocument *document = [activeDocument activeDocument];
    RptqDatabase *databaseSchemas = [[document hasDatabaseSchemas] anyObject];
    RptqUserCredentals *userCredentals = [databaseSchemas ownedByUser];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection credentalsFromRptqCredentals:userCredentals];
    MTDatabase *database = [MTDatabase databaseFactory:databaseConnection];
    RptqQuery *query = [[databaseSchemas hasQueries] anyObject];
    
    if (query) {
        NSUInteger numberOfGroups = [[query hasQueryGroups] count];
        NSMutableArray *groupLevelKeys = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        NSMutableArray *nextGroupLevelKeys = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        
        NSUInteger numberOfPages = [[self cachedLayoutByPage] count];
        
        if (index < numberOfPages) {
            
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
                        BOOL lastPage = index == numberOfPages - 1;
                        if (lastPage) {
                            RptqDocumentSection *pageFooterSection = [document hasReportFooterSection];
                            CGFloat sizeHeightReportFooter = [[pageFooterSection layoutHeight] floatValue];
                            originY = pageRect.origin.y + pageRect.size.height - sectionHeight - sizeHeightReportFooter;
                        } else {
                            originY = pageRect.origin.y + pageRect.size.height - sectionHeight;
                            pageNumber++;
                        }
                        [whiteColor setFill];
                        
                    } else if ([MTReportHeader isEqualToString:pageSectionId]) {

                        documentSection = [document hasReportHeaderSection];
                        [whiteColor setFill];
                        
                    } else if ([MTReportFooter isEqualToString:pageSectionId]) {
                        
                        documentSection = [document hasReportFooterSection];
                        CGFloat sizeHeightReportFooter = [[documentSection layoutHeight] floatValue];
                        originY = pageRect.origin.y + pageRect.size.height - sizeHeightReportFooter;
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
                    BOOL sectionIsVisible = [[documentSection visibility] boolValue];
                    CGFloat sizeHeight = sectionIsVisible ? [RptqDocumentSection layoutHeightForSection:documentSection] : CGSizeZero.height;
                    sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                    
                    if (sectionIsVisible) {
                        UIBezierPath *bezierPathForSection = [UIBezierPath bezierPathWithRect:sectionRect];
                        [bezierPathForSection fill];
                    }

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
                    
                    [groupLevelKeys removeAllObjects];
                    [nextGroupLevelKeys removeAllObjects];
                    if (rowData != nil) {
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
                    }

                    if (sectionIsVisible) {
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
                                            
                                            NSString *fieldKey = [database safeQueryField:queryField];
                                            
                                            RptqDatabaseSchemaField *databaseSchemaField = [queryField databaseSchemaField];
                                            NSNumber *databaseSchemaFieldDataType = [databaseSchemaField dataType];
                                            MTDataType aggregateType = [databaseSchemaFieldDataType integerValue];
                                            id aggregateResult = nil;
                                            switch ([[aggregateField function] integerValue]) {
                                                    
                                                case MTAggregateFunctionTypeCount:
                                                    aggregateResult = @([dataForGroup count]);
                                                    break;
                                                    
                                                case MTAggregateFunctionTypeFirst:
                                                    if ([dataForGroup count] >= 1) {
                                                        aggregateResult = [[dataForGroup objectAtIndex:0] objectForKey:fieldKey];
                                                    } else {
                                                        aggregateResult = @"";
                                                    }
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
                                            if ([displayString isEqualToString:@"(null)"]) {
                                                displayString = @"";
                                            }
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeImage: {
                                            drawingObject = [[[item isImage] image] retain];
                                            displayString = @"";
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeBarcode: {
                                            
                                            RptqDocumentObjectBarcode *barcodeObject = [item isBarcode];
                                            RptqQueryField *queryField1 = [[barcodeObject referencesField1] retain];
                                            RptqQueryField *queryField2 = [[barcodeObject referencesField2] retain];
                                            
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

                                            NSString *tableFieldKey1 = [database safeQueryField:queryField1];
                                            NSString *tableFieldKey2 = [database safeQueryField:queryField2];
                                            id value1 = [rd objectForKey: tableFieldKey1];
                                            id value2 = [rd objectForKey: tableFieldKey2];
                                            RptqDatabaseSchemaField *schemaField1 = [queryField1 databaseSchemaField];
                                            RptqDatabaseSchemaField *schemaField2 = [queryField2 databaseSchemaField];
                                            NSNumber *dataTypeNumber1 = [schemaField1 dataType];
                                            NSNumber *dataTypeNumber2 = [schemaField2 dataType];
                                            MTDataType dataType1 = [dataTypeNumber1 integerValue];
                                            MTDataType dataType2 = [dataTypeNumber2 integerValue];
                                            NSString *input1 = [item formattedString:dataType1 forValue:value1];
                                            if ([input1 isEqualToString:@"(null)"]) {
                                                input1 = @"";
                                            }
                                            NSString *input2 = [item formattedString:dataType2 forValue:value2];
                                            if ([input2 isEqualToString:@"(null)"]) {
                                                input2 = @"";
                                            }
                                            MTBarcode *barcode = [[RptqDocumentObjectBarcode barcodeWithDocumentObject:barcodeObject] retain];
                                            
                                            [barcode setInput:              input1];
                                            [barcode setPrimaryData:        input2];
                                            drawingObject = [barcode retain];
                                            [barcode release];
                                            [queryField1 release];
                                            [queryField2 release];
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeLabelDynamic: {
                                            if (rowData != nil) {
                                                RptqDocumentObjectLabelDataField *labelDataField = [item isLabelDataField];
                                                RptqQueryField *queryField = [labelDataField referencesQueryField];

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
                                                
                                                NSString *tableFieldKey = [database safeQueryField:queryField];
                                                id value = [rd objectForKey: tableFieldKey];
                                                RptqDatabaseSchemaField *schemaField = [queryField databaseSchemaField];
                                                NSNumber *dataTypeNumber = [schemaField dataType];
                                                MTDataType dataType = [dataTypeNumber integerValue];
                                                displayString = [item formattedString:dataType forValue:value];
                                                if ([displayString isEqualToString:@"(null)"]) {
                                                    displayString = @"";
                                                }
                                            } else {
                                                displayString = @"";
                                            }
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
                                    
                                    CGFloat originPointXPadding = originPointX + [[item paddingLeft] floatValue] + [[item marginLeft] floatValue];
                                    CGFloat originPointYPadding = originPointY + [[item paddingTop] floatValue] + [[item marginTop] floatValue];
                                    
                                    CGFloat sizeWidthPadding = [[item sizewidth] floatValue] + [[item paddingRight] floatValue] + [[item marginRight] floatValue];
                                    CGFloat sizeHeightPadding = [[item sizeheight] floatValue] + [[item paddingBottom] floatValue] + [[item marginBottom] floatValue];
                                    
                                    
                                    //CGRect paddingFrame = [item paddingViewFrame];
                                    CGRect elementCanvasRect = CGRectMake(originPointXPadding, originPointYPadding, sizeWidthPadding, sizeHeightPadding);
                                    
                                    if (drawingObject == nil) {
                                        
                                        NSDictionary *attributes = [self attributesForDocumentObject:item];
                                        
                                        // FIXME: This hack gets around known iOS7 bug.
                                        //          Want to draw the fucking rect without
                                        //          having to do a fucking translation.
                                        
                                        CGContextSaveGState(ctx);
                                        {
                                            CGContextTranslateCTM(ctx, elementCanvasRect.origin.x, elementCanvasRect.origin.y);
                                            CGRect drawingRect = CGRectMake(0.0000f, 0.0000f, elementCanvasRect.size.width, elementCanvasRect.size.height);
                                            NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;
                                            [displayString drawWithRect:drawingRect options:options attributes:attributes context:nil];
                                        }
                                        CGContextRestoreGState(ctx);
                                        
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
            [whiteColor release];
        }
        
        [nextGroupLevelKeys release];
        [groupLevelKeys release];
    }


    if ([self showWaterMark]) {
        [self drawWatermarkWithContext:ctx inPageRect:pageRect];
    }

    [printableStrings release];
}

- (void)drawWatermarkWithContext:(CGContextRef)ctx inPageRect:(CGRect)pageRect {

    UIFont *customFont = [UIFont boldSystemFontOfSize:12.0000f];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    UIColor *strokeColor = [UIColor colorWithRed:170.0000f/256.0000f green:170.0000f/256.0000f blue:170.0000f/256.0000f alpha:0.8000f];
    UIColor *foregroundColor = [UIColor colorWithRed:85.0000f/256.0000f green:85.0000f/256.0000f blue:85.0000f/256.0000f alpha:0.8000f];
    NSNumber *strokeWidth = @(3.0000f);
    NSDictionary *results = @{NSFontAttributeName : customFont,
                              NSStrokeWidthAttributeName : strokeWidth,
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

- (NSDictionary *)attributesForDocumentObject:(RptqDocumentObject *)documentObject {
    MTFont *font = [[MTFont alloc] initWithFamilyName:[documentObject fontname] andPointSize:[[documentObject fontsize] floatValue] isBold:[[documentObject bold] boolValue] isItalic:[[documentObject italic] boolValue]];
    UIFont *customFont = [font font];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];

    // ???: Where is NSLineBreakByClipping in iOS7... There attributed string is buggy as fuck.
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
            if (cachedDataIndex < [[self cachedDataByReport] count]) {
                rowData = [[self cachedDataByReport] objectAtIndex:cachedDataIndex];
            }
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

- (id)dataForCachedGroupData:(id)data andKeys:(NSArray *)keys {
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
                resultData = [[self dataForCachedGroupData:subData andKeys:subKeys] retain];
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

- (void)prepareForDrawingPages:(NSRange)range {
    [self cachePrintPageRenderDataForSize:[self printableRect].size];
}

#pragma mark - Routines to cache the data

//  Data is cached by group, page, and report.

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize {
    [self cachePrintPageRenderDataForSize:printableSize onlyFirstPage:NO];
}

- (void)cachePrintPageRenderDataForSize:(CGSize)printableSize onlyFirstPage:(BOOL)onlyFirstPage {

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    // FIXME: This is overriding the user set document....
    //          Maybe this whole fucking class should somehow be related to the document modal
    //          MAYBE@!@!!@!!!!  That way it only prints its fucking self.  There, I said it.
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *activeDocument = [applicationInstance activeDocument];
    if (activeDocument) {


        RptqDocument *document = [activeDocument activeDocument];
        
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
            RptqUserCredentals *userCredentals = [database ownedByUser];
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection credentalsFromRptqCredentals:userCredentals];
            MTDatabase *madDatabase = [MTDatabase databaseFactory:databaseConnection];
            
            NSSet *hasQueries = [database hasQueries];
            RptqQuery *query = [hasQueries anyObject];
            
            SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithDocument:document];
            
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
            
            NSURL *url = [[activeDocument cachedDataUrl] retain];
            
            MTCache *cache = [[MTCache alloc] initWithUrl:url];
            NSArray *cachedResultsForReportSerialized = [cache results];
            
            
            NSSet *hasQueryGroups = [query hasQueryGroups];
            
            NSString *sortKey = NSStringFromSelector(@selector(weight));
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: sortKey ascending: YES];
            NSArray *sortedHasQueryGroups = [[hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]] retain];
            [self setSortedQueryGroups:sortedHasQueryGroups];
            [sortedHasQueryGroups release];
            
            NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
            
            for (RptqQueryGroup *queryGroup in sortedHasQueryGroups) {
                
                BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
                RptqQueryField *groupField = [queryGroup hasField];
                
                NSString *queryTable = [[groupField inQueryTable] queryAlias];
                NSString *safeQueryTable = [madDatabase safeIdentifier:queryTable];
                NSString *fieldName = [[groupField databaseSchemaField] name];
                NSString *safeFieldName = [madDatabase safeIdentifier:fieldName];
                NSString *key = [NSString stringWithFormat:@"%@.%@", safeQueryTable, safeFieldName];
                
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
            
            id groupedRows = [self cachedGroupedResults:sortedResultsByRow level:0];
            
            [self setPrintableSpaceUsedPageHeight: CGSizeZero.height];
            
            //Report Header
            RptqDocumentSection *reportHeaderSection = [document hasReportHeaderSection];
            BOOL reportHeaderIsVisable = [[reportHeaderSection visibility] boolValue];
            CGFloat reportHeaderHeight = reportHeaderIsVisable ? [[reportHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
            CGFloat printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportHeaderHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cacheReportHeaderWithValueDictionary:groupedRows];
            
            //First Page Header
            RptqDocumentSection *pageHeaderSection = [document hasPageHeaderSection];
            BOOL pageHeaderIsVisable = [[pageHeaderSection visibility] boolValue];
            CGFloat pageHeaderHeight = pageHeaderIsVisable ? [[pageHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
            printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageHeaderHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cachePageHeaderWithValueDictionary:groupedRows];
            
            [sortedSortDescriptorsGroup release];
            
            BOOL detailPrinted = NO;
            
            RptqQueryGroup *firstGroup = [query firstQueryGroup];
            if (onlyFirstPage) {
                BOOL firstPageComplete = NO;
                [self cacheUntilFirstPageStartingWithGroup:firstGroup groupedRows:groupedRows groupedRowsLevel:0 detailPrinted:&detailPrinted firstPageComplete:&firstPageComplete];
            } else {
                [self cacheGroupLevel:firstGroup groupedRows:groupedRows groupedRowsLevel:0 detailPrinted:&detailPrinted];
            }
            
            RptqDocumentSection *reportFooter = [document hasReportFooterSection];
            BOOL reportFooterIsVisible = [[reportFooter visibility] boolValue];
            CGFloat reportFooterHeight = reportFooterIsVisible ? [[reportFooter layoutHeight] floatValue] : CGSizeZero.height;
            
            [self cachePageBreakWithNextItemHeight: reportFooterHeight
                                       groupedRows: groupedRows];
            
            
            RptqDocumentSection *pageFooterSection = [document hasPageFooterSection];
            BOOL pageFooterIsVisible = [[pageFooterSection visibility] boolValue];
            CGFloat pageFooterHeight = pageFooterIsVisible ? [[pageFooterSection layoutHeight] floatValue] : CGSizeZero.height;
            
            printableSpaceUsed = [self printableSpaceUsedPageHeight] + pageFooterHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cachePageFooterWithValueDictionary:groupedRows];
            
            
            printableSpaceUsed = [self printableSpaceUsedPageHeight] + reportFooterHeight;
            [self setPrintableSpaceUsedPageHeight: printableSpaceUsed];
            [self cacheReportFooterWithValueDictionary:groupedRows];
            
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

            [url autorelease];
            [tdbp release];
            
            [cachedResultsForReport release];
            [cache release];
            [sortedResultsByRow release];
            [sortDescriptor release];
            
        }
        
    }


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
                        BOOL isVisible = [[documentSection visibility] boolValue];
                        CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                        *firstPageComplete = [self cachePageBreakWithNextItemHeight: layoutHeight
                                                                        groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }
                
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
                        BOOL isVisible = [[documentSection visibility] boolValue];
                        CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                        [self cachePageBreakWithNextItemHeight: layoutHeight groupedRows: groupedRows];
                        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
                        [self setPrintableSpaceUsedPageHeight: printableHeightUsed];
                        break;
                    }
                }
                
                [self cacheGroupFooterWithValueDictionary:obj andLevel:groupedRowsLevel];
                
                }

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
                    BOOL isVisible = [[documentSection visibility] boolValue];
                    CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                    [self cachePageBreakWithNextItemHeight: layoutHeight
                                               groupedRows: groupedRows];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
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
                    BOOL isVisible = [[documentSection visibility] boolValue];
                    CGFloat layoutHeight = isVisible ? [[documentSection layoutHeight] floatValue] : CGSizeZero.height;
                    [self cachePageBreakWithNextItemHeight: layoutHeight groupedRows: groupedRows];
                    CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
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

    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *activeDocument = [applicationInstance activeDocument];
    RptqDocument *document = [activeDocument activeDocument];
    RptqDocumentSection *detailSection = [document hasDetailSection];
    BOOL isVisible = [[detailSection visibility] boolValue];
    CGFloat layoutHeight = isVisible ? [[detailSection layoutHeight] floatValue] : CGSizeZero.height;
    for (NSDictionary *resultDictionary in containerDetails) {
        [self cachePageBreakWithNextItemHeight: layoutHeight groupedRows: groupedRows];
        [self cacheDetailWithValueDictionary:resultDictionary];
        CGFloat printableHeightUsed = [self printableSpaceUsedPageHeight] + layoutHeight;
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
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *activeDocument = [applicationInstance activeDocument];
    RptqDocument *document = [activeDocument activeDocument];
    RptqDocumentSection *pageFooterSection = [document hasPageFooterSection];
    BOOL pageFooterIsVisable = [[pageFooterSection visibility] boolValue];
    CGFloat pageFooterSectionHeight = pageFooterIsVisable ? [[pageFooterSection layoutHeight] floatValue] : CGSizeZero.height;
    
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
        
        [[self temporaryLayoutForPage] removeAllObjects];
        [[self temporaryDataForPage] removeAllObjects];
        
        RptqDocumentSection *pageHeaderSection = [document hasPageHeaderSection];
        BOOL pageHeaderIsVisable = [[pageHeaderSection visibility] boolValue];
        CGFloat pageHeaderHeight = CGPointZero.y;
        pageHeaderHeight += pageHeaderIsVisable ? [[pageHeaderSection layoutHeight] floatValue] : CGSizeZero.height;
        [self setPrintableSpaceUsedPageHeight: pageHeaderHeight];
        [self cachePageHeaderWithValueDictionary:groupedRows];
        
    }
    return newPageCreated;
}

- (void)cachePageHeaderWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTPageHeader};
    [[self temporaryLayoutForPage] addObject:  d];
}

- (void)cachePageFooterWithValueDictionary:(NSDictionary *)values {
    NSDictionary *d = @{MTReportSectionType : MTPageFooter};
    [[self temporaryLayoutForPage] addObject: d];
}

- (void)cacheReportHeaderWithValueDictionary:(NSDictionary *)values {
    [[self temporaryLayoutForPage] removeAllObjects];
    [[self temporaryDataForPage] removeAllObjects];
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
