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

#import "MADocument.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseField.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"

#import "RptqDatabase.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

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

#import "MTPaper.h"
#import "RptqQuery+Extras.h"

#import "MTReportFormatter.h"
#import "MTQuery.h"
#import "MTDatabase.h"
#import "MTDataTable.h"

#import "MTBarcode.h"

#import "MTReportFormatter.h"
#import "MADArrayCaching.h"

@interface MTReportViewerPrintPageRenderer ()


@property (nonatomic, strong) MTReportFormatter *reportFormatter;

@property (nonatomic, assign) NSUInteger temporaryCachedDetailCounter;

@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;
@property (nonatomic, assign) CGSize printableSize;
@property (nonatomic, assign) CGSize cachedPageSize;
@property (nonatomic, assign) CGRect cachedPageRect;
@property (nonatomic, assign) BOOL showWaterMark;
@property (nonatomic, assign) BOOL debugMode;

@property (nonatomic, strong) MTDataTable *dataTable;

@end

@implementation MTReportViewerPrintPageRenderer

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter dataTable:(MTDataTable *)dataTable {
    return [self initWithReportFormatter:reportFormatter dataTable:dataTable andPrintableAreaSize:[MTPaper sizeLetter]];
}

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter dataTable:(MTDataTable *)dataTable andPrintableAreaSize:(CGSize)printableAreaSize {
    self = [super init];
    if (self) {
        [self initCommon];
        self.dataTable = dataTable;
        self.printableSize = printableAreaSize;
        self.reportFormatter = reportFormatter;
    }
    return self;
}

- (void)initCommon {
    
    self.showWaterMark = NO;
    self.debugMode = NO;

    self.cachedPageSize = CGSizeZero;
    self.cachedPageRect = CGRectZero;
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    if ([standardUserDefaults valueForKey:@"MTCachedSizeHorizontal"] == nil) {

        [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero)
                                 forKey: @"MTCachedSizeHorizontal"];
        
        [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero)
                                 forKey: @"MTCachedSizeVertical"];
        
        [standardUserDefaults synchronize];
        
    }
}

- (UIImage *)thumbnailWithRect:(CGRect)rect
                          size:(CGFloat)size
                    edgeEffect:(BOOL)edgeEffect
                    zoomEffect:(BOOL)zoomEffect
                  squareEffect:(BOOL)squareEffect
                    cornerSize:(CGFloat)cornerSize
                         scale:(CGFloat)scale {
    size = size * scale;
    cornerSize = cornerSize * scale;
    CGFloat imageSizeWidth = (size * rect.size.width) / rect.size.height;
    CGSize trueSize = CGSizeMake(imageSizeWidth, size);
    CGRect zoomRect = CGRectMake(0.0000f, 0.0000f, trueSize.width, trueSize.height);
    CGRect pathRect = CGRectMake(zoomRect.origin.x, zoomRect.origin.y, zoomRect.size.width/scale, zoomRect.size.height/scale);
    CGFloat startPointY = pathRect.origin.y + pathRect.size.height;
    CGPoint startPoint = CGPointMake(pathRect.origin.x, startPointY);
    CGFloat topRightPointX = pathRect.origin.x + pathRect.size.width;
    CGPoint topRightPoint = CGPointMake(topRightPointX, pathRect.origin.y);
    CGPoint bottomRightPoint = CGPointMake(topRightPointX, startPointY);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0000f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (zoomEffect) {
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
    }
    
    if (edgeEffect) {

        CGMutablePathRef zigPath = CGPathCreateMutable();
        CGPathMoveToPoint(zigPath, NULL, startPoint.x, startPoint.y);
        CGPathAddLineToPoint(zigPath, NULL, pathRect.origin.x, pathRect.origin.y);
        CGPathAddLineToPoint(zigPath, NULL, topRightPoint.x, topRightPoint.y);

        //zig
        CGFloat zigDivisor = 4.0000f;
        int topRandNumber = 4;
        
        NSInteger numberOfZigs = pathRect.size.height / zigDivisor;
        for (NSInteger zigCounter = 0; zigCounter <= numberOfZigs; zigCounter++) {
            NSInteger zigNumber = [MTMath getRandomNumberBetween: 0 to: topRandNumber];
            CGFloat zigReal = zigNumber / scale;
            CGFloat zigDistance = pow(zigNumber, 1.0001) + zigReal;
            CGFloat zigX = topRightPoint.x - zigDistance;
            CGFloat zigY = topRightPoint.y + (zigCounter * zigDivisor);
            CGPoint zigPoint = CGPointMake(zigX, zigY);
            CGPathAddLineToPoint(zigPath, NULL, zigPoint.x, zigPoint.y);
        }
        CGPathAddLineToPoint(zigPath, NULL, startPoint.x, startPoint.y);
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
            
            NSInteger zagNumber = [MTMath getRandomNumberBetween: 0 to: topRandNumber];
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
    }
    

    CGContextSaveGState(context);
    
    [self drawPageAtIndex:0 inRect:rect withTransparentBackground:YES];

    CGContextRestoreGState(context);
        
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *croppedImage;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, zoomEffect ? zoomRect : rect);
    croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    UIGraphicsEndImageContext();
    
    if (squareEffect) {
        croppedImage = [UIImage imageMadeSquare:croppedImage];
    }
    
    return croppedImage;

}

