//
//  RptqDocumentElementBarcode+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementBarcode_CoreDataProperties_h
#define MAD_RptqDocumentElementBarcode_CoreDataProperties_h

#import "RptqDocumentElementBarcode+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementBarcode (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementBarcode *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *add2dComponent;
@property (nullable, nonatomic, copy) NSNumber *barcodeType;
@property (nullable, nonatomic, copy) NSNumber *barcodeBorderStyle;
@property (nullable, nonatomic, copy) NSNumber *barcodeBorderType;
@property (nullable, nonatomic, copy) NSNumber *barcodeBorderWidth;
@property (nullable, nonatomic, copy) NSNumber *barcodeHeight;
@property (nullable, nonatomic, copy) NSNumber *humanReadable;
@property (nullable, nonatomic, copy) NSString *inputField1;
@property (nullable, nonatomic, copy) NSString *inputField2;
@property (nullable, nonatomic, copy) NSNumber *inputMode;
@property (nullable, nonatomic, copy) NSString *inputStatic1;
@property (nullable, nonatomic, copy) NSString *inputStatic2;
@property (nullable, nonatomic, copy) NSNumber *option1;
@property (nullable, nonatomic, copy) NSNumber *option2;
@property (nullable, nonatomic, copy) NSNumber *option3;
@property (nullable, nonatomic, copy) NSNumber *scale;
@property (nullable, nonatomic, copy) NSNumber *showErrorMessage;
@property (nullable, nonatomic, copy) NSNumber *useStaticInput1;
@property (nullable, nonatomic, copy) NSNumber *useStaticInput2;
@property (nullable, nonatomic, copy) NSNumber *whitespaceWidth;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField1;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField2;

@end

NS_ASSUME_NONNULL_END

#endif
