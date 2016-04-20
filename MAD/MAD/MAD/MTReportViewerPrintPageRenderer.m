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
#import "RptqDocumentObjectAggregate+Extras.h"

#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectBarcode+Extras.h"

#import "RptqDatabaseSchemaField.h"

#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqDocumentObjectImage.h"

#import "MTPaper.h"

#import "MTReportFormatter.h"
#import "MTQuery.h"
#import "MTDatabase.h"

#import "MTReportFormatter.h"
#import "MADArrayCaching.h"

#import "MADSectionPlist.h"

#import "MADAccessibilityLine.h"
#import "MADReportTextRepresentation.h"
#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"
#import "MADReportLineRepresentation.h"

#import <MAD/MTDataTableFast.h>

static NSString * const MTCachedSizeHorizontal = @"MTCachedSizeHorizontal";
static NSString * const MTCachedSizeVertical = @"MTCachedSizeVertical";

static inline CGFloat cornerRadiusForHorizontalSizeClass(UIUserInterfaceSizeClass sc);
static inline CGFloat cornerRadiusForHorizontalSizeClass(UIUserInterfaceSizeClass sc) {
    return sc == UIUserInterfaceSizeClassRegular ? 10.0000f : 5.0000f;
}

@protocol MADDataTableAggregateResultesProtocol <NSObject>

    - (id)resultsForAggregateType:(MTAggregateGroupByType)groupByType
                         function:(MTAggregateFunctionType)function
                         fieldKey:(NSString *)fieldKey
                        groupKeys:(NSArray *)groupKeys
                           rowids:(NSArray *)rowids;

@end


@interface MTReportViewerPrintPageRenderer ()

    @property (nonatomic, weak) MTReportFormatter *reportFormatter;
    @property (nonatomic, weak) MTDataTableFast<MADDataTableAggregateResultesProtocol> *dataTable;

    @property (nonatomic, assign) bool showWaterMark;
    @property (nonatomic, assign) bool accessibilityCacheNeedsUpdate;

    @property (nonatomic, assign) NSUInteger accessibilityCurrentPageIndex;
    @property (nonatomic, assign) CGRect accessibilityCurrentPageRect;
    @property (nonatomic, strong) NSArray <__kindof MADAccessibilityLine *> *accessibilityItems;

    @property (nonatomic, strong, readwrite) MADReportTextRepresentation *textRepresentation;
    @property (nonatomic, strong) dispatch_queue_t textRepresentationQueue;

@end

@implementation MTReportViewerPrintPageRenderer

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter
                              dataTable:(MTDataTableFast *)dataTable {
    
    return [self initWithReportFormatter:reportFormatter dataTable:dataTable
                    andPrintableAreaSize:[MTPaper sizeLetter]];
    
}

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter
                              dataTable:(MTDataTableFast *)dataTable
                   andPrintableAreaSize:(CGSize)printableAreaSize {
    if (self = [super init]) {
        [self initCommon];
        self.dataTable = (MTDataTableFast<MADDataTableAggregateResultesProtocol> *)dataTable;
        self.reportFormatter = reportFormatter;
    }
    return self;
}

- (void)initCommon {

    NSString *classnameConcurrentBackground = [NSStringFromClass(self.class) stringByAppendingString:@"DispatchConcurrentBackground"];
    const char *queueName = [classnameConcurrentBackground cStringUsingEncoding:NSUTF8StringEncoding];
    self.textRepresentationQueue =  dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);
    
    self.showWaterMark = false;
    self.accessibilityCacheNeedsUpdate = false;
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    if ([standardUserDefaults valueForKey:@"MTCachedSizeHorizontal"] == nil) {

        [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero) forKey: MTCachedSizeHorizontal];
        
        [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero) forKey: MTCachedSizeVertical];
        
        [standardUserDefaults synchronize];
        
    }
}

