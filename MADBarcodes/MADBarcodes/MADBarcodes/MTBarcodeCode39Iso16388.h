//
//  MTBarcodeCode39Iso16388.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeCode39Iso16388_h
#define Barcodes_MTBarcodeCode39Iso16388_h

#import "MTBarcode.h"

@interface MTBarcodeCode39Iso16388 : MTBarcode

- (void)setMod43CheckDigitEnabled:(BOOL)enabled;
- (BOOL)mod43CheckDigitEnabled;

@end

@interface MTBarcodeCode39Hbic : MTBarcode

@end

#endif
