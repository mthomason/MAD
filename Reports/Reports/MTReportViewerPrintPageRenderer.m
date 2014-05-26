//
//  MTPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportViewerPrintPageRenderer.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "MTApplicationInstance.h"
#import "MAReportDocument.h"
#import "MTDatabaseField.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"

#import "RptqDatabase.h"
#import "RptqQueryField.h"
#import "RptqUserCredentals.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentSectionRows.h"

#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectBarcode.h"

#import "RptqDocumentObjectBarcode+Extras.h"

#import "RptqDatabaseSchemaField.h"

#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectImage.h"

#import "MTStoreKitController+NonRenewableLicensing.h"
#import "UIDevice+Hack.h"
#import "MTPaper.h"
#import "RptqQuery+Extras.h"

#import "MTReportFormatter.h"
#import "MTQuery.h"
#import "MTDataTable.h"

#import "MTBarcode.h"
#import "MTFont.h"

@interface MTReportViewerPrintPageRenderer ()


@property (nonatomic, strong) MTReportFormatter *reportFormatter;

@property (nonatomic, assign) NSUInteger temporaryCachedDetailCounter;

@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;
@property (nonatomic, assign) CGSize printableSize;
@property (nonatomic, assign) CGSize cachedPageSize;
@property (nonatomic, assign) CGRect cachedPageRect;
@property (nonatomic, assign) BOOL showWaterMark;
@property (nonatomic, assign) BOOL debugMode;

@end

@implementation MTReportViewerPrintPageRenderer

- (id)initWithReportFormatter:(MTReportFormatter *)reportFormatter {
    return [self initWithReportFormatter:reportFormatter andPrintableAreaSize:[MTPaper sizeLetter]];
}

- (id)initWithReportFormatter:(MTReportFormatter *)reportFormatter andPrintableAreaSize:(CGSize)printableAreaSize {
    self = [super init];
    if (self) {
        [self initCommon];
        [self setPrintableSize:printableAreaSize];
        [self setReportFormatter:reportFormatter];
    }
    return self;
}

- (void)initCommon {
    
    BOOL showWatermark = [MTStoreKitController licensedUser] == NO;
    [self setShowWaterMark: showWatermark];
    
    [self setDebugMode:NO];

    [self setCachedPageSize:CGSizeZero];
    [self setCachedPageRect:CGRectZero];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([standardUserDefaults valueForKey:@"MTCachedSizeHorizontal"] == nil) {

        [standardUserDefaults setObject:NSStringFromCGSize(CGSizeZero) forKey:@"MTCachedSizeHorizontal"];
        [standardUserDefaults setObject:NSStringFromCGSize(CGSizeZero) forKey:@"MTCachedSizeVertical"];
        [standardUserDefaults synchronize];
    }
}