- (MADReportTextRepresentation *)textRepresentation {
    if (_textRepresentation == nil) {
        _textRepresentation = [[MADReportTextRepresentation alloc] initWithPageCount:self.reportFormatter.numberOfPages];
    }
    return _textRepresentation;
}

- (UIImage *)thumbnailWithRect:(CGRect)rect size:(CGFloat)size
                    edgeEffect:(BOOL)edgeEffect
                    zoomEffect:(BOOL)zoomEffect
                  squareEffect:(BOOL)squareEffect
                    cornerSize:(CGFloat)cornerSize
                         scale:(CGFloat)scale {
    size = size * scale;
    cornerSize = cornerSize * scale;
    CGFloat imageSizeWidth = (size * rect.size.width) / rect.size.height;
    CGRect zoomRect = CGRectMake(CGPointZero.x, CGPointZero.y, imageSizeWidth, size);
    CGRect pathRect = CGRectMake(zoomRect.origin.x, zoomRect.origin.y,
                                 zoomRect.size.width/scale, zoomRect.size.height/scale);
    CGFloat startPointY = pathRect.origin.y + pathRect.size.height;
    CGPoint startPoint = CGPointMake(pathRect.origin.x, startPointY);
    CGPoint topRightPoint = CGPointMake(pathRect.origin.x + pathRect.size.width, pathRect.origin.y);
    CGPoint bottomRightPoint = CGPointMake(pathRect.origin.x + pathRect.size.width, startPointY);
    
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
        const unsigned int topRandNumber = 4;
        
        CGFloat numberOfZigs = pathRect.size.height / zigDivisor;
        for (NSInteger zigCounter = 0; zigCounter <= numberOfZigs; zigCounter++) {
            NSUInteger zigNumber = madRandomNumberBetween(0, topRandNumber);
            CGFloat zigReal = zigNumber / scale;
            CGFloat zigDistance = (CGFloat)pow(zigNumber, 1.0001) + zigReal;
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
        CGFloat numberOfZags = pathRect.size.height / zagDivisor;
        for (NSInteger zagCounter = 0; zagCounter <= numberOfZags; zagCounter++) {
            
            NSUInteger zagNumber = madRandomNumberBetween(0, topRandNumber);
            CGFloat zagReal = zagNumber / scale;
            CGFloat zagX = bottomRightPoint.x - (zagCounter * zagDivisor);
            CGFloat zagDistance = (CGFloat)pow(zagNumber, 1.0001) + zagReal;
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
        croppedImage = [MADImage imageMadeSquare:croppedImage];
    }
    
    return croppedImage;

}

- (UIImage *)thumbnailWithTraits:(UITraitCollection *)traits {
    return [self thumbnailWithRect: [MTPaper rectLetter]
                              size: MADFloat_1024
                        edgeEffect: YES
                        zoomEffect: YES
                      squareEffect: NO
                        cornerSize: cornerRadiusForHorizontalSizeClass(traits.horizontalSizeClass)
                             scale: traits.displayScale];
}

- (void)drawWhiteCanvas:(CGContextRef)ctx pageRect:(CGRect)pageRect {
    [[UIColor whiteColor] setFill];
    CGPathRef path = CGPathCreateWithRect(pageRect, NULL);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);
}

