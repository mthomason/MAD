//
//  RptqDocumentObject+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObject+Extras.h"
#import "MTBarcode.h"
#import "RptqDocumentObject.h"
#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectGroupKey.h"

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
    
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
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
    [self setDropPointX:@(CGPointZero.x)];
    [self setDropPointY:@(CGPointZero.y)];
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

#pragma mark - Member

- (MTDocumentObjectType)getType {
    return [[self type] integerValue];
}

- (NSString *)designerRepresentationText {

    NSString *result = nil;
    
    switch ([[self type] integerValue]) {
    
        case MTDocumentObjectTypeAggregate: {
            RptqDocumentObjectAggregate *aggregateObject = [self isAggregate];
            if ([aggregateObject aggregateField] != nil) {
                result = [NSString stringWithFormat:@"Aggregate: %@", [[aggregateObject aggregateField] toStringHumanReadable]];
            } else if ([aggregateObject aggregateFunction] != nil) {
                result = @"Aggregate function";
            }
            
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
            //MTBarcode *barcode = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
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

#pragma mark - RptqDocumentObjectFactory

+ (RptqDocumentObject *)addDocumentObject:(NSDictionary *)documentObjectDefination toDocument:(RptqDocument *)document {

    NSManagedObjectContext *mangedObjectContext = [document managedObjectContext];
    
    MTDocumentObjectType objectType = [[documentObjectDefination objectForKey:MTDocumentObjectDefinationType] integerValue];

    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: mangedObjectContext];
    
    RptqDocumentObject *documentObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                 insertIntoManagedObjectContext: mangedObjectContext];

    [documentObject setOriginx: @(CGPointZero.x)];
    [documentObject setOriginy: @(CGPointZero.y)];
    [documentObject setSizewidth: @(75.0000f)];
    [documentObject setSizeheight: @(22.0000f)];

    NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabelDataField class])
                                                                 inManagedObjectContext: mangedObjectContext];

            NSManagedObjectID *fieldObjectId = [documentObjectDefination objectForKey: MTDocumentObjectDefinationObject];
            RptqQueryField *field = [RptqQueryField getQueryFieldForObjectID: fieldObjectId
                                                                        fromObjectContext: mangedObjectContext];
            
            
            RptqDocumentObjectLabelDataField *reportObject = [[RptqDocumentObjectLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                                       insertIntoManagedObjectContext: mangedObjectContext];
            
            [documentObject setIsLabelDataField: reportObject];
            [[documentObject isLabelDataField] setReferencesQueryField: field];
            
            [reportObject setReferencesQueryField: field];

            [documentObject setType: @(MTDocumentObjectTypeLabelDynamic)];
            
            [reportObject release];
            
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {

            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabel class])
                                                                 inManagedObjectContext: mangedObjectContext];

            NSString *labelText = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectLabel *reportObject = [[RptqDocumentObjectLabel alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            
            [documentObject setIsLabel: reportObject];
            [[documentObject isLabel] setText: labelText];
            
            [documentObject setType: @(MTDocumentObjectTypeLabelStatic)];
            
            [reportObject release];
            
            break;
        }
        case MTDocumentObjectTypeAggregate: {

            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectAggregate class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSDictionary *aggregateOptions = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectAggregate *reportObject = [[RptqDocumentObjectAggregate alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                             insertIntoManagedObjectContext: [document managedObjectContext]];

            NSNumber *groupTypeContainer = [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregatePivotType];
            NSNumber *functionInputType = [aggregateOptions objectForKey:MTDocumentObjectDefinationAggregateFunctionInputType];

            MTAggregateFunctionInputType functionType = [functionInputType integerValue];
            [reportObject setGroupNumber:   [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregatePivotNumber]];
            [reportObject setGroupType:     groupTypeContainer];
            [reportObject setFunction:      [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregateType]];

            NSManagedObjectID *objectId = [aggregateOptions objectForKey:MTDocumentObjectDefinationAggregateObjectId];

            switch (functionType) {
                case MTAggregateFunctionInputTypeField: {
                    RptqQueryField *field = [RptqQueryField getQueryFieldForObjectID:objectId fromObjectContext:mangedObjectContext];
                    [reportObject setAggregateField:field];
                    [reportObject setAggregateFunction:nil];
                    break;
                }
                case MTAggregateFunctionInputTypeFormula: {
                    RptqDocumentObjectFormula *formula = [RptqDocumentObjectFormula getElementForObjectID:objectId fromObjectContext:mangedObjectContext];
                    [reportObject setAggregateField:nil];
                    [reportObject setAggregateFunction:formula];
                    break;
                }
                default:
                    break;
            }
            
            [documentObject setIsAggregate: reportObject];
            [documentObject setType: @(MTDocumentObjectTypeAggregate)];

            [reportObject release];

            break;
        }
        case MTDocumentObjectTypeImage: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectImage class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            UIImage *image = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectImage *reportObject = [[RptqDocumentObjectImage alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            [reportObject setImage:image];
            [documentObject setIsImage: reportObject];
            [documentObject setSizeheight:@([image size].height)];
            [documentObject setSizewidth:@([image size].width)];
            [documentObject setType: @(MTDocumentObjectTypeImage)];
            
            [reportObject release];

            break;
        }
        case MTDocumentObjectTypeWhtiespace: {

            [documentObject setType: @(MTDocumentObjectTypeWhtiespace)];

            break;
        }
        case MTDocumentObjectTypeBarcode: {
            
            MTBarcode *barcode = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
            NSManagedObjectID *field1ObjectId = [documentObjectDefination objectForKey:MTDocumentObjectDefinationField1];
            NSManagedObjectID *field2ObjectId = [documentObjectDefination objectForKey:MTDocumentObjectDefinationField2];
            RptqQueryField *field1 = [RptqQueryField getQueryFieldForObjectID:field1ObjectId fromObjectContext:mangedObjectContext];
            RptqQueryField *field2 = [RptqQueryField getQueryFieldForObjectID:field2ObjectId fromObjectContext:mangedObjectContext];
            RptqDocumentObjectBarcode *reportObject = [[RptqDocumentObjectBarcode barcodeWithMtBarcode:barcode queryFieldOne:field1 queryFieldTwo:field2] retain];
            
            [documentObject setIsBarcode: reportObject];
            [documentObject setType: @(MTDocumentObjectTypeBarcode)];

            [reportObject release];
            
            break;
        }
        default:
            break;
    }
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[[[document hasDetailSection] hasRows] objectAtIndex:0] hasObjects]];
    [hasObjects insertObject:documentObject atIndex:0];
    [[[[document hasDetailSection] hasRows] objectAtIndex:0] setHasObjects:hasObjects];
    [hasObjects release];
    //[[document managedObjectContext] save:nil];
    return [documentObject autorelease];
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

