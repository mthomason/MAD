//
//  MTViewControllerBarcodeType.h
//  MAD
//
//  Created by Michael Thomason on 11/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTViewController.h"
#import "MTBarcode.h"


@protocol MTViewControllerBarcodeTypeDelegate
- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType;
@end

@interface MTViewControllerBarcodeType : UIViewController
    <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, assign) id <MTViewControllerBarcodeTypeDelegate> delegate;
@property (nonatomic, assign) NSInteger initalKey;
@end
