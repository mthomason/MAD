//
//  RptqDocumentElementBarcode+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementBarcode.h"
#import "RptqQueryField.h"
@implementation RptqDocumentElementBarcode

@end

@implementation RptqDocumentElementBarcode (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementBarcode *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementBarcode"];
}

@dynamic add2dComponent;
@dynamic barcodeType;
@dynamic barcodeBorderStyle;
@dynamic barcodeBorderType;
@dynamic barcodeBorderWidth;
@dynamic barcodeHeight;
@dynamic humanReadable;
@dynamic inputField1;
@dynamic inputField2;
@dynamic inputMode;
@dynamic inputStatic1;
@dynamic inputStatic2;
@dynamic option1;
@dynamic option2;
@dynamic option3;
@dynamic scale;
@dynamic showErrorMessage;
@dynamic useStaticInput1;
@dynamic useStaticInput2;
@dynamic whitespaceWidth;
@dynamic referencesField1;
@dynamic referencesField2;

@end