- (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect
                       withTransparentBackground:(BOOL)transparentBackground {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self drawWhiteCanvas: ctx pageRect: pageRect];
    
    [self drawPageAtIndex: index withContext: ctx inPageRect: pageRect];

    if (self.showWaterMark) {
        [self drawWatermarkWithContext: ctx inPageRect: pageRect];
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

- (void)drawPageAtIndex:(NSUInteger)pageIndex withContext:(CGContextRef)ctx inPageRect:(CGRect)pageRect {
    if (pageIndex >= self.reportFormatter.numberOfPages) {
        return;
    }

    NSUInteger rowIndex = 0, offsetElement = 0, offsetCharacter = 0;
    RptqDocument *document = [self.reportFormatter.layout activeDocumentModel];
    RptqDatabase *databaseSchemas = document.hasDatabaseSchemas.anyObject;

    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUserCredentals:databaseSchemas.ownedByUser];
    MTDatabase *database = [MTDatabase newDatabaseWithConnection:databaseConnection];
    
    CGFloat originY = pageRect.origin.y;
    NSUInteger layoutSectionCounter = 0, readGroupCounter = 0;
    
    NSEnumerator *layoutEnumerator = [self.reportFormatter layoutEnumeratorForPage:pageIndex];
    NSArray *pageSections = layoutEnumerator.allObjects;
    MADReportPageRepresentation *pageRepresentation = [[MADReportPageRepresentation alloc] initWithNumberOfSections:pageSections.count];
    for (MADSectionPlist *pageSection in pageSections) {
        
        RptqDocumentSection *documentSection = [document documentSectionForType:pageSection.sectionType andLevel:pageSection.groupLevel];
        
        CGRect sectionRect = [self sectionRectForDocumentSection:documentSection pageSection:pageSection inDocument:document
                                                        pageRect:pageRect numberOfPages:self.reportFormatter.numberOfPages
                                                       pageIndex:pageIndex offset:&originY];
        
        [self setBackgroundColorForDocumentSection:documentSection inRect:sectionRect];
        
        if (pageSection.sectionType == MNSDocumentSectionTypeGroupFooter && pageSection.groupLevel == self.reportFormatter.numberOfGroups - 1) {
            readGroupCounter++;
        }
        
        MADReportSectionRepresentation *sectionRepresentation = [self drawSection:documentSection pageRect:pageRect
                                                                      pageSection:pageSection document:document
                                                                           onPage:pageIndex withDatabase:database offset:&originY
                                                                 offsetElement:&offsetElement offsetCharacter:&offsetCharacter];
        [pageRepresentation addSection:sectionRepresentation];
        
        if (pageSection.sectionType == MNSDocumentSectionTypeBody) {
            rowIndex++;
        }
        originY += sectionRect.size.height;
        layoutSectionCounter++;
    }
    
    
    [self.textRepresentation setPage:pageRepresentation forPageIndex:pageIndex];
    
}

- (MADReportSectionRepresentation *)drawSection: (RptqDocumentSection *)documentSection
                                       pageRect: (CGRect)pageRect
                                    pageSection: (MADSectionPlist *)pageSection
                                       document: (RptqDocument *)document
                                         onPage: (NSUInteger)pageIndex
                                   withDatabase: (MTDatabase *)database
                                         offset: (CGFloat *)originY
                                  offsetElement: (NSUInteger *)offsetElement
                                offsetCharacter: (NSUInteger *)offsetCharacter {
    
    NSOrderedSet *rows = documentSection.hasRows;
    MADReportSectionRepresentation * _Nonnull sectionRepresentation = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:rows.count];
    sectionRepresentation.type = pageSection.sectionType;
    sectionRepresentation.elementOffset = *(offsetElement);
    
    if ((sectionRepresentation.visibility = documentSection.visibility.boolValue)) {
        CGRect sectionRect = [self sectionRectForDocumentSection:documentSection pageSection:pageSection inDocument:document
                                                        pageRect:pageRect numberOfPages:self.reportFormatter.numberOfPages
                                                       pageIndex:pageIndex offset:originY];
        
        NSArray *groupLevelKeys = [self groupLevelKeysForDetailRow:pageSection.detailRowId];
        
        for (RptqDocumentSectionRows *row in rows) {
            NSOrderedSet *items = row.hasObjects;
            MADReportSectionRowsRepresentation * _Nonnull rowRepresentation = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:items.count];
                        
            for (RptqDocumentObject *item in items) {
                @autoreleasepool {
                    id drawingObject = [self drawingObjectForDatabase:database pageIndex:pageIndex groupLevelKeys:groupLevelKeys detailRowId:pageSection.detailRowId andItem:item];
                    CGRect elementCanvasRect = item.frame;
                    elementCanvasRect.origin.x = elementCanvasRect.origin.x + sectionRect.origin.x;
                    elementCanvasRect.origin.y = elementCanvasRect.origin.y + sectionRect.origin.y;
                    
                    if ([drawingObject isKindOfClass:[NSString class]]) {
                        @autoreleasepool {
                            NSDictionary *attributes = [item attributesForDrawingText];
                            [drawingObject drawWithRect: elementCanvasRect
                                                options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                                             attributes: attributes
                                                context: nil];
                        }
                    } else {
                        [drawingObject drawInRect:elementCanvasRect];
                    }
                    
                    MADReportLineRepresentation * _Nonnull line = [[MADReportLineRepresentation alloc] initWithObject:drawingObject
                                                                                                                                 type:item.getType
                                                                                                                                frame:elementCanvasRect];
                    [rowRepresentation addLine:line];
                    line.elementOffset = *(offsetElement);
                    (*(offsetElement))++;
                    
                }
            }
            [sectionRepresentation addRow:rowRepresentation];
        }
    }
    return sectionRepresentation;
}


