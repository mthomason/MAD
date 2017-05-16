//
//  MADElementMigrationPolicy.m
//  MAD Designer
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADElementMigrationPolicy.h"
#import <UIKit/UIGeometry.h>
#import <UIKit/UIColor.h>

#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/RptqPoint.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqDirectionalProperty.h>

#import <MAD/MADAlignment.h>
#import <MAD/MADCurrencyFormatter.h>

#import <MADCocoaExtensions/MADBorderStyle.h>
#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/MADTextStyle.h>

@implementation MADElementMigrationManager

- (NSArray<__kindof NSManagedObject *> *)destinationInstancesForEntityMappingNamed:(NSString *)mappingName
                                                                   sourceInstances:(NSArray<__kindof NSManagedObject *> *)sourceInstances {
    NSArray <__kindof NSManagedObject *> *results = [super destinationInstancesForEntityMappingNamed: mappingName
                                                                                     sourceInstances: sourceInstances];
    NSLog(@"Results (%@): %@", mappingName, results);
    return results;
}

@end

@implementation MADElementMigrationPolicy

/*- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance
                                      entityMapping:(NSEntityMapping *)mapping
                                            manager:(NSMigrationManager *)manager
                                              error:(NSError * _Nullable *)error{
    BOOL result = [super createDestinationInstancesForSourceInstance: sInstance
                                                       entityMapping: mapping
                                                             manager: manager
                                                               error: error];
 */
    /*
     if ([sInstance.entity.name isEqualToString: @"RptqDocumentObject"]) {
        NSArray *sInstances = [[NSArray alloc] initWithObjects:sInstance, nil];
        NSArray<__kindof NSManagedObject *> *dInstances = [manager destinationInstancesForEntityMappingNamed: mapping.name
                                                                                             sourceInstances: sInstances];
        NSAssert(dInstances.count == 1, @"We expect one and only one result.");
        NSManagedObjectContext *destinationContext = manager.destinationContext;
        RptqDocumentElement *destinationElement = dInstances[0];
        [self addBorderToElement:destinationElement fromElement:sInstance forContext:destinationContext];
        [self addPaddingToElement:destinationElement fromElement:sInstance forContext:destinationContext];
        [self addRectToElement:destinationElement fromElement:sInstance forContext:destinationContext];
        [self addNumericFormatToElement:destinationElement fromElement:sInstance forContext:destinationContext];
        [self addAlignmentToElement:destinationElement fromElement:sInstance forContext:destinationContext];
        [self addTextStyleToElement:destinationElement fromElement:sInstance forContext:destinationContext];
        [self addPointToElement:destinationElement fromElement:sInstance forContext:destinationContext];
       // NSError *saveError = nil;
        //if (![destinationContext save:&saveError]) {
        //    NSLog(@"%@", saveError);
       // }
    }*/
/*
    return result;
}*/

- (void)addBorderToElement:(RptqDocumentElement *)destinationElement
               fromElement:(NSManagedObject *)sourceElement
                forContext:(NSManagedObjectContext *)context {

    NSString *key = NSStringFromClass([RptqBorder class]);
    NSEntityDescription *entityDescription;
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqBorder *border = (RptqBorder *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                insertIntoManagedObjectContext: context];
    
    key = NSStringFromClass([RptqDirectionalProperty class]);
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqDirectionalProperty *style = (RptqDirectionalProperty *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                                         insertIntoManagedObjectContext: context];
    
    key = NSStringFromClass([RptqDirectionalAsymmetry class]);
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqDirectionalAsymmetry *width = (RptqDirectionalAsymmetry *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                                           insertIntoManagedObjectContext: context];

    NSNumber *n = [sourceElement valueForKey:@"borderHeightTop"];
    if (n != nil) [width setValue:n forKey:@"top"];
    
    n = [sourceElement valueForKey:@"borderHeightBottom"];
    if (n != nil) [width setValue:n forKey:@"bottom"];
    
    n = [sourceElement valueForKey:@"borderWidthLeft"];
    if (n != nil) [width setValue:n forKey:@"left"];
    
    n = [sourceElement valueForKey:@"borderWidthRight"];
    if (n != nil) [width setValue:n forKey:@"right"];

    n = [sourceElement valueForKey:@"borderStyleTop"];
    if (n != nil) [style setValue:n forKey:@"top"];
    
    n = [sourceElement valueForKey:@"borderStyleBottom"];
    if (n != nil) [style setValue:n forKey:@"bottom"];
    
    n = [sourceElement valueForKey:@"borderStyleLeft"];
    if (n != nil) [style setValue:n forKey:@"left"];

    n = [sourceElement valueForKey:@"borderStyleRight"];
    if (n != nil) [style setValue:n forKey:@"right"];
    
    border.width = width;
    border.style = style;
    destinationElement.border = border;

}

