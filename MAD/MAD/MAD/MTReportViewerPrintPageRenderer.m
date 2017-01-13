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
#import <UIKit/UIInterface.h>
#import <UIKit/NSParagraphStyle.h>

#import "MADocument.h"
#import "MADDatabaseConnection.h"
#import "MTDatabaseField.h"

#import "RptqDocument+Extras.h"
#import "RptqDocumentObject+Extras.h"

#import "RptqDatabase.h"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryField.h"
#import "RptqUserCredentals.h"

#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentObjectAggregate+Extras.h"
#import "RptqDocumentObjectBarcode+Extras.h"

#import "RptqDatabaseSchemaField.h"

#import "RptqDocumentObjectLabel.h"
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
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MTDataTableFast.h>
#import <MADQueryCacheAggregateFunctionParamaters.h>

#import "MADParameters+QueryCacheAggregate.h"

#import "MADocumentObjectAttributesText.h"

@class MTBarcode;

static NSString * const MTCachedSizeHorizontal = @"MTCachedSizeHorizontal";
static NSString * const MTCachedSizeVertical = @"MTCachedSizeVertical";

static const char *MADQueueTextRepresentation = "com.everdayapps.mad.accessibility";

static inline NSRange MADRangeToGroup(NSNumber *groupNumber);
static inline NSRange MADRangeToGroup(NSNumber *groupNumber) {
    return NSMakeRange(0, groupNumber.unsignedIntegerValue + 1);
}

typedef MTDataTableFast MADDataTableAggregate;
typedef NSMutableDictionary <NSManagedObjectID *, UIFontDescriptor *> MADMutableFontDescriptorMap;

@interface MTReportViewerPrintPageRenderer ()

    @property (nonatomic, assign) BOOL showWaterMark;
    @property (nonatomic, assign) BOOL accessibilityCacheNeedsUpdate;

    @property (nonatomic, assign) NSUInteger accessibilityCurrentPageIndex;
    @property (nonatomic, assign) CGRect accessibilityCurrentPageRect;

    @property (nonatomic, weak) MTReportFormatter *reportFormatter;
    @property (nonatomic, weak) MADDataTableAggregate *dataTable;

    @property (nonatomic, strong) NSArray <__kindof MADAccessibilityLine *> *accessibilityItems;

    @property (nonatomic, strong, readwrite) MADReportTextRepresentation *textRepresentation;

    @property (nonatomic, strong) dispatch_queue_t textRepresentationQueue;

@end

@implementation MTReportViewerPrintPageRenderer

