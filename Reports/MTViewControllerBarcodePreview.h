//
//  MTViewControllerBarcodePreview.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTBarcode.h"

@protocol MTViewControllerBarcodePreviewDelegate
- (void)didChangeBarcodeType:(MTBarcodeType)type;
@end


@interface MTViewControllerBarcodePreview : UIViewController

@property (nonatomic, assign) id <MTViewControllerBarcodePreviewDelegate> delegate;
- (void)setBarcodeToPreview:(MTBarcode *)barcode;

- (void)update;

@end
