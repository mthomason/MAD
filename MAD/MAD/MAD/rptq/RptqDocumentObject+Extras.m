//
//  RptqDocumentObject+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentObject+Extras.h"

#import <UIKit/NSAttributedString.h>
#import <UIKit/UITextView.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "MTAlignment.h"
#import "MADFont.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectAggregate+Extras.h"
#import "RptqDocumentObjectFormula.h"
#import "RptqDocumentObjectGroupKey.h"
#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectImage.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentSectionRows.h"

#import <MADBarcodes/MTBarcode.h>

//#import <Foundation/NSNumberFormatter.h>
//#import <Foundation/NSSortDescriptor.h>
//#import <Foundation/NSBundle.h>

#import "MADSectionLayoutManager.h"

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

@implementation RptqDocumentObject (Extras)

#pragma mark - Static Helpers

+ (instancetype)documentObjectForObject:(NSManagedObject *)managedObject {
    RptqDocumentObject *result = nil;
    
    if ([managedObject isKindOfClass:[RptqDocumentObject class]]) {
        result = (RptqDocumentObject *)managedObject;
        
    } else if ([managedObject respondsToSelector:@selector(parentObject)]) {
        result = [(RptqDocumentObjectGroupKey *)managedObject parentObject];
        
    } else if ([managedObject isKindOfClass:[RptqDocumentObjectLabel class]]) {
        result = [(RptqDocumentObjectLabel *)managedObject parentObjectLabel];
        
    } else if ([managedObject isKindOfClass:[RptqDocumentObjectBarcode class]]) {
        result = [(RptqDocumentObjectBarcode *)managedObject parentObjectBarcode];
        
    } else if ([managedObject isKindOfClass:[RptqDocumentObjectLabelDataField class]]) {
        result = [(RptqDocumentObjectLabelDataField *)managedObject parentObjectLabelDataField];
        
    }
    return result;
}

+ (void)removeDocumentObject:(RptqDocumentObject *)documentObject fromParentSection:(RptqDocumentSection *)section withLayoutManager:(MADSectionLayoutManager *)layoutManager {
    
    RptqDocumentSectionRows *sectionRow = documentObject.inSectionRow;
    
    NSOrderedSet *sectionRowHasObjects =  documentObject.inSectionRow.hasObjects;
    NSUInteger deleteIndex = [sectionRowHasObjects indexOfObject:documentObject];
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: documentObject.inSectionRow.hasObjects];
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

static inline CGFloat paddingViewBoundsSizeHeight(NSNumber *paddingTop, NSNumber *paddingBottom, NSNumber *sizeHeight);
static inline CGFloat paddingViewBoundsSizeHeight(NSNumber *paddingTop, NSNumber *paddingBottom, NSNumber *sizeHeight) {
    return paddingTop.floatValue + paddingBottom.floatValue + sizeHeight.floatValue;
}

