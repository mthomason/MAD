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


@protocol MTViewControllerBarcodeOptionsDelegate
- (void)didToggleHumanReadable;
- (void)didToggleShowErrorMessages;
- (void)setInput:(NSString *)input;
- (void)setBorderWidth:(CGFloat)borderWidth;
- (void)setBorderType:(MTBarcodeBorderStyle)borderStyle;
- (void)setSampleData:(NSArray *)sampleData;
@end

@interface MTViewControllerBarcodeOptions : UITableViewController
    <MTQueryBuilderChooseFieldDelegate>

- (void)setBarcodeType:(MTBarcodeType)barcodeType;

@property (nonatomic, assign) id <MTViewControllerBarcodeOptionsDelegate> delegate;

@end
