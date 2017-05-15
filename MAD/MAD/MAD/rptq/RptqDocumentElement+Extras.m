//
//  RptqDocumentElement+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElement+Extras.h"

#import <UIKit/UIFontDescriptor.h>
#import <UIKit/UIGeometry.h>

#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>

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

#import "RptqDirectionalAsymmetry.h"
#import "RptqNumericFormat.h"
#import "RptqAlignment.h"
#import "RptqRect.h"
#import "RptqSize.h"
#import "RptqPoint.h"
#import "RptqTextStyle.h"
#import "RptqBorder.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentElementGroupKey.h"
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

static inline CGFloat MADDocObjSizeWidthCalculated(CGFloat, CGFloat, CGFloat, CGFloat,
                                                   CGFloat, CGFloat, CGFloat);
static inline CGFloat MADDocObjSizeHeightCalculated(CGFloat, CGFloat, CGFloat, CGFloat,
                                                    CGFloat, CGFloat, CGFloat);
static inline CGRect MADDocObjFrameCalculated(CGFloat, CGFloat, CGFloat, CGFloat,
                                              CGFloat, CGFloat, CGFloat, CGFloat);
static inline double paddingViewBoundsSizeHeight(double, double, double);
static inline double paddingViewBoundsSizeWidth(double, double, double);

static inline double paddingViewBoundsSizeHeight(double paddingTop,
                                                 double paddingBottom,
                                                 double sizeHeight) {
    return paddingTop + paddingBottom + sizeHeight;
}

static inline double paddingViewBoundsSizeWidth(double paddingLeft,
                                                double paddingRight,
                                                double sizeWidth) {
    return paddingLeft + paddingRight + sizeWidth;
}

static inline CGFloat MADDocObjSizeWidthCalculated(CGFloat paddingLeft,
                                                   CGFloat borderWidthLeft,
                                                   CGFloat marginLeft,
                                                   CGFloat sizewidth,
                                                   CGFloat marginRight,
                                                   CGFloat borderWidthRight,
                                                   CGFloat paddingRight) {
    return paddingLeft + borderWidthLeft + marginLeft + sizewidth + marginRight + borderWidthRight +
                            paddingRight;
}

static inline CGFloat MADDocObjSizeHeightCalculated(CGFloat paddingTop,
                                                    CGFloat borderHeightTop,
                                                    CGFloat marginTop,
                                                    CGFloat sizeheight,
                                                    CGFloat marginBottom,
                                                    CGFloat borderHeightBottom,
                                                    CGFloat paddingBottom) {
    return paddingTop + borderHeightTop + marginTop + sizeheight + marginBottom +
                            borderHeightBottom + paddingBottom;
}

static inline CGRect MADDocObjFrameCalculated(CGFloat x, CGFloat sx, CGFloat y, CGFloat sy, CGFloat w, CGFloat sw, CGFloat h, CGFloat wh) {
    return CGRectMake(x + sx, y + sy, w + sw, h + wh);
}

@implementation RptqDocumentElement (Extras)

#pragma mark -
#pragma mark Static Helpers

+ (NSFetchRequest <__kindof RptqDocumentElement *> *)fetchRequestElement:(int64_t)identifier {
    NSFetchRequest *request;
    NSPredicate *predicate;
    NSExpression *left, *right;
    left = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(identifier))];
    right = [NSExpression expressionForConstantValue:@(identifier)];
    predicate = [NSComparisonPredicate predicateWithLeftExpression: left
                                                   rightExpression: right
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([self class])];
    request.predicate = predicate;
    
    request.fetchLimit = 1;
    request.resultType = NSManagedObjectResultType;
    request.includesSubentities = YES;
    request.includesPropertyValues = YES;
    return request;
}

+ (NSString *)keyInSectionRow {
    NSString *result = NSStringFromSelector(@selector(inSectionRow));
    return result;
}

