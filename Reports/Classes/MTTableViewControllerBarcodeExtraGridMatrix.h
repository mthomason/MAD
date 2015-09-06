//
//  MTTableViewControllerBarcodeExtraGridMatrix.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraGridMatrix_h
#define Barcodes_MTTableViewControllerBarcodeExtraGridMatrix_h

#import <UIKit/UIKit.h>

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
