//
//  MTTableViewControllerBarcodeExtraGridMatrix.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraGridMatrix_h
#define Barcodes_MTTableViewControllerBarcodeExtraGridMatrix_h

#import <UIKit/UITableViewController.h>

@protocol MTTableViewControllerBarcodeExtraGridMatrixDelegate
- (void)barcodeGridMatrixDidEnableAutomaticResizing;
- (void)barcodeGridMatrixDidSetSize:(NSInteger)size;
- (void)barcodeGridMatrixDidSetErrorCorrection:(NSInteger)errorCorrection;

- (BOOL)barcodeGridMatrixAutomaticResizing;
- (NSInteger)barcodeGridMatrixInitalSize;
- (NSInteger)barcodeGridMatrixInitalErrorCorrection;
@end

@interface MTTableViewControllerBarcodeExtraGridMatrix : UITableViewController

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraGridMatrixDelegate> delegate;

@end

#endif