+ (void)initialize {
    [super initialize];
    
    if (self == [MTReportViewerPrintPageRenderer self]) {
        
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

+ (MTReportViewerPrintPageRenderer *)newReportViewerPrintPageRenderer:(MADocument *)document {
    
    MTReportFormatter *reportFormatter;
    reportFormatter = [MTReportFormatter newReportFormatterWithLayout: document
                                                              options: MTReportFormatterOptionsMargin];
    reportFormatter.overrideIdentifier = @"madprinter";
    reportFormatter.dataDelegate = document;
    reportFormatter.datasource = document;
    reportFormatter.cachedDelegate = document;
    
    MTDataTableFast *mainDataTable;
    id printPageRenderer;
    
    mainDataTable = document.mainDataTable;
    printPageRenderer = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: reportFormatter
                                                                               dataTable: mainDataTable];
    document.printingReportFormatter = reportFormatter;
    return printPageRenderer;
    
}

- (void)dealloc {
    _reportFormatter = nil;
    _dataTable = nil;
}

#pragma -
#pragma Constructors

- (instancetype)initWithReportFormatter:(MTReportFormatter *)reportFormatter
                              dataTable:(MTDataTableFast *)dataTable {

    if (self = [super init]) {
        
        dispatch_queue_t queue = dispatch_queue_create(MADQueueTextRepresentation,
                                                       DISPATCH_QUEUE_SERIAL);
        
        self.textRepresentationQueue =  queue;
        
        self.showWaterMark = NO;
        self.accessibilityCacheNeedsUpdate = NO;

        self.dataTable = (MADDataTableAggregate *)dataTable;
        self.reportFormatter = reportFormatter;
        
    }

    return self;
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
#pragma Propery Overrides

- (MADReportTextRepresentation *)textRepresentation {
    if (_textRepresentation == nil) {
        _textRepresentation =
            [[MADReportTextRepresentation alloc] initWithPageCount:
                                            (NSUInteger)self.reportFormatter.reportLayout.count];
    }
    return _textRepresentation;
}

#pragma -
#pragma Drawing Helpers

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
    [MTReportViewerPrintPageRenderer drawWhiteCanvas: ctx pageRect: pageRect];
    
    [self drawPageAtIndex: index withContext: ctx inPageRect: pageRect];

    if (self.showWaterMark) {
        [MTReportViewerPrintPageRenderer drawWatermarkWithContext: ctx inPageRect: pageRect];
    }

}

- (void)drawPageAtIndex:(NSUInteger)pageIndex
            withContext:(CGContextRef)ctx
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
    MADDatabaseConnection *databaseConnection;
    
    document = (reportFormatter.layout).activeDocumentModel;
    databaseSchemas = document.hasDatabaseSchemas.anyObject;
    
    RptqUserCredentals *credentals = databaseSchemas.ownedByUser;
    databaseConnection = [MADDatabaseConnection newDatabaseConnectionWithCredentals: credentals];
    
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
        
        if (pageSection.sectionType == MADDocumentSectionTypeGroupFooter &&
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
        
        if (pageSection.sectionType == MADDocumentSectionTypeBody) {
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
    
    NSOrderedSet *rows = [[NSOrderedSet alloc] initWithOrderedSet: documentSection.hasRows];
    
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
    
    NSNumber *detailRowID = pageSection.detailRowId.copy;

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
    
    groupLevelKeys = [self newObjectArrayOfGroupLevelKeysForDetailRow:detailRowID];
    
    for (row in rows) {
        
        //@autoreleasepool {
            
            items = [[NSOrderedSet alloc] initWithOrderedSet: row.hasObjects];
            
            rowRepresentation = [[MADReportSectionRowsRepresentation alloc]
                                 initWithNumberOfSectionRowElements:items.count];
            
            fontDescriptors = [[MADMutableFontDescriptorMap alloc] initWithCapacity:items.count];
            
            for (item in items) {
                //@autoreleasepool {
                
                
                
                    drawingObject = [self newDrawingObjectForDatabase: database
                                                            pageIndex: pageIndex
                                                       groupLevelKeys: groupLevelKeys
                                                          detailRowId: detailRowID
                                                              andItem: item];
                    
                    elementCanvasRect = item.frame;
                    elementCanvasRect.origin.x = elementCanvasRect.origin.x + sectionRect.origin.x;
                    elementCanvasRect.origin.y = elementCanvasRect.origin.y + sectionRect.origin.y;
                    
                    if ([drawingObject isKindOfClass:[NSString class]]) {
                        
                        fontDescriptor = fontDescriptors[item.objectID];
                        
                        MADocumentObjectAttributesText *attt;
                        attt = [[MADocumentObjectAttributesText alloc] initWithObject: item
                                                                    andFontDescriptor: fontDescriptor];
                        
                        if (!fontDescriptor) {
                            fontDescriptor = attt.fontDescriptor.copy;
                            fontDescriptors[item.objectID] = fontDescriptor;
                        }

                        [MTReportViewerPrintPageRenderer displayDrawingString: drawingObject
                                                            elementCanvasRect: elementCanvasRect
                                                               withAttributes: attt.fontAttributes];
                        
                    } else {
                        [MTReportViewerPrintPageRenderer displayDrawingObject: drawingObject
                                                            elementCanvasRect: elementCanvasRect];
                    }
                    
                    line = [[MADReportLineRepresentation alloc] initWithObject: drawingObject
                                                                          type: item.getType
                                                                         frame: item.frame];
                    line.elementOffset = offsetElement;
                    offsetElement++;
                    
                    [rowRepresentation addLine:line];
                    
                //}
                
            }
            
            [sectionRepresentation addRow:rowRepresentation];
            [fontDescriptors removeAllObjects];
        //}
    }

END_DrawSection:;

    return sectionRepresentation;
}

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
    
        case MADDocumentSectionTypePageFooter:
            originY = pageIndex == numberOfPages - 1 ?  // last page?
                            pageRect.origin.y + pageRect.size.height - sizeHeight -
                                [reportFormatter heightForSectionWithObjectID:document.hasReportFooterSection.objectID] :
                            pageRect.origin.y + pageRect.size.height - sizeHeight;
            break;
            
        case MADDocumentSectionTypeReportFooter:
            originY = pageRect.origin.y + pageRect.size.height -
                        [reportFormatter heightForSectionWithObjectID: documentSection.objectID];
            break;
            
        default:
            break;
    }
    
    return CGRectMake(pageRect.origin.x, originY, pageRect.size.width, sizeHeight);
}