- (void)addPaddingToElement:(RptqDocumentElement *)destinationElement
                fromElement:(NSManagedObject *)sourceElement
                 forContext:(NSManagedObjectContext *)context {
    
    NSString *key = NSStringFromClass([RptqDirectionalAsymmetry class]);
    NSEntityDescription *entityDescription;
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqDirectionalAsymmetry *padding = (RptqDirectionalAsymmetry *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                                             insertIntoManagedObjectContext: context];
    
    NSNumber *n = [sourceElement valueForKey:@"paddingBottom"];
    if (n != nil) [padding setValue:n forKey:@"bottom"];
    
    n = [sourceElement valueForKey:@"paddingLeft"];
    if (n != nil) [padding setValue:n forKey:@"left"];
    
    n = [sourceElement valueForKey:@"paddingRight"];
    if (n != nil) [padding setValue:n forKey:@"right"];
    
    n = [sourceElement valueForKey:@"paddingTop"];
    if (n != nil) [padding setValue:n forKey:@"top"];
    
    destinationElement.padding = padding;

    RptqDirectionalAsymmetry *margin = (RptqDirectionalAsymmetry *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                                            insertIntoManagedObjectContext: context];
    
    n = [sourceElement valueForKey:@"marginBottom"];
    if (n != nil) [margin setValue:n forKey:@"bottom"];
    
    n = [sourceElement valueForKey:@"marginLeft"];
    if (n != nil) [margin setValue:n forKey:@"left"];
    
    n = [sourceElement valueForKey:@"marginRight"];
    if (n != nil) [margin setValue:n forKey:@"right"];
    
    n = [sourceElement valueForKey:@"marginTop"];
    if (n != nil) [margin setValue:n forKey:@"top"];
    
    destinationElement.margin = margin;
}

- (void)addRectToElement:(RptqDocumentElement *)destinationElement
             fromElement:(NSManagedObject *)sourceElement
              forContext:(NSManagedObjectContext *)context {
    
    NSString *key = NSStringFromClass([RptqRect class]);
    NSEntityDescription *entityDescription;
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    
    RptqRect *rect = (RptqRect *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                          insertIntoManagedObjectContext: context];

    key = NSStringFromClass([RptqPoint class]);
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];

    RptqPoint *origin = (RptqPoint *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                              insertIntoManagedObjectContext: context];

    key = NSStringFromClass([RptqSize class]);
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];

    RptqSize *size = (RptqSize *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                          insertIntoManagedObjectContext: context];

    NSNumber *n = [sourceElement valueForKey:@"originx"];
    if (n != nil) [origin setValue:n forKey:@"x"];

    n = [sourceElement valueForKey:@"originy"];
    if (n != nil) [origin setValue:n forKey:@"y"];
    
    n = [sourceElement valueForKey:@"sizewidth"];
    if (n != nil) [size setValue:n forKey:@"width"];

    n = [sourceElement valueForKey:@"sizeheight"];
    if (n != nil) [size setValue:n forKey:@"height"];

    rect.origin = origin;
    rect.size = size;
    destinationElement.rect = rect;
}

- (void)addNumericFormatToElement:(RptqDocumentElement *)destinationElement
                      fromElement:(NSManagedObject *)sourceElement
                       forContext:(NSManagedObjectContext *)context {
    
    NSString *key = NSStringFromClass([RptqNumericFormat class]);
    NSEntityDescription *entityDescription;
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqNumericFormat *numericFormat = (RptqNumericFormat *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                                     insertIntoManagedObjectContext: context];
    
    NSNumber *n;
    n = [sourceElement valueForKey:@"formatNumericDecimals"];
    if (n != nil) [numericFormat setValue:n forKey:@"decimalCount"];
    
    n = [sourceElement valueForKey:@"formatNumericCurrency"];
    if (n != nil) [numericFormat setValue:n forKey:@"enabled"];
    
    NSString *currencyLocale = [sourceElement valueForKey:@"formatNumericCurrencyLocal"];
    if (currencyLocale != nil) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:currencyLocale];
        if (locale != nil) [numericFormat setValue:locale forKey:@"locale"];
    }
    destinationElement.numericFormat = numericFormat;

}

- (void)addAlignmentToElement:(RptqDocumentElement *)destinationElement
                  fromElement:(NSManagedObject *)sourceElement
                   forContext:(NSManagedObjectContext *)context {
    
    NSEntityDescription *entityDescription;
    NSString *key;
    key = NSStringFromClass([RptqAlignment class]);
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqAlignment *alignment = (RptqAlignment *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                         insertIntoManagedObjectContext: context];;
    
    NSNumber *n;
    n = [sourceElement valueForKey:@"horizontalAlignment"];
    if (n != nil) [alignment setValue:n forKey:@"horizontal"];
    
    n = [sourceElement valueForKey:@"verticalAlignment"];
    if (n != nil) [alignment setValue:n forKey:@"vertical"];
    
    destinationElement.alignment = alignment;
}

