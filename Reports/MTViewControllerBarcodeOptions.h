//
//  MTViewControllerBarcodeOptions.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTBarcode.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "MTViewControllerBarcodeType.h"

@protocol MTViewControllerBarcodeOptionsDelegate
- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType;
- (BOOL)didToggleHumanReadable;
- (BOOL)didToggleShowErrorMessages;
- (void)didChangeSymbolHeight:(NSInteger)symbolHeight;
- (void)setInput:(NSString *)input;
- (void)setBorderWidth:(CGFloat)borderWidth;
- (void)setBorderType:(MTBarcodeBorderStyle)borderStyle;
- (void)setSampleData:(NSArray *)sampleData;
@end

@interface MTViewControllerBarcodeOptions : UITableViewController
    <MTQueryBuilderChooseFieldDelegate, MTViewControllerBarcodeTypeDelegate>

//@property (nonatomic, assign) MTBarcodeType barcodeType;
@property (nonatomic, retain) MTBarcode *barcode;
@property (nonatomic, assign) id <MTViewControllerBarcodeOptionsDelegate> delegate;

@end
