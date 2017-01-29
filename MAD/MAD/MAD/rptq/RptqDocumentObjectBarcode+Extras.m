//
//  RptqDocumentObjectBarcode+Extras.m
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentObjectBarcode+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <MADBarcodes/MADBarcodes.h>
#import "RptqDataHelper.h"

@implementation RptqDocumentObjectBarcode (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
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

- (NSString *)copyBarcodeTypeName {
    NSString *result = [MTBarcode newBarcodeNameForType:self.type.unsignedIntegerValue];
    return result;
}

- (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne fieldTwo:(RptqQueryField *)fieldTwo {

    self.add2dComponent = @(barcode.has2dComponent);
    self.borderStyle =       @(barcode.borderStyle);
    self.borderWidth =        @(barcode.borderWidth);
    self.type = @(barcode.barcodeType);
    self.height = @(barcode.height);
    self.humanReadable = @(barcode.humanReadable);
    self.option1 = @(barcode.option1);
    self.option2 = @(barcode.option2);
    self.option3 = @(barcode.option3);
    self.showErrorMessage = @(barcode.showErrorMessages);
    self.whitespaceWidth = @(barcode.whitespaceWidth);
    self.scale = @(barcode.scale);
    self.referencesField1 = fieldOne;
    self.referencesField2 = fieldTwo;
    [self.managedObjectContext save:nil];
}

+ (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject {
    
    MTBarcodeType type = documentObject.type.unsignedIntegerValue;
    MTBarcode *barcode = [MTBarcode newBarcodeWithType:type];

    barcode.has2dComponentEnabled =     documentObject.add2dComponent.boolValue;
    barcode.borderStyle =               documentObject.borderStyle.unsignedCharValue;
    barcode.borderWidth =               documentObject.borderWidth.integerValue;
    barcode.height =                    documentObject.height.integerValue;
    barcode.humanReadable =             documentObject.humanReadable.boolValue;
    barcode.option1 =                   documentObject.option1.integerValue;
    barcode.option2 =                   documentObject.option2.integerValue;
    barcode.option3 =                   documentObject.option3.integerValue;
    barcode.showErrorMessages =         documentObject.showErrorMessage.boolValue;
    barcode.whitespaceWidth =           documentObject.whitespaceWidth.boolValue;
    barcode.scale =                     documentObject.scale.floatValue;
    barcode.input =                     @"Sample data";
    barcode.primaryData =               @"";
    return barcode;
}

+ (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject
                                     input1:(NSString *)input1
                                     input2:(NSString *)input2 {
    MTBarcode *barcode = [self newBarcodeWithDocumentObject:documentObject];
    barcode.input = input1.copy;
    barcode.primaryData = input2.copy;
    return barcode;
}

+ (instancetype)barcodeWithMtBarcode:(MTBarcode *)barcode
                       queryFieldOne:(RptqQueryField *)queryFieldOne
                       queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED {
    
    RptqDocumentObjectBarcode *reportObject = nil;
    
    if (queryFieldOne != nil) {
    
        NSString *className = NSStringFromClass([RptqDocumentObjectBarcode class]);
        NSEntityDescription *entityDescription;
        NSManagedObjectContext *objectContext = queryFieldOne.managedObjectContext;
        entityDescription = [NSEntityDescription entityForName: className
                                        inManagedObjectContext: objectContext];
        
        reportObject = [[RptqDocumentObjectBarcode alloc] initWithEntity: entityDescription
                                          insertIntoManagedObjectContext: objectContext];
        
        
        NSNumber *componentEnabled = [[NSNumber alloc] initWithBool: barcode.has2dComponentEnabled];
        reportObject.add2dComponent = componentEnabled;
        
        NSNumber *borderStyle = [[NSNumber alloc] initWithInteger: barcode.borderStyle];
        reportObject.borderStyle = borderStyle;
        
        NSNumber *borderWidth = [[NSNumber alloc] initWithInteger: barcode.borderWidth];
        reportObject.borderWidth = borderWidth;

        NSData *colorBackground = [NSKeyedArchiver archivedDataWithRootObject:[UIColor whiteColor]];
        reportObject.colorBackground = colorBackground;

        NSData *colorForeground = [NSKeyedArchiver archivedDataWithRootObject:[UIColor blackColor]];
        reportObject.colorForeground = colorForeground;
        
        NSNumber *height = [[NSNumber alloc] initWithInteger: barcode.height];
        reportObject.height = height;
        
        NSNumber *humanReadable = [[NSNumber alloc] initWithBool: barcode.humanReadable];
        reportObject.humanReadable = humanReadable;
        
        NSNumber *option1 = [[NSNumber alloc] initWithInteger: barcode.option1];
        reportObject.option1 = option1;
        
        NSNumber *option2 = [[NSNumber alloc] initWithInteger: barcode.option2];
        reportObject.option2 = option2;
        
        NSNumber *option3 = [[NSNumber alloc] initWithInteger: barcode.option3];
        reportObject.option3 = option3;
        
        NSNumber *showErrorMessage = [[NSNumber alloc] initWithBool:barcode.showErrorMessages];
        reportObject.showErrorMessage = showErrorMessage;
        
        NSNumber *barcodeType = [[NSNumber alloc] initWithInteger: barcode.barcodeType];
        reportObject.type = barcodeType;
        
        NSNumber *whitespaceWidth = [[NSNumber alloc] initWithInteger: barcode.whitespaceWidth];
        reportObject.whitespaceWidth = whitespaceWidth;
        
        NSNumber *useStaticInput1 = [[NSNumber alloc] initWithBool: NO];
        reportObject.useStaticInput1 = useStaticInput1;
        
        NSNumber *useStaticInput2 = [[NSNumber alloc] initWithBool: NO];
        reportObject.useStaticInput2 = useStaticInput2;
        
        NSNumber *scale = [[NSNumber alloc] initWithFloat: barcode.scale];
        reportObject.scale = scale;
        
        reportObject.referencesField1 = queryFieldOne;
        reportObject.referencesField2 = queryFieldTwo;

    }
    
    return reportObject;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Encoded text:           %@\n", self.humanReadable];
    [description appendFormat:@"*********"];
    return description;
}

@end
