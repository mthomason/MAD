//
//  MADBarcodeQrCodeIso18004.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcodeQrCodeIso18004_h
#define Barcodes_MADBarcodeQrCodeIso18004_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeQrCodeIso18004 : MADBarcode

- (MADBarcodeSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(NSInteger)size;
- (void)setErrorCorrection:(NSInteger)errorCorrection;

- (NSInteger)size;
- (NSInteger)errorCorrection;

@end

#endif
