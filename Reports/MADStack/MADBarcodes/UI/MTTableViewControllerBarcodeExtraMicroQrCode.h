//
//  MTTableViewControllerBarcodeExtraMicroQrCode.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraMicroQrCode_h
#define Barcodes_MTTableViewControllerBarcodeExtraMicroQrCode_h

#import <UIKit/UITableViewController.h>

@protocol MTTableViewControllerBarcodeExtraMicroQrCodeDelegate
    - (void)barcodeMicroQrCodeDidEnableAutomaticResizing;
    - (void)barcodeMicroQrCodeDidSetSize:(NSInteger)size;
    - (void)barcodeMicroQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection;

    - (BOOL)barcodeMicroQrCodeAutomaticResizing;
    - (NSInteger)barcodeMicroQrCodeInitalSize;
    - (NSInteger)barcodeMicroQrCodeInitalErrorCorrection;
@end

@interface MTTableViewControllerBarcodeExtraMicroQrCode : UITableViewController

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraMicroQrCodeDelegate> delegate;

@end

#endif
