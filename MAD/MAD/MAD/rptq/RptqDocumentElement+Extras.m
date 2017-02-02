//
//  RptqDocumentElement+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElement+CoreDataProperties.h"

#import <UIKit/UIFontDescriptor.h>
#import <UIKit/UIGeometry.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSData.h>

#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/MADBorderStyle.h>
#import <MADCocoaExtensions/MADTextStyle.h>

#import "MADAlignment.h"
#import "MADFont.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentElementGroupKey.h"
#import "RptqDocumentElementGroupKey+CoreDataProperties.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElementAggregate+Extras.h"
#import "RptqDocumentElementFormula.h"
#import "RptqDocumentElementGroupKey.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"

#import "MADSectionLayoutManager.h"
#import "RptqDocumentElementBarcode+Extras.h"

#import "MADCurrencyFormatter.h"

#import <math.h>

NSString * const MTDocumentObjectDefinationType = @"MTDocumentObjectDefinationType";
NSString * const MTDocumentObjectDefinationObject = @"MTDocumentObjectDefinationObject";

NSString * const MTDocumentObjectDefinationAggregateType = @"MTDocumentObjectDefinationAggregateType";
NSString * const MTDocumentObjectDefinationAggregatePivotNumber = @"MTDocumentObjectDefinationAggregatePivotNumber";
NSString * const MTDocumentObjectDefinationAggregatePivotType = @"MTDocumentObjectDefinationAggregatePivotType";
NSString * const MTDocumentObjectDefinationAggregateObjectId = @"MTDocumentObjectDefinationAggregateObjectId";
NSString * const MTDocumentObjectDefinationAggregateFunctionInputType = @"MTDocumentObjectDefinationAggregateFunctionInputType";

NSString * const MTDocumentObjectDefinationField1 = @"MTDocumentObjectDefinationField1";
NSString * const MTDocumentObjectDefinationField2 = @"MTDocumentObjectDefinationField2";

static NSNumberFormatter *currencyNumberFormatter;

//
//             Box model refresher
//
//  ..............................................
//  :                Margin                      :
//  :    ------------Border------------------    :
//  :    |           Padding                |    :
//  :    |                                  |    :
//  :    |                                  |    :
//  :    |                                  |    :
//  :    |                                  |    :
//  :    |           Padding                |    :
//  :    ------------Border------------------    :
//  :                Margin                      :
//  :.............................................
//
//

@implementation RptqDocumentElement (Extras)

#pragma mark -
#pragma mark Static Helpers


static inline CGFloat MADDocObjSizeWidthCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGFloat MADDocObjSizeHeightCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGRect MADDocObjFrameCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline double paddingViewBoundsSizeHeight(double, double, double);
static inline double paddingViewBoundsSizeWidth(double, double, double);

static inline double paddingViewBoundsSizeHeight(double paddingTop, double paddingBottom, double sizeHeight) {
    return paddingTop + paddingBottom + sizeHeight;
}

static inline double paddingViewBoundsSizeWidth(double paddingLeft, double paddingRight, double sizeWidth) {
    return paddingLeft + paddingRight + sizeWidth;
}

static inline CGFloat MADDocObjSizeWidthCalculated(CGFloat paddingLeft, CGFloat borderWidthLeft, CGFloat marginLeft, CGFloat sizewidth, CGFloat marginRight, CGFloat borderWidthRight, CGFloat paddingRight) {
    return paddingLeft + borderWidthLeft + marginLeft + sizewidth + marginRight + borderWidthRight + paddingRight;
}

static inline CGFloat MADDocObjSizeHeightCalculated(CGFloat paddingTop, CGFloat borderHeightTop, CGFloat marginTop, CGFloat sizeheight, CGFloat marginBottom, CGFloat borderHeightBottom, CGFloat paddingBottom) {
    return paddingTop + borderHeightTop + marginTop + sizeheight + marginBottom + borderHeightBottom + paddingBottom;
}

