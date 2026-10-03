//
//  RptqDocumentElementBarcode.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentElementBarcode_RptqDocumentElement_h
#define MAD_RptqDocumentElementBarcode_RptqDocumentElement_h

#import <MAD/RptqDocumentElement.h>
@class RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementBarcode : RptqDocumentElement

@end

@interface RptqDocumentElementBarcode (CoreDataProperties)

@property (nonatomic) BOOL add2dComponent;
@property (nonatomic) BOOL humanReadable;
@property (nonatomic) BOOL showErrorMessage;
@property (nonatomic) BOOL useStaticInput1;
@property (nonatomic) BOOL useStaticInput2;
@property (nonatomic) float scale;
@property (nonatomic) int16_t barcodeType;
@property (nonatomic) int16_t barcodeBorderStyle;
@property (nonatomic) int16_t barcodeBorderType;
@property (nonatomic) int16_t barcodeBorderWidth;
@property (nonatomic) int16_t barcodeHeight;
@property (nonatomic) int16_t option1;
@property (nonatomic) int16_t option2;
@property (nonatomic) int16_t option3;
@property (nonatomic) int16_t whitespaceWidth;
@property (nonatomic) int16_t inputMode;
@property (nullable, nonatomic, copy) NSString *inputField1;
@property (nullable, nonatomic, copy) NSString *inputField2;
@property (nullable, nonatomic, copy) NSString *inputStatic1;
@property (nullable, nonatomic, copy) NSString *inputStatic2;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField1;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField2;

@end

NS_ASSUME_NONNULL_END

#endif