- (UIImage *)thumbnailWithTraits:(UITraitCollection *)traits {
    return [self thumbnailWithRect: [MTPaper rectLetter]
                              size: MADFloat_1024
                        edgeEffect: YES
                        zoomEffect: YES
                      squareEffect: NO
                        cornerSize: traits.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 10.0000f : 5.0000f
                             scale: traits.displayScale];
}

- (void)drawWhiteCanvas:(CGContextRef)ctx pageRect:(CGRect)pageRect {
    [[UIColor whiteColor] setFill];
    CGPathRef path = CGPathCreateWithRect(pageRect, NULL);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect withTransparentBackground:(BOOL)transparentBackground {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self drawWhiteCanvas: ctx
                 pageRect: pageRect];
    
    [self drawPageAtIndex: index
              withContext: ctx
               inPageRect: pageRect];

    if (self.showWaterMark) {
        [self drawWatermarkWithContext: ctx
                            inPageRect: pageRect];
    }

}

- (void)setBackgroundColorForDocumentSection:(RptqDocumentSection *)documentSection inRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setFill];
    
    switch ([documentSection getDocumentSectionType]) {
        case MNSDocumentSectionTypeBody:
            [[UIColor whiteColor] setFill];
            break;
        case MNSDocumentSectionTypeGroupFooter:
            [[UIColor whiteColor] setFill];
            break;
        case MNSDocumentSectionTypeGroupHeader:
            [[UIColor whiteColor] setFill];
            break;
        case MNSDocumentSectionTypePageFooter:
            [[UIColor whiteColor] setFill];
            break;
        case MNSDocumentSectionTypePageHeader:
            [[UIColor whiteColor] setFill];
            break;
        case MNSDocumentSectionTypeReportFooter:
            [[UIColor whiteColor] setFill];
            break;
        case MNSDocumentSectionTypeReportHeader:
            [[UIColor whiteColor] setFill];
            break;
        default:
            [[UIColor whiteColor] setFill];
            break;
    }
    
    CGPathRef path = CGPathCreateWithRect(rect, NULL);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);

}

