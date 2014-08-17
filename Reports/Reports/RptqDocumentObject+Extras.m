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

#import <CoreData/CoreData.h>

#import "MTFont.h"
#import "Constants.h"
#import "MTBarcode.h"
#import "RptqDocument.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"
#import "RptqDocumentObjectFactory.h"
#import "RptqDocumentObject.h"
#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectLabel+Extras.h"
#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectBarcode+Extras.h"
#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectAggregate+Extras.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqDocumentObjectGroupKey.h"
#import "RptqDocumentObjectGroupKey+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentObjectLabelLink.h"
#import "RptqDocumentObjectLabelLink+Extras.h"

#import "RptqDocumentObjectChart.h"
#import "RptqDocumentObjectChart+Extras.h"

#import "RptqDocumentObjectImage.h"
#import "RptqDocumentObjectImage+Extras.h"

#import "RptqDocumentObjectFormula.h"
#import "RptqDocumentObjectFormula+Extras.h"


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


@implementation RptqDocumentObject (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObject class])];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(identifier))
                                                                     ascending: NO];
    
    [request setSortDescriptors: @[sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    NSUInteger lastDropIndex = 0;
    if (error == nil) {
        RptqDocumentObject *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
        lastDropIndex = [[lastObject dropIndex] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
    // MARK: Default style.
    [self setFontname:[MTFont defaultFamily]];
    [self setFontsize:@([MTFont defaultSize])];
    [self setBold:@NO];
    [self setItalic:@NO];
    [self setUnderline:@NO];
    [self setStrike:@NO];
    [self setMarginBottom:@(CGSizeZero.height)];
    [self setMarginTop:@(CGSizeZero.height)];
    [self setMarginLeft:@(CGSizeZero.width)];
    [self setMarginRight:@(CGSizeZero.width)];
    [self setPaddingBottom:@(CGSizeZero.height)];
    [self setPaddingTop:@(CGSizeZero.height)];
    [self setPaddingLeft:@(CGSizeZero.width)];
    [self setPaddingRight:@(CGSizeZero.width)];

    [self setBorderHeightBottom:@(CGSizeZero.width)];
    [self setBorderWidthLeft:@(CGSizeZero.width)];
    [self setBorderWidthRight:@(CGSizeZero.width)];
    [self setBorderHeightTop:@(CGSizeZero.width)];
    
    [self setVerticalAlignment:@(MTVerticalAlignmentTop)];
    [self setHorizontalAlignment:@(MTHorizontalAlignmentLeft)];
    [self setSectionRowNumber:@(1)];
    [self setDropPoint:CGPointZero];
    [self setDropIndex:@(lastDropIndex)];
    
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

- (CGSize)size {
    CGFloat width = self.paddingLeft.floatValue + self.borderWidthLeft.floatValue + self.marginLeft.floatValue + self.sizewidth.floatValue + self.marginRight.floatValue + self.borderWidthRight.floatValue + self.paddingRight.floatValue;
    CGFloat height = self.paddingTop.floatValue + self.borderHeightTop.floatValue + self.marginTop.floatValue + self.sizeheight.floatValue + self.marginBottom.floatValue + self.borderHeightBottom.floatValue + self.paddingBottom.floatValue;
    return CGSizeMake(width, height);
}

- (CGSize)sizeContentView {
    return CGSizeMake(self.sizewidth.floatValue, self.sizeheight.floatValue);
}

- (CGRect)boundsContentView {
    CGSize size = [self size];
    return CGRectMake(CGPointZero.x, CGPointZero.y, size.width, size.height);
}

- (CGRect)paddingViewFrame {
    CGFloat paddingBoundsSizeWidth = self.paddingLeft.floatValue + self.paddingRight.floatValue + self.sizewidth.floatValue;
    CGFloat paddingBoundsSizeHeight = self.paddingTop.floatValue + self.paddingBottom.floatValue + self.sizeheight.floatValue;
    CGRect paddingViewBounds = CGRectMake(CGPointZero.x, CGPointZero.y, paddingBoundsSizeWidth, paddingBoundsSizeHeight);
    CGFloat originX = CGPointZero.x + [[self marginLeft] floatValue];
    CGFloat originY = CGPointZero.y + [[self marginTop] floatValue];
    CGFloat sizeWidth = paddingViewBounds.size.width;
    CGFloat sizeHeight = paddingViewBounds.size.height;
    return CGRectMake(originX, originY, sizeWidth, sizeHeight);
}

- (CGRect)elementViewBounds {
    return CGRectMake(CGPointZero.x, CGPointZero.y, self.sizewidth.floatValue, self.sizeheight.floatValue);
}

- (CGRect)elementViewFrame {
    CGRect elementViewBounds = [self elementViewBounds];
    CGFloat originX = CGPointZero.x + [[self paddingLeft] floatValue];
    CGFloat originY = CGPointZero.y + [[self paddingTop] floatValue];
    CGFloat sizeWidth = elementViewBounds.size.width;
    CGFloat sizeHeight = elementViewBounds.size.height;
    return CGRectMake(originX, originY, sizeWidth, sizeHeight);
}

- (void)setDropPoint:(CGPoint)drop {
    NSNumber *x = @(drop.x), *y = @(drop.y);
    [self setDropPointX: x];
    [self setDropPointY: y];
}

- (CGPoint)dropPoint {
    return CGPointMake(self.dropPointX.floatValue, self.dropPointY.floatValue);
}

- (void)setOrigin:(CGPoint)origin {
    NSNumber *x = @(origin.x), *y = @(origin.y);
    [self setOriginx: x];
    [self setOriginy: y];
}

#pragma mark - Member

- (MTDocumentObjectType)getType {
    return [[self type] integerValue];
}

- (NSString *)designerRepresentationText {

    NSString *result = nil;
    
    switch ([[self type] integerValue]) {
    
        case MTDocumentObjectTypeAggregate: {
            result = [[self isAggregate] designerRepresentationText];
            break;
        }

        case MTDocumentObjectTypeChart:
            result = @"chart";
            break;

        case MTDocumentObjectTypeFormula:
            result = [[self isFormula] source];
            break;
        
        case MTDocumentObjectTypeGroupKey: {
            NSInteger groupNumber = [[[self isGroupKey] groupNumber] integerValue];
            NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: @(groupNumber)
                                                                         numberStyle: NSNumberFormatterSpellOutStyle];
            NSString *gorupFormatString = NSLocalizedString(@"Group %@", @"Like 'Group Three.'");
            result = [NSString stringWithFormat:gorupFormatString, [groupNumberText uppercaseString]];
            break;
        }
        
        case MTDocumentObjectTypeImage:
            result = @"image";
            break;
        
        case MTDocumentObjectTypeLabelDynamic:
            result = [[[self isLabelDataField] referencesQueryField] toStringReverse];
            break;
        
        case MTDocumentObjectTypeLabelStatic:
            result = [[self isLabel] text];
            break;
        case MTDocumentObjectTypeWhtiespace:
            result = @"Whitespace";
            break;
            
        case MTDocumentObjectTypeBarcode: {
            MTBarcodeType type = [[[self isBarcode] type] integerValue];
            NSString *barcodeName = [MTBarcode barcodeNameForType:type];
            result = [NSString stringWithFormat:@"Barcode (%@)", barcodeName];
            break;
        }
        default:
            result = @"";
            break;
    
    }

    return result;
}

+ (void)removeDocumentObject:(RptqDocumentObject *)documentObject {
    
    MTDocumentObjectType objectType = [[documentObject type] integerValue];
    NSManagedObjectContext *managedObjectContext = [documentObject managedObjectContext];
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            [managedObjectContext deleteObject:[documentObject isLabelDataField]];
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {
            [managedObjectContext deleteObject:[documentObject isLabel]];
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            [managedObjectContext deleteObject:[documentObject isAggregate]];
            break;
        }
        case MTDocumentObjectTypeImage: {
            [managedObjectContext deleteObject:[documentObject isImage]];
            break;
        }
        case MTDocumentObjectTypeWhtiespace: {
            break;
        }
        case MTDocumentObjectTypeBarcode: {
            [managedObjectContext deleteObject:[documentObject isBarcode]];
            break;
        }
        default:
            break;
    }
    [managedObjectContext deleteObject: documentObject];
    [managedObjectContext save:nil];
}

+ (instancetype)documentObjectForObjectID:(NSManagedObjectID *)objid managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objid];
    return (RptqDocumentObject *)result;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqDocumentObject *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

#pragma mark - MTProtocolCompare

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value {

    
    NSString *result;
    switch (dataType) {
        case MTDataTypeYear:
            if ([value isKindOfClass:[NSString class]]) {
                result = value;
            } else if ([value isKindOfClass:[NSNumber class]]) {
                result = [NSString stringWithFormat:@"%d", [(NSNumber *)value integerValue]];
            } else {
                result = [NSString stringWithFormat:@"%@", value];
            }
            break;
        case MTDataTypeGeometry:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MTDataTypeImage:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MTDataTypeSet:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MTDataTypeUnknown:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp: {
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
                case MTDataTypeDate:
                    result = [dateformatter stringFromDate:d];
                    break;
                case MTDataTypeDateTime:
                    result = [dateTimeformatter stringFromDate:d];
                    break;
                case MTDataTypeTime:
                    result = [timeformatter stringFromDate:d];
                    break;
                    
                case MTDataTypeTimeStamp:
                    result = [dateformatter stringFromDate:d];
                    break;

                default:
                    result = [NSString stringWithFormat:@"%@", value];
                    break;
            }
  
            break;
        }
        case MTDataTypeBlob:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        case MTDataTypeBit:
        case MTDataTypeFloat:
        case MTDataTypeInteger:
        case MTDataTypeLong:
        case MTDataTypeLongLong:
        case MTDataTypeInt24:
        case MTDataTypeEnum:
        case MTDataTypeDouble:
        case MTDataTypeDecimal:
        case MTDataTypeNumber:
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
        case MTDataTypeString:
            result = [NSString stringWithFormat:@"%@", value];
            break;
        default:
            result = [NSString stringWithFormat:@"%@", value];
            break;
    }
    if (result == nil) {
        result = @"";
    }
    return result;
}

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

- (NSDictionary *)attributesForDrawingText {
    MTFont *font = [[MTFont alloc] initWithFamilyName:[self fontname]
                                         andPointSize:[[self fontsize] floatValue]
                                               isBold:[[self bold] boolValue]
                                             isItalic:[[self italic] boolValue]];
    UIFont *customFont = [font font];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    // ???: Where is NSLineBreakByClipping in iOS7... There attributed string is buggy as fuck.
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    switch ([[self horizontalAlignment] integerValue]) {
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
    NSNumber *underlineStyle = [[self underline] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    NSNumber *strikethroughStyle = [[self strike] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    return  @{
              NSFontAttributeName : customFont,
              NSBaselineOffsetAttributeName : baselineOffset,
              NSUnderlineStyleAttributeName : underlineStyle,
              NSStrikethroughStyleAttributeName : strikethroughStyle,
              NSParagraphStyleAttributeName: paragraphStyle
              };
}

#pragma mark - MTProtocolLog

- (NSString *)toString {
    return [self toStringDebug];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat: @"%@-%@", self, [self designerRepresentationText]];
}

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat: @"%@", [self designerRepresentationText]];
}

- (NSAttributedString *)toAttributedString {
    return nil;
}

@end
