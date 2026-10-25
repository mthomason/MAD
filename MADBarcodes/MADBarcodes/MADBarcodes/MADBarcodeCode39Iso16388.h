//
//  MADBarcodeCode39Iso16388.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeCode39Iso16388_h
#define Barcodes_MADBarcodeCode39Iso16388_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeCode39Iso16388 : MADBarcode

- (void)setMod43CheckDigitEnabled:(BOOL)enabled;
- (BOOL)mod43CheckDigitEnabled;

@end

@interface MADBarcodeCode39Hbic : MADBarcode

@end

#endif
