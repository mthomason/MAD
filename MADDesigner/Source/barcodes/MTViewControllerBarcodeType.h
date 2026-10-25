//
//  MTViewControllerBarcodeType.h
//  MAD
//
//  Created by Michael Thomason on 11/8/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MTViewControllerBarcodeType_h
#define Barcodes_MTViewControllerBarcodeType_h

#import <UIKit/UIViewController.h>
#import <UIKit/UIPickerView.h>

#import <MADBarcodes/MADBarcodeType.h>

@protocol MTViewControllerBarcodeTypeDelegate
    - (void)didChangeBarcodeType:(MADBarcodeType)barcodeType;
@end

@interface MTViewControllerBarcodeType : UIViewController
    <UIPickerViewDataSource, UIPickerViewDelegate>

    @property (nonatomic, weak) id <MTViewControllerBarcodeTypeDelegate> delegate;
    @property (nonatomic, assign) NSInteger initalKey;

@end

#endif
