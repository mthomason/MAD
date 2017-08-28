//
//  MADPrintPageRendererReport.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADPrintPageRenderer.h"

#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <UIKit/NSStringDrawing.h>
#import <UIKit/UIInterface.h>
#import <UIKit/NSParagraphStyle.h>

#import "MADocument.h"
#import "MADDatabaseConnection.h"
#import "MADDatabaseField.h"

#import "RptqDocument+Extras.h"
#import "RptqDocument+Extras.h"

#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDatabase.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryField.h"

#import "RptqDatabaseCredentals.h"

#import "RptqDocumentSectionRows.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentElementAggregate+Extras.h"
#import "RptqDocumentElementBarcode+Extras.h"

#import "RptqDatabaseSchemaField.h"

#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementLabelDataField+Extras.h"
#import "RptqDocumentElementImage.h"

#import "MTPaper.h"

#import "MADReportFormatter.h"
#import "MTQuery.h"
#import "MTDatabase.h"

#import "MADReportFormatter.h"
#import "MADArrayCaching.h"

#import "MADSectionRepresentation.h"

#import "MADAccessibilityLine.h"
#import "MADReportTextRepresentation.h"
#import "MADReportPageRepresentation.h"
#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"
#import "MADReportLineRepresentation.h"

#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADDataTableFast.h"
#import <MADQueryCacheAggregateFunctionParamaters.h>

#import "MADParameters+QueryCacheAggregate.h"

#import "MADElementStylizedText.h"

#import "MADPrintPageRendererDataSource.h"

#import "MADDocumentObjectReference.h"
#import "MADDocumentObject.h"

@class MTBarcode;

static NSString * const MTCachedSizeHorizontal = @"MTCachedSizeHorizontal";
static NSString * const MTCachedSizeVertical = @"MTCachedSizeVertical";

static const char *MADQueueTextRepresentation = "com.everdayapps.mad.accessibility";

static inline CGRect ElementBounds(CGRect, CGPoint);
static inline CGFloat HeightWithVisibility(CGFloat, BOOL);
static inline CGRect SectionBounds(CGRect, CGFloat, BOOL, MADDocumentSectionType, NSUInteger, NSUInteger, CGFloat);

static inline CGRect ElementBounds(CGRect documentObjectFrame, CGPoint sectionBoundsOrigin) {
    return CGRectMake(documentObjectFrame.origin.x + sectionBoundsOrigin.x,
                      documentObjectFrame.origin.y + sectionBoundsOrigin.y,
                      documentObjectFrame.size.width,
                      documentObjectFrame.size.height);
}

static inline CGFloat HeightWithVisibility(CGFloat height, BOOL visibility) {
    return visibility ? height : CGSizeZero.height;
}

static inline CGRect SectionBounds(CGRect pageRect,
                                   CGFloat sectionHeight,
                                   BOOL visility,
                                   MADDocumentSectionType sectionType,
                                   NSUInteger numberOfPages,
                                   NSUInteger pageIndex,
                                   CGFloat originY) {

    switch (sectionType) {
            
        case MADDocumentSectionTypePageFooter:
            originY = pageIndex == numberOfPages - 1 ?  // last page?
                pageRect.origin.y + pageRect.size.height - HeightWithVisibility(sectionHeight, visility) - sectionHeight :
                pageRect.origin.y + pageRect.size.height - HeightWithVisibility(sectionHeight, visility);
            break;
            
        case MADDocumentSectionTypeReportFooter:
            originY = pageRect.origin.y + pageRect.size.height - sectionHeight;
            break;
            
        default:
            break;
    }
    return CGRectMake(pageRect.origin.x,
                      originY,
                      pageRect.size.width,
                      HeightWithVisibility(sectionHeight, visility));
    
}


@interface MADPrintPageRenderer ()

    @property (nonatomic, assign) NSUInteger accessibilityCurrentPageIndex;
    @property (nonatomic, assign) CGRect accessibilityCurrentPageRect;

    @property (nonatomic, strong) NSArray <__kindof MADAccessibilityLine *> *accessibilityItems;

    @property (nonatomic, strong, readwrite) MADReportTextRepresentation *textRepresentation;

    @property (nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;

    @property (nonatomic, strong) MADDocumentObjectDataReference *dataReference;

@end

@implementation MADPrintPageRenderer {
    BOOL _showWaterMark;
    BOOL _accessibilityCacheNeedsUpdate;
    NSUInteger _accessibilityCurrentPageIndex;
}

+ (void)initialize {
    [super initialize];
    
    if (self == [MADPrintPageRenderer self]) {
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if ([standardUserDefaults valueForKey:MTCachedSizeHorizontal] == nil) {
            
            [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero)
                                     forKey: MTCachedSizeHorizontal];
            
            [standardUserDefaults setObject: NSStringFromCGSize(CGSizeZero)
                                     forKey: MTCachedSizeVertical];
            
            [standardUserDefaults synchronize];
            
        }
    }
}