static inline CGFloat paddingViewBoundsSizeWidth(NSNumber *paddingLeft, NSNumber *paddingRight, NSNumber *sizeWidth);
static inline CGFloat paddingViewBoundsSizeWidth(NSNumber *paddingLeft, NSNumber *paddingRight, NSNumber *sizeWidth) {
    return paddingLeft.floatValue + paddingRight.floatValue + sizeWidth.floatValue;
}

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocumentObject class])];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: NSStringFromSelector(@selector(identifier))
                                                                     ascending: NO];
    
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSUInteger idNumber = 0;
    NSUInteger lastDropIndex = 0;
    if (error == nil) {
        RptqDocumentObject *lastObject = fetchResults.lastObject;
        idNumber = [[lastObject identifier] unsignedIntegerValue] + 1;
        lastDropIndex = [[lastObject dropIndex] unsignedIntegerValue] + 1;
    }
    
    NSString *fontname = [[NSString alloc] initWithString:[MADFont defaultFamily]];
    self.fontname = fontname;

    NSNumber *bold = @NO;
    self.bold = bold;

    NSNumber *italic = @NO;
    self.italic = italic;

    NSNumber *underline = @NO;
    self.underline = underline;

    NSNumber *strike = @NO;
    self.strike = strike;

    CGFloat fontPointSize = [MADFont defaultSize];
    CFNumberRef fontSize = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &fontPointSize);
    self.fontsize = (__bridge NSNumber *)(fontSize);
    CFRelease(fontSize);

    NSNumber *identifier = [[NSNumber alloc] initWithUnsignedInteger: idNumber];
    self.identifier = identifier;

    CFNumberRef marginBottom = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.height);
    self.marginBottom = (__bridge NSNumber *)(marginBottom);
    CFRelease(marginBottom);

    CFNumberRef marginTop = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.height);
    self.marginTop = (__bridge NSNumber *)(marginTop);
    CFRelease(marginTop);

    CFNumberRef marginLeft = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.width);
    self.marginLeft = (__bridge NSNumber *)(marginLeft);
    CFRelease(marginLeft);

    CFNumberRef marginRight = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.width);
    self.marginRight = (__bridge NSNumber *)(marginRight);
    CFRelease(marginRight);

    CFNumberRef paddingBottom = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.height);
    self.paddingBottom = (__bridge NSNumber *)(paddingBottom);
    CFRelease(paddingBottom);

    CFNumberRef paddingTop = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.height);
    self.paddingTop = (__bridge NSNumber *)(paddingTop);
    CFRelease(paddingTop);

    CFNumberRef paddingLeft = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.width);
    self.paddingLeft = (__bridge NSNumber *)(paddingLeft);
    CFRelease(paddingLeft);

    CFNumberRef paddingRight = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.width);
    self.paddingRight = (__bridge NSNumber *)(paddingRight);
    CFRelease(paddingRight);

    CFNumberRef borderHeightBottom = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.height);
    self.borderHeightBottom = (__bridge NSNumber *)(borderHeightBottom);
    CFRelease(borderHeightBottom);
    
    CFNumberRef borderHeightTop = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.height);
    self.borderHeightTop = (__bridge NSNumber *)(borderHeightTop);
    CFRelease(borderHeightTop);
    
    CFNumberRef borderWidthLeft = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.width);
    self.borderWidthLeft = (__bridge NSNumber *)(borderWidthLeft);
    CFRelease(borderWidthLeft);
    
    CFNumberRef borderWidthRight = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &CGSizeZero.width);
    self.borderWidthRight = (__bridge NSNumber *)(borderWidthRight);
    CFRelease(borderWidthRight);
    
    NSNumber *verticalAlignment = [[NSNumber alloc] initWithUnsignedInteger:MTVerticalAlignmentTop];
    self.verticalAlignment = verticalAlignment;
    
    NSNumber *horizontalAlignment = [[NSNumber alloc] initWithUnsignedInteger:MTHorizontalAlignmentLeft];
    self.horizontalAlignment = horizontalAlignment;

    NSNumber *sectionRowNumber = [[NSNumber alloc] initWithUnsignedInteger: 1];
    self.sectionRowNumber = sectionRowNumber;

    NSNumber *dropIndex = [[NSNumber alloc] initWithUnsignedInteger: lastDropIndex];
    self.dropIndex = dropIndex;
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
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
    NSNumber *x = [[NSNumber alloc] initWithFloat: origin.x];
    NSNumber *y = [[NSNumber alloc] initWithFloat: origin.y];
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
    return self.paddingLeft.floatValue + self.borderWidthLeft.floatValue + self.marginLeft.floatValue +
            self.sizewidth.floatValue + self.marginRight.floatValue + self.borderWidthRight.floatValue +
            self.paddingRight.floatValue;
}