/*- (void)updateAccessibilityItems {
    if (!self.accessibilityCacheNeedsUpdate) return;
    NSArray *items = [self accessibilityDrawingObjectsOnPageAtIndex:self.accessibilityCurrentPageIndex inPageRect:self.accessibilityCurrentPageRect];
    self.accessibilityItems = [NSArray arrayWithArray:items];
    self.accessibilityCacheNeedsUpdate = false;
}*/
/*
NSComparator accessibilityLineComparson = ^NSComparisonResult(MADAccessibilityLine *  _Nonnull obj1, MADAccessibilityLine *  _Nonnull obj2) {
    // Sort from left to right.
    if (obj1.frame.origin.y < obj2.frame.origin.y) {
        return NSOrderedAscending;
    } else if (obj1.frame.origin.y == obj2.frame.origin.y && obj1.frame.origin.x < obj2.frame.origin.x) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
};

// FIXME: This is the start of an attempt at a seperate accessibility run.
//  May store this stuff off seperately on og pass, and use UITextInput protocol.

- (NSArray *)accessibilityDrawingObjectsOnPageAtIndex:(NSUInteger)pageIndex inPageRect:(CGRect)pageRect {
    NSUInteger rowIndex = 0, layoutSectionCounter = 0, readGroupCounter = 0;
    NSMutableArray *accessibilityDrawingObjects = [[NSMutableArray alloc] init];
    
    RptqDocument *document = [self.reportFormatter.layout activeDocumentModel];
    RptqDatabase *databaseSchemas = document.hasDatabaseSchemas.anyObject;
    
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUserCredentals:databaseSchemas.ownedByUser];
    MTDatabase *database = [MTDatabase newDatabaseWithConnection:databaseConnection];
    
    NSUInteger numberOfPages = self.reportFormatter.numberOfPages;
    if (pageIndex < numberOfPages) {
        
        CGFloat originY = pageRect.origin.y;
        NSEnumerator *layoutEnumerator = [self.reportFormatter layoutEnumeratorForPage:pageIndex];
        for (NSDictionary *pageSection in layoutEnumerator) {
            
            RptqDocumentSection *documentSection = [document documentSectionForType:pageSection.sectionType andLevel:pageSection.groupLevel];
            
            CGRect sectionRect = [self sectionRectForDocumentSection:documentSection pageSection:pageSection inDocument:document pageRect:pageRect numberOfPages:numberOfPages pageIndex:pageIndex offset:&originY];
            
            self.backgroundColorForDocumentSection:documentSection inRect:sectionRect];
            
            NSArray *groupLevelKeys = [self groupLevelKeysForDetailRow:pageSection.detailRowId];
            if (pageSection.sectionType == MNSDocumentSectionTypeGroupFooter && pageSection.groupLevel == self.reportFormatter.numberOfGroups - 1) {
                readGroupCounter++;
            }
            if (documentSection.visibility.boolValue) {
                
                NSMutableArray *accessibilityLinesInSection = [[NSMutableArray alloc] init];
                for (RptqDocumentSectionRows *row in documentSection.hasRows) {
                    for (RptqDocumentObject *item in row.hasObjects) {
                        @autoreleasepool {
                            id drawingObject = [self drawingObjectForDatabase:database pageIndex:pageIndex groupLevelKeys:groupLevelKeys detailRowId:pageSection.detailRowId andItem:item];
                            MADAccessibilityLine *line = [[MADAccessibilityLine alloc] initWithValue:drawingObject
                                                                                                type:item.getType
                                                                                            andFrame:CGRectMake(item.originx.floatValue + sectionRect.origin.x + item.spacingLeft,
                                                                                                                                       item.originy.floatValue + sectionRect.origin.y + item.spacingTop,
                                                                                                                                       item.sizewidth.floatValue + item.spacingRight,
                                                                                                                                       item.sizeheight.floatValue + item.spacingBottom)];
                            [accessibilityLinesInSection addObject:line];
                        }
                    }
                }
                [accessibilityLinesInSection sortUsingComparator:accessibilityLineComparson];
                [accessibilityDrawingObjects addObjectsFromArray:accessibilityLinesInSection];

            }
            
            if (pageSection.sectionType == MNSDocumentSectionTypeBody) {
                rowIndex++;
            }
            originY += sectionRect.size.height;
        }
        layoutSectionCounter++;
    }
    return accessibilityDrawingObjects;
}
*/

