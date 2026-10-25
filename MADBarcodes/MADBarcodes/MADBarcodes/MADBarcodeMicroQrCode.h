//
//  MADBarcodeMicroQrCode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeMicroQrCode_h
#define Barcodes_MADBarcodeMicroQrCode_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeMicroQrCode : MADBarcode

- (MADBarcodeSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(NSInteger)size;
- (void)setMinmumErrorCorrection:(NSInteger)minmumErrorCorrection;

- (NSInteger)size;
- (NSInteger)errorCorrection;

@end

#endif