+ (NSString *)keyRowNumber {
    NSString *result = [self keyInSectionRow];
    NSString *keyRowNumber = NSStringFromSelector(@selector(rowNumber));
    result = [result stringByAppendingString:@"."];
    result = [result stringByAppendingString:keyRowNumber];
    return result;
}

+ (NSString *)keyInSection {
    NSString *result = [self keyInSectionRow];
    NSString *keyInSection = NSStringFromSelector(@selector(inSection));
    result = [result stringByAppendingString: @"."];
    result = [result stringByAppendingString: keyInSection];
    return result;
}

+ (NSString *)keyOrigin {
    NSString *result = NSStringFromSelector(@selector(origin));
    return result;
}

+ (NSString *)keySize {
    NSString *result = NSStringFromSelector(@selector(size));
    return result;
}

+ (NSString *)keyMargin {
    NSString *result = NSStringFromSelector(@selector(margin));
    return result;
}

+ (NSString *)keyBorder {
    NSString *result = NSStringFromSelector(@selector(border));
    return result;
}

+ (NSString *)keyPadding {
    NSString *result = NSStringFromSelector(@selector(padding));
    return result;
}

+ (NSFetchRequest <NSDictionary *> *)fetchRequestElementsInSection:(NSManagedObjectID *)sectionID {
    NSFetchRequest *request;
    NSPredicate *predicate;
    NSUInteger expressionCount = 6;
    //NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *left, *right;
    
    NSString *keySelf = NSStringFromSelector(@selector(self));
    NSString *keyInSection = [self keyInSection];
    NSString *keyBorder = [self keyBorder];
    NSString *keyPadding = [self keyPadding];
    NSString *keyMargin = [self keyMargin];
    NSString *keySize = [self keySize];
    NSString *keyRowNumber = [self keyRowNumber];
    
    NSString *keys[] = {
        keySelf,
        keyBorder,
        keyPadding,
        keyMargin,
        keySize,
        keyRowNumber,
    };
    //NSKeyedUnarchiveFromDataTransformerName
    NSExpression *expressions[] = {
        [NSExpression expressionForEvaluatedObject],
        [NSExpression expressionForKeyPath: keyBorder],
        [NSExpression expressionForKeyPath: keyPadding],
        [NSExpression expressionForKeyPath: keyMargin],
        [NSExpression expressionForKeyPath: keySize],
        [NSExpression expressionForKeyPath: keyRowNumber],
    };
    
    NSAttributeType types[] = {
        NSObjectIDAttributeType,
        NSTransformableAttributeType,
        NSTransformableAttributeType,
        NSTransformableAttributeType,
        NSTransformableAttributeType,
        NSInteger32AttributeType,
    };
    
    
    //NSArray *propertiesToFetch = [[NSArray alloc] init];
    
    NSExpressionDescription *expressionSelf = [[NSExpressionDescription alloc] init];
    expressionSelf.name = keys[0].copy;
    expressionSelf.expression = expressions[0];
    expressionSelf.expressionResultType = types[0];
    //propertiesToFetch = [propertiesToFetch arrayByAddingObject:expressionDescription];
    

    //expressionDescription = [[NSExpressionDescription alloc] init];
    //expressionDescription.name = keys[1].copy;
    //expressionDescription.expression = expressions[1];
    //expressionDescription.expressionResultType = types[1];
    //propertiesToFetch = [propertiesToFetch arrayByAddingObject:expressionDescription];
    /*
    NSAttributeDescription *attributeDescription = [[NSAttributeDescription alloc] init];
    attributeDescription.name = keys[1].copy;
    attributeDescription.attributeType = types[1];
    
    attributeDescription.valueTransformerName = NSKeyedUnarchiveFromDataTransformerName;
    attributeDescription.attributeValueClassName = NSStringFromClass([MADBorderStyle class]);
    propertiesToFetch = [propertiesToFetch arrayByAddingObject:attributeDescription];*;
    attributeDescription = [[NSAttributeDescription alloc] init];
    attributeDescription.name = keys[2].copy;
    attributeDescription.attributeType = types[2];
    attributeDescription.valueTransformerName = NSUnarchiveFromDataTransformerName;
    attributeDescription.attributeValueClassName = NSStringFromClass([MADPadding class]);
    propertiesToFetch = [propertiesToFetch arrayByAddingObject:attributeDescription];
    
    attributeDescription = [[NSAttributeDescription alloc] init];
    attributeDescription.name = keys[3].copy;
    attributeDescription.attributeType = types[3];
    attributeDescription.valueTransformerName = NSUnarchiveFromDataTransformerName;
    attributeDescription.attributeValueClassName = NSStringFromClass([MADMargin class]);
    propertiesToFetch = [propertiesToFetch arrayByAddingObject:attributeDescription];

    attributeDescription = [[NSAttributeDescription alloc] init];
    attributeDescription.name = keys[4].copy;
    attributeDescription.attributeType = types[4];
    attributeDescription.valueTransformerName = NSUnarchiveFromDataTransformerName;
    attributeDescription.attributeValueClassName = NSStringFromClass([NSNumber class]);
    propertiesToFetch = [propertiesToFetch arrayByAddingObject:attributeDescription];

    expressionDescription = [[NSExpressionDescription alloc] init];
    expressionDescription.name = keys[5].copy;
    expressionDescription.expression = expressions[5];
    expressionDescription.expressionResultType = types[5];
    propertiesToFetch = [propertiesToFetch arrayByAddingObject:expressionDescription];
  */
    //for (NSUInteger i=0; i<expressionCount; i++) {
    //        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    //        expressionDescription[i].name = keys[i].copy;
    //        expressionDescription[i].expression = expressions[i];
    //        expressionDescription[i].expressionResultType = types[i];
//            propertiesToFetch = [propertiesToFetch arrayByAddingObject:expressionDescription];
    //}
    
    //NSArray *propertiesToFetch;
    //propertiesToFetch = [[NSArray alloc] initWithObjects: expressionDescription
    //                                               count: (NSUInteger)expressionCount];
    
    left = [NSExpression expressionForKeyPath:keyInSection];
    right = [NSExpression expressionForConstantValue:sectionID];
    predicate = [NSComparisonPredicate predicateWithLeftExpression: left
                                                   rightExpression: right
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    
    
    NSString *entityName = NSStringFromClass([self class]);
    request = [[NSFetchRequest alloc] initWithEntityName: entityName];
    request.predicate = predicate;
    request.resultType = NSDictionaryResultType;// NSManagedObjectResultType;
    //NSArray *properties = [[NSArray alloc] init];
    //NSExpression *objectID = [NSExpression expressionForEvaluatedObject];
    NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects: expressionSelf,
                                  @"border.width.top", @"border.width.bottom",
                                  @"padding.top", @"padding.bottom",
                                  @"margin.top", @"margin.bottom",
                                  @"rect.origin.y", @"rect.size.height", nil];
    request.propertiesToFetch = propertiesToFetch;
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        //expressionDescription[i] = nil;
        keys[i] = nil;
        expressions[i] = nil;
    }
    
    return request;
}

