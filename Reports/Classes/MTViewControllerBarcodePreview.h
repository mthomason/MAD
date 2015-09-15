//
//  MTViewControllerBarcodePreview.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcodePreview_h
#define Barcodes_MTViewControllerBarcodePreview_h

#import <UIKit/UIKit.h>
#import <MADBarcodes/MADBarcodes.h>
#import "MTViewControllerBarcodePreviewDelegate.h"

@class MTBarcode;

@interface MTViewControllerBarcodePreview : UIViewController

@property (nonatomic, weak) id <MTViewControllerBarcodePreviewDelegate> delegate;

- (void)setBarcodeToPreview:(MTBarcode *)barcode;
- (void)update;

@end

#endif