- (CGFloat)sizeHeightCalculated {
    return self.paddingTop.floatValue + self.borderHeightTop.floatValue + self.marginTop.floatValue +
            self.sizeheight.floatValue + self.marginBottom.floatValue + self.borderHeightBottom.floatValue +
            self.paddingBottom.floatValue;
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
    return CGRectMake(self.originx.floatValue + self.spacingLeft, self.originy.floatValue + self.spacingTop,
                      self.sizewidth.floatValue + self.spacingRight, self.sizeheight.floatValue + self.spacingBottom);
}

#pragma mark - Member

- (MTDocumentObjectType)getType {
    return self.type.shortValue;
}

- (NSString *)copyDesignerRepresentationText {

    NSString *result = nil;
    
    switch (self.type.integerValue) {
    
        case MTDocumentObjectTypeAggregate: {
            result = [self.isAggregate copyDesignerRepresentationText];
            break;
        }

        case MTDocumentObjectTypeChart:
            result = @"chart";
            break;

        case MTDocumentObjectTypeFormula:
            result = self.isFormula.source;
            break;
        
        case MTDocumentObjectTypeGroupKey: {
            NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: self.isGroupKey.groupNumber
                                                                         numberStyle: NSNumberFormatterSpellOutStyle];
            NSString *gorupFormatString = NSLocalizedString(@"Group %@", @"Like 'Group Three.'");
            result = [NSString stringWithFormat:gorupFormatString, [groupNumberText uppercaseString]];
            break;
        }
        
        case MTDocumentObjectTypeImage:
            result = @"image";
            break;
        
        case MTDocumentObjectTypeLabelDynamic:
            result = self.isLabelDataField.referencesQueryField.toStringReverse;
            break;
        
        case MTDocumentObjectTypeLabelStatic:
            result = self.isLabel.text;
            break;
        case MTDocumentObjectTypeWhtiespace:
            result = @"Whitespace";
            break;
            
        case MTDocumentObjectTypeBarcode: {
            NSString *barcodeName = [MTBarcode newBarcodeNameForType:self.isBarcode.type.unsignedIntegerValue];
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
    NSNumber *sizeWidth = @(nearbyint(rect.size.width));
    NSNumber *sizeHeight = @(nearbyint(rect.size.height));
    self.sizewidth = sizeWidth;
    self.sizeheight = sizeHeight;
}

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    
    NSString *result;
    switch (dataType) {
        case MADDataTypeYear:
            if ([value isKindOfClass:[NSString class]]) {
                result = value;
            } else if ([value isKindOfClass:[NSNumber class]]) {
                result = [NSString stringWithFormat:@"%ld", (long)[(NSNumber *)value integerValue]];
            } else {
                result = [NSString stringWithFormat:@"%@", value];
            }
            break;
        case MADDataTypeGeometry:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MADDataTypeImage:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MADDataTypeSet:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MADDataTypeUnknown:
            result = [NSString stringWithFormat:@"%@", value];
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
                [dateformatter setDateStyle:NSDateFormatterShortStyle];
                [dateformatter setTimeStyle:NSDateFormatterNoStyle];
            }
            if (timeformatter == nil) {
                timeformatter = [[NSDateFormatter alloc] init];
                [timeformatter setDateStyle:NSDateFormatterNoStyle];
                [timeformatter setTimeStyle:NSDateFormatterShortStyle];
            }
            if (dateTimeformatter == nil) {
                dateTimeformatter = [[NSDateFormatter alloc] init];
                [dateTimeformatter setDateStyle:NSDateFormatterShortStyle];
                [dateTimeformatter setTimeStyle:NSDateFormatterShortStyle];
            }
            NSDate *d = nil;
            if ([value isKindOfClass:[NSData class]]) {
                d = value;
            } else {
                NSTimeInterval t = 0;
                if ([value isKindOfClass:[NSString class]]) {
                    t = [(NSString *)value longLongValue];
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
                    result = [NSString stringWithFormat:@"%@", value];
                    break;
            }
  
            break;
        }
        case MADDataTypeBlob:
            result = [NSString stringWithFormat:@"%@", value];
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
                if ([[self formatNumericCurrency] boolValue]) {
                    if (!currencyNumberFormatter) {
                        currencyNumberFormatter = [[NSNumberFormatter alloc] init];
                        [currencyNumberFormatter setLocale:[NSLocale currentLocale]];
                        [currencyNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    }
                    result = [currencyNumberFormatter stringFromNumber:value];
                } else {
                    NSMutableString *formatString = [[NSMutableString alloc] initWithString:@"%."];
                    [formatString appendFormat:@"%ld", (long)[[self formatNumericDecimals] integerValue]];
                    [formatString appendString:@"f"];
                    result = [NSString stringWithFormat:formatString, [value floatValue]];
                }
            } else {
                result = [NSString stringWithFormat:@"%@", value];
            }
            break;
        }
        case MADDataTypeString:
            result = [NSString stringWithFormat:@"%@", value];
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

