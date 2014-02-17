//
//  MTViewControllerBarcode.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewControllerBarcodePreview.h"
#import "MTViewControllerBarcodeOptions.h"
#import "MTApplicaitonInstance.h"

extern NSString * const MTIdentifierSegueDocumentObjectEditBarcode;
extern NSString * const MTDocumentObjectNewBarcodeViewControllerIdentifier;
extern NSString * const MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier;

@protocol MTViewControllerBarcodeDelegate
- (void)didUpdateBarcode:(MTBarcode *)barcode withFieldOne:(RptqQueryField *)fieldOne andFieldTwo:(RptqQueryField *)fieldTwo;
@end

@interface MTViewControllerBarcode : UIViewController
    <MTViewControllerBarcodePreviewDelegate, MTViewControllerBarcodeOptionsDelegate>

@property (nonatomic, assign) id <MTViewControllerBarcodeDelegate> delegate;

//@property (nonatomic, retain) MTApplicaitonInstance *applicationInstance;

@property (nonatomic, retain, readwrite) RptqQueryField *queryField1;
@property (nonatomic, retain, readwrite) RptqQueryField *queryField2;
@property (nonatomic, retain, readwrite) MTBarcode *barcode;
@property (nonatomic, retain, readonly) MTViewControllerBarcodeOptions *optionsViewController;
@property (nonatomic, assign) BOOL editmode;

- (void)updateBarcode;

- (void)setBarcodeToEdit:(RptqDocumentObjectBarcode *)barcodeDocumentObject;

@end
