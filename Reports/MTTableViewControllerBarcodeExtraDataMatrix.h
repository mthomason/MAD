//
//  MTTableViewControllerBarcodeExtraDataMatrix.h
//  MAD
//
//  Created by Michael Thomason on 11/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTTableViewControllerBarcodeExtraDataMatrixDelegate
- (NSInteger)barcodeDataMatrixInitalSize;
- (void)barcodeDataMatrixDidSelectSize:(NSInteger)size;
- (void)barcodeDataMatrixDidSuppressRectangularSymbols:(BOOL)suppress;
- (BOOL)barcodeDataMatrixSuppressRectangularSymbols;
@end

@interface MTTableViewControllerBarcodeExtraDataMatrix : UITableViewController

@property (nonatomic, assign) id <MTTableViewControllerBarcodeExtraDataMatrixDelegate> delegate;

@end
