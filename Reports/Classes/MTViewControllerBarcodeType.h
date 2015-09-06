//
//  MTViewControllerBarcodeType.h
//  MAD
//
//  Created by Michael Thomason on 11/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcodeType_h
#define Barcodes_MTViewControllerBarcodeType_h

#import "MTBarcode.h"

@protocol MTViewControllerBarcodeTypeDelegate
- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType;
@end

@interface MTViewControllerBarcodeType : UIViewController
    <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) id <MTViewControllerBarcodeTypeDelegate> delegate;
@property (nonatomic, assign) NSInteger initalKey;

@end

#endif
