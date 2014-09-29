//
//  MTBarcodeView.h
//  Barcodes
//
//  Created by Michael Thomason on 11/3/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeView_h
#define Barcodes_MTBarcodeView_h

#import <UIKit/UIKit.h>

@class MTBarcode;

@interface MTBarcodeView : UIView

@property (nonatomic, retain) MTBarcode *barcode;

@end

#endif