- (NSArray *)groupLevelKeysForDetailRow:(NSNumber *)detailRowID {
    if (self.reportFormatter.numberOfGroups > 0) {
        NSArray *keys = [self.reportFormatter keysForCachedID:detailRowID];
        return [NSArray arrayWithArray: keys];
    } else {
        return @[];
    }
}

- (CGRect)sectionRectForDocumentSection:(RptqDocumentSection *)documentSection
                            pageSection:(MADSectionPlist *)pageSection
                             inDocument:(RptqDocument *)document
                               pageRect:(CGRect)pageRect
                          numberOfPages:(NSUInteger)numberOfPages
                              pageIndex:(NSUInteger)pageIndex
                                 offset:(CGFloat *)originY {

    CGFloat sizeHeight = documentSection.visibility.boolValue ? [self.reportFormatter heightForSection:documentSection] : CGSizeZero.height;
    switch (pageSection.sectionType) {
        case MNSDocumentSectionTypePageFooter:
            *originY = pageIndex == numberOfPages - 1 ?  // last page?
                            pageRect.origin.y + pageRect.size.height - sizeHeight - [self.reportFormatter heightForSection:document.hasReportFooterSection] :
                            pageRect.origin.y + pageRect.size.height - sizeHeight;
            break;
        case MNSDocumentSectionTypeReportFooter:
            *originY = pageRect.origin.y + pageRect.size.height - [self.reportFormatter heightForSection:documentSection];
            break;
            
        default:
            break;
    }
    
    return CGRectMake(pageRect.origin.x, *originY, pageRect.size.width, sizeHeight);
}

- (void)displayDrawingObject:(id)drawingObject forItem:(RptqDocumentObject *)item inSectionRect:(CGRect)sectionRect {
    CGRect elementCanvasRect = item.frame;
    elementCanvasRect.origin.x = elementCanvasRect.origin.x + sectionRect.origin.x;
    elementCanvasRect.origin.y = elementCanvasRect.origin.y + sectionRect.origin.y;
    
    if ([drawingObject isKindOfClass:[NSString class]]) {
        
        NSDictionary *attributes = [item attributesForDrawingText];
        [drawingObject drawWithRect: elementCanvasRect
                            options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                         attributes: attributes context: nil];
        attributes = nil;
        
    } else {
        [drawingObject drawInRect:elementCanvasRect];
    }
}