+ (void)displayDrawingObject: (id)drawingObject
           elementCanvasRect: (CGRect)elementCanvasFrame {
    [drawingObject drawInRect: elementCanvasFrame];
}

+ (void)displayDrawingString: (NSString *)drawingString
           elementCanvasRect: (CGRect)elementCanvasFrame
              withAttributes: (NSDictionary *)attributes {
    [drawingString drawWithRect: elementCanvasFrame
                        options: NSStringDrawingUsesLineFragmentOrigin
                     attributes: attributes
                        context: nil];
}

- (id)newDocumentObjectForDocumentImage:(RptqDocumentObjectImage *)item {
    return item.image;
}


- (NSString *)newDocumentObjectForLabelStatic:(RptqDocumentObjectLabel *)item {
    return [NSString stringWithString:item.text];
}

- (NSString *)newDocumentObjectForLabelDynamic:(RptqDocumentObjectLabelDataField *)item
                                   forDatabase:(MTDatabase *)database
                                      forRowID:(NSNumber *)rowID {
    NSString *drawingObject;
    NSDictionary *rowData = [self.dataTable copyDataForCacheId:rowID];
    if (rowData != nil) {
        NSString *qa = [item.referencesQueryField.inQueryTable copyQueryAlias];
        MADSafeQueryField *tableFieldKey = [database newSafeQueryField: item.referencesQueryField.databaseSchemaField.name
                                                              andTable: qa];
        
        NSString *text = [item formattedString: item.referencesQueryField.databaseSchemaField.dataType.shortValue
                                      forValue: rowData[tableFieldKey]];
        drawingObject = [NSString stringWithString:text];
        if ([drawingObject isEqualToString:MTNullIdentifier]) {
            drawingObject = @"";
        }
    } else {
        drawingObject = @"";
    }
    return drawingObject;
}

- (MTBarcode *)newDocumentObjectForBarcode:(RptqDocumentObjectBarcode *)item
                               forDatabase:(MTDatabase *)database
                                  forRowID:(NSNumber *)rowID {
    
    NSDictionary *rowData = [self.dataTable copyDataForCacheId:rowID];
    
    NSString *tableQueryAlias1 = [item.referencesField1.inQueryTable copyQueryAlias];
    NSString *tableQueryAlias2 = [item.referencesField2.inQueryTable copyQueryAlias];

    MADSafeQueryField *tableFieldKey1, *tableFieldKey2;
    tableFieldKey1 = [database newSafeQueryField: item.referencesField1.databaseSchemaField.name
                                        andTable: tableQueryAlias1];
    tableFieldKey2 = [database newSafeQueryField: item.referencesField2.databaseSchemaField.name
                                        andTable: tableQueryAlias2];
                                                           
    NSString *input1 = [self inputForField: item.referencesField1
                         forDocumentObject: item.parentObjectBarcode
                                     value: rowData[tableFieldKey1]];
    NSString *input2 = [self inputForField: item.referencesField2
                         forDocumentObject: item.parentObjectBarcode
                                     value: rowData[tableFieldKey2]];
    
    MTBarcode *barcode = [RptqDocumentObjectBarcode newBarcodeWithDocumentObject:item
                                                                          input1:input1
                                                                          input2:input2];
    return barcode;
}