- (void)writeToPdf:(NSURL *)filepath {
    NSDictionary *options = @{(NSString *)kCGPDFContextCreator :  @"Mad Designer"};
    CGRect letterRect = [MTPaper rectLetter];
    [[self reportFormatter] formatForSize:letterRect.size];
    NSUInteger numberOfPages = [[self reportFormatter] numberOfPages];
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

- (NSInteger)numberOfPages {
    return [[self reportFormatter] numberOfPages];
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

    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    UIGraphicsEndImageContext();
    return croppedImage;
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

    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *activeDocument = [applicationInstance activeDocument];
    RptqDocument *document = [activeDocument activeDocument];

    if (document) {
        [self drawPageAtIndex:index ofDocument:document withContext:ctx inPageRect:pageRect];
    }
    
    if ([self showWaterMark]) {
        [self drawWatermarkWithContext:ctx inPageRect:pageRect];
    }

}

- (void)setBackgroundColorForDocumentSection:(RptqDocumentSection *)documentSection {
    [[UIColor whiteColor] setFill];
}


- (void)drawPageAtIndex:(NSInteger)pageIndex ofDocument:(RptqDocument *)document withContext:(CGContextRef)ctx inPageRect:(CGRect)pageRect {

    NSMutableDictionary *dataCacheForPage = [[NSMutableDictionary alloc] init];
    
    NSUInteger rowIndex = 0, pageNumber = 0;
    
    RptqDatabase *databaseSchemas = [[document hasDatabaseSchemas] anyObject];
    RptqUserCredentals *userCredentals = [databaseSchemas ownedByUser];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
    MTDatabase *database = [MTDatabase databaseFactory:databaseConnection];
    RptqQuery *query = [[databaseSchemas hasQueries] anyObject];
    
    if (query) {
        NSUInteger numberOfGroups = [[query hasQueryGroups] count];
        NSMutableArray *groupLevelKeys = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        BOOL groupLevelKeySet = NO;
        NSUInteger numberOfPages = [[self reportFormatter] numberOfPages];
        
        if (pageIndex < numberOfPages) {
            
            CGFloat originY = pageRect.origin.y;
            CGFloat originX = pageRect.origin.x;
            CGFloat sizeWidth = pageRect.size.width;
            
            NSInteger layoutSectionCounter = 0;
            NSInteger readGroupIndex = 0;
            NSArray *groupData = nil;
            
            NSEnumerator *dataForPageIndexEnumerator = [[self reportFormatter] dataForPageIndex:pageIndex];
            for (NSDictionary *pageSection in [[self reportFormatter] layoutEnumeratorForPage:pageIndex]) {
                
                @autoreleasepool {
                    
                    NSInteger groupLevel = [[pageSection objectForKey:MTReportGroupLevel] integerValue];
                    
                    MNSDocumentSectionType typeDocumentSection = [[pageSection objectForKey: MTReportSectionType] integerValue];
                    RptqDocumentSection *documentSection = [RptqDocumentSection RptqDocumentSectionForDocument:document andType:typeDocumentSection andLevel:groupLevel];
                    BOOL sectionIsVisible = [[documentSection visibility] boolValue];

                    switch (typeDocumentSection) {
                            
                        case MNSDocumentSectionTypePageFooter: {
                            CGFloat sectionHeight = [[documentSection layoutHeight] floatValue];
                            BOOL lastPage = pageIndex == numberOfPages - 1;
                            if (lastPage) {
                                originY = pageRect.origin.y + pageRect.size.height - sectionHeight - [[[document hasReportFooterSection] layoutHeight] floatValue];
                            } else {
                                originY = pageRect.origin.y + pageRect.size.height - sectionHeight;
                                pageNumber++;
                            }
                            break;
                        }

                        case MNSDocumentSectionTypeReportFooter:
                            originY = pageRect.origin.y + pageRect.size.height - [[documentSection layoutHeight] floatValue];
                            break;
                        
                        default:
                            break;
                    }
                    
                    if (typeDocumentSection != MNSDocumentSectionTypeBody) readGroupIndex = 0;
                    NSInteger readRowIndex = rowIndex;
                    NSInteger readPageIndex = pageIndex;
                    CGFloat sizeHeight = sectionIsVisible ? [RptqDocumentSection layoutHeightForSection:documentSection] : CGSizeZero.height;
                    CGRect sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                    
                    NSDictionary *rowData = nil;
                
                    if (numberOfGroups > 0) {
                        
                        if ([groupLevelKeys count] < numberOfGroups) {
                            [groupLevelKeys removeAllObjects];
                            NSArray *keys = [self groupLevelKeysForPage:readPageIndex row:layoutSectionCounter numberOfGroups:numberOfGroups andSection:pageSection];
                            [groupLevelKeys addObjectsFromArray:keys];
                            groupLevelKeySet = YES;
                        }
                        
                        NSMutableString *groupKey = [[NSMutableString alloc] init];
                        for (id key in groupLevelKeys) {
                            NSString *safeKey = nil;
                            if ([key isEqual: [NSNull null]]) {
                                safeKey = MTNullIdentifier;
                            }
                            if ([key isKindOfClass:[NSString class]] == NO) {
                                safeKey = [NSString stringWithFormat:@"%@", safeKey];
                            } else {
                                safeKey = key;
                            }
                            [groupKey appendString:([safeKey isEqual: [NSNull null]]) ? MTNullIdentifier : safeKey];
                        }
                        NSNumber *hash = @([groupKey hash]);
                        
                        id data = [dataCacheForPage objectForKey:hash];
                        if (data == nil) {
                            data = [[self reportFormatter] dataForGroupKeys:groupLevelKeys];
                        }
                        [dataCacheForPage setObject:data forKey:hash];
                        if ([data isKindOfClass:[NSDictionary class]]) {
                            
                            rowData = [NSDictionary dictionaryWithDictionary:data];
                            
                        } else {
                            groupData = [NSArray arrayWithArray: data];
                            rowData = [data firstObject];
                        }
                        
                        if (typeDocumentSection == MNSDocumentSectionTypeBody) {
                            if (readGroupIndex < [groupData count]) {
                                rowData = [dataForPageIndexEnumerator nextObject];
                            }
                            readGroupIndex++;
                        }

                    } else {
                        rowData = [dataForPageIndexEnumerator nextObject];
                    }
                    
                    if (sectionIsVisible) {
                        for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                            
                            for (RptqDocumentObject *item in [row hasObjects]) {
                                
                                @autoreleasepool {
                                    
                                    NSMutableString *displayString = [NSMutableString new];
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
                                                    
                                                    NSUInteger pageIndicesCount = [[self reportFormatter] countOnPageIndex:pageIndex];
                                                    dataForGroup = [[NSMutableArray alloc] initWithCapacity:pageIndicesCount];
                                                    NSIndexSet *indexSet = [[self reportFormatter] objectEnumeratorForPage:pageIndex];
                                                    
                                                    NSArray *objectsToAdd = [[[[self reportFormatter] query] datatable] objectAtRow: [indexSet firstIndex]
                                                                                                                              limit: [indexSet count]];
                                                    
                                                    [(NSMutableArray *)dataForGroup addObjectsFromArray:objectsToAdd];
                                                    break;
                                                }
                                                case MTAggregateGroupByTypeSection: {
                                                    dataForGroup = [[self reportFormatter] dataForGroupKeys:groupLevelKeys];
                                                    break;
                                                }
                                                case MTAggregateGroupByTypeReport:
                                                    dataForGroup = [[[[self reportFormatter] query] datatable] allObjects];
                                                    break;
                                                    
                                                default:
                                                    dataForGroup = [[[[self reportFormatter] query] datatable] allObjects];
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
                                            
                                            [displayString setString: [item formattedString:aggregateType
                                                                         forValue:aggregateResult]];
                                            if ([displayString isEqualToString:MTNullIdentifier]) {
                                                [displayString setString: @""];
                                            }
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeImage: {
                                            drawingObject = [[item isImage] image];
                                            [displayString setString: @""];
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeBarcode: {
                                            
                                            RptqDocumentObjectBarcode *barcodeObject = [item isBarcode];
                                            RptqQueryField *queryField1 = [barcodeObject referencesField1];
                                            RptqQueryField *queryField2 = [barcodeObject referencesField2];
                                            NSString *tableFieldKey1 = [database safeQueryField:queryField1];
                                            NSString *tableFieldKey2 = [database safeQueryField:queryField2];
                                            id value1 = [rowData objectForKey: tableFieldKey1];
                                            id value2 = [rowData objectForKey: tableFieldKey2];
                                            RptqDatabaseSchemaField *schemaField1 = [queryField1 databaseSchemaField];
                                            RptqDatabaseSchemaField *schemaField2 = [queryField2 databaseSchemaField];
                                            NSNumber *dataTypeNumber1 = [schemaField1 dataType];
                                            NSNumber *dataTypeNumber2 = [schemaField2 dataType];
                                            MTDataType dataType1 = [dataTypeNumber1 integerValue];
                                            MTDataType dataType2 = [dataTypeNumber2 integerValue];
                                            NSString *input1 = [item formattedString:dataType1 forValue:value1];
                                            if ([input1 isEqualToString:MTNullIdentifier]) {
                                                input1 = @"";
                                            }
                                            NSString *input2 = [item formattedString:dataType2 forValue:value2];
                                            if ([input2 isEqualToString:MTNullIdentifier]) {
                                                input2 = @"";
                                            }
                                            MTBarcode *barcode = [RptqDocumentObjectBarcode barcodeWithDocumentObject:barcodeObject];
                                            
                                            [barcode setInput:              input1];
                                            [barcode setPrimaryData:        input2];
                                            drawingObject = barcode;
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeLabelDynamic: {
                                            if (rowData != nil) {
                                                RptqDocumentObjectLabelDataField *labelDataField = [item isLabelDataField];
                                                RptqQueryField *queryField = [labelDataField referencesQueryField];
                                                NSString *tableFieldKey = [database safeQueryField:queryField];
                                                id value = [rowData objectForKey: tableFieldKey];
                                                RptqDatabaseSchemaField *schemaField = [queryField databaseSchemaField];
                                                NSNumber *dataTypeNumber = [schemaField dataType];
                                                MTDataType dataType = [dataTypeNumber integerValue];
                                                [displayString setString: [item formattedString:dataType forValue:value]];
                                                if ([displayString isEqualToString:MTNullIdentifier]) {
                                                    [displayString setString: @""];
                                                }
                                            } else {
                                                [displayString setString: @""];
                                            }
                                            break;
                                        }
                                            
                                        case MTDocumentObjectTypeLabelStatic: {
                                            [displayString setString: [[item isLabel] text]];
                                            break;
                                        }
                                            
                                        default: {
                                            [displayString setString: @""];
                                            break;
                                        }
                                    }
                                    
                                    CGFloat originPointX        = [[item dropPointX] floatValue] + sectionRect.origin.x;
                                    CGFloat originPointY        = [[item dropPointY] floatValue] + sectionRect.origin.y;
                                    
                                    CGFloat originPointXPadding = originPointX + [[item paddingLeft] floatValue] + [[item marginLeft] floatValue];
                                    CGFloat originPointYPadding = originPointY + [[item paddingTop] floatValue] + [[item marginTop] floatValue];
                                    
                                    CGFloat sizeWidthPadding = [[item sizewidth] floatValue] + [[item paddingRight] floatValue] + [[item marginRight] floatValue];
                                    CGFloat sizeHeightPadding = [[item sizeheight] floatValue] + [[item paddingBottom] floatValue] + [[item marginBottom] floatValue];
                                    
                                    CGRect elementCanvasRect = CGRectMake(originPointXPadding, originPointYPadding, sizeWidthPadding, sizeHeightPadding);
                                    
                                    if (drawingObject == nil) {
                                        
                                        NSDictionary *attributes = [self attributesForDocumentObject:item];
                                        
                                        // FIXME: This hack gets around known iOS7 bug.
                                        //          Want to draw the fucking rect without
                                        //          having to do a fucking translation.
                                        
                                        CGContextSaveGState(ctx); {
                                            
                                            CGContextTranslateCTM(ctx, elementCanvasRect.origin.x, elementCanvasRect.origin.y);
                                            CGRect drawingRect = CGRectMake(0.0000f, 0.0000f, elementCanvasRect.size.width, elementCanvasRect.size.height);
                                            NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;
                                            [displayString drawWithRect:drawingRect options:options attributes:attributes context:nil];
                                        }
                                        CGContextRestoreGState(ctx);
                                        attributes = nil;
                                        
                                    } else {
                                        [drawingObject drawInRect:elementCanvasRect];
                                    }
                                    displayString = nil;
                                    drawingObject = nil;
                                }
                            }
                        }
                    }
                    
                    if (typeDocumentSection == MNSDocumentSectionTypeBody) {
                        rowIndex++;
                    }
                    originY += sizeHeight;
                    if (typeDocumentSection == MNSDocumentSectionTypeGroupFooter) {
                        [groupLevelKeys removeAllObjects];
                    }

                }
                
                layoutSectionCounter++;
            }
        }
    }
    
    [dataCacheForPage removeAllObjects];
}