- (void)addTextStyleToElement:(RptqDocumentElement *)destinationElement
                  fromElement:(NSManagedObject *)sourceElement
                   forContext:(NSManagedObjectContext *)context {
    
    NSEntityDescription *entityDescription;
    NSString *key;
    key = NSStringFromClass([RptqTextStyle class]);
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqTextStyle *textStyle = (RptqTextStyle *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                                         insertIntoManagedObjectContext: context];
    
    NSNumber *n;
    n = [sourceElement valueForKey:@"underline"];
    if (n != nil) [textStyle setValue:n forKey:@"underline"];
    
    n = [sourceElement valueForKey:@"bold"];
    if (n != nil) [textStyle setValue:n forKey:@"bold"];
    
    n = [sourceElement valueForKey:@"strike"];
    if (n != nil) [textStyle setValue:n forKey:@"strikethrough"];
    
    n = [sourceElement valueForKey:@"italic"];
    if (n != nil) [textStyle setValue:n forKey:@"italic"];

    destinationElement.textStyle = textStyle;

}

- (void)addPointToElement:(RptqDocumentElement *)destinationElement
              fromElement:(NSManagedObject *)sourceElement
               forContext:(NSManagedObjectContext *)context {
    
    NSEntityDescription *entityDescription;
    NSString *key = NSStringFromClass([RptqPoint class]);
    entityDescription = [NSEntityDescription entityForName: key
                                    inManagedObjectContext: context];
    RptqPoint *point = (RptqPoint *)[[NSManagedObject alloc] initWithEntity: entityDescription
                                             insertIntoManagedObjectContext: context];
    
    NSNumber *n;
    key = NSStringFromClass([RptqPoint class]);
    n = [sourceElement valueForKey:@"dropPointX"];
    if (n != nil) [point setValue: n forKey:@"x"];
    
    n = [sourceElement valueForKey:@"dropPointY"];
    if (n != nil) [point setValue: n forKey:@"y"];

    destinationElement.dropPoint = point;
}


- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance
                                    entityMapping:(NSEntityMapping *)mapping
                                          manager:(NSMigrationManager *)manager
                                            error:(NSError * _Nullable __autoreleasing *)error {
    
    NSError *errorCreate = NULL;
    BOOL result = [super createRelationshipsForDestinationInstance: dInstance
                                                     entityMapping: mapping
                                                           manager: manager
                                                             error: &errorCreate];

    NSString *keyDocumentElement = NSStringFromClass([RptqDocumentElement class]);
    if ([dInstance.entity.name hasPrefix:keyDocumentElement]) {
        NSArray *dInstances = [[NSArray alloc] initWithObjects:dInstance, nil];
        NSArray <__kindof NSManagedObject *> *sInstances = [manager sourceInstancesForEntityMappingNamed:mapping.name
                                                                                    destinationInstances:dInstances];
        NSAssert(dInstances.count == 1, @"We expect one and only one result.");
        NSLog(@"%@", sInstances);
        NSManagedObject *element = sInstances[0];
        //NSString *key = NSStringFromClass([RptqBorder class]);
        NSManagedObjectContext *destinationContext = manager.destinationContext;
        NSAssert(destinationContext != nil, @"We need a managed object context.");
        __kindof RptqDocumentElement *dElement = (RptqDocumentElement *)dInstance;
        [self addBorderToElement:dElement fromElement:element forContext:destinationContext];
        [self addPaddingToElement:dElement fromElement:element forContext:destinationContext];
        [self addRectToElement:dElement fromElement:element forContext:destinationContext];
        [self addNumericFormatToElement:dElement fromElement:element forContext:destinationContext];
        [self addAlignmentToElement:dElement fromElement:element forContext:destinationContext];
        [self addTextStyleToElement:dElement fromElement:element forContext:destinationContext];
        [self addPointToElement:dElement fromElement:element forContext:destinationContext];
        
        //NSLog(@"%@", dInstance);
        //NSError *errorSave = NULL;
        //[destinationContext save:&errorSave];
    }
    return result;
}

- (BOOL)endRelationshipCreationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [super endRelationshipCreationForEntityMapping:mapping manager:manager error:error];
    return result;
}

- (NSValue *)migrateValueFromPointX:(NSNumber *)x pointY:(NSNumber *)y {
    CGPoint origin = CGPointMake(x.floatValue, y.floatValue);
    return [NSValue valueWithCGPoint:origin];
}

