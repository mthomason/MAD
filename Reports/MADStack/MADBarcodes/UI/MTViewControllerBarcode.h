//
//  MTViewControllerBarcode.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcode_h
#define Barcodes_MTViewControllerBarcode_h

#import <UIKit/UIKit.h>
#import <MAD/MAD.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MTQuery.h>
#import <MAD/MTDataTable+Factory.h>
#import <MADFoundation/MTDataTable.h>

#import "MTViewControllerBarcodePreview.h"
#import "MTViewControllerBarcodeOptions.h"
#import "MTUnwindProtocol.h"
#import "MADViewController.h"

@class RptqDocumentObjectBarcode;

@protocol MTViewControllerBarcodeDelegate
- (void)didUpdateBarcode:(MTBarcode *)barcode withFieldOne:(RptqQueryField *)fieldOne andFieldTwo:(RptqQueryField *)fieldTwo;
@end

@interface MTViewControllerBarcode : MADViewController
    <MTViewControllerBarcodePreviewDelegate,
        MTViewControllerBarcodeOptionsDelegate,
        MTUnwindProtocol>

+ (instancetype)ViewControllerBarcode;

@property (nonatomic, weak) id <MTViewControllerBarcodeDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, strong, readwrite) RptqQueryField *queryField1;
@property (nonatomic, strong, readwrite) RptqQueryField *queryField2;
@property (nonatomic, strong, readwrite) MTBarcode *barcode;
@property (nonatomic, strong, readonly) MTViewControllerBarcodeOptions *optionsViewController;
@property (nonatomic, assign) BOOL editmode;

- (void)updateBarcode;

- (void)setBarcodeToEdit:(RptqDocumentObjectBarcode *)barcodeDocumentObject;

@end

#endif