static inline CGRect MADDocObjFrameCalculated(CGFloat x, CGFloat sx, CGFloat y, CGFloat sy, CGFloat w, CGFloat sw, CGFloat h, CGFloat wh) {
    return CGRectMake(x + sx, y + sy, w + sw, h + wh);
}

+ (instancetype)documentObjectForObject:(NSManagedObject *)managedObject {
    RptqDocumentElement *result = nil;
    
    if ([managedObject isKindOfClass:[RptqDocumentElement class]]) {
        result = (RptqDocumentElement *)managedObject;
        
    } else if ([managedObject isKindOfClass:[RptqDocumentElementGroupKey class]]) {
        result = ((RptqDocumentElementGroupKey *)managedObject);
        
    } else if ([managedObject isKindOfClass:[RptqDocumentElementLabel class]]) {
        result = ((RptqDocumentElementLabel *)managedObject);
        
    } else if ([managedObject isKindOfClass:[RptqDocumentElementBarcode class]]) {
        result = ((RptqDocumentElementBarcode *)managedObject);
        
    } else if ([managedObject isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
        result = ((RptqDocumentElementLabelDataField *)managedObject);
        
    }
    return result;
}

+ (void)removeDocumentObject:(RptqDocumentElement *)documentObject
           fromParentSection:(RptqDocumentSection *)section
           withLayoutManager:(MADSectionLayoutManager *)layoutManager {
    
    RptqDocumentSectionRows *sectionRow = documentObject.inSectionRow;
    
    NSOrderedSet *sectionRowHasObjects =  documentObject.inSectionRow.hasObjects;
    NSUInteger deleteIndex = [sectionRowHasObjects indexOfObject:documentObject];
    
    NSMutableOrderedSet *hasObjects = documentObject.inSectionRow.hasObjects.mutableCopy;
    [hasObjects removeObjectAtIndex:deleteIndex];
    
    [layoutManager removeItemWithID:documentObject.objectID];
    [layoutManager layout];
    
    sectionRow.hasObjects = hasObjects;
    documentObject.inSectionRow = nil;
    section.height = (float)layoutManager.size.height;
}

#pragma mark -
#pragma mark Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSFetchRequest *request;
    NSString *entityName = NSStringFromClass([RptqDocumentElement class]);
    NSString *key = NSStringFromSelector(@selector(identifier));
    
    request = [[NSFetchRequest alloc] initWithEntityName: entityName];

    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key ascending: NO];
    
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    int64_t idNumber = 0;
    int64_t lastDropIndex = 0;
    if (error == nil) {
        RptqDocumentElement *lastObject = fetchResults.lastObject;
        idNumber = lastObject.identifier + 1;
        lastDropIndex = lastObject.dropIndex + 1;
    }
    
    NSString *fontname = [[NSString alloc] initWithString:[MADFont defaultFamily]];
    self.fontname = fontname;

    self.fontsize = [MADFont defaultSize];
    self.identifier = idNumber;
    self.dropIndex = lastDropIndex;
    
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

- (void)setPaddingTop:(double)v {
    MADLayoutPadding_t p;
    [(NSValue *)self.padding getValue:&p];
    p.top = v;
    [NSValue value:&p withObjCType:@encode(MADLayoutPadding_t)];
}

- (void)setPaddingBottom:(double)v {
    MADLayoutPadding_t p;
    [(NSValue *)self.padding getValue:&p];
    p.bottom = v;
    [NSValue value:&p withObjCType:@encode(MADLayoutPadding_t)];
}


- (void)setPaddingLeft:(double)v {
    MADLayoutPadding_t p;
    [(NSValue *)self.padding getValue:&p];
    p.left = v;
    [NSValue value:&p withObjCType:@encode(MADLayoutPadding_t)];
}

- (void)setPaddingRight:(double)v {
    MADLayoutPadding_t p;
    [(NSValue *)self.padding getValue:&p];
    p.right = v;
    [NSValue value:&p withObjCType:@encode(MADLayoutPadding_t)];
}

