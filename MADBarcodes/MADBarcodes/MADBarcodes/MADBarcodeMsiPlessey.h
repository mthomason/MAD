//
//  MADBarcodeMsiPlessey.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeMsiPlessey_h
#define Barcodes_MADBarcodeMsiPlessey_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeMsiPlessey : MADBarcode

- (NSInteger)checkpointDigit;
- (void)setCheckDigit:(NSInteger)checkDigit;

@end

#endif
