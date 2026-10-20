//
//  MTBarcodeView.h
//  Barcodes
//
//  Created by Michael Thomason on 11/3/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeView_h
#define Barcodes_MTBarcodeView_h

#import <UIKit/UIView.h>

@class MTBarcode;

@interface MTBarcodeView : UIView

	@property (nonatomic, retain) MTBarcode *barcode;

@end

#endif
