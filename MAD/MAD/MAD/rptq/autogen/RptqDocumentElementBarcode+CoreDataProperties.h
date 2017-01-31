//
//  RptqDocumentElementBarcode+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementBarcode+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementBarcode (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementBarcode *> *)fetchRequest;

@property (nonatomic) BOOL add2dComponent;
@property (nonatomic) int16_t barcodeType;
@property (nonatomic) int16_t barcodeBorderStyle;
@property (nonatomic) int16_t barcodeBorderType;
@property (nonatomic) int16_t barcodeBorderWidth;
@property (nonatomic) int16_t barcodeHeight;
@property (nonatomic) BOOL humanReadable;
@property (nullable, nonatomic, copy) NSString *inputField1;
@property (nullable, nonatomic, copy) NSString *inputField2;
@property (nonatomic) int16_t inputMode;
@property (nullable, nonatomic, copy) NSString *inputStatic1;
@property (nullable, nonatomic, copy) NSString *inputStatic2;
@property (nonatomic) int64_t option1;
@property (nonatomic) int64_t option2;
@property (nonatomic) int64_t option3;
@property (nonatomic) float scale;
@property (nonatomic) BOOL showErrorMessage;
@property (nonatomic) BOOL useStaticInput1;
@property (nonatomic) BOOL useStaticInput2;
@property (nonatomic) int16_t whitespaceWidth;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField1;
@property (nullable, nonatomic, retain) RptqQueryField *referencesField2;

@end

NS_ASSUME_NONNULL_END
