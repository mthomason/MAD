//
//  MADBarcodeView.h
//  Barcodes
//
//  Created by Michael Thomason on 11/3/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcodeView_h
#define Barcodes_MADBarcodeView_h

#import <UIKit/UIView.h>

@class MADBarcode;

@interface MADBarcodeView : UIView

	@property (nonatomic, retain) MADBarcode *barcode;

@end

#endif
