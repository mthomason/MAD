//
//  MTViewControllerBarcodePreview.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcodePreview_h
#define Barcodes_MTViewControllerBarcodePreview_h

#import <UIKit/UIViewController.h>

@protocol MTViewControllerBarcodePreviewDelegate;

@class MADBarcode;

@interface MTViewControllerBarcodePreview : UIViewController

    @property (nonatomic, weak) id <MTViewControllerBarcodePreviewDelegate> delegate;

    - (void)setBarcodeToPreview:(MADBarcode *)barcode;
    - (void)update;

@end

#endif
