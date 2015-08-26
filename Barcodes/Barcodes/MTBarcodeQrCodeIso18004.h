//
//  MTBarcodeQrCodeIso18004.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeQrCodeIso18004_h
#define Barcodes_MTBarcodeQrCodeIso18004_h

#import "MTBarcode.h"

@interface MTBarcodeQrCodeIso18004 : MTBarcode

- (MTBarcodeSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(NSInteger)size;
- (void)setErrorCorrection:(NSInteger)errorCorrection;

- (NSInteger)size;
- (NSInteger)errorCorrection;

@end

#endif