+ (instancetype)newDocumentElementWithIdentifier:(int64_t)identifier
                               fromObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest <__kindof RptqDocumentElement *> *fetchRequet;
    fetchRequet = [self fetchRequestElement: identifier];
    return [context executeFetchRequest:fetchRequet error:nil].firstObject;
}

+ (void)removeDocumentObject:(RptqDocumentElement *)documentObject
           fromParentSection:(RptqDocumentSection *)section
           withLayoutManager:(MADSectionLayoutManager *)layoutManager {
    
    RptqDocumentSectionRows *sectionRow = documentObject.inSectionRow;
    
    NSOrderedSet *sectionRowHasObjects =  documentObject.inSectionRow.hasObjects;
    NSUInteger deleteIndex = [sectionRowHasObjects indexOfObject:documentObject];
    
    NSMutableOrderedSet *hasObjects = documentObject.inSectionRow.hasObjects.mutableCopy;
    [hasObjects removeObjectAtIndex:deleteIndex];
    
    [layoutManager removeItemWithID:@(documentObject.identifier)];
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
    NSString *keyDropIndex = NSStringFromSelector(@selector(dropIndex));
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    
    NSExpressionDescription *edIdentifier, *edLastObject;
    edIdentifier = [[NSExpressionDescription alloc] init];
    edIdentifier.name = keyIdentifier;
    edIdentifier.expression = [NSExpression expressionForKeyPath:keyIdentifier];
    edIdentifier.expressionResultType = NSInteger64AttributeType;

    edLastObject = [[NSExpressionDescription alloc] init];
    edLastObject.name = keyDropIndex;
    edLastObject.expression = [NSExpression expressionForKeyPath:keyDropIndex];
    edLastObject.expressionResultType = NSInteger64AttributeType;

    request.propertiesToFetch = @[edIdentifier, edLastObject];
    request.resultType = NSDictionaryResultType;
    NSError *error = nil;
    NSArray <NSDictionary *> *fetchResults;
    fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    int64_t idNumber = 0;
    int64_t lastDropIndex = 0;
    if (fetchResults.count) {

        NSDictionary <NSString *, NSNumber *> *lastObject = fetchResults.lastObject;

        
        CFNumberGetValue((__bridge CFNumberRef)(lastObject[keyIdentifier]),
                         kCFNumberSInt64Type,
                         &idNumber);
        CFNumberGetValue((__bridge CFNumberRef)(lastObject[keyDropIndex]),
                         kCFNumberSInt64Type,
                         &lastDropIndex);

        idNumber++;
        lastDropIndex++;
    }
    
    self.fontname = [MADFont defaultFamily];
    self.fontsize = [MADFont defaultSize];
    self.identifier = idNumber;
    self.dropIndex = lastDropIndex;
    
}

