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

#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <UIKit/NSStringDrawing.h>

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

#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/MADImage.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MADBarcodes/MTBarcode.h>

#import <MTDataTableFast.h>
#import <MADQueryCacheAggregateFunctionParamaters.h>

static NSString * const MTCachedSizeHorizontal = @"MTCachedSizeHorizontal";
static NSString * const MTCachedSizeVertical = @"MTCachedSizeVertical";

static const char *MADQueueTextRepresentation = "com.everdayapps.mad.accessibility";

static inline CGFloat cornerRadiusForHorizontalSizeClass(UIUserInterfaceSizeClass sc);
static inline CGFloat cornerRadiusForHorizontalSizeClass(UIUserInterfaceSizeClass sc) {
    return sc == UIUserInterfaceSizeClassRegular ? 10.0000f : 5.0000f;
}

@protocol MADDataTableAggregateResultesProtocol <NSObject>

@end

typedef MTDataTableFast <MADDataTableAggregateResultesProtocol> MADDataTableAggregate;
typedef NSMutableDictionary <NSManagedObjectID *, UIFontDescriptor *> MADMutableFontDescriptorMap;

@interface MTReportViewerPrintPageRenderer ()

    @property (nonatomic, weak) MTReportFormatter *reportFormatter;
    @property (nonatomic, weak) MADDataTableAggregate *dataTable;

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
    if (self = [super init]) {
        [self initCommon];
        self.dataTable = (MADDataTableAggregate *)dataTable;
        self.reportFormatter = reportFormatter;
    }
    return self;
}

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter
                              dataTable:(MTDataTableFast *)dataTable
                   andPrintableAreaSize:(CGSize)printableAreaSize {
    if (self = [super init]) {
        [self initCommon];
        self.dataTable = (MADDataTableAggregate *)dataTable;
        self.reportFormatter = reportFormatter;
    }
    return self;
}

+ (MTReportViewerPrintPageRenderer *)newReportViewerPrintPageRenderWithDocument:(MADocument *)document {
    MTReportFormatter *reportFormatter = [MTReportFormatter newReportFormatterWithLayout: document
                                                                                 options: MTReportFormatterOptionsMargin];
    reportFormatter.overrideIdentifier = @"madprinter";
    reportFormatter.dataDelegate = document;
    reportFormatter.datasource = document;
    reportFormatter.cachedDelegate = document;
    [reportFormatter initialize];
    
    id printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: reportFormatter
                                                                                dataTable: document.mainDataTable];
    document.printingReportFormatter = reportFormatter;
    return printPageRender;
    
}

- (void)initCommon {

    dispatch_queue_t queue = dispatch_queue_create(MADQueueTextRepresentation,
                                                   DISPATCH_QUEUE_SERIAL);
    self.textRepresentationQueue =  queue;
    
    self.showWaterMark = false;
    self.accessibilityCacheNeedsUpdate = false;
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    if ([standardUserDefaults valueForKey:@"MTCachedSizeHorizontal"] == nil) {

        [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero)
                                 forKey: MTCachedSizeHorizontal];
        [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero)
                                 forKey: MTCachedSizeVertical];
        [standardUserDefaults synchronize];
        
    }
}

- (MADReportTextRepresentation *)textRepresentation {
    if (_textRepresentation == nil) {
        _textRepresentation =
            [[MADReportTextRepresentation alloc] initWithPageCount:
                                            (NSUInteger)self.reportFormatter.reportLayout.count];
    }
    return _textRepresentation;
}

- (UIImage *)newThumbnailWithRect:(CGRect)rect size:(CGFloat)size
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

- (UIImage *)newThumbnailWithTraits:(UITraitCollection *)traits {
    return [self newThumbnailWithRect: [MTPaper rectLetter]
                                 size: MADFloat_1024
                           edgeEffect: YES
                           zoomEffect: YES
                         squareEffect: NO
                           cornerSize: cornerRadiusForHorizontalSizeClass(traits.horizontalSizeClass)
                                scale: traits.displayScale];
}