- (void)drawPageAtIndex:(NSInteger)pageIndex withContext:(CGContextRef)ctx inPageRect:(CGRect)pageRect {

    NSUInteger rowIndex = 0;
    RptqDocument *document = [self.reportFormatter.layout activeDocumentModel];
    RptqDatabase *databaseSchemas = document.hasDatabaseSchemas.anyObject;
    RptqUserCredentals *userCredentals = databaseSchemas.ownedByUser;
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
    MTDatabase *database = [MTDatabase databaseFactory:databaseConnection];
    RptqQuery *query = databaseSchemas.hasQueries.anyObject;
    
    if (query) {
        NSUInteger numberOfGroups = [self.reportFormatter numberOfGroups];
        NSMutableArray *groupLevelKeys = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
        NSUInteger numberOfPages = [self.reportFormatter numberOfPages];
        
        if (pageIndex < numberOfPages) {

            CGFloat originY = pageRect.origin.y;
            CGFloat originX = pageRect.origin.x;
            CGFloat sizeWidth = pageRect.size.width;
            
            NSInteger layoutSectionCounter = 0;
            NSInteger readGroupIndex = 0;

            NSNumber *detailRowId = nil;
            
            for (NSDictionary *pageSection in [self.reportFormatter layoutEnumeratorForPage:pageIndex]) {
                NSInteger groupLevel = [pageSection[MTReportGroupLevel] integerValue];
                
                MNSDocumentSectionType typeDocumentSection = [pageSection[[MTReportFormatter KeyReportSectionType]] integerValue];
                RptqDocumentSection *documentSection = [document documentSectionForType:typeDocumentSection andLevel:groupLevel];

                
                CGFloat sizeHeight = documentSection.visibility.boolValue ? [self.reportFormatter heightForSection:documentSection] : CGSizeZero.height;
                switch (typeDocumentSection) {
                    case MNSDocumentSectionTypePageFooter: {
                        BOOL lastPage = pageIndex == numberOfPages - 1;
                        if (lastPage) {
                            originY = pageRect.origin.y + pageRect.size.height - sizeHeight - [self.reportFormatter heightForSection:document.hasReportFooterSection];
                        } else {
                            originY = pageRect.origin.y + pageRect.size.height - sizeHeight;
                        }
                        break;
                    }
                    case MNSDocumentSectionTypeReportFooter:
                        originY = pageRect.origin.y + pageRect.size.height - [self.reportFormatter heightForSection:documentSection];
                        break;
                        
                    default:
                        break;
                }
                
                CGRect sectionRect = CGRectMake(originX, originY, sizeWidth, sizeHeight);
                
                [self setBackgroundColorForDocumentSection:documentSection inRect:sectionRect];
                
                if (numberOfGroups > 0) {
                    NSArray *keys = [self.reportFormatter keysForCachedID:pageSection[MTReportDetailRowId]];
                    [groupLevelKeys setArray:keys];
                }
                if (typeDocumentSection == MNSDocumentSectionTypeGroupFooter && groupLevel == [self.reportFormatter numberOfGroups] - 1) {
                    readGroupIndex++;
                }
                
                if (documentSection.visibility.boolValue) {
                    for (RptqDocumentSectionRows *row in [documentSection hasRows]) {
                        
                        for (RptqDocumentObject *item in [row hasObjects]) {
                            
                            @autoreleasepool {
                                
                                id drawingObject = nil;
                                
                                switch ([item getType]) {
                                        
                                    case MTDocumentObjectTypeAggregate: {
                                        
                                        RptqDocumentObjectAggregate *aggregateField = [item isAggregate];
                                        RptqQueryField *queryField = [aggregateField aggregateField];
                                        NSString *fieldKey = [database safeQueryField: queryField.databaseSchemaField.name
                                                                             andTable: queryField.inQueryTable.queryAlias];
                                        
                                        NSArray *groupKeys;
                                        NSInteger groupCount = [aggregateField.groupNumber integerValue];
                                        if (groupCount < [groupLevelKeys count]) {
                                            NSRange rangeForLevel = NSMakeRange(0, groupCount + 1);
                                            groupKeys = [groupLevelKeys subarrayWithRange: rangeForLevel];
                                        }
                                        
                                        MTAggregateFunctionType functionType = [aggregateField.function integerValue];
                                        RptqDatabaseSchemaField *databaseSchemaField = [queryField databaseSchemaField];
                                        NSNumber *databaseSchemaFieldDataType = [databaseSchemaField dataType];
                                        MTDataType aggregateType = [databaseSchemaFieldDataType integerValue];
                                        
                                        BOOL calculateInMemory = functionType == MTAggregateFunctionTypeFirst || functionType == MTAggregateFunctionTypeLast;
                                        
                                        id aggregateResult;
                                        
                                        if (calculateInMemory == NO) {
                                            
                                            aggregateResult = [self.dataTable resultsForAggregateType: [aggregateField.groupType integerValue]
                                                                                             function: [aggregateField.function integerValue]
                                                                                             fieldKey: fieldKey
                                                                                            groupKeys: groupKeys
                                                                                               rowids: [self.reportFormatter rowidsForPage:pageIndex]];
                                            
                                        } else {    //Handle first and last
                                            
                                            NSArray *dataForGroup = nil;
                                            NSDictionary *dataOfInterest = nil;
                                            NSNumber *aggregateFieldGroupType = aggregateField.groupType;
                                            MTAggregateGroupByType aggregateGroupType = [aggregateFieldGroupType integerValue];
                                            
                                            switch (aggregateGroupType) {
                                                case MTAggregateGroupByTypeSection: {
                                                    NSInteger groupCount = [aggregateField.groupNumber integerValue];
                                                    if (groupCount < [groupLevelKeys count]) {
                                                        NSRange rangeForLevel = NSMakeRange(0, groupCount + 1);
                                                        NSArray *groupKeys = [groupLevelKeys subarrayWithRange: rangeForLevel];
                                                        dataForGroup = [self.dataTable objectsForGroupKeys:groupKeys];
                                                    } else {
                                                        dataForGroup = @[];
                                                    }
                                                    switch (functionType) {
                                                        case MTAggregateFunctionTypeFirst:
                                                            dataOfInterest = ([dataForGroup count] >= 1) ? dataForGroup[0] : @{fieldKey:@""};
                                                            break;
                                                        case MTAggregateFunctionTypeLast:
                                                            dataOfInterest = ([dataForGroup count] >= 1) ? [dataForGroup lastObject] : @{fieldKey:@""};
                                                            break;
                                                        default:
                                                            dataOfInterest = @{fieldKey:@""};
                                                            break;
                                                    }
                                                    break;
                                                }
                                                case MTAggregateGroupByTypePage: {
                                                    switch (functionType) {
                                                        case MTAggregateFunctionTypeFirst: {
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            //don't get data from report formattter
                                                            //get it from data table
                                                            
                                                                NSNumber *firstRowid = nil;
                                                                for (NSDictionary *pageSection in self.reportFormatter.reportLayout[pageIndex]) {
                                                                    MNSDocumentSectionType typeDocumentSection = [pageSection[[MTReportFormatter KeyReportSectionType]] integerValue];
                                                                    if (typeDocumentSection == MNSDocumentSectionTypeBody) {
                                                                        firstRowid = pageSection[MTReportDetailRowId];
                                                                        break;
                                                                    }
                                                                }
                                                                dataOfInterest =  firstRowid != nil ? [self.dataTable dataForCacheId:firstRowid] : nil;
                                                            break;
                                                        }
                                                        case MTAggregateFunctionTypeLast: {
                                                            
                                                            
                                                            
                                                            
                                                            
                                                            NSNumber *lastRowid = nil;
                                                            for (NSDictionary *pageSection in [self.reportFormatter.reportLayout[pageIndex] reverseObjectEnumerator]) {
                                                                MNSDocumentSectionType typeDocumentSection = [pageSection[[MTReportFormatter KeyReportSectionType]] integerValue];
                                                                if (typeDocumentSection == MNSDocumentSectionTypeBody) {
                                                                    lastRowid = pageSection[MTReportDetailRowId];
                                                                    break;
                                                                }
                                                            }
                                                            dataOfInterest = lastRowid != nil ? [self.dataTable dataForCacheId:lastRowid] : nil;
                                                            break;
                                                            
                                                    }
                                                        default:
                                                            dataOfInterest = @{fieldKey:@""};
                                                            break;
                                                    }
                                                    break;
                                                }
                                                case MTAggregateGroupByTypeReport: {
                                                    switch (functionType) {
                                                        case MTAggregateFunctionTypeFirst: {
                                                            
                                                            NSNumber *firstRowid = nil;
                                                            for (NSDictionary *pageSection in self.reportFormatter.reportLayout[0]) {
                                                                MNSDocumentSectionType typeDocumentSection = [pageSection[[MTReportFormatter KeyReportSectionType]] integerValue];
                                                                if (typeDocumentSection == MNSDocumentSectionTypeBody) {
                                                                    firstRowid = pageSection[MTReportDetailRowId];
                                                                    break;
                                                                }
                                                            }
                                                            dataOfInterest =  firstRowid != nil ? [self.dataTable dataForCacheId:firstRowid] : nil;
                                                            break;
                                                        }
                                                        case MTAggregateFunctionTypeLast: {
                                                            
                                                            NSNumber *lastRowid = nil;
                                                            for (NSDictionary *pageSection in [self.reportFormatter.reportLayout[[self.reportFormatter numberOfPages] - 1] reverseObjectEnumerator]) {
                                                                MNSDocumentSectionType typeDocumentSection = [pageSection[[MTReportFormatter KeyReportSectionType]] integerValue];
                                                                if (typeDocumentSection == MNSDocumentSectionTypeBody) {
                                                                    lastRowid = pageSection[MTReportDetailRowId];
                                                                    break;
                                                                }
                                                            }
                                                            dataOfInterest = lastRowid != nil ? [self.dataTable dataForCacheId:lastRowid] : nil;
                                                            break;
                                                        }
                                                        default:
                                                            dataOfInterest = @{fieldKey:@""};
                                                            break;
                                                    }
                                                    break;
                                                }
                                                default:
                                                    break;
                                            }
                                            aggregateResult = dataOfInterest[fieldKey];
                                        }
                                        
                                        drawingObject = [NSString stringWithString:[item formattedString:aggregateType
                                                                                                forValue:aggregateResult]];
                                        if ([drawingObject isEqualToString:MTNullIdentifier]) {
                                            drawingObject = @"";
                                        }
                                        
                                        break;
                                    }
                                        
                                    case MTDocumentObjectTypeImage: {
                                        drawingObject = [[item isImage] image];
                                        break;
                                    }
                                        
                                    case MTDocumentObjectTypeBarcode: {
                                        detailRowId = pageSection[MTReportDetailRowId];
                                        NSDictionary *rowData = [NSDictionary dictionaryWithDictionary: [self.dataTable dataForCacheId:detailRowId]];

                                        RptqDocumentObjectBarcode *barcodeObject = [item isBarcode];
                                        RptqQueryField *queryField1 = [barcodeObject referencesField1];
                                        RptqQueryField *queryField2 = [barcodeObject referencesField2];
                                        NSString *tableFieldKey1 = [database safeQueryField: queryField1.databaseSchemaField.name
                                                                                   andTable: queryField1.inQueryTable.queryAlias];
                                        NSString *tableFieldKey2 = [database safeQueryField: queryField2.databaseSchemaField.name
                                                                                   andTable: queryField2.inQueryTable.queryAlias];
                                        id value1 = rowData[tableFieldKey1];
                                        id value2 = rowData[tableFieldKey2];
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
                                        detailRowId = pageSection[MTReportDetailRowId];
                                        NSDictionary *rowData = [NSDictionary dictionaryWithDictionary: [self.dataTable dataForCacheId:detailRowId]];
                                        if (rowData != nil) {
                                            RptqDocumentObjectLabelDataField *labelDataField = [item isLabelDataField];
                                            RptqQueryField *queryField = [labelDataField referencesQueryField];
                                            NSString *tableFieldKey = [database safeQueryField: queryField.databaseSchemaField.name
                                                                                      andTable: queryField.inQueryTable.queryAlias];
                                            id value = rowData[tableFieldKey];
                                            RptqDatabaseSchemaField *schemaField = [queryField databaseSchemaField];
                                            NSNumber *dataTypeNumber = [schemaField dataType];
                                            MTDataType dataType = [dataTypeNumber integerValue];
                                            drawingObject = [NSString stringWithString:[item formattedString:dataType forValue:value]];
                                            if ([drawingObject isEqualToString:MTNullIdentifier]) {
                                                drawingObject = @"";
                                            }
                                        } else {
                                            drawingObject = @"";
                                        }
                                        break;
                                    }
                                        
                                    case MTDocumentObjectTypeLabelStatic: {
                                        drawingObject = [NSString stringWithString:item.isLabel.text];
                                        break;
                                    }
                                        
                                    default: {
                                        drawingObject = @"";
                                        break;
                                    }
                                }
                                
                                CGFloat originPointXPadding = item.originx.floatValue + sectionRect.origin.x + item.spacingLeft;
                                CGFloat originPointYPadding = item.originy.floatValue + sectionRect.origin.y + item.spacingTop;
                                
                                CGFloat sizeWidthPadding = item.sizewidth.floatValue + item.spacingRight;
                                CGFloat sizeHeightPadding = item.sizeheight.floatValue + item.spacingBottom;
                                
                                CGRect elementCanvasRect = CGRectMake(originPointXPadding, originPointYPadding, sizeWidthPadding, sizeHeightPadding);
                                
                                if ([drawingObject isKindOfClass:[NSString class]]) {
                                    
                                    NSDictionary *attributes = [item attributesForDrawingText];
                                    
                                    [drawingObject drawWithRect: elementCanvasRect
                                                        options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                                                     attributes: attributes
                                                        context: nil];
                                    attributes = nil;
                                    
                                } else {
                                    [drawingObject drawInRect:elementCanvasRect];
                                }

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

- (void)drawWatermarkWithContext:(CGContextRef)ctx inPageRect:(CGRect)pageRect {

    UIFont *customFont = [UIFont boldSystemFontOfSize:12.0000f];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    UIColor *strokeColor = [UIColor colorWithRed:170.0000f/256.0000f
                                           green:170.0000f/256.0000f
                                            blue:170.0000f/256.0000f alpha:0.8000f];
    UIColor *foregroundColor = [UIColor colorWithRed:85.0000f/256.0000f
                                               green:85.0000f/256.0000f
                                                blue:85.0000f/256.0000f alpha:0.8000f];
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
                CGContextTranslateCTM(ctx, x, columnCounter % 2 == 0 ?
                                      y :
                                      y + ((logoRect.size.height + (logoMargin.height * 2)) / 2.0000f));
                CGContextRotateCTM(ctx, angle315Degrees);
                [getMad drawInRect:CGRectMake(CGPointZero.x, CGPointZero.y,
                                              logoRect.size.width, logoRect.size.height)];
            }
            CGContextRestoreGState(ctx);
            columnCounter++;
        } while (logoRect.origin.x + logoRect.size.width < pageRect.size.width);
        rowCounter++;
    } while (logoRect.origin.y + logoRect.size.height < pageRect.size.height);
}

#pragma mark - UIPrintPageRender

- (NSInteger)numberOfPages {
    return [self.reportFormatter numberOfPages];
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    [self drawPageAtIndex: index
                   inRect: pageRect
withTransparentBackground: NO];
}

- (void)drawHeaderForPageAtIndex:(NSInteger)index inRect:(CGRect)headerRect {
    [super drawHeaderForPageAtIndex: index
                             inRect: headerRect];
}

- (void)drawContentForPageAtIndex:(NSInteger)index inRect:(CGRect)contentRect {
    [super drawContentForPageAtIndex: index
                              inRect: contentRect];
}

- (void)drawFooterForPageAtIndex:(NSInteger)index inRect:(CGRect)footerRect {
    [super drawFooterForPageAtIndex: index
                             inRect: footerRect];
}

@end
