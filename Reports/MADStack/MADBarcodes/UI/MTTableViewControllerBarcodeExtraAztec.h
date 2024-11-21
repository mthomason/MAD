//
//  MTTableViewControllerBarcodeExtraAztec.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraAztec_h
#define Barcodes_MTTableViewControllerBarcodeExtraAztec_h

#import <UIKit/UITableViewController.h>

@protocol MTTableViewControllerBarcodeExtraAztecDelegate

	- (void)barcodeAztecDidEnableAutomaticResizing;
	- (void)barcodeAztecDidSetSize:(NSInteger)size;
	- (void)barcodeAztecDidSetErrorCorrection:(NSInteger)errorCorrection;

	- (BOOL)barcodeAztecAutomaticResizing;
	- (NSInteger)barcodeAztecInitalSize;
	- (NSInteger)barcodeAztecInitalErrorCorrection;

@end

@interface MTTableViewControllerBarcodeExtraAztec : UITableViewController

	@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraAztecDelegate> delegate;

@end

#endif
