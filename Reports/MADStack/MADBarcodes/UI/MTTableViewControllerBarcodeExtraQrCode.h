//
//  MTTableViewControllerBarcodeExtraQrCode.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraQrCode_h
#define Barcodes_MTTableViewControllerBarcodeExtraQrCode_h

#import <UIKit/UIKit.h>

@protocol MTTableViewControllerBarcodeExtraQrCodeDelegate
- (void)barcodeQrCodeDidEnableAutomaticResizing;
- (void)barcodeQrCodeDidSetSize:(NSInteger)size;
- (void)barcodeQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection;

- (BOOL)barcodeQrCodeAutomaticResizing;
- (NSInteger)barcodeQrCodeInitalSize;
- (NSInteger)barcodeQrCodeInitalErrorCorrection;
@end

@interface MTTableViewControllerBarcodeExtraQrCode : UITableViewController

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraQrCodeDelegate> delegate;

@end

#endif