+ (instancetype)newReportViewerPrintPageRendererWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource {
    
    [datasource updatePrintingReportFormatter];
    
    id printPageRenderer;
    printPageRenderer = [[MADPrintPageRenderer alloc] initWithDataSource:datasource];
    return printPageRenderer;
}

#pragma -
#pragma Helpers Drawing

+ (void)drawWhiteCanvas:(CGContextRef)ctx pageRect:(CGRect)pageRect {
    [[UIColor whiteColor] setFill];
    CGPathRef path = CGPathCreateWithRect(pageRect, NULL);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);
}

+ (void)drawWatermarkWithContext:(CGContextRef)ctx
                      inPageRect:(CGRect)pageRect {
    
    UIFont *customFont = [UIFont boldSystemFontOfSize:12.0000f];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIColor *strokeColor = [[UIColor alloc] initWithRed:170.0000f/256.0000f
                                                  green:170.0000f/256.0000f
                                                   blue:170.0000f/256.0000f alpha:0.8000f];
    UIColor *foregroundColor = [[UIColor alloc] initWithRed:85.0000f/256.0000f
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
    NSAttributedString *getMad = [[NSAttributedString alloc] initWithString: getMadS
                                                                 attributes: results];
    
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

#pragma -
#pragma NSObject

- (void)dealloc { }

#pragma -
#pragma Constructors

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource {
    if (self = [super init]) {
        self.datasource = datasource;
        self.dataReference = [[MADDocumentObjectDataReference alloc] initWithDataSource:datasource];
        _showWaterMark = NO;
        _accessibilityCacheNeedsUpdate = NO;
    }
    return self;
}

#pragma -
#pragma Propery Overrides

- (MADReportTextRepresentation *)textRepresentation {
    if (_textRepresentation == nil) {
        _textRepresentation =
            [[MADReportTextRepresentation alloc] initWithPageCount:
                                            (NSUInteger)self.datasource.reportFormatter.reportLayout.count];
    }
    return _textRepresentation;
}

#pragma -
#pragma Drawing Helpers

+ (UIColor *)backgroundColorForDocumentSectionType:(MADDocumentSectionType)type {
    switch (type) {
        case MADDocumentSectionTypeBody:
            return [UIColor redColor];
            break;
            
        case MADDocumentSectionTypeGroupFooter:
            return [UIColor purpleColor];
            break;
            
        case MADDocumentSectionTypeGroupHeader:
            return [UIColor yellowColor];
            break;
            
        case MADDocumentSectionTypePageFooter:
            return [UIColor grayColor];
            break;
            
        case MADDocumentSectionTypePageHeader:
            return [UIColor greenColor];
            break;
            
        case MADDocumentSectionTypeReportFooter:
            return [UIColor brownColor];
            break;
            
        case MADDocumentSectionTypeReportHeader:
            return [UIColor blueColor];
            break;
            
        default:
            return [UIColor magentaColor];
            break;
    }
}

- (void)setBackgroundColorForDocumentSection:(RptqDocumentSection *)documentSection
                                      inRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setFill];
    
    switch ([documentSection getDocumentSectionType]) {
        case MADDocumentSectionTypeBody:
            [[UIColor redColor] setFill];
            break;
            
        case MADDocumentSectionTypeGroupFooter:
            [[UIColor purpleColor] setFill];
            break;
            
        case MADDocumentSectionTypeGroupHeader:
            [[UIColor yellowColor] setFill];
            break;
            
        case MADDocumentSectionTypePageFooter:
            [[UIColor grayColor] setFill];
            break;
            
        case MADDocumentSectionTypePageHeader:
            [[UIColor greenColor] setFill];
            break;
            
        case MADDocumentSectionTypeReportFooter:
            [[UIColor brownColor] setFill];
            break;
            
        case MADDocumentSectionTypeReportHeader:
            [[UIColor blueColor] setFill];
            break;
            
        default:
            [[UIColor magentaColor] setFill];
            break;
    }
    
    CGPathRef path = CGPathCreateWithRect(rect, NULL);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);

}

#pragma -
#pragma Drawing loop

- (void)drawPageAtIndex:(NSUInteger)index inRect:(CGRect)pageRect
                       withTransparentBackground:(BOOL)transparentBackground {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [MADPrintPageRenderer drawWhiteCanvas: ctx pageRect: pageRect];
    
    [self drawPageAtIndex: index withContext: ctx inPageRect: pageRect];

    if (_showWaterMark) {
        [MADPrintPageRenderer drawWatermarkWithContext: ctx inPageRect: pageRect];
    }

}

