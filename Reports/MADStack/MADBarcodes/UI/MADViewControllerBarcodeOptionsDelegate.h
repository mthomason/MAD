//
//  MADViewControllerBarcodeOptionsDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADViewControllerBarcodeOptionsDelegate_h
#define MADViewControllerBarcodeOptionsDelegate_h

#import <MADBarcodes/MADBarcodeType.h>
#import <MADBarcodes/MADBarcodeBorderStyle.h>

@class MTBarcode;
@class RptqQueryField;

@protocol MTViewControllerBarcodeOptionsDelegate

    - (MTBarcode *)barcodeToDisplay;
    - (void)updateBarcode;
    - (void)didChangeBarcodeType:(MTBarcodeType)barcodeType;
    - (BOOL)didToggleHumanReadable;
    - (BOOL)didToggleShowErrorMessages;
    - (void)didChangeSymbolHeight:(int16_t)symbolHeight;
    - (void)setInput:(NSString *)input;
    - (void)setBorderWidth:(int16_t)borderWidth;
    - (void)setBorderType:(MTBarcodeBorderStyle)borderStyle;
    - (void)setSampleData:(NSArray *)sampleData;

    - (void)barcodeAztecDidEnableAutomaticResizing;
    - (void)barcodeAztecDidSetSize:(NSUInteger)size;
    - (void)barcodeAztecDidSetErrorCorrection:(NSUInteger)errorCorrection;

    - (void)barcodeGridMatrixDidEnableAutomaticResizing;
    - (void)barcodeGridMatrixDidSetSize:(NSInteger)size;
    - (void)barcodeGridMatrixDidSetErrorCorrection:(NSInteger)errorCorrection;

    - (void)barcodeQrCodeDidEnableAutomaticResizing;
    - (void)barcodeQrCodeDidSetSize:(NSInteger)size;
    - (void)barcodeQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection;

    - (void)barcodeMicroQrCodeDidEnableAutomaticResizing;
    - (void)barcodeMicroQrCodeDidSetSize:(NSInteger)size;
    - (void)barcodeMicroQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection;

    - (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode;
    - (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData;

    - (void)barcode2dComponentSetEnabled:(BOOL)enabled;
    - (void)barcode2dComponentSetType:(NSInteger)type;
    - (void)barcode2dComponentsetSampleData:(NSArray *)sampleData;

    - (void)barcodePDF417DidSetColumns:(NSInteger)columns;
    - (void)barcodePDF417DidSetFormat:(NSInteger)format;
    - (void)barcodePDF417DidSetErrorCorrection:(NSInteger)errorCorrection;

    - (void)didSetField1:(RptqQueryField *)field;
    - (void)didSetField2:(RptqQueryField *)field;

    - (RptqQueryField *)barcodeQueryField1;
    - (RptqQueryField *)barcodeQueryField2;

@end

#endif /* MADViewControllerBarcodeOptionsDelegate_h */
