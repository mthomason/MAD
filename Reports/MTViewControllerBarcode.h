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

@interface MTViewControllerBarcode : UIViewController
    <MTViewControllerBarcodePreviewDelegate, MTViewControllerBarcodeOptionsDelegate>

@property (nonatomic, retain, readwrite) RptqQueryField *queryField1;
@property (nonatomic, retain, readwrite) RptqQueryField *queryField2;
@property (nonatomic, retain, readwrite) MTBarcode *barcode;
@property (nonatomic, retain, readonly) MTViewControllerBarcodeOptions *optionsViewController;

@property (nonatomic, assign) BOOL editmode;

- (void)updateBarcode;

@end
