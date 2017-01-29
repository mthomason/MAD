//
//  RptqDocumentObjectBarcode+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectBarcode+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentObjectBarcode (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectBarcode *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *add2dComponent;
@property (nullable, nonatomic, copy) NSNumber *barcodeType;
@property (nullable, nonatomic, copy) NSNumber *borderStyle;
@property (nullable, nonatomic, copy) NSNumber *borderType;
@property (nullable, nonatomic, copy) NSNumber *borderWidth;
@property (nullable, nonatomic, copy) NSNumber *height;
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
@property (nullable, nonatomic, retain) RptqDocumentObject *parentObjectBarcode;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField1;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField2;

@end

NS_ASSUME_NONNULL_END
