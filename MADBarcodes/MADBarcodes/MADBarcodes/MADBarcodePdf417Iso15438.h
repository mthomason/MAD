//
//  MADBarcodePdf417Iso15438.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodePdf417Iso15438_h
#define Barcodes_MADBarcodePdf417Iso15438_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodePdf417Iso15438 : MADBarcode

- (void)setNumberOfColumns:(NSInteger)numberOfColumns;
- (void)setErrorCorrectionCapacity:(NSInteger)errorCorrectionCapacity;
- (void)setFormat:(NSInteger)format;
- (NSInteger)errorCorrectionCapacity;
- (NSInteger)format;
- (NSInteger)numberOfColumns;

@end

#endif
