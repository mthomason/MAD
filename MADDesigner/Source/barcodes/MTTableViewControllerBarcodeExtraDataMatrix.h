//
//  MTTableViewControllerBarcodeExtraDataMatrix.h
//  MAD
//
//  Created by Michael Thomason on 11/15/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraDataMatrix_h
#define Barcodes_MTTableViewControllerBarcodeExtraDataMatrix_h

#import <UIKit/UITableViewController.h>

@protocol MTTableViewControllerBarcodeExtraDataMatrixDelegate
- (NSInteger)barcodeDataMatrixInitalSize;
- (void)barcodeDataMatrixDidSelectSize:(NSInteger)size;
- (void)barcodeDataMatrixDidSuppressRectangularSymbols:(BOOL)suppress;
- (BOOL)barcodeDataMatrixSuppressRectangularSymbols;
@end

@interface MTTableViewControllerBarcodeExtraDataMatrix : UITableViewController

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraDataMatrixDelegate> delegate;

@end

#endif
