//
//  MTTableViewControllerBarcodeExtraDataMatrix.h
//  MAD
//
//  Created by Michael Thomason on 11/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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