- (void)drawPageAtIndex:(NSUInteger)pageIndex
            withContext:(CGContextRef)ctx
             inPageRect:(CGRect)pageRect {

    MADReportFormatter *reportFormatter = self.datasource.reportFormatter;
    if (pageIndex >= reportFormatter.numberOfPages) {
        return;
    }

    RptqDocument *document;
    CGFloat originY = pageRect.origin.y;
    NSUInteger rowIndex = 0, offsetElement = 0, offsetCharacter = 0;
    NSUInteger layoutSectionCounter = 0, readGroupCounter = 0;
    CGRect rect;
    
    [self.textRepresentation removeAllPages];
    document = (reportFormatter.layout).activeDocumentModel;
    
    NSEnumerator *layoutEnumerator = [reportFormatter layoutEnumerator:pageIndex];
    
    MADReportPageRepresentation *pageRepresentation =
            [[MADReportPageRepresentation alloc] initWithNumberOfSections:0];
    
    RptqDocumentSection *documentSection;
    MADReportSectionRepresentation *sectionRepresentation;
    
    self.dataReference.pageIndex = pageIndex;

    NSNumber *sectionIdentifier;
    for (MADSectionRepresentation *pageSection in layoutEnumerator) {

        self.dataReference.detailRowId = pageSection.detailRowId;
        
        documentSection = [document documentSectionForType: pageSection.sectionType
                                                  andLevel: pageSection.groupLevel];
        
        sectionIdentifier = @(documentSection.identifier);
        rect = SectionBounds(pageRect,
                             HeightWithVisibility([reportFormatter heightSection:sectionIdentifier],
                                                  documentSection.visibility),
                             documentSection.visibility,
                             pageSection.sectionType,
                             reportFormatter.numberOfPages,
                             pageIndex,
                             originY);

        
        if (pageSection.sectionType == MADDocumentSectionTypeGroupFooter &&
            pageSection.groupLevel == reportFormatter.numberOfGroups - 1) {
            readGroupCounter++;
        }
        
        sectionRepresentation = [self drawSection: documentSection
                                           inRect: rect
                                         pageRect: pageRect
                                      pageSection: pageSection
                                         document: document
                                          ofPages: reportFormatter.numberOfPages
                                           offset: originY
                                    offsetElement: offsetElement
                                  offsetCharacter: offsetCharacter];
        
        [pageRepresentation addSection:sectionRepresentation];
        
        if (pageSection.sectionType == MADDocumentSectionTypeBody) {
            rowIndex++;
        }
        
        originY += rect.size.height;
        layoutSectionCounter++;
    }
    
    
    [self.textRepresentation setPage:pageRepresentation forPageIndex:pageIndex];
    
}

- (MADReportSectionRepresentation *)drawSection: (RptqDocumentSection *)documentSection
                                         inRect: (CGRect)rect
                                       pageRect: (CGRect)pageRect
                                    pageSection: (MADSectionRepresentation *)pageSection
                                       document: (RptqDocument *)document
                                        ofPages: (NSUInteger)numberOfPages
                                         offset: (CGFloat)originY
                                  offsetElement: (NSUInteger)offsetElement
                                offsetCharacter: (NSUInteger)offsetCharacter {
    
    MADReportSectionRepresentation * _Nonnull sectionRepresentation;
    
    sectionRepresentation = [self drawSection: pageSection
                              documentSection: documentSection
                                       inRect: rect
                                offsetElement: offsetElement];
    

    return sectionRepresentation;
}

+ (void)setBackgroundColorForSectionType:(MADDocumentSectionType)type inRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[self backgroundColorForDocumentSectionType:type] setFill];
    CGPathRef path = CGPathCreateWithRect(rect, NULL);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);
}