- (NSArray *)groupLevelKeysForPage:(NSUInteger)page row:(NSInteger)row numberOfGroups:(NSInteger)numberOfGroups andSection:(NSDictionary *)pageSection {
    
    NSMutableArray *currentGroupLevelKeys = [[NSMutableArray alloc] init];
    MNSDocumentSectionType type = [[pageSection objectForKey: MTReportSectionType] integerValue];

    if (type == MNSDocumentSectionTypeReportHeader) {
        NSArray *sectionsForPage = [[self reportFormatter] layoutForPage:page];
        if ([sectionsForPage count] > 2) {
            NSInteger nextRow = row + 1;
            NSArray *keys = [self groupLevelKeysForPage:page row:nextRow numberOfGroups:numberOfGroups andSection:[sectionsForPage objectAtIndex:nextRow]];
            [currentGroupLevelKeys addObjectsFromArray:keys];
        }
    } else if (type == MNSDocumentSectionTypePageHeader) {
        NSArray *sectionsForPage = [[self reportFormatter] layoutForPage:page];
        if ([sectionsForPage count] > 2) {
            NSInteger nextRow = row + 1;
            NSArray *keys = [self groupLevelKeysForPage:page row:nextRow numberOfGroups:numberOfGroups andSection:[sectionsForPage objectAtIndex:nextRow]];
            [currentGroupLevelKeys addObjectsFromArray:keys];
        }
    } else if (type == MNSDocumentSectionTypeGroupHeader) {
        NSArray *keys = [self groupLevelKeysForGroupHeader:pageSection page:page row:row numberOfGroups:numberOfGroups];
        [currentGroupLevelKeys addObjectsFromArray:keys];
    } else if (type == MNSDocumentSectionTypeBody) {
        NSArray *keys = [self groupLevelKeysForDetail:pageSection page:page row:row numberOfGroups:numberOfGroups];
        [currentGroupLevelKeys addObjectsFromArray:keys];
    } else if (type == MNSDocumentSectionTypeGroupFooter) {
        NSArray *keys = [self groupLevelKeysForGroupFooter:pageSection page:page row:row numberOfGroups:numberOfGroups];
        [currentGroupLevelKeys addObjectsFromArray:keys];
    }
    return currentGroupLevelKeys;
    
}