- (MADAlignment *)migrateValueFromAlignmentHorizontal:(NSNumber *)horizontal
                                             vertical:(NSNumber *)vertical {
    int16_t h, v;
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)horizontal, kCFNumberSInt16Type, &h);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)vertical, kCFNumberSInt16Type, &v);
    MADAlignment *a = [[MADAlignment alloc] initWithHorizontal:h
                                                      vertical:v];
    return a;
}

- (UIColor *)migrateColorFromData:(NSData *)colorData {
    return colorData != nil ? [NSKeyedUnarchiver unarchiveObjectWithData:colorData] : nil;
}

- (MADMargin *)migrateValueFromMarginLeft:(NSNumber *)left
                                    right:(NSNumber *)right
                                      top:(NSNumber *)top
                                   bottom:(NSNumber *)bottom {
    id result = [[MADMargin alloc] initWithLeft: left.doubleValue
                                          right: right.doubleValue
                                            top: top.doubleValue
                                         bottom: bottom.doubleValue];
    return result;
}

- (MADPadding *)migrateValueFromPaddingLeft:(NSNumber *)left
                                      right:(NSNumber *)right
                                        top:(NSNumber *)top
                                     bottom:(NSNumber *)bottom {
    id padding = [[MADPadding alloc] initWithLeft: left.doubleValue
                                            right: right.doubleValue
                                              top: top.doubleValue
                                           bottom: bottom.doubleValue];
    return padding;
}

- (MADTextStyle *)migrateTextStyleBold:(NSNumber *)bold
                         strikethrough:(NSNumber *)strikethrough
                                italic:(NSNumber *)italic
                             underline:(NSNumber *)underline {
    id textStyle = [[MADTextStyle alloc] initWithBold: bold.boolValue
                                               italic: italic.boolValue
                                            underline: underline.boolValue
                                        strikethrough: strikethrough.boolValue];
    return textStyle;
}

- (NSValue *)migrateValueFromSizeWidth:(NSNumber *)width height:(NSNumber *)height {
    CGSize s = CGSizeMake(width.floatValue, height.floatValue);
    return [NSValue valueWithCGSize:s];
}

- (MADBorderStyle *)migrateValueFromBorderHeightBottom:(NSNumber *)heightBottom
                                             heightTop:(NSNumber *)heightTop
                                             widthLeft:(NSNumber *)widthLeft
                                            widthRight:(NSNumber *)widthRight
                                           styleBottom:(NSNumber *)styleBottom
                                              styleTop:(NSNumber *)styleTop
                                             styleLeft:(NSNumber *)styleLeft
                                            styleRight:(NSNumber *)styleRight {
    if (heightBottom == nil ||
        heightTop == nil ||
        widthLeft == nil ||
        widthRight == nil ||
        styleBottom == nil ||
        styleTop == nil ||
        styleRight == nil ||
        styleBottom == nil) return nil;
    
    int16_t ls, rs, ts, bs;

    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleLeft, kCFNumberSInt16Type, &ls);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleRight, kCFNumberSInt16Type, &rs);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleTop, kCFNumberSInt16Type, &ts);
    CFNumberGetValue((__bridge CFNumberRef _Nonnull)styleBottom, kCFNumberSInt16Type, &bs);

    id style = [[MADBorderStyle alloc] initWithLeft: widthLeft.doubleValue
                                              right: widthRight.doubleValue
                                                top: heightTop.doubleValue
                                             bottom: heightBottom.doubleValue
                                          leftStyle: ls
                                         rightStyle: rs
                                           topStyle: ts
                                        bottomStyle: bs];
    
    return style;
}

- (MADCurrencyFormatter *)migrateCurrencyFormatterForCurrencyEnabled:(NSNumber *)enabled
                                                              locale:(NSString *)locale
                                                        decimalCount:(NSNumber *)decimalCount {
    MADCurrencyFormatter *currency;
    currency = [[MADCurrencyFormatter alloc] init];
    currency.enabled = [enabled boolValue];
    currency.decimalCount = [decimalCount integerValue];
    currency.locale = [NSLocale currentLocale];
    return currency;
}

- (NSString *)migrateValueFromMySQLDatabaseName:(NSString *)mySQLDBName
                                      tdsDBName:(NSString *)tdsDBName {
    NSString *databaseName;
    if (mySQLDBName.length > 0)
        databaseName = mySQLDBName.copy;
    else if (tdsDBName.length > 0)
        databaseName = tdsDBName.copy;

    return databaseName;
}

- (NSString *)migrateStringNotNullOrEmpty:(NSString *)s1
                                  string2:(NSString *)s2 {
    return s1.length > 0 ? s1 : s2;
}

- (NSNumber *)migrateValueInt64NotZero:(NSNumber *)v1
                                value2:(NSNumber *)v2 {
    return [v1 isEqualToNumber: @0] ? v2 : v1;
    
}

@end
