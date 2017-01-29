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

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSData.h>

#import "MTAlignment.h"
#import "MADFont.h"
#import "RptqQueryField+CoreDataClass.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentElementGroupKey+CoreDataClass.h"
#import "RptqDocumentElementGroupKey+CoreDataProperties.h"
#import "RptqDocumentElementAggregate+CoreDataClass.h"
#import "RptqDocumentElementAggregate+Extras.h"
#import "RptqDocumentElementFormula+CoreDataClass.h"
#import "RptqDocumentElementFormula+CoreDataProperties.h"
#import "RptqDocumentElementGroupKey+CoreDataClass.h"
#import "RptqDocumentElementLabel+CoreDataClass.h"
#import "RptqDocumentElementImage+CoreDataClass.h"
#import "RptqDocumentElementLabelDataField+CoreDataClass.h"
#import "RptqDocumentElementLabelDataField+CoreDataProperties.h"
#import "RptqDocumentElementBarcode+CoreDataClass.h"
#import "RptqDocumentSection+CoreDataClass.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows+CoreDataClass.h"

#import "MADSectionLayoutManager.h"
#import "RptqDocumentElementBarcode+Extras.h"

#import <math.h>

#import <UIKit/UIFontDescriptor.h>

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


static inline CGFloat paddingViewBoundsSizeHeight(NSNumber *paddingTop, NSNumber *paddingBottom, NSNumber *sizeHeight);
static inline CGFloat MADDocObjSizeWidthCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGFloat MADDocObjSizeHeightCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGRect MADDocObjFrameCalculated(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGFloat paddingViewBoundsSizeWidth(NSNumber *paddingLeft, NSNumber *paddingRight, NSNumber *sizeWidth);

static inline CGFloat paddingViewBoundsSizeHeight(NSNumber *paddingTop, NSNumber *paddingBottom, NSNumber *sizeHeight) {
    return paddingTop.floatValue + paddingBottom.floatValue + sizeHeight.floatValue;
}

static inline CGFloat paddingViewBoundsSizeWidth(NSNumber *paddingLeft, NSNumber *paddingRight, NSNumber *sizeWidth) {
    return paddingLeft.floatValue + paddingRight.floatValue + sizeWidth.floatValue;
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
        
    } else if ([managedObject respondsToSelector:@selector(parentObject)]) {
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
    
    CGFloat h = layoutManager.size.height;
    
    CFNumberRef height = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &h);
    section.height = (__bridge NSNumber *)(height);
    CFRelease(height);
    
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
    NSUInteger idNumber = 0;
    NSUInteger lastDropIndex = 0;
    if (error == nil) {
        RptqDocumentElement *lastObject = fetchResults.lastObject;
        idNumber = lastObject.identifier.unsignedIntegerValue + 1;
        lastDropIndex = lastObject.dropIndex.unsignedIntegerValue + 1;
    }
    
    NSString *fontname = [[NSString alloc] initWithString:[MADFont defaultFamily]];
    self.fontname = fontname;

    double fontPointSize = [MADFont defaultSize];
    CFNumberRef fontSize = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &fontPointSize);
    self.fontsize = (__bridge NSNumber *)(fontSize);
    CFRelease(fontSize);

    NSNumber *identifier = [[NSNumber alloc] initWithUnsignedInteger: idNumber];
    self.identifier = identifier;

    NSNumber *dropIndex = [[NSNumber alloc] initWithUnsignedInteger: lastDropIndex];
    self.dropIndex = dropIndex;
    
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

- (void)setOrigin:(CGPoint)origin {
    NSNumber *x = [[NSNumber alloc] initWithUnsignedLong:(unsigned long) origin.x];
    NSNumber *y = [[NSNumber alloc] initWithUnsignedLong:(unsigned long) origin.y];
    self.originx = x;
    self.originy = y;
}

- (CGFloat)spacingLeft {
    return self.marginLeft.floatValue + self.borderWidthLeft.floatValue + self.paddingLeft.floatValue;
}

- (CGFloat)spacingRight {
    return self.marginRight.floatValue + self.borderWidthRight.floatValue + self.paddingRight.floatValue;
}

- (CGFloat)spacingTop {
    return self.marginTop.floatValue + self.borderHeightTop.floatValue + self.paddingTop.floatValue;
}

- (CGFloat)spacingBottom {
    return self.marginBottom.floatValue + self.borderHeightBottom.floatValue + self.paddingBottom.floatValue;
}