- (void)setMarginTop:(double)v {
    MADMargin_t m;
    [(NSValue *)self.margin getValue:&m];
    m.top = v;
    [NSValue value:&m withObjCType:@encode(MADMargin_t)];
}

- (void)setMarginBottom:(double)v {
    MADMargin_t m;
    [(NSValue *)self.margin getValue:&m];
    m.bottom = v;
    [NSValue value:&m withObjCType:@encode(MADMargin_t)];
}

- (void)setMarginRight:(double)v {
    MADMargin_t m;
    [(NSValue *)self.margin getValue:&m];
    m.right = v;
    [NSValue value:&m withObjCType:@encode(MADMargin_t)];
}

- (void)setMarginLeft:(double)v {
    MADMargin_t m;
    [(NSValue *)self.margin getValue:&m];
    m.left = v;
    [NSValue value:&m withObjCType:@encode(MADMargin_t)];
}

- (void)setBold:(BOOL)bold {
    MADTextStyle_t textStyle;
    [(NSValue *)self.style getValue:&textStyle];
    textStyle.bold = bold;
    [NSValue value:&textStyle withObjCType:@encode(MADTextStyle_t)];
}

- (void)setItalic:(BOOL)italic {
    MADTextStyle_t textStyle;
    [(NSValue *)self.style getValue:&textStyle];
    textStyle.italic = italic;
    [NSValue value:&textStyle withObjCType:@encode(MADTextStyle_t)];
}

- (void)setStrikethrough:(BOOL)strikethrough {
    MADTextStyle_t textStyle;
    [(NSValue *)self.style getValue:&textStyle];
    textStyle.strikethrough = strikethrough;
    [NSValue value:&textStyle withObjCType:@encode(MADTextStyle_t)];
}

- (void)setUnderline:(BOOL)underline {
    MADTextStyle_t textStyle;
    [(NSValue *)self.style getValue:&textStyle];
    textStyle.underline = underline;
    [NSValue value:&textStyle withObjCType:@encode(MADTextStyle_t)];
}

- (void)setSizeWidth:(double)width {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    s.width = width;
    [NSValue value:&s withObjCType:@encode(CGSize)];
}

- (void)setSizeHeight:(double)height {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    s.height = height;
    [NSValue value:&s withObjCType:@encode(CGSize)];
}

- (void)setHorizontalAlignment:(MADHorizontalAlignment)alignment {
    MADAlignment_t a;
    [(NSValue *)self.alignment getValue:&a];
    a.horizontal = alignment;
    [NSValue value:&a withObjCType:@encode(MADAlignment_t)];
}

- (void)setVerticalAlignment:(MADVerticalAlignment)alignment {
    MADAlignment_t a;
    [(NSValue *)self.alignment getValue:&a];
    a.vertical = alignment;
    [NSValue value:&a withObjCType:@encode(MADAlignment_t)];
}

- (CGPoint)placementPoint {
    CGPoint placementPoint = [(NSValue *)self.dropPoint CGPointValue];
    return placementPoint;
}

- (void)setSizeWidth:(double)w height:(double)h {
    CGSize s = CGSizeMake(w, h);
    self.size = [NSValue valueWithCGSize:s];
}

- (void)setSizeValue:(CGSize)size {
    self.size = [NSValue valueWithCGSize:size];
}

- (void)setOriginPoint:(CGPoint)or {
    self.origin = [NSValue valueWithCGPoint:or];
}

- (MADMargin_t)layoutMargin {
    MADMargin_t layoutMargin;
    [(NSValue *)self.margin getValue:&layoutMargin];
    return layoutMargin;
}

- (MADLayoutPadding_t)layoutPadding {
    MADLayoutPadding_t padding;
    [(NSValue *)self.padding getValue:&padding];
    return padding;
}

- (MADBorderStyle_t)layoutBorderStyle {
    MADBorderStyle_t borderStyle;
    [(NSValue *)self.border getValue:&borderStyle];
    return borderStyle;
}

