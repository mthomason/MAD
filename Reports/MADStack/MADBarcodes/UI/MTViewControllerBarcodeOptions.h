//
//  MTViewControllerBarcodeOptions.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcodeOptions_h
#define Barcodes_MTViewControllerBarcodeOptions_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MAD/MAD.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MTQuery.h>
#import <MADFoundation/MTDataTable.h>

#import "MTViewControllerBarcodeType.h"
#import "MTTableViewControllerBarcodeExtraAztec.h"
#import "MTTableViewControllerBarcodeExtraGridMatrix.h"
#import "MTTableViewControllerBarcodeExtraMicroQrCode.h"
#import "MTTableViewControllerBarcodeExtraQrCode.h"
#import "MTTableViewControllerBarcodeExtraMaxicode.h"
#import "MTTableViewControllerBarcodeExtraDataMatrix.h"
#import "MTTableViewControllerBarcodeExtraPdf417Iso24728.h"

@protocol MTViewControllerBarcodeOptionsDelegate
- (MTBarcode *)barcodeToDisplay;
- (void)updateBarcode;
- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType;
- (BOOL)didToggleHumanReadable;
- (BOOL)didToggleShowErrorMessages;
- (void)didChangeSymbolHeight:(NSInteger)symbolHeight;
- (void)setInput:(NSString *)input;
- (void)setBorderWidth:(NSUInteger)borderWidth;
- (void)setBorderType:(MTBarcodeBorderStyle)borderStyle;
- (void)setSampleData:(NSArray *)sampleData;

- (void)barcodeAztecDidEnableAutomaticResizing;
- (void)barcodeAztecDidSetSize:(NSInteger)size;
- (void)barcodeAztecDidSetErrorCorrection:(NSInteger)errorCorrection;

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

@interface MTViewControllerBarcodeOptions : UITableViewController
    <MTQueryBuilderChooseFieldDelegate,
        MTViewControllerBarcodeTypeDelegate,
        MTTableViewControllerBarcodeExtraAztecDelegate,
        MTTableViewControllerBarcodeExtraGridMatrixDelegate,
        MTTableViewControllerBarcodeExtraMicroQrCodeDelegate,
        MTTableViewControllerBarcodeExtraQrCodeDelegate,
        MTTableViewControllerBarcodeExtraMaxicodeDelegate,
        MTTableViewControllerBarcodeExtraDataMatrixDelegate,
        MTTableViewControllerBarcodeExtraPdf417Iso24728Delegate>

@property (nonatomic, weak) id <MTViewControllerBarcodeOptionsDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, retain) NSArray *sampleBarcodeData;
@property (nonatomic, retain) NSArray *sampleBarcodeData2dComponent;
@property (nonatomic, retain) NSArray *sampleBarcodeDataMaxicode;

@end

#endif
