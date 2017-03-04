//
//  MTBarcodeMicroQrCode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeMicroQrCode_h
#define Barcodes_MTBarcodeMicroQrCode_h

#import "MTBarcode.h"

@interface MTBarcodeMicroQrCode : MTBarcode

- (MTBarcodeSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(NSInteger)size;
- (void)setMinmumErrorCorrection:(NSInteger)minmumErrorCorrection;

- (NSInteger)size;
- (NSInteger)errorCorrection;

@end

#endif
