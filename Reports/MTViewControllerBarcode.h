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

@property (nonatomic, retain, readonly) RptqQueryField *queryField1;
@property (nonatomic, retain, readonly) RptqQueryField *queryField2;
@property (nonatomic, retain, readonly) MTBarcode *barcode;

@end
