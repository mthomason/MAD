//
//  MADBarcodeCode39Extended.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcodeCode39Extended_h
#define Barcodes_MADBarcodeCode39Extended_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeCode39Extended : MADBarcode

- (void)setMod43CheckDigitEnabled:(BOOL)enabled;
- (BOOL)mod43CheckDigitEnabled;

@end

#endif
