//
//  MADBarcodeMicroPdf417Iso24728.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeMicroPdf417Iso24728_h
#define Barcodes_MADBarcodeMicroPdf417Iso24728_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeMicroPdf417Iso24728 : MADBarcode

- (NSInteger)numberOfDataColumns;
- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns;

@end

#endif