- (CGFloat)sizeWidthCalculated {
    return MADDocObjSizeWidthCalculated(self.paddingLeft.floatValue,
                                         self.borderWidthLeft.floatValue,
                                         self.marginLeft.floatValue,
                                         self.sizewidth.floatValue,
                                         self.marginRight.floatValue,
                                         self.borderWidthRight.floatValue,
                                         self.paddingRight.floatValue);
}

- (CGFloat)sizeHeightCalculated {
    return MADDocObjSizeHeightCalculated(self.paddingTop.floatValue,
                                         self.borderHeightTop.floatValue,
                                         self.marginTop.floatValue,
                                         self.sizeheight.floatValue,
                                         self.marginBottom.floatValue,
                                         self.borderHeightBottom.floatValue,
                                         self.paddingBottom.floatValue);
}

- (CGSize)size { return CGSizeMake([self sizeWidthCalculated], [self sizeHeightCalculated]); }

- (CGSize)sizeContentView {
    return CGSizeMake(self.sizewidth.floatValue, self.sizeheight.floatValue);
}

- (CGRect)boundsContentView {
    CGSize size = [self size];
    return CGRectMake(CGPointZero.x, CGPointZero.y, size.width, size.height);
}

- (CGRect)paddingViewBounds {
    return CGRectMake(CGPointZero.x, CGPointZero.y,
                      paddingViewBoundsSizeWidth(self.paddingLeft,
                                                 self.paddingRight,
                                                 self.sizewidth),
                      paddingViewBoundsSizeHeight(self.paddingTop,
                                                  self.paddingBottom,
                                                  self.sizeheight));
}

- (CGRect)paddingViewFrame {
    CGRect paddingViewBounds = [self paddingViewBounds];
    return CGRectMake(CGPointZero.x + self.marginLeft.floatValue,
                      CGPointZero.y + self.marginTop.floatValue,
                      paddingViewBounds.size.width, paddingViewBounds.size.height);
}

- (CGRect)elementViewBounds {
    return CGRectMake(CGPointZero.x, CGPointZero.y, self.sizewidth.floatValue, self.sizeheight.floatValue);
}

- (CGRect)elementViewFrameDesigner {
    return CGRectMake(self.originx.floatValue, self.originy.floatValue,
                      self.size.width, self.size.height);
}

- (CGRect)elementViewFrame {
    CGRect elementViewBounds = [self elementViewBounds];
    return CGRectMake(CGPointZero.x + self.paddingLeft.floatValue,
                      CGPointZero.y + self.paddingTop.floatValue,
                      elementViewBounds.size.width, elementViewBounds.size.height);
}

- (CGRect)frame {
    return MADDocObjFrameCalculated(self.originx.floatValue, self.spacingLeft,
                                    self.originy.floatValue, self.spacingTop,
                                    self.sizewidth.floatValue, self.spacingRight,
                                    self.sizeheight.floatValue, self.spacingBottom);
}

#pragma mark - Member

- (MTDocumentObjectType)documentObjectType {
    return self.type.shortValue;
}

- (NSString *)copyDesignerRepresentationText {

    NSString *result = nil;
    
    switch (self.type.integerValue) {
    
        case MTDocumentObjectTypeAggregate: {
            result = [self copyDesignerRepresentationText];
            break;
        }

        case MTDocumentObjectTypeChart:
            result = @"chart";
            break;

        case MTDocumentObjectTypeFormula:
            result = [(RptqDocumentElementFormula *)self source];
            break;
        
        case MTDocumentObjectTypeGroupKey: {
            NSNumber *groupNumber = [((RptqDocumentElementGroupKey *)self) groupNumber];
            NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: groupNumber
                                                                         numberStyle: NSNumberFormatterSpellOutStyle];
            NSString *gorupFormatString = NSLocalizedString(@"Group %@", @"Like 'Group Three.'");
            result = [[NSString alloc] initWithFormat:gorupFormatString, groupNumberText.uppercaseString];
            break;
        }
        
        case MTDocumentObjectTypeImage:
            result = @"image";
            break;
        
        case MTDocumentObjectTypeLabelDynamic:
            result = [((RptqDocumentElementLabelDataField *)self) referencesQueryField].toStringReverse;
            break;
        
        case MTDocumentObjectTypeLabelStatic:
            result = ((RptqDocumentElementLabel *)self).text;
            break;
        case MTDocumentObjectTypeWhtiespace:
            result = @"Whitespace";
            break;
            
        case MTDocumentObjectTypeBarcode: {
            NSString *barcodeName = [(RptqDocumentElementBarcode *)self copyBarcodeTypeName];
            result = [[NSString alloc] initWithFormat:@"Barcode (%@)", barcodeName];
            break;
        }
        default:
            result = @"";
            break;
    
    }
    return result;
}