- (id)documentObjectForDocumentImage:(RptqDocumentObjectImage *)item {
    return item.image;
}

- (NSString *)documentObjectForLabelDynamic:(RptqDocumentObjectLabelDataField *)item forDatabase:(MTDatabase *)database forRowID:(NSNumber *)rowID {
    NSString *drawingObject;
    NSDictionary *rowData = [NSDictionary dictionaryWithDictionary: [self.dataTable dataForCacheId:rowID]];
    if (rowData != nil) {
        NSString *tableFieldKey = [database safeQueryField: item.referencesQueryField.databaseSchemaField.name
                                                  andTable: item.referencesQueryField.inQueryTable.queryAlias];
        NSString *text = [item formattedString:item.referencesQueryField.databaseSchemaField.dataType.unsignedIntegerValue
                                      forValue:rowData[tableFieldKey]];
        drawingObject = [NSString stringWithString:text];
        if ([drawingObject isEqualToString:MTNullIdentifier]) {
            drawingObject = @"";
        }
    } else {
        drawingObject = @"";
    }
    return drawingObject;
}

- (NSString *)documentObjectForLabelStatic:(RptqDocumentObjectLabel *)item {
    return [NSString stringWithString:item.text];
}

- (MTBarcode *)documentObjectForBarcode:(RptqDocumentObjectBarcode *)item forDatabase:(MTDatabase *)database forRowID:(NSNumber *)rowID {
    NSDictionary *rowData = [NSDictionary dictionaryWithDictionary: [self.dataTable dataForCacheId:rowID]];
    
    NSString *tableFieldKey1 = [database safeQueryField: item.referencesField1.databaseSchemaField.name
                                               andTable: item.referencesField1.inQueryTable.queryAlias];
    NSString *tableFieldKey2 = [database safeQueryField: item.referencesField2.databaseSchemaField.name
                                               andTable: item.referencesField2.inQueryTable.queryAlias];
    NSString *input1 = [self inputForField:item.referencesField1 forDocumentObject:item.parentObjectBarcode value:rowData[tableFieldKey1]];
    NSString *input2 = [self inputForField:item.referencesField2 forDocumentObject:item.parentObjectBarcode value:rowData[tableFieldKey2]];
    
    MTBarcode *barcode = [RptqDocumentObjectBarcode barcodeWithDocumentObject:item];
    barcode.input = input1;
    barcode.primaryData = input2;
    return barcode;
}

- (NSString *)inputForField:(RptqQueryField *)field forDocumentObject:(RptqDocumentObject *)item value:(id)value {
    NSString *input1 = [item formattedString:field.databaseSchemaField.dataType.unsignedIntegerValue
                                                        forValue:value];
    if ([input1 isEqualToString:MTNullIdentifier]) {
        return @"";
    } else {
        return [NSString stringWithString:input1];
    }
}

