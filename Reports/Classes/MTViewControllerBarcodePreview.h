//
//  MTViewControllerBarcodePreview.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewControllerBarcodePreviewDelegate.h"

@class MTBarcode;

@interface MTViewControllerBarcodePreview : UIViewController

@property (nonatomic, assign) id <MTViewControllerBarcodePreviewDelegate> delegate;

- (void)setBarcodeToPreview:(MTBarcode *)barcode;
- (void)update;

@end