- (double)spacingLeft {
    MADMargin_t margin = [self layoutMargin];
    MADLayoutPadding_t padding = [self layoutPadding];
    MADBorderStyle_t border = [self layoutBorderStyle];
    return margin.left + border.left + padding.left;
}

- (double)spacingRight {
    MADMargin_t margin = [self layoutMargin];
    MADLayoutPadding_t padding = [self layoutPadding];
    MADBorderStyle_t border = [self layoutBorderStyle];
    return margin.right + border.right + padding.right;
}

- (double)spacingTop {
    MADMargin_t margin = [self layoutMargin];
    MADLayoutPadding_t padding = [self layoutPadding];
    MADBorderStyle_t border = [self layoutBorderStyle];
    return margin.top + border.top + padding.top;
}

- (double)spacingBottom {
    MADMargin_t margin = [self layoutMargin];
    MADLayoutPadding_t padding = [self layoutPadding];
    MADBorderStyle_t border = [self layoutBorderStyle];
    return margin.bottom + border.bottom + padding.bottom;
}

- (CGFloat)sizeWidthCalculated {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    MADMargin_t margin = [self layoutMargin];
    MADLayoutPadding_t padding = [self layoutPadding];
    MADBorderStyle_t border = [self layoutBorderStyle];
    return MADDocObjSizeWidthCalculated(padding.left,
                                         border.left,
                                         margin.left,
                                         s.width,
                                         margin.right,
                                         border.right,
                                         padding.right);
}

- (CGFloat)sizeHeightCalculated {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    MADMargin_t margin = [self layoutMargin];
    MADLayoutPadding_t padding = [self layoutPadding];
    MADBorderStyle_t border = [self layoutBorderStyle];
    return MADDocObjSizeHeightCalculated(padding.top,
                                         border.top,
                                         margin.top,
                                         s.height,
                                         margin.bottom,
                                         border.bottom,
                                         padding.bottom);
}

- (CGSize)innerSize {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    return s;
}

- (CGSize)sizeCalculated {
    return CGSizeMake([self sizeWidthCalculated], [self sizeHeightCalculated]);
}

- (CGSize)sizeContentView {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    return s;
}

- (CGRect)boundsContentView {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    return CGRectMake(CGPointZero.x, CGPointZero.y, s.width, s.height);
}

- (CGRect)paddingViewBounds {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    MADLayoutPadding_t padding = [self layoutPadding];
    return CGRectMake(CGPointZero.x, CGPointZero.y,
                      paddingViewBoundsSizeWidth(padding.left,
                                                 padding.right,
                                                 s.width),
                      paddingViewBoundsSizeHeight(padding.top,
                                                  padding.bottom,
                                                  s.height));
}

- (CGRect)paddingViewFrame {
    CGRect paddingViewBounds = [self paddingViewBounds];
    MADMargin_t margin = [self layoutMargin];
    return CGRectMake(CGPointZero.x + margin.left,
                      CGPointZero.y + margin.top,
                      paddingViewBounds.size.width, paddingViewBounds.size.height);
}

- (CGRect)elementViewBounds {
    CGSize s;
    [(NSValue *)self.size getValue:&s];
    return CGRectMake(CGPointZero.x, CGPointZero.y, s.width, s.height);
}

- (CGRect)elementViewFrameDesigner {
    CGPoint o; CGSize s;
    [(NSValue *)self.size getValue:&s];
    [(NSValue *)self.origin getValue:&o];
    return CGRectMake(o.x, o.y, s.width, s.height);
}

- (CGRect)elementViewFrame {
    CGRect elementViewBounds = [self elementViewBounds];
    MADLayoutPadding_t p = [self layoutPadding];
    return CGRectMake(CGPointZero.x + p.left,
                      CGPointZero.y + p.top,
                      elementViewBounds.size.width, elementViewBounds.size.height);
}

- (CGRect)frame {
    CGPoint o; CGSize s;
    [(NSValue *)self.size getValue:&s];
    [(NSValue *)self.origin getValue:&o];
    return MADDocObjFrameCalculated(o.x, self.spacingLeft,
                                    o.y, self.spacingTop,
                                    s.width, self.spacingRight,
                                    s.height, self.spacingBottom);
}