- (void)setSizeWidth:(float)width {
    self.rect.size.width = width;
}

- (void)setSizeHeight:(float)height {
    self.rect.size.height = height;
}

- (void)setHorizontalAlignment:(MADHorizontalAlignment)alignment {
    self.alignment.horizontal = alignment;
}

- (void)setVerticalAlignment:(MADVerticalAlignment)alignment {
    self.alignment.vertical = alignment;
}

- (CGPoint)placementPoint {
    CGPoint placementPoint = [(NSValue *)self.dropPoint CGPointValue];
    return placementPoint;
}

- (void)setSizeWidth:(float)w height:(float)h {
    self.rect.size.width = w;
    self.rect.size.height = h;
}

- (void)setSizeValue:(CGSize)size {
    self.rect.size.width = (float)size.width;
    self.rect.size.height = (float)size.height;
}

- (void)setOriginPoint:(CGPoint)or {
    self.rect.origin.x = (float)or.x;
    self.rect.origin.y = (float)or.y;
}

- (double)spacingLeft {
    return self.margin.left + self.border.width.left + self.padding.left;
}

- (double)spacingRight {
    return self.margin.right + self.border.width.right + self.padding.right;
}

- (double)spacingTop {
    return self.margin.top + self.border.width.top + self.padding.top;
}

- (double)spacingBottom {
    return self.margin.bottom + self.border.width.bottom + self.padding.bottom;
}

- (CGFloat)sizeWidthCalculated {
    return MADDocObjSizeWidthCalculated(self.padding.left,
                                        self.border.width.left,
                                        self.margin.left,
                                        self.rect.size.width,
                                        self.margin.right,
                                        self.border.width.right,
                                        self.padding.right);
}

- (CGFloat)sizeHeightCalculated {
    return MADDocObjSizeHeightCalculated(self.padding.top,
                                         self.border.width.top,
                                         self.margin.top,
                                         self.rect.size.height,
                                         self.margin.bottom,
                                         self.border.width.bottom,
                                         self.padding.bottom);
}

- (CGSize)innerSize {
    return CGSizeMake(self.rect.size.width, self.rect.size.height);
}

- (CGSize)sizeCalculated {
    return CGSizeMake([self sizeWidthCalculated], [self sizeHeightCalculated]);
}