- (id)drawingObjectForDatabase:(MTDatabase *)database
                     pageIndex:(NSUInteger)pageIndex
                groupLevelKeys:(NSArray *)groupLevelKeys
                   detailRowId:(NSNumber *)detailRowId
                       andItem:(RptqDocumentObject *)item {

    id drawingObject = nil;
    switch (item.getType) {
            
        case MTDocumentObjectTypeAggregate: {
            
            NSString *fieldKey = [database safeQueryField: item.isAggregate.aggregateField.databaseSchemaField.name
                                                 andTable: item.isAggregate.aggregateField.inQueryTable.queryAlias];
            
            NSArray *groupKeys;
            if (item.isAggregate.groupNumber.unsignedIntegerValue < groupLevelKeys.count) {
                groupKeys = [groupLevelKeys subarrayWithRange: NSMakeRange(0, item.isAggregate.groupNumber.unsignedIntegerValue + 1)];
            }
            
            MTDataType aggregateType = item.isAggregate.aggregateField.databaseSchemaField.dataType.unsignedIntegerValue;
            
            BOOL calculateInMemory = item.isAggregate.function.unsignedIntegerValue == MTAggregateFunctionTypeFirst ||
                                     item.isAggregate.function.unsignedIntegerValue == MTAggregateFunctionTypeLast;
            
            id aggregateResult;
            if (calculateInMemory == NO) {
                
                aggregateResult = [self resultsForAggregateType: item.isAggregate.groupType.unsignedIntegerValue
                                                                 function: item.isAggregate.function.unsignedIntegerValue
                                                                 fieldKey: fieldKey
                                                                groupKeys: groupKeys
                                                                   rowids: [self.reportFormatter rowidsForPage:pageIndex]];
                
            } else {    //Handle first and last
                
                NSArray *dataForGroup = nil;
                NSDictionary *dataOfInterest = nil;
                
                switch (item.isAggregate.groupType.unsignedIntegerValue) {
                    case MTAggregateGroupByTypeSection: {
                        if (item.isAggregate.groupNumber.unsignedIntegerValue < groupLevelKeys.count) {
                            NSArray *groupKeys = [groupLevelKeys subarrayWithRange: NSMakeRange(0, item.isAggregate.groupNumber.unsignedIntegerValue + 1)];
                            dataForGroup = [self.dataTable objectsForGroupKeys:groupKeys];
                        } else {
                            dataForGroup = @[];
                        }
                        switch (item.isAggregate.function.unsignedIntegerValue) {
                            case MTAggregateFunctionTypeFirst:
                                dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup[0] :
                                                                             @{fieldKey : @""};
                                break;
                            case MTAggregateFunctionTypeLast:
                                dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.lastObject :
                                                                             @{fieldKey : @""};
                                break;
                            default:
                                dataOfInterest = @{fieldKey : @""};
                                break;
                        }
                        break;
                    }
                    case MTAggregateGroupByTypePage: {
                        switch (item.isAggregate.function.unsignedIntegerValue) {
                            case MTAggregateFunctionTypeFirst: {
                                
                                //don't get data from report formattter
                                //get it from data table
                                
                                NSNumber *firstRowid = nil;
                                for (NSDictionary *pageSection in self.reportFormatter.reportLayout[pageIndex]) {
                                    NSNumber *section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
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
                                    NSNumber *section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
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
                        switch (item.isAggregate.function.unsignedIntegerValue) {
                            case MTAggregateFunctionTypeFirst: {
                                
                                NSNumber *firstRowid = nil;
                                for (NSDictionary *pageSection in self.reportFormatter.reportLayout[0]) {
                                    NSNumber *section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
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
                                    NSNumber *section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
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
            
        case MTDocumentObjectTypeImage:
            drawingObject = [self documentObjectForDocumentImage: item.isImage];
            break;
            
        case MTDocumentObjectTypeBarcode:
            drawingObject = [self documentObjectForBarcode:item.isBarcode forDatabase:database forRowID:detailRowId];
            break;
            
        case MTDocumentObjectTypeLabelDynamic:
            drawingObject = [self documentObjectForLabelDynamic:item.isLabelDataField forDatabase:database forRowID:detailRowId];
            break;
            
        case MTDocumentObjectTypeLabelStatic:
            drawingObject = [self documentObjectForLabelStatic:item.isLabel];
            break;
            
        default:
            drawingObject = @"";
            break;
    }

    return drawingObject;
}

// FIXME: Return error handler... remove credentals
- (id)resultsForAggregateType:(MTAggregateGroupByType)groupByType
                     function:(MTAggregateFunctionType)function
                     fieldKey:(NSString *)fieldKey
                    groupKeys:(NSArray *)groupKeys
                       rowids:(NSArray *)rowids {
    id result = nil;
    
    NSString *columnKey = [self.dataTable columnKeyForColumnName:fieldKey];
    
    if (columnKey) {
        NSDictionary *queryParameters;
        
        MTQueryType queryType = MTQueryTypeCacheAggregateFunction;
        switch (groupByType) {
            case MTAggregateGroupByTypePage: {
                queryParameters = [NSMutableDictionary dictionaryWithDictionary: [self paramatersAggregateByPageWithFieldKey:columnKey andRowIds:rowids andFunctionType:function]];
                NSNumber *groupByTypeNumber = @(groupByType);
                NSNumber *groupByTypeKey = @(MTQueryCacheAggregateFunctionParamatersGroupByType);
                ((NSMutableDictionary *)queryParameters)[groupByTypeKey] = groupByTypeNumber;
                
                break;
            }
            case MTAggregateGroupByTypeReport:
                queryParameters = [self parametersAggregateByReportWithFieldKey:columnKey andFunctionType:function];
                break;
                
            case MTAggregateGroupByTypeSection:
                //[self initalizeGroupKeys];
                queryParameters = [self paramatersAggregateByGroupKeys:groupKeys andFieldKey:columnKey andFunctionType:function];
                break;
                
            default:
                break;
        }
        
        MTQuery *query = [[MTQuery alloc] initWithQueryType:queryType object:queryParameters];
        result = [self.dataTable runSelectQuery:query];
        
    }
    
    return result;
}

- (NSDictionary *)paramatersAggregateWithFieldKey:(NSString *)fieldKey andFunctionType:(MTAggregateFunctionType)functionType {
    NSNumber *keyTableName = @(MTQueryCacheAggregateFunctionParamatersTableName);
    NSNumber *keyFieldKey = @(MTQueryCacheAggregateFunctionParamatersFieldKey);
    NSNumber *keyAggregateFunctionType = @(MTQueryCacheAggregateFunctionParamatersAggregateFunctionType);
    NSNumber *keyFieldDescriptors = @(MTQueryCacheAggregateFunctionParamatersFieldDescriptors);
    NSNumber *objFunctionType = @(functionType);
    NSString *tableName = [self.dataTable tableName];
    return @{
             keyTableName : tableName,
             keyFieldKey : fieldKey,
             keyFieldDescriptors : self.dataTable.columns,
             keyAggregateFunctionType: objFunctionType
             };
}

- (NSDictionary *)paramatersAggregateByPageWithFieldKey:(NSString *)fieldKey andRowIds:(NSArray *)rowids andFunctionType:(MTAggregateFunctionType)functionType {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:[self paramatersAggregateWithFieldKey:fieldKey andFunctionType:functionType]];
    NSNumber *keyRowids = @(MTQueryCacheAggregateFunctionParamatersRowids);
    parameters[keyRowids] = rowids;
    return parameters;
}

- (NSDictionary *)paramatersAggregateByGroupKeys:(NSArray *)groupKeys andFieldKey:(NSString *)fieldKey andFunctionType:(MTAggregateFunctionType)functionType {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:[self paramatersAggregateWithFieldKey:fieldKey andFunctionType:functionType]];
    NSNumber *keyWhereClause = @(MTQueryCacheAggregateFunctionParamatersPredicates);
    parameters[keyWhereClause] = [self.dataTable whereClauseForGroupKeys:groupKeys];
    return parameters;
}

- (NSDictionary *)parametersAggregateByReportWithFieldKey:(NSString *)fieldKey andFunctionType:(MTAggregateFunctionType)functionType {
    return [self paramatersAggregateWithFieldKey:fieldKey andFunctionType:functionType];
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
                static CGFloat angle315Degrees = 7.0000f * (CGFloat)M_PI / 4.0000f;
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
    return (NSInteger)[self.reportFormatter numberOfPages];
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    [self drawPageAtIndex: (unsigned long)labs(index)
                   inRect: pageRect withTransparentBackground: NO];
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

#pragma mark

- (id)debugQuickLookObject {
    return [self textRepresentation];
}

@end