- (UIFontDescriptor *)newFontDescriptor {

    UIFontDescriptorSymbolicTraits traits = 0;
    UIFontDescriptor *f = [UIFontDescriptor fontDescriptorWithName:self.fontname
                                                              size:self.fontsize.floatValue];
    
    //bool gotTraits = false;
    if (self.italic.boolValue && self.bold.boolValue) {
        f = [f fontDescriptorWithSymbolicTraits:(UIFontDescriptorSymbolicTraits)
                                        (UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold)];
    } else if (self.italic.boolValue) {
        traits = UIFontDescriptorTraitItalic;
        f = [f fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    } else if (self.bold.boolValue) {
        f = [f fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    }
    return f;
}

- (NSDictionary *)newTextAttributesWithFontDescriptor:(UIFontDescriptor *)fontDescriptor {
    
    UIFont *customFont = [UIFont fontWithDescriptor: fontDescriptor
                                               size: 0.0];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    // ???: Where is NSLineBreakByClipping in iOS7... There attributed string is buggy as fuck.
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    
    switch (self.horizontalAlignment.integerValue) {
        case MTHorizontalAlignmentLeft:
            paragraphStyle.alignment = NSTextAlignmentLeft;
            break;
        case MTHorizontalAlignmentRight:
            paragraphStyle.alignment = NSTextAlignmentRight;
            break;
        case MTHorizontalAlignmentCenter:
            paragraphStyle.alignment = NSTextAlignmentCenter;
            break;
        case MTHorizontalAlignmentJustified:
            paragraphStyle.alignment = NSTextAlignmentJustified;
            break;
        case MTHorizontalAlignmentNatrual:
            paragraphStyle.alignment = NSTextAlignmentNatural;
            break;
        default:
            paragraphStyle.alignment = NSTextAlignmentLeft;
            break;
    }
    
    NSNumber *baselineOffset = @0.00000000f;
    NSNumber *underlineStyle = [[NSNumber alloc] initWithInteger:self.underline.boolValue ?
                                         NSUnderlineStyleSingle : NSUnderlineStyleNone];
    NSNumber *strikethroughStyle = [[NSNumber alloc] initWithInteger:self.strike.boolValue ?
                                             NSUnderlineStyleSingle : NSUnderlineStyleNone];
    
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                customFont, NSFontAttributeName,
                                baselineOffset, NSBaselineOffsetAttributeName,
                                underlineStyle, NSUnderlineStyleAttributeName,
                                strikethroughStyle, NSStrikethroughStyleAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName, nil];
    
    return  attributes;
}

- (NSDictionary *)newDictionaryOfTextAttributes {

    UIFontDescriptor *f = [self newFontDescriptor];
    id attributes = [self newTextAttributesWithFontDescriptor: f];
    return attributes;
    
}

#pragma mark - MTProtocolLog

- (NSString *)toString {
    return [self toStringDebug];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat: @"%@-%@", self, [self copyDesignerRepresentationText]];
}

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat: @"%@", [self copyDesignerRepresentationText]];
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
