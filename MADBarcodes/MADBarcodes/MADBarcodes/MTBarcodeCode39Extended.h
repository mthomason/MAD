//
//  MTBarcodeCode39Extended.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeCode39Extended_h
#define Barcodes_MTBarcodeCode39Extended_h

#import <MADBarcodes/MTBarcode.h>

@interface MTBarcodeCode39Extended : MTBarcode

- (void)setMod43CheckDigitEnabled:(BOOL)enabled;
- (BOOL)mod43CheckDigitEnabled;

@end

#endif