+ (void)DrawWhiteCanvas:(CGContextRef *)ctx pageRect:(CGRect)pageRect {
    [[UIColor whiteColor] setFill];
    CGPathRef path = CGPathCreateWithRect(pageRect, NULL);
    CGContextAddPath(*ctx, path);
    CGContextDrawPath(*ctx, kCGPathFill);
    CGPathRelease(path);
}

- (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect
                       withTransparentBackground:(BOOL)transparentBackground {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [MTReportViewerPrintPageRenderer DrawWhiteCanvas: &ctx pageRect: pageRect];
    
    [self drawPageAtIndex: index withContext: ctx inPageRect: pageRect];

    if (self.showWaterMark) {
        [MTReportViewerPrintPageRenderer DrawWatermarkWithContext: &ctx inPageRect: pageRect];
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

- (void)drawPageAtIndex:(NSUInteger)pageIndex withContext:(CGContextRef)ctx
             inPageRect:(CGRect)pageRect {

    MTReportFormatter *reportFormatter = self.reportFormatter;
    if (pageIndex >= reportFormatter.numberOfPages) {
        return;
    }

    CGFloat originY = pageRect.origin.y;
    NSUInteger rowIndex = 0, offsetElement = 0, offsetCharacter = 0;
    NSUInteger layoutSectionCounter = 0, readGroupCounter = 0;
    CGRect sectionRect;
    
    RptqDocument *document;
    RptqDatabase *databaseSchemas;
    MTDatabaseConnection *databaseConnection;
    
    document = [reportFormatter.layout activeDocumentModel];
    databaseSchemas = document.hasDatabaseSchemas.anyObject;
    
    RptqUserCredentals *credentals = databaseSchemas.ownedByUser;
    databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUserCredentals: credentals];
    
    MTDatabase *database = [MTDatabase newDatabaseWithConnection:databaseConnection];
    
    NSEnumerator *layoutEnumerator = [reportFormatter layoutEnumeratorForPage:pageIndex];
    NSArray *pageSections = layoutEnumerator.allObjects;
    MADReportPageRepresentation *pageRepresentation =
            [[MADReportPageRepresentation alloc] initWithNumberOfSections:pageSections.count];
    
    RptqDocumentSection *documentSection;
    MADReportSectionRepresentation *sectionRepresentation;
    
    for (MADSectionPlist *pageSection in pageSections) {
        
        documentSection = [document documentSectionForType: pageSection.sectionType
                                                  andLevel: pageSection.groupLevel];
        
        sectionRect = [self sectionRectForDocumentSection: documentSection
                                              pageSection: pageSection
                                               inDocument: document
                                                 pageRect: pageRect
                                            numberOfPages: reportFormatter.numberOfPages
                                                pageIndex: pageIndex
                                                   offset: originY];
        
        [self setBackgroundColorForDocumentSection: documentSection
                                            inRect: sectionRect];
        
        if (pageSection.sectionType == MNSDocumentSectionTypeGroupFooter &&
            pageSection.groupLevel == reportFormatter.numberOfGroups - 1) {
            readGroupCounter++;
        }
        
        sectionRepresentation = [self drawSection: documentSection
                                         pageRect: pageRect
                                      pageSection: pageSection
                                         document: document
                                           onPage: pageIndex
                                     withDatabase: database
                                           offset: originY
                                    offsetElement: offsetElement
                                  offsetCharacter: offsetCharacter];
        
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
                                         offset: (CGFloat)originY
                                  offsetElement: (NSUInteger)offsetElement
                                offsetCharacter: (NSUInteger)offsetCharacter {
    
    NSOrderedSet *rows = documentSection.hasRows;
    MADReportSectionRepresentation * _Nonnull sectionRepresentation;
    CGRect sectionRect, elementCanvasRect;
    NSArray *groupLevelKeys;
    MADReportSectionRowsRepresentation * _Nonnull rowRepresentation;
    NSOrderedSet *items;
    MADReportLineRepresentation * _Nonnull line;
    MADMutableFontDescriptorMap *fontDescriptors;
    RptqDocumentSectionRows *row;
    RptqDocumentObject *item;
    id drawingObject;
    UIFontDescriptor *fontDescriptor;
    NSDictionary *attributes;

    sectionRepresentation = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:rows.count];
    sectionRepresentation.type = pageSection.sectionType;
    sectionRepresentation.elementOffset = offsetElement;
    
    if (!((sectionRepresentation.visibility =
           documentSection.visibility.boolValue))) goto END_DrawSection;
    
    
        
    sectionRect = [self sectionRectForDocumentSection: documentSection
                                          pageSection: pageSection
                                           inDocument: document
                                             pageRect: pageRect
                                        numberOfPages: self.reportFormatter.numberOfPages
                                            pageIndex: pageIndex
                                               offset: originY];
    
    groupLevelKeys = [self newObjectArrayOfGroupLevelKeysForDetailRow:pageSection.detailRowId];
    
    for (row in rows) {
        
        @autoreleasepool {
            
            items = row.hasObjects;
            
            rowRepresentation = [[MADReportSectionRowsRepresentation alloc]
                                 initWithNumberOfSectionRowElements:items.count];
            
            fontDescriptors = [[MADMutableFontDescriptorMap alloc] initWithCapacity:items.count];
            
            for (item in items) {
                @autoreleasepool {
                    
                    drawingObject = [self newDrawingObjectForDatabase: database
                                                            pageIndex: pageIndex
                                                       groupLevelKeys: groupLevelKeys
                                                          detailRowId: pageSection.detailRowId
                                                              andItem: item];
                    
                    elementCanvasRect = item.frame;
                    elementCanvasRect.origin.x = elementCanvasRect.origin.x + sectionRect.origin.x;
                    elementCanvasRect.origin.y = elementCanvasRect.origin.y + sectionRect.origin.y;
                    
                    if ([drawingObject isKindOfClass:[NSString class]]) {
                        
                        fontDescriptor = fontDescriptors[item.objectID];
                        if (!fontDescriptor) {
                            fontDescriptor = [item newFontDescriptor];
                            fontDescriptors[item.objectID] = fontDescriptor;
                        }
                        
                        attributes = [item newTextAttributesWithFontDescriptor:fontDescriptor];
                        
                        [MTReportViewerPrintPageRenderer displayDrawingString: &drawingObject
                                                            elementCanvasRect: &elementCanvasRect
                                                               withAttributes: &attributes];
                        
                    } else {
                        [MTReportViewerPrintPageRenderer displayDrawingObject: &drawingObject
                                                            elementCanvasRect: &elementCanvasRect];
                    }
                    
                    line = [[MADReportLineRepresentation alloc] initWithObject: drawingObject
                                                                          type: item.getType
                                                                         frame: item.frame];
                    line.elementOffset = offsetElement;
                    offsetElement++;
                    
                    [rowRepresentation addLine:line];
                    
                }
                
            }
            
            line = nil;
            [sectionRepresentation addRow:rowRepresentation];
            [fontDescriptors removeAllObjects];
        }
    }
    rowRepresentation = nil;

END_DrawSection:;

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
            
            NSArray *groupLevelKeys = [self newObjectArrayOfGroupLevelKeysForDetailRow:pageSection.detailRowId];
            if (pageSection.sectionType == MNSDocumentSectionTypeGroupFooter && pageSection.groupLevel == self.reportFormatter.numberOfGroups - 1) {
                readGroupCounter++;
            }
            if (documentSection.visibility.boolValue) {
                
                NSMutableArray *accessibilityLinesInSection = [[NSMutableArray alloc] init];
                for (RptqDocumentSectionRows *row in documentSection.hasRows) {
                    for (RptqDocumentObject *item in row.hasObjects) {
                        @autoreleasepool {
                            id drawingObject = [self newDrawingObjectForDatabase:database pageIndex:pageIndex groupLevelKeys:groupLevelKeys detailRowId:pageSection.detailRowId andItem:item];
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

- (MADObjectArray *)newObjectArrayOfGroupLevelKeysForDetailRow:(NSNumber *)detailRowID {
    MTReportFormatter *reportFormatter = self.reportFormatter;
    NSArray *keys;
    if (reportFormatter.numberOfGroups > 0) {
        keys = [reportFormatter newObjectArrayOfKeysForCachedID:detailRowID];
        return keys;
    } else {
        keys = [[NSArray alloc] init];
        return keys;
    }
}

- (CGRect)sectionRectForDocumentSection: (RptqDocumentSection *)documentSection
                            pageSection: (MADSectionPlist *)pageSection
                             inDocument: (RptqDocument *)document
                               pageRect: (CGRect)pageRect
                          numberOfPages: (NSUInteger)numberOfPages
                              pageIndex: (NSUInteger)pageIndex
                                 offset: (CGFloat)originY {

    MTReportFormatter * __unsafe_unretained reportFormatter = self.reportFormatter;
    CGFloat sizeHeight = documentSection.visibility.boolValue ?
                [reportFormatter heightForSectionWithObjectID:documentSection.objectID] : CGSizeZero.height;
    
    switch (pageSection.sectionType) {
    
        case MNSDocumentSectionTypePageFooter:
            originY = pageIndex == numberOfPages - 1 ?  // last page?
                            pageRect.origin.y + pageRect.size.height - sizeHeight -
                                [reportFormatter heightForSectionWithObjectID:document.hasReportFooterSection.objectID] :
                            pageRect.origin.y + pageRect.size.height - sizeHeight;
            break;
            
        case MNSDocumentSectionTypeReportFooter:
            originY = pageRect.origin.y + pageRect.size.height -
                        [reportFormatter heightForSectionWithObjectID: documentSection.objectID];
            break;
            
        default:
            break;
    }
    
    return CGRectMake(pageRect.origin.x, originY, pageRect.size.width, sizeHeight);
}

+ (void)displayDrawingObject: (id __autoreleasing *)drawingObject
           elementCanvasRect: (CGRect *)elementCanvasFrame {
    [*drawingObject drawInRect: *elementCanvasFrame];
}

+ (void)displayDrawingString: (NSString * __autoreleasing *)drawingString
           elementCanvasRect: (CGRect *)elementCanvasFrame
              withAttributes: (NSDictionary * __autoreleasing *)attributes {
    [*drawingString drawWithRect: *elementCanvasFrame
                         options: NSStringDrawingUsesLineFragmentOrigin
                      attributes: *attributes
                         context: nil];
}
/*
+ (void)displayDrawingObject: (id *)drawingObject
                     forItem: (CGRect)itemFrame
               inSectionRect: (CGRect)sectionRect {

    CGRect elementCanvasRect = item.frame;
    elementCanvasRect.origin.x = elementCanvasRect.origin.x + sectionRect.origin.x;
    elementCanvasRect.origin.y = elementCanvasRect.origin.y + sectionRect.origin.y;
    
    if ([drawingObject isKindOfClass:[NSString class]]) {
        
        UIFontDescriptor *fontDescriptor = [item newFontDescriptor];
        NSDictionary *attributes = [item newTextAttributesWithFontDescriptor:fontDescriptor];
        [drawingObject drawWithRect: elementCanvasRect
                            options: NSStringDrawingUsesLineFragmentOrigin
                         attributes: attributes context: nil];
        attributes = nil;
        
    } else {
        [drawingObject drawInRect:elementCanvasRect];
    }
}
*/
- (id)newDocumentObjectForDocumentImage:(RptqDocumentObjectImage *)item {
    return item.image;
}

- (NSString *)newDocumentObjectForLabelDynamic:(RptqDocumentObjectLabelDataField *)item
                                   forDatabase:(MTDatabase *)database forRowID:(NSNumber *)rowID {
    NSString *drawingObject;
    NSDictionary *rowData = [self.dataTable copyDataForCacheId:rowID];
    if (rowData != nil) {
        NSString *qa = [item.referencesQueryField.inQueryTable copyQueryAlias];
        MADSafeQueryField *tableFieldKey = [database newSafeQueryField: item.referencesQueryField.databaseSchemaField.name
                                                              andTable: qa];
        
        NSString *text = [item formattedString:item.referencesQueryField.databaseSchemaField.dataType.shortValue
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

- (NSString *)newDocumentObjectForLabelStatic:(RptqDocumentObjectLabel *)item {
    return [NSString stringWithString:item.text];
}

- (MTBarcode *)newDocumentObjectForBarcode:(RptqDocumentObjectBarcode *)item forDatabase:(MTDatabase *)database forRowID:(NSNumber *)rowID {
    NSDictionary *rowData = [self.dataTable copyDataForCacheId:rowID];
    
    NSString *tableQueryAlias1 = [item.referencesField1.inQueryTable copyQueryAlias];
    NSString *tableQueryAlias2 = [item.referencesField2.inQueryTable copyQueryAlias];
    MADSafeQueryField *tableFieldKey1 = [database newSafeQueryField: item.referencesField1.databaseSchemaField.name
                                                           andTable: tableQueryAlias1];
    MADSafeQueryField *tableFieldKey2 = [database newSafeQueryField: item.referencesField2.databaseSchemaField.name
                                                           andTable: tableQueryAlias2];
    NSString *input1 = [self inputForField: item.referencesField1
                         forDocumentObject: item.parentObjectBarcode
                                     value: rowData[tableFieldKey1]];
    NSString *input2 = [self inputForField: item.referencesField2
                         forDocumentObject: item.parentObjectBarcode
                                     value: rowData[tableFieldKey2]];
    
    MTBarcode *barcode = [RptqDocumentObjectBarcode newBarcodeWithDocumentObject:item];
    barcode.input = input1;
    barcode.primaryData = input2;
    return barcode;
}

- (NSString *)inputForField:(RptqQueryField *)field forDocumentObject:(RptqDocumentObject *)item value:(id)value {
    NSString *input1 = [item formattedString: field.databaseSchemaField.dataType.shortValue
                                    forValue: value];
    if ([input1 isEqualToString:MTNullIdentifier]) {
        return @"";
    } else {
        return [NSString stringWithString:input1];
    }
}

static inline NSRange MADRangeToGroup(NSNumber *groupNumber);
static inline NSRange MADRangeToGroup(NSNumber *groupNumber) {
    return NSMakeRange(0, groupNumber.unsignedIntegerValue + 1);
}

- (NSArray *)dataForAggregateGroupByTypeSection:(NSNumber *)groupNumber
                                 groupLevelKeys:(NSArray *)groupLevelKeys {
    NSArray <__kindof NSDictionary *> *dataForGroup;
    if (groupNumber.unsignedIntegerValue < groupLevelKeys.count) {
        NSArray *groupKeys = [groupLevelKeys subarrayWithRange: MADRangeToGroup(groupNumber)];
        dataForGroup = [self.dataTable objectsForGroupKeys:groupKeys];
    } else {
        dataForGroup = @[];
    }
    return dataForGroup;
}

+ (NSDictionary *)newDictionaryEmptyStringForKey:(id)key {
    id dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"", key, nil];
    return dictionary;
}

- (id)newDrawingObjectForDatabase:(MTDatabase *)database pageIndex:(NSUInteger)pageIndex
                   groupLevelKeys:(NSArray *)groupLevelKeys detailRowId:(NSNumber *)detailRowId
                          andItem:(RptqDocumentObject *)item {

    id drawingObject = nil;
    switch (item.getType) {
            
        case MTDocumentObjectTypeAggregate: {
            
            RptqDocumentObjectAggregate *isAggregate = item.isAggregate;
            RptqQueryField *aggregateField = isAggregate.aggregateField;
            RptqQueryTable *inQueryTable = aggregateField.inQueryTable;
            
            NSString *queryAlias = [inQueryTable copyQueryAlias];
            MADSafeQueryField *fieldKey = [database newSafeQueryField: aggregateField.databaseSchemaField.name
                                                             andTable: queryAlias];
            
            NSArray *groupKeys;
            
            NSNumber *groupNumber = isAggregate.groupNumber;
            if (groupNumber.unsignedIntegerValue < groupLevelKeys.count) {
                groupKeys = [groupLevelKeys subarrayWithRange: MADRangeToGroup(groupNumber)];
            }
            
            RptqDatabaseSchemaField *databaseSchemaField = aggregateField.databaseSchemaField;
            MTDataType aggregateType = databaseSchemaField.dataType.shortValue;
            
            NSNumber * __unsafe_unretained function = isAggregate.function;
            BOOL calculateInMemory = function.unsignedIntegerValue == MTAggregateFunctionTypeFirst ||
                                     function.unsignedIntegerValue == MTAggregateFunctionTypeLast;
            
            id aggregateResult;
            MTReportFormatter *reportFormatter = self.reportFormatter;

            if (calculateInMemory == NO) {
                
                NSNumber * __unsafe_unretained groupType = isAggregate.groupType;
                MADIndexArray *rowIdsForPage = [reportFormatter rowidsForPage:pageIndex];
                aggregateResult = [MTReportViewerPrintPageRenderer newResultsForAggregateType: groupType.unsignedIntegerValue
                                                                                     function: function.unsignedIntegerValue
                                                                                     fieldKey: fieldKey
                                                                                    groupKeys: groupKeys
                                                                                       rowids: rowIdsForPage
                                                                                fromDataTable: self.dataTable];
                
            } else {    //Handle first and last
                
                NSArray <__kindof NSDictionary *> *dataForGroup = nil;
                NSDictionary *dataOfInterest = nil;
                MADDataTableAggregate *dataTable = self.dataTable;
                switch (item.isAggregate.groupType.unsignedIntegerValue) {
                    case MTAggregateGroupByTypeSection: {
                    
                        dataForGroup = [self dataForAggregateGroupByTypeSection:groupNumber groupLevelKeys:groupLevelKeys];
                        
                        switch (item.isAggregate.function.unsignedIntegerValue) {
                            case MTAggregateFunctionTypeFirst:
                                dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup[0] :
                                                                             [MTReportViewerPrintPageRenderer newDictionaryEmptyStringForKey: fieldKey];
                                break;
                            case MTAggregateFunctionTypeLast:
                                dataOfInterest = (dataForGroup.count >= 1) ? dataForGroup.lastObject :
                                                                             [MTReportViewerPrintPageRenderer newDictionaryEmptyStringForKey: fieldKey];
                                break;
                            default:
                                dataOfInterest = [MTReportViewerPrintPageRenderer newDictionaryEmptyStringForKey: fieldKey];
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
                                for (NSDictionary *pageSection in reportFormatter.reportLayout[pageIndex]) {
                                    NSNumber *section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
                                        firstRowid = pageSection[MTReportDetailRowId];
                                        break;
                                    }
                                }
                                dataOfInterest =  firstRowid != nil ? [dataTable copyDataForCacheId:firstRowid] : nil;
                                break;
                            }
                            case MTAggregateFunctionTypeLast: {
                                
                                NSNumber *lastRowid = nil;
                                for (NSDictionary *pageSection in [reportFormatter.reportLayout[pageIndex] reverseObjectEnumerator]) {
                                    NSNumber *section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
                                        lastRowid = pageSection[MTReportDetailRowId];
                                        break;
                                    }
                                }
                                dataOfInterest = lastRowid != nil ? [dataTable copyDataForCacheId:lastRowid] : nil;
                                break;
                                
                            }
                            default:
                                dataOfInterest = [MTReportViewerPrintPageRenderer newDictionaryEmptyStringForKey: fieldKey];
                                break;
                        }
                        break;
                    }
                    case MTAggregateGroupByTypeReport: {
                        switch (item.isAggregate.function.unsignedIntegerValue) {
                            case MTAggregateFunctionTypeFirst: {
                                
                                NSNumber *firstRowid = nil;
                                for (NSDictionary *pageSection in reportFormatter.reportLayout[0]) {
                                    NSNumber *section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
                                        firstRowid = pageSection[MTReportDetailRowId];
                                        break;
                                    }
                                }
                                dataOfInterest =  firstRowid != nil ? [dataTable copyDataForCacheId:firstRowid] : nil;
                                break;
                            }
                            case MTAggregateFunctionTypeLast: {
                                
                                NSNumber *lastRowid = nil;
                                
                                MADSectionArray *sectionArray = reportFormatter.reportLayout[(NSUInteger)reportFormatter.reportLayout.count - 1];
                                NSEnumerator <__kindof MADSectionPlist *> *reverseObjectEnumerator = [sectionArray reverseObjectEnumerator];
                                for (NSDictionary *pageSection in reverseObjectEnumerator) {
                                    NSNumber * __unsafe_unretained section = pageSection[MTReportSectionType];
                                    if (section.unsignedIntegerValue == MNSDocumentSectionTypeBody) {
                                        lastRowid = pageSection[MTReportDetailRowId];
                                        break;
                                    }
                                }
                                dataOfInterest = lastRowid != nil ? [dataTable copyDataForCacheId:lastRowid] : nil;
                                break;
                            }
                            default: {
                                
                                dataOfInterest = [MTReportViewerPrintPageRenderer newDictionaryEmptyStringForKey: fieldKey];
                                break;
                            }
                        }
                        break;
                    }
                    default:
                        break;
                }
                aggregateResult = dataOfInterest[fieldKey];
            }
            
            NSString *formattedString = [item formattedString: aggregateType
                                                     forValue: aggregateResult];
            
            drawingObject = [[NSString alloc] initWithString:formattedString];
            if ([drawingObject isEqualToString:MTNullIdentifier]) {
                drawingObject = @"";
            }
            
            break;
        }
            
        case MTDocumentObjectTypeImage:
            drawingObject = [self newDocumentObjectForDocumentImage: item.isImage];
            break;
            
        case MTDocumentObjectTypeBarcode:
            drawingObject = [self newDocumentObjectForBarcode: item.isBarcode
                                                  forDatabase: database forRowID: detailRowId];
            break;
            
        case MTDocumentObjectTypeLabelDynamic:
            drawingObject = [self newDocumentObjectForLabelDynamic: item.isLabelDataField
                                                       forDatabase: database
                                                          forRowID: detailRowId];
            break;
            
        case MTDocumentObjectTypeLabelStatic:
            drawingObject = [self newDocumentObjectForLabelStatic:item.isLabel];
            break;
            
        default:
            drawingObject = @"";
            break;
    }

    return drawingObject;
}

// FIXME: Return error handler... remove credentals
+ (id)newResultsForAggregateType:(MTAggregateGroupByType)groupByType
                        function:(MTAggregateFunctionType)function
                        fieldKey:(NSString *)fieldKey
                       groupKeys:(NSArray *)groupKeys
                          rowids:(NSArray *)rowids
                   fromDataTable:(MTDataTableFast <MADDataTableAggregateResultesProtocol> *)dataTable {
    id result = nil;
    
    NSString *columnKey = [dataTable columnKeyForColumnName:fieldKey];
    
    if (columnKey) {
        NSDictionary *queryParameters;
        
        MADQueryType queryType = MADQueryTypeCacheAggregateFunction;
        switch (groupByType) {
            case MTAggregateGroupByTypePage: {
                NSDictionary *d = [MTReportViewerPrintPageRenderer newParamatersAggregateByPageWithFieldKey: columnKey
                                                                                                  andRowIds: rowids
                                                                                            andFunctionType: function
                                                                                               andDataTable: dataTable];
                queryParameters = [[NSMutableDictionary alloc] initWithDictionary:d copyItems:NO];
                
                NSNumber *groupByTypeNumber = [[NSNumber alloc] initWithUnsignedInteger: groupByType];
                NSNumber *groupByTypeKey = [[NSNumber alloc] initWithShort: MADQueryCacheAggregateFunctionParamatersGroupByType];
                ((NSMutableDictionary *)queryParameters)[groupByTypeKey] = groupByTypeNumber;
                
                break;
            }
            case MTAggregateGroupByTypeReport:
                queryParameters = [MTReportViewerPrintPageRenderer newParametersAggregateByReportWithFieldKey: columnKey
                                                                                              andFunctionType: function
                                                                                                 andDataTable: dataTable];
                break;
                
            case MTAggregateGroupByTypeSection:
                queryParameters = [MTReportViewerPrintPageRenderer newParamatersAggregateByGroupKeys: groupKeys
                                                                                         andFieldKey: columnKey
                                                                                     andFunctionType: function
                                                                                        andDataTable: dataTable];
                break;
                
            default:
                break;
        }
        
        MTQuery *query = [[MTQuery alloc] initWithQueryType:queryType object:queryParameters];
        result = [dataTable runSelectQuery:query];
        
    }
    
    return result;
}

+ (NSDictionary *)newParamatersAggregateWithFieldKey:(NSString *)fieldKey
                                     andFunctionType:(MTAggregateFunctionType)functionType
                                        andDataTable:(MTDataTableFast <MADDataTableAggregateResultesProtocol> *)dataTable {
    
    id keyTableName = [[NSNumber alloc] initWithShort: MADQueryCacheAggregateFunctionParamatersTableName];
    id keyFieldKey = [[NSNumber alloc] initWithShort: MADQueryCacheAggregateFunctionParamatersFieldKey];
    id keyAggregateFunctionType = [[NSNumber alloc] initWithShort: MADQueryCacheAggregateFunctionParamatersAggregateFunctionType];
    id keyFieldDescriptors = [[NSNumber alloc] initWithShort: MADQueryCacheAggregateFunctionParamatersFieldDescriptors];
    NSNumber *objFunctionType = [[NSNumber alloc] initWithUnsignedInteger: functionType];
    NSString *tableName = [dataTable tableName].copy;
    NSDictionary *paramaters = [[NSDictionary alloc] initWithObjectsAndKeys:tableName, keyTableName,
                                fieldKey, keyFieldKey, dataTable.columns, keyFieldDescriptors,
                                objFunctionType, keyAggregateFunctionType, nil];
    return paramaters;
}

+ (NSDictionary *)newParamatersAggregateByPageWithFieldKey:(NSString *)fieldKey
                                                 andRowIds:(NSArray *)rowids
                                           andFunctionType:(MTAggregateFunctionType)functionType
                                              andDataTable:(MTDataTableFast <MADDataTableAggregateResultesProtocol> *)dataTable {
    
    NSDictionary *d = [MTReportViewerPrintPageRenderer newParamatersAggregateWithFieldKey: fieldKey
                                                                          andFunctionType: functionType
                                                                             andDataTable: dataTable];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:d];
    NSNumber *keyRowids = [[NSNumber alloc] initWithShort: MADQueryCacheAggregateFunctionParamatersRowids];
    parameters[keyRowids] = rowids;
    return parameters;
}

+ (NSDictionary *)newParamatersAggregateByGroupKeys:(NSArray *)groupKeys
                                        andFieldKey:(NSString *)fieldKey
                                    andFunctionType:(MTAggregateFunctionType)functionType
                                       andDataTable:(MTDataTableFast <MADDataTableAggregateResultesProtocol> *)dataTable {
    id d = [MTReportViewerPrintPageRenderer newParamatersAggregateWithFieldKey:fieldKey andFunctionType:functionType
                                    andDataTable:dataTable];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:d];
    NSNumber *keyWhereClause = [[NSNumber alloc] initWithShort: MADQueryCacheAggregateFunctionParamatersPredicates];
    parameters[keyWhereClause] = [dataTable whereClauseForGroupKeys:groupKeys];
    return parameters;
}

+ (NSDictionary *)newParametersAggregateByReportWithFieldKey:(NSString *)fieldKey
                                          andFunctionType:(MTAggregateFunctionType)functionType
                                          andDataTable:(MTDataTableFast <MADDataTableAggregateResultesProtocol> *)dataTable {
    return [MTReportViewerPrintPageRenderer newParamatersAggregateWithFieldKey: fieldKey
                                                               andFunctionType: functionType
                                                                  andDataTable: dataTable];
}

+ (void)DrawWatermarkWithContext:(CGContextRef *)ctx inPageRect:(CGRect)pageRect {

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
    NSNumber *strokeWidth = @3.0000f;
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
            
            CGContextSaveGState(*ctx);
            {
                static CGFloat angle315Degrees = 7.0000f * (CGFloat)M_PI / 4.0000f;
                CGContextTranslateCTM(*ctx, x, columnCounter % 2 == 0 ?
                                      y :
                                      y + ((logoRect.size.height + (logoMargin.height * 2)) / 2.0000f));
                CGContextRotateCTM(*ctx, angle315Degrees);
                [getMad drawInRect:CGRectMake(CGPointZero.x, CGPointZero.y,
                                              logoRect.size.width, logoRect.size.height)];
            }
            CGContextRestoreGState(*ctx);
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