- (NSArray *)groupLevelKeysForDetail:(NSDictionary *)pageSection page:(NSInteger)page row:(NSInteger)row numberOfGroups:(NSInteger)numberOfGroups {
    NSMutableArray *currentGroupLevelKeys = [[NSMutableArray alloc] init];
    BOOL firstTime = YES;
    for (NSInteger pageCtr = page; pageCtr >= 0; pageCtr--) {
        NSArray *sectionsForPage = [NSArray arrayWithArray:[[self reportFormatter] layoutForPage:pageCtr]];
        NSInteger sectionRowCounter = [sectionsForPage count] - 1;
        NSRange range = NSMakeRange(0, firstTime ? row : [sectionsForPage count] - 1);
        for (NSDictionary *pageSec in [[sectionsForPage subarrayWithRange:range] reverseObjectEnumerator]) {
            if ([[pageSec objectForKey: MTReportSectionType] integerValue] == MNSDocumentSectionTypeGroupHeader &&
                [[pageSec objectForKey: MTReportGroupLevelKeys] count] == numberOfGroups) {
                [currentGroupLevelKeys addObjectsFromArray:[pageSec objectForKey: MTReportGroupLevelKeys]];
                pageCtr = -1;
                break;
            }
            sectionRowCounter--;
        }
        firstTime = NO;
    }
    return currentGroupLevelKeys;
}

