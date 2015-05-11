//
//  MTTableViewControllerBarcodeExtraMicroQrCode.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTTableViewControllerBarcodeExtraMicroQrCodeDelegate
- (void)barcodeMicroQrCodeDidEnableAutomaticResizing;
- (void)barcodeMicroQrCodeDidSetSize:(NSInteger)size;
- (void)barcodeMicroQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection;

- (BOOL)barcodeMicroQrCodeAutomaticResizing;
- (NSInteger)barcodeMicroQrCodeInitalSize;
- (NSInteger)barcodeMicroQrCodeInitalErrorCorrection;
@end

@interface MTTableViewControllerBarcodeExtraMicroQrCode : UITableViewController

@property (nonatomic, assign) id <MTTableViewControllerBarcodeExtraMicroQrCodeDelegate> delegate;

@end