#pragma mark - Member

- (MTDocumentObjectType)documentObjectType {
    return self.type;
}

- (NSString *)copyDesignerRepresentationText {
    @throw NSInternalInconsistencyException;
}

- (void)dropAtRect:(CGRect)rect {
    rect.size.width = nearbyint(rect.size.width);
    rect.size.height = nearbyint(rect.size.height);
    self.size = [NSValue value:&rect.size withObjCType:@encode(CGSize)];
}

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    
    NSString *result;
    switch (dataType) {
    
        case MADDataTypeYear:
            if ([value isKindOfClass:[NSString class]]) {
                result = value;
            } else if ([value isKindOfClass:[NSNumber class]]) {
                result = [[NSString alloc] initWithFormat:@"%ld", (long)((NSNumber *)value).integerValue];
            } else {
                result = [[NSString alloc] initWithFormat:@"%@", value];
            }
            break;
            
        case MADDataTypeGeometry:
            result = [[NSString alloc] initWithFormat:@"%@", value];
            break;
            
        case MADDataTypeImage:
            result = [[NSString alloc] initWithFormat:@"%@", value];
            break;
            
        case MADDataTypeSet:
            result = [[NSString alloc] initWithFormat:@"%@", value];
            break;
            
        case MADDataTypeUnknown:
            result = [[NSString alloc] initWithFormat:@"%@", value];
            break;
            
        case MADDataTypeDate:
        case MADDataTypeDateTime:
        case MADDataTypeTime:
        case MADDataTypeTimeStamp: {
            static NSDateFormatter *dateformatter;
            static NSDateFormatter *timeformatter;
            static NSDateFormatter *dateTimeformatter;
            if (dateformatter == nil) {
                dateformatter = [[NSDateFormatter alloc] init];
                dateformatter.dateStyle = NSDateFormatterShortStyle;
                dateformatter.timeStyle = NSDateFormatterNoStyle;
            }
            if (timeformatter == nil) {
                timeformatter = [[NSDateFormatter alloc] init];
                timeformatter.dateStyle = NSDateFormatterNoStyle;
                timeformatter.timeStyle = NSDateFormatterShortStyle;
            }
            if (dateTimeformatter == nil) {
                dateTimeformatter = [[NSDateFormatter alloc] init];
                dateTimeformatter.dateStyle = NSDateFormatterShortStyle;
                dateTimeformatter.timeStyle = NSDateFormatterShortStyle;
            }
            NSDate *d = nil;
            if ([value isKindOfClass:[NSData class]]) {
                d = value;
            } else {
                NSTimeInterval t = 0;
                if ([value isKindOfClass:[NSString class]]) {
                    t = ((NSString *)value).longLongValue;
                } else if ([value isKindOfClass:[NSNumber class]]) {
                    t = [value longLongValue];
                }
                d = [NSDate dateWithTimeIntervalSince1970:t];
            }
            switch (dataType) {
                case MADDataTypeDate:
                    result = [dateformatter stringFromDate:d];
                    break;
                case MADDataTypeDateTime:
                    result = [dateTimeformatter stringFromDate:d];
                    break;
                case MADDataTypeTime:
                    result = [timeformatter stringFromDate:d];
                    break;
                    
                case MADDataTypeTimeStamp:
                    result = [dateformatter stringFromDate:d];
                    break;

                default:
                    result = [[NSString alloc] initWithFormat:@"%@", value];
                    break;
            }
  
            break;
        }
        
        case MADDataTypeBlob:
            result = [[NSString alloc] initWithFormat:@"%@", value];
            break;
            
        case MADDataTypeBit:
        case MADDataTypeFloat:
        case MADDataTypeInteger:
        case MADDataTypeLong:
        case MADDataTypeLongLong:
        case MADDataTypeInt24:
        case MADDataTypeEnum:
        case MADDataTypeDouble:
        case MADDataTypeDecimal:
        case MADDataTypeNumber:
        {
            if ([value isKindOfClass:[NSNumber class]]) {
                
                if (((MADCurrencyFormatter *)self.numericFormat).enabled) {
                    if (!currencyNumberFormatter) {
                        currencyNumberFormatter = [[NSNumberFormatter alloc] init];
                        currencyNumberFormatter.locale = [NSLocale currentLocale];
                        currencyNumberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
                    }
                    result = [currencyNumberFormatter stringFromNumber:value];
                } else {
                    NSMutableString *formatString = [[NSMutableString alloc] initWithString:@"%."];
                    [formatString appendFormat:@"%ld", ((MADCurrencyFormatter *)self.numericFormat).decimalCount];
                    [formatString appendString:@"f"];
                    result = [[NSString alloc] initWithFormat:formatString, [value floatValue]];
                }
            } else {
                result = [[NSString alloc] initWithFormat:@"%@", value];
            }
            break;
        }
        case MADDataTypeString:
            result = [[NSString alloc] initWithFormat:@"%@", value];
            break;
        default:
            result = [[NSString alloc] initWithFormat:@"%@", value];
            break;
    }
    if (result == nil) {
        result = @"";
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toString {
    return [self toStringDebug];
}

- (NSString *)toStringDebug {
    return [[NSString alloc] initWithFormat: @"%@-%@", self, [self copyDesignerRepresentationText]];
}

- (NSString *)toStringHumanReadable {
    NSString *result = [self copyDesignerRepresentationText];
    return result;
}

- (NSAttributedString *)toAttributedString {
    return nil;
}

- (NSString *)debugDescriptionType {
    switch (self.type) {
        case MTDocumentObjectTypeAggregate:
            return @"Aggregate";
            break;
            
        case MTDocumentObjectTypeChart:
            return @"Chart";
            break;
            
        case MTDocumentObjectTypeFormula:
            return @"Formula";
            break;
            
        case MTDocumentObjectTypeGroupKey:
            return @"Group Key";
            break;

        case MTDocumentObjectTypeImage:
            return @"Image";
            break;
            
        case MTDocumentObjectTypeLabelDynamic:
            return @"Dynamic";
            break;
            
        case MTDocumentObjectTypeLabelStatic:
            return @"Static";
            break;
            
        case MTDocumentObjectTypeWhtiespace:
            return @"Whitespace";
            break;
            
        case MTDocumentObjectTypeBarcode:
            return @"Barcode";
            break;

        default:
            return @"Unknown";
            break;
    }
}

- (UIFontDescriptor *)fontDescriptor {
    
    MADTextStyle_t textStyle;
    [(NSValue *)self.style getValue:&textStyle];
    NSString *fontname;
    
    UIFontDescriptorSymbolicTraits traits = 0;
    if (textStyle.italic) traits     |= UIFontDescriptorTraitItalic;
    if (textStyle.bold)   traits     |= UIFontDescriptorTraitBold;
    
    NSNumber *traitsWrapper = [[NSNumber alloc] initWithUnsignedInt: traits];
    
    NSDictionary *symbolicTraits = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    traitsWrapper, UIFontSymbolicTrait, nil];
    
    fontname = self.fontname;

    NSDictionary *fontAttributes;
    fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      fontname,       UIFontDescriptorFamilyAttribute,
                      self.fontsize,  UIFontDescriptorSizeAttribute,
                      symbolicTraits, UIFontDescriptorTraitsAttribute, nil];
    
    UIFontDescriptor *fontDescriptor;
    fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
    fontAttributes = nil;
    return fontDescriptor;
}


- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %lld (%@)\n", self.identifier, self.debugDescriptionType];
    [description appendFormat:@"Section:                %@\n", [self.inSectionRow.inSection localizedDisplayName]];
    [description appendFormat:@"Font:                   %@ (%f)\n", self.fontname, self.fontsize];
    [description appendFormat:@"*********"];
    return description;
}

@end