- (NSArray *)groupLevelKeysForGroupFooter:(NSDictionary *)pageSection page:(NSInteger)page row:(NSInteger)row numberOfGroups:(NSInteger)numberOfGroups {
    return [self groupLevelKeysForDetail:pageSection page:page row:row numberOfGroups:numberOfGroups];
}

- (NSArray *)groupLevelKeysForGroupHeader:(NSDictionary *)pageSection page:(NSInteger)page row:(NSInteger)row numberOfGroups:(NSInteger)numberOfGroups {
    NSMutableArray *currentGroupLevelKeys = [[NSMutableArray alloc] init];

    NSInteger groupLevel = [[pageSection objectForKey:MTReportGroupLevel] integerValue];
    
    if (groupLevel < numberOfGroups) {
        NSInteger rangeStartLocation = row;
        NSUInteger numberOfPages = [[self reportFormatter] numberOfPages];
        for (NSInteger pageCtr = page; pageCtr < numberOfPages; pageCtr++) {
            @autoreleasepool {
                NSArray *sectionsForPage = [NSArray arrayWithArray:[[self reportFormatter] layoutForPage:pageCtr]];
                NSRange range = NSMakeRange(rangeStartLocation, [sectionsForPage count] - rangeStartLocation);
                NSArray *subArray = [sectionsForPage subarrayWithRange:range];
                for (NSDictionary *pageSec in subArray) {
                    if ([[pageSec objectForKey: MTReportSectionType] integerValue] == MNSDocumentSectionTypeGroupHeader &&
                        [[pageSec objectForKey: MTReportGroupLevelKeys] count] == numberOfGroups) {
                        [currentGroupLevelKeys addObjectsFromArray:[pageSec objectForKey: MTReportGroupLevelKeys]];
                        pageCtr = numberOfPages;
                        break;
                    }
                }
                rangeStartLocation = 0;
            }
        }
    } else {
        NSArray *keys = [pageSection objectForKey:MTReportGroupLevelKeys];
        [currentGroupLevelKeys addObjectsFromArray:keys];
    }
    return currentGroupLevelKeys;
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
}