- (MADReportSectionRepresentation *)drawSection: (MADSectionRepresentation *)pageSection
                                documentSection: (RptqDocumentSection *)documentSection
                                         inRect: (CGRect)sectionRect
                                  offsetElement: (NSUInteger)offsetElement {
    
    
    MADReportSectionRepresentation * _Nonnull sectionRepresentation;
    MADReportSectionRowsRepresentation * _Nonnull rowRepresentation;

    MADReportLineRepresentation * _Nonnull line;

    id drawingObject;

    NSEnumerator <RptqDocumentSectionRows *> *rowsEnumerator = documentSection.hasRows.objectEnumerator;
    
    sectionRepresentation = [[MADReportSectionRepresentation alloc] initWithNumberOfRows:1];
    sectionRepresentation.type = pageSection.sectionType;
    sectionRepresentation.elementOffset = offsetElement;
    
    NSEnumerator *documentObjectEnumerator;
    if (!((sectionRepresentation.visibility =
           documentSection.visibility))) goto END_DrawSection;
    
    MADDocumentSectionType type = [documentSection getDocumentSectionType];
    [MADPrintPageRenderer setBackgroundColorForSectionType: type
                                                    inRect: sectionRect];
    
    for (RptqDocumentSectionRows *row in rowsEnumerator) {
        
        documentObjectEnumerator = row.hasObjects.objectEnumerator;
        rowRepresentation = [[MADReportSectionRowsRepresentation alloc] initWithNumberOfSectionRowElements:0];
        
        for (RptqDocumentElement *item in documentObjectEnumerator) {

            self.dataReference.item = item;

            drawingObject = [MADDocumentObject newDocumentObject:self.dataReference];
            [drawingObject drawInRect:ElementBounds(item.frame, sectionRect.origin)];
            line = [[MADReportLineRepresentation alloc] initWithObject: drawingObject
                                                                  type: item.documentObjectType
                                                                 frame: item.frame];
            line.elementOffset = offsetElement;
            offsetElement++;
            
            [rowRepresentation addLine:line];
        }
        NSError * __autoreleasing error = nil;
        [sectionRepresentation addRow:rowRepresentation error:&error];
    }
    
END_DrawSection:;

    return sectionRepresentation;
}

#pragma mark -
#pragma mark UIPrintPageRender

- (NSInteger)numberOfPages {
    return (NSInteger)(self.datasource.reportFormatter).numberOfPages;
}

- (void)drawPageAtIndex:(NSInteger)index inRect:(CGRect)pageRect {
    CGRect rect = pageRect;
    [self drawPageAtIndex: (unsigned long)labs(index)
                   inRect: rect withTransparentBackground: NO];
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
    return self.textRepresentation;
}

/*- (void)updateAccessibilityItems {
    if (!self.accessibilityCacheNeedsUpdate) return;
    NSArray *items = [self accessibilityDrawingObjectsOnPageAtIndex:self.accessibilityCurrentPageIndex inPageRect:self.accessibilityCurrentPageRect];
    self.accessibilityItems = [NSArray arrayWithArray:items];
    self.accessibilityCacheNeedsUpdate = NO;
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
    
    MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnectionForUserCredentals:databaseSchemas.ownedByUser];
    MTDatabase *database = [MTDatabase newDatabaseWithConnection:databaseConnection];
    
    NSUInteger numberOfPages = self.reportFormatter.numberOfPages;
    if (pageIndex < numberOfPages) {
        
        CGFloat originY = pageRect.origin.y;
        NSEnumerator *layoutEnumerator = [self.reportFormatter layoutEnumerator:pageIndex];
        for (NSDictionary *pageSection in layoutEnumerator) {
            
            RptqDocumentSection *documentSection = [document documentSectionForType:pageSection.sectionType andLevel:pageSection.groupLevel];
            
            CGRect sectionRect = [self sectionRectForDocumentSection:documentSection pageSection:pageSection inDocument:document pageRect:pageRect numberOfPages:numberOfPages pageIndex:pageIndex offset:&originY];
            
            self.backgroundColorForDocumentSection:documentSection inRect:sectionRect];
            
            NSArray *groupLevelKeys = [self newObjectArrayOfGroupLevelKeysForDetailRow:pageSection.detailRowId];
            if (pageSection.sectionType == MADDocumentSectionTypeGroupFooter && pageSection.groupLevel == self.reportFormatter.numberOfGroups - 1) {
                readGroupCounter++;
            }
            if (documentSection.visibility.boolValue) {
                
                NSMutableArray *accessibilityLinesInSection = [[NSMutableArray alloc] init];
                for (RptqDocumentSectionRows *row in documentSection.hasRows) {
                    for (RptqDocumentElement *item in row.hasObjects) {
                        @autoreleasepool {
                            id drawingObject = [self newDrawingObjectForDatabase:database pageIndex:pageIndex groupLevelKeys:groupLevelKeys detailRowId:pageSection.detailRowId andItem:item];
                            MADAccessibilityLine *line = [[MADAccessibilityLine alloc] initWithValue:drawingObject
                                                                                                type:item.documentObjectType
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
            
            if (pageSection.sectionType == MADDocumentSectionTypeBody) {
                rowIndex++;
            }
            originY += sectionRect.size.height;
        }
        layoutSectionCounter++;
    }
    return accessibilityDrawingObjects;
}
*/
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

@end