- (CGSize)sizeContentView {
    return CGSizeMake(self.rect.size.width, self.rect.size.height);
}

- (CGRect)boundsContentView {
    return CGRectMake(CGPointZero.x, CGPointZero.y, self.rect.size.width, self.rect.size.height);
}

- (CGRect)paddingViewBounds {
    return CGRectMake(CGPointZero.x, CGPointZero.y,
                      paddingViewBoundsSizeWidth(self.padding.left,
                                                 self.padding.right,
                                                 self.rect.size.width),
                      paddingViewBoundsSizeHeight(self.padding.top,
                                                  self.padding.bottom,
                                                  self.rect.size.height));
}

- (CGRect)paddingViewFrame {
    CGRect paddingViewBounds = [self paddingViewBounds];
    return CGRectMake(CGPointZero.x + self.margin.left,
                      CGPointZero.y + self.margin.top,
                      paddingViewBounds.size.width, paddingViewBounds.size.height);
}

- (CGRect)elementViewBounds {
    return CGRectMake(CGPointZero.x, CGPointZero.y, self.rect.size.width, self.rect.size.height);
}

- (CGRect)elementViewFrameDesigner {
    return CGRectMake(self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height);
}

- (CGRect)elementViewFrame {
    CGRect elementViewBounds = [self elementViewBounds];
    return CGRectMake(CGPointZero.x + self.padding.left,
                      CGPointZero.y + self.padding.top,
                      elementViewBounds.size.width, elementViewBounds.size.height);
}

- (CGRect)frame {
    return MADDocObjFrameCalculated(self.rect.origin.x, self.spacingLeft,
                                    self.rect.origin.y, self.spacingTop,
                                    self.rect.size.width, self.spacingRight,
                                    self.rect.size.height, self.spacingBottom);
}

#pragma mark - Member

- (MTDocumentObjectType)documentObjectType {
    return self.type;
}

- (NSString *)designerRepresentationText {
    @throw NSInternalInconsistencyException;
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
                    NSMutableString *format;
                    format = [[NSMutableString alloc] initWithString:@"%."];
                    [format appendFormat:@"%lld", self.numericFormat.decimalCount];
                    [format appendString:@"f"];
                    result = [[NSString alloc] initWithFormat:format, [value floatValue]];
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

#pragma mark -
#pragma mark MTProtocolLog

- (NSString *)toString {
    return [self toStringDebug];
}

- (NSString *)toStringDebug {
    return [[NSString alloc] initWithFormat: @"%@-%@", self,
                                    [self designerRepresentationText]];
}

- (NSString *)toStringHumanReadable {
    return [self designerRepresentationText];
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
    
    NSString *fontname;
    
    UIFontDescriptorSymbolicTraits traits = 0;
    if (self.textStyle.italic) traits     |= UIFontDescriptorTraitItalic;
    if (self.textStyle.bold)   traits     |= UIFontDescriptorTraitBold;
    
    NSNumber *traitsWrapper = [[NSNumber alloc] initWithUnsignedInt: traits];
    
    NSDictionary *symbolicTraits = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    traitsWrapper, UIFontSymbolicTrait, nil];
    
    fontname = self.fontname;

    NSDictionary *fontAttributes;
    fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      fontname,         UIFontDescriptorFamilyAttribute,
                      @(self.fontsize), UIFontDescriptorSizeAttribute,
                      symbolicTraits,   UIFontDescriptorTraitsAttribute, nil];
    
    UIFontDescriptor *fontDescriptor;
    fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
    fontAttributes = nil;
    return fontDescriptor;
}


- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"ID:  \t\t%lld (%@)\n", self.identifier, self.debugDescriptionType];
    [description appendFormat:@"Sec: \t\t%@\n", [self.inSectionRow.inSection localizedDisplayName]];
    [description appendFormat:@"Font:\t\t%@ (%f)\n", self.fontname, self.fontsize];
    [description appendFormat:@"*********"];
    return description;
}

@end