- (NSDictionary *)attributesForDocumentObject:(RptqDocumentObject *)documentObject {
    MTFont *font = [[MTFont alloc] initWithFamilyName:[documentObject fontname]
                                         andPointSize:[[documentObject fontsize] floatValue]
                                               isBold:[[documentObject bold] boolValue]
                                             isItalic:[[documentObject italic] boolValue]];
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
    return  @{
              NSFontAttributeName : customFont,
              NSBaselineOffsetAttributeName : baselineOffset,
              NSUnderlineStyleAttributeName : underlineStyle,
              NSStrikethroughStyleAttributeName : strikethroughStyle,
              NSParagraphStyleAttributeName: paragraphStyle
              };
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
    NSNumber *underline = [[documentObject underline] boolValue] ? @(kCTUnderlineStyleSingle) : @(kCTUnderlineStyleNone);
    NSNumber *strikethough = [[documentObject strike] boolValue] ? @(kCTUnderlineStyleSingle) : @(kCTUnderlineStyleNone);
    NSDictionary *result = @{(NSString *)kCTFontAttributeName : (id)CFBridgingRelease(customFont),
                             (NSString *)kCTUnderlineStyleAttributeName : underline,
                             (NSString *)NSStrikethroughStyleAttributeName : strikethough,
                             (NSString *)kCTParagraphStyleAttributeName: paragraphStyle};
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

- (void)drawHeaderForPageAtIndex:(NSInteger)index inRect:(CGRect)headerRect {
    [super drawHeaderForPageAtIndex:index inRect:headerRect];
}

- (void)drawContentForPageAtIndex:(NSInteger)index inRect:(CGRect)contentRect {
    [super drawContentForPageAtIndex:index inRect:contentRect];
}

- (void)drawFooterForPageAtIndex:(NSInteger)index inRect:(CGRect)footerRect {
    [super drawFooterForPageAtIndex:index inRect:footerRect];
}

@end