- (void)dropAtRect:(CGRect)rect {
    id size = [[NSNumber alloc] initWithDouble: nearbyint(rect.size.width)];
    self.sizewidth = size;

    size = [[NSNumber alloc] initWithDouble: nearbyint(rect.size.height)];
    self.sizeheight = size;
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
                if (self.formatNumericCurrency.boolValue) {
                    if (!currencyNumberFormatter) {
                        currencyNumberFormatter = [[NSNumberFormatter alloc] init];
                        currencyNumberFormatter.locale = [NSLocale currentLocale];
                        currencyNumberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
                    }
                    result = [currencyNumberFormatter stringFromNumber:value];
                } else {
                    NSMutableString *formatString = [[NSMutableString alloc] initWithString:@"%."];
                    [formatString appendFormat:@"%ld", (long)self.formatNumericDecimals.integerValue];
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
    switch (self.type.integerValue) {
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
    
    NSString *fontname;
    NSNumber *fontsize, *italic, *bold;
    italic = self.italic;
    bold = self.bold;
    
    UIFontDescriptorSymbolicTraits traits = 0;
    if (italic.boolValue) traits     |= UIFontDescriptorTraitItalic;
    if (bold.boolValue)   traits     |= UIFontDescriptorTraitBold;
    
    NSNumber *traitsWrapper = [[NSNumber alloc] initWithUnsignedInt: traits];
    
    NSDictionary *symbolicTraits = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    traitsWrapper, UIFontSymbolicTrait, nil];
    
    fontname = self.fontname.copy;
    fontsize = self.fontsize.copy;
    
    NSDictionary *fontAttributes;
    fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      fontname,       UIFontDescriptorFamilyAttribute,
                      fontsize,       UIFontDescriptorSizeAttribute,
                      symbolicTraits, UIFontDescriptorTraitsAttribute, nil];
    
    UIFontDescriptor *fontDescriptor;
    fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
    return fontDescriptor;
}


- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@ (%@)\n", self.identifier, self.debugDescriptionType];
    [description appendFormat:@"Section:                %@\n", [self.inSectionRow.inSection localizedDisplayName]];
    [description appendFormat:@"Font:                   %@ (%f)\n", self.fontname, self.fontsize.floatValue];
    [description appendFormat:@"Currency:               %@-%@\n", self.formatNumericCurrencyLocal, self.formatNumericCurrency.boolValue ? @"YES" : @"NO"];
    [description appendFormat:@"Numeric:                %@\n", self.formatNumericDecimals.boolValue ? @"YES" : @"NO"];
    [description appendFormat:@"Horizontal alignment:   %@\n", self.horizontalAlignment];
    [description appendFormat:@"B: %@ I: %@ S: %@ U: %@\n", self.bold.boolValue ? @"YES" : @"NO ", self.italic.boolValue ? @"YES" : @"NO ", self.strike.boolValue ? @"YES" : @"NO ", self.underline.boolValue ? @"YES" : @"NO "];
    [description appendFormat:@"Label:                  %@\n", self.label];
    [description appendFormat:@"Drop point:             (%f, %f)\n", self.dropPointX.floatValue, self.dropPointY.floatValue];
    [description appendFormat:@"Drop index:             %ld\n", (long)self.dropIndex.integerValue];
    [description appendFormat:@"Origin:                 (%f, %f)\n", self.originx.floatValue, self.originy.floatValue];
    [description appendFormat:@"Size:                   (%f, %f)\n", self.sizewidth.floatValue, self.sizeheight.floatValue];
    [description appendFormat:@"Padding:                (%f, %f, %f, %f)\n", self.paddingLeft.floatValue, self.paddingTop.floatValue, self.paddingRight.floatValue, self.paddingBottom.floatValue];
    [description appendFormat:@"Margin:                 (%f, %f, %f, %f)\n", self.marginLeft.floatValue, self.marginTop.floatValue, self.marginRight.floatValue, self.marginBottom.floatValue];
    [description appendFormat:@"Border:                 (%f, %f, %f, %f)\n", self.borderWidthLeft.floatValue, self.borderHeightTop.floatValue, self.borderWidthRight.floatValue, self.borderHeightBottom.floatValue];
    [description appendFormat:@"*********"];
    return description;
}

@end