+ (id)getElementForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objid];
    return result;
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
    
    if (!currencyNumberFormatter) {
        currencyNumberFormatter = [[NSNumberFormatter alloc] init];
        [currencyNumberFormatter setLocale:[NSLocale currentLocale]];
        [currencyNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    }
    
    NSString *result;
    switch (dataType) {
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
            //result = NSLocalizedString(@"Not implemented.", @"Not implemented.");
                        result = [NSString stringWithFormat:@"%@", value];
            /*            @throw [NSException exceptionWithName: NSInternalInconsistencyException
             reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
             userInfo: nil];*/
            
            break;
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
                    //NSNumberFormatter *currencyNumberFormatter = [[NSNumberFormatter alloc] init];
                    //[currencyNumberFormatter setLocale:[NSLocale currentLocale]];
                    //[currencyNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    result = [currencyNumberFormatter stringFromNumber:value];
                } else {
                    NSMutableString *formatString = [[NSMutableString alloc] initWithString:@"%."];
                    [formatString appendFormat:@"%ld", (long)[[self formatNumericDecimals] integerValue]];
                    [formatString appendString:@"f"];
                    result = [NSString stringWithFormat:formatString, [value floatValue]];
                    [formatString release];
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

+ (RptqDocumentObject *)documentObjectForObject:(NSManagedObject *)managedObject {
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
    return [[result retain] autorelease];
}

#pragma mark - MTProtocolLog

- (NSString *)toString {
    return [self toStringDebug];
}

- (NSString *)toStringDebug {
    return [[[NSString stringWithFormat: @"%@-%@", self, [self designerRepresentationText]] retain] autorelease];
}

- (NSString *)toStringHumanReadable {
    return [[[NSString stringWithFormat: @"%@", [self designerRepresentationText]] retain] autorelease];
}

- (NSAttributedString *)toAttributedString {
    return nil;
}

@end
