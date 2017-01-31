//
//  RptqDocumentElementBarcode+Extras.m
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElementBarcode+Extras.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <MADFoundation/MADDataType.h>

#import <MADBarcodes/MADBarcodes.h>

#import "RptqDocumentElement+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDataHelper.h"

@implementation RptqDocumentElementBarcode (Extras)

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

- (NSString *)copyDesignerRepresentationText {
    NSString *barcodeName = [(RptqDocumentElementBarcode *)self copyBarcodeTypeName];
    id result = [[NSString alloc] initWithFormat:@"Barcode (%@)", barcodeName];
    return result;
}

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    return [super formattedString:dataType forValue:value];
}

- (NSString *)copyBarcodeTypeName {
    NSString *result = [MTBarcode newBarcodeNameForType:self.barcodeType];
    return result;
}

- (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne fieldTwo:(RptqQueryField *)fieldTwo {

    self.add2dComponent =       @(barcode.has2dComponent);
    self.barcodeBorderStyle =   barcode.borderStyle;
    self.barcodeBorderWidth =   barcode.borderWidth;
    self.type =                 barcode.barcodeType;
    self.barcodeHeight =        barcode.height;
    self.humanReadable =        barcode.humanReadable;
    self.option1 =              barcode.option1;
    self.option2 =              barcode.option2;
    self.option3 =              barcode.option3;
    self.showErrorMessage =     barcode.showErrorMessages;
    self.whitespaceWidth =      barcode.whitespaceWidth;
    self.scale =                barcode.scale;
    self.referencesField1 =     fieldOne;
    self.referencesField2 =     fieldTwo;
    [self.managedObjectContext save:nil];
}

+ (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentElementBarcode *)documentObject {
    
    MTBarcode *barcode = [MTBarcode newBarcodeWithType:documentObject.barcodeType];
    barcode.has2dComponentEnabled =     documentObject.add2dComponent;
    barcode.borderStyle =               documentObject.barcodeBorderWidth;
    barcode.borderWidth =               documentObject.barcodeBorderWidth;
    barcode.height =                    documentObject.barcodeHeight;
    barcode.humanReadable =             documentObject.humanReadable;
    barcode.option1 =                   documentObject.option1;
    barcode.option2 =                   documentObject.option2;
    barcode.option3 =                   documentObject.option3;
    barcode.showErrorMessages =         documentObject.showErrorMessage;
    barcode.whitespaceWidth =           documentObject.whitespaceWidth;
    barcode.scale =                     documentObject.scale;
    barcode.input =                     @"Sample data";
    barcode.primaryData =               @"";
    return barcode;
}

+ (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentElementBarcode *)documentObject
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
    
    RptqDocumentElementBarcode *reportObject = nil;
    
    if (queryFieldOne != nil) {
    
        NSString *className = NSStringFromClass([RptqDocumentElementBarcode class]);
        NSEntityDescription *entityDescription;
        NSManagedObjectContext *objectContext = queryFieldOne.managedObjectContext;
        entityDescription = [NSEntityDescription entityForName: className
                                        inManagedObjectContext: objectContext];
        
        reportObject = [[RptqDocumentElementBarcode alloc] initWithEntity: entityDescription
                                          insertIntoManagedObjectContext: objectContext];
        reportObject.add2dComponent = barcode.has2dComponentEnabled;
        reportObject.barcodeBorderStyle = barcode.borderStyle;
        reportObject.barcodeBorderWidth = barcode.borderWidth;
        reportObject.backgroundColor = [UIColor whiteColor];
        reportObject.foregroundColor = [UIColor blackColor];
        reportObject.barcodeHeight = barcode.height;
        reportObject.humanReadable = barcode.humanReadable;
        reportObject.option1 = barcode.option1;
        reportObject.option2 = barcode.option2;
        reportObject.option3 = barcode.option3;
        reportObject.showErrorMessage = barcode.showErrorMessages;
        reportObject.type = barcode.barcodeType;
        reportObject.whitespaceWidth = barcode.whitespaceWidth;
        reportObject.useStaticInput1 = NO;
        reportObject.useStaticInput2 = NO;
        reportObject.scale = barcode.scale;
        
        reportObject.referencesField1 = queryFieldOne;
        reportObject.referencesField2 = queryFieldTwo;

    }
    
    return reportObject;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %lld\n", self.identifier];
    [description appendFormat:@"Encoded text:           %@\n", self.toStringHumanReadable];
    [description appendFormat:@"*********"];
    return description;
}

@end