- (NSString *)inputForField:(RptqQueryField *)field forDocumentObject:(RptqDocumentObject *)item
                      value:(id)value {
    NSString *input1 = [item formattedString: field.databaseSchemaField.dataType.shortValue
                                    forValue: value];
    if ([input1 isEqualToString:MTNullIdentifier]) {
        return @"";
    } else {
        return [NSString stringWithString:input1];
    }
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

- (id)newDrawingObjectForDatabase: (MTDatabase *)database
                        pageIndex: (NSUInteger)pageIndex
                   groupLevelKeys: (NSArray *)groupLevelKeys
                      detailRowId: (NSNumber *)detailRowId
                          andItem: (RptqDocumentObject *)item {

    id drawingObject = nil;
    switch (item.getType) {
            
        case MTDocumentObjectTypeAggregate: {
            
            RptqDocumentObjectAggregate *isAggregate = item.isAggregate;
            RptqQueryField *aggregateField = isAggregate.aggregateField;
            RptqQueryTable *inQueryTable = aggregateField.inQueryTable;
            
            NSString *queryAlias = [inQueryTable copyQueryAlias];
            MADSafeQueryField *fieldKey;
            fieldKey = [database newSafeQueryField: aggregateField.databaseSchemaField.name
                                          andTable: queryAlias];
            
            NSArray *groupKeys;
            
            NSNumber *groupNumber = isAggregate.groupNumber;
            if (groupNumber.unsignedIntegerValue < groupLevelKeys.count) {
                groupKeys = [groupLevelKeys subarrayWithRange: MADRangeToGroup(groupNumber)];
            }
            
            RptqDatabaseSchemaField *databaseSchemaField = aggregateField.databaseSchemaField;
            MADDataType aggregateType = databaseSchemaField.dataType.shortValue;
            
            NSNumber * __unsafe_unretained function = isAggregate.function;
            BOOL calculateInMemory = function.unsignedIntegerValue == MTAggregateFunctionTypeFirst ||
                                     function.unsignedIntegerValue == MTAggregateFunctionTypeLast;
            
            id aggregateResult;
            MTReportFormatter *reportFormatter = self.reportFormatter;

            if (calculateInMemory == NO) {
                
                NSNumber * __unsafe_unretained groupType = isAggregate.groupType;
                MADIndexArray *rowIdsForPage = [reportFormatter rowidsForPage:pageIndex];
                aggregateResult = [MTReportViewerPrintPageRenderer newResultsForAggregateType: groupType.shortValue
                                                                                     function: function.shortValue
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
                                    if (section.unsignedIntegerValue == MADDocumentSectionTypeBody) {
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
                                    if (section.unsignedIntegerValue == MADDocumentSectionTypeBody) {
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
                                    if (section.unsignedIntegerValue == MADDocumentSectionTypeBody) {
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
                                    if (section.unsignedIntegerValue == MADDocumentSectionTypeBody) {
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
                                                  forDatabase: database
                                                     forRowID: detailRowId];
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
                   fromDataTable:(MTDataTableFast *)dataTable {

    id result = nil;
    NSString *columnKey = [dataTable columnKeyForColumnName:fieldKey];
    
    if (columnKey) {
        id queryParameters;
        
        switch (groupByType) {
            case MTAggregateGroupByTypePage: {
                queryParameters = [MADParameters newParamatersAggregateByPageWithFieldKey: columnKey
                                                                                andRowIds: rowids
                                                                          andFunctionType: function
                                                                             andDataTable: dataTable];
                break;
            }
            case MTAggregateGroupByTypeReport:
                queryParameters = [MADParameters newParametersAggregateByReportWithFieldKey: columnKey
                                                                            andFunctionType: function
                                                                               andDataTable: dataTable];
                break;
                
            case MTAggregateGroupByTypeSection:
                queryParameters = [MADParameters newParamatersAggregateByGroupKeys: groupKeys
                                                                       andFieldKey: columnKey
                                                                   andFunctionType: function
                                                                      andDataTable: dataTable];
                break;
                
            default:
                break;
        }
        
        MTQuery *query = [[MTQuery alloc] initWithQueryType: MADQueryTypeCacheAggregateFunction
                                                     object: queryParameters];
        result = [dataTable runSelectQuery:query];
        
    }
    
    return result;
}

#pragma mark -
#pragma mark UIPrintPageRender

- (NSInteger)numberOfPages {
    return (NSInteger)(self.reportFormatter).numberOfPages;
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
        NSEnumerator *layoutEnumerator = [self.reportFormatter layoutEnumeratorForPage:pageIndex];
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
