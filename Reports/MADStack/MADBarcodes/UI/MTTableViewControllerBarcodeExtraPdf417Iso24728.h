//
//  MTTableViewControllerBarcodeExtraGridMatrix.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//


// FIXME: Not yet implemented.

#import <UIKit/UIKit.h>

#ifndef Barcodes_MTTableViewControllerBarcodeExtraPdf417Iso24728_h
#define Barcodes_MTTableViewControllerBarcodeExtraPdf417Iso24728_h

@protocol MTTableViewControllerBarcodeExtraPdf417Iso24728Delegate

- (void)barcodePDF417DidSetColumns:(NSInteger)columns;
- (void)barcodePDF417DidSetFormat:(NSInteger)format;
- (void)barcodePDF417DidSetErrorCorrection:(NSInteger)errorCorrection;

- (NSInteger)barcodePDF417Columns;
- (NSInteger)barcodePDF417Format;
- (NSInteger)barcodePDF417ErrorCorrection;

@end

@interface MTTableViewControllerBarcodeExtraPdf417Iso24728 : UITableViewController

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraPdf417Iso24728Delegate> delegate;

@end

#endif
