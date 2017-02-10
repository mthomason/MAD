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

@dynamic has2dComponentEnabled;

- (NSString *)designerRepresentationText {
    NSString *barcodeName = [(RptqDocumentElementBarcode *)self copyBarcodeTypeName];
    id result = [[NSString alloc] initWithFormat:@"Barcode (%@)", barcodeName];
    return result;
}

- (NSString *)copyBarcodeTypeName {
    NSString *result = [MTBarcode newBarcodeNameForType:self.barcodeType];
    return result;
}

- (void)setHas2dComponentEnabled:(BOOL)has2dComponentEnabled {
    self.add2dComponent = has2dComponentEnabled;
}

- (BOOL)has2dComponentEnabled {
    return self.add2dComponent;
}

- (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne fieldTwo:(RptqQueryField *)fieldTwo {

    self.add2dComponent =       @(barcode.has2dComponent);
    self.barcodeBorderStyle =   barcode.barcodeBorderStyle;
    self.barcodeBorderWidth =   barcode.barcodeBorderWidth;
    self.type =                 barcode.barcodeType;
    self.barcodeHeight =        barcode.barcodeHeight;
    self.humanReadable =        barcode.humanReadable;
    self.option1 =              barcode.option1;
    self.option2 =              barcode.option2;
    self.option3 =              barcode.option3;
    self.showErrorMessage =     barcode.showErrorMessage;
    self.whitespaceWidth =      barcode.whitespaceWidth;
    self.scale =                barcode.scale;
    self.referencesField1 =     fieldOne;
    self.referencesField2 =     fieldTwo;
    [self.managedObjectContext save:nil];
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
        reportObject.barcodeBorderStyle = barcode.barcodeBorderStyle;
        reportObject.barcodeBorderWidth = barcode.barcodeBorderWidth;
        reportObject.backgroundColor = [UIColor whiteColor];
        reportObject.foregroundColor = [UIColor blackColor];
        reportObject.barcodeHeight = barcode.barcodeHeight;
        reportObject.humanReadable = barcode.humanReadable;
        reportObject.option1 = barcode.option1;
        reportObject.option2 = barcode.option2;
        reportObject.option3 = barcode.option3;
        reportObject.showErrorMessage = barcode.showErrorMessage;
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
