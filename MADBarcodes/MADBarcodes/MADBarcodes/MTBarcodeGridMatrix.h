//
//  MTBarcodeGridMatrix.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeGridMatrix_h
#define Barcodes_MTBarcodeGridMatrix_h

#import "MTBarcode.h"

@interface MTBarcodeGridMatrix : MTBarcode

- (MTBarcodeSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(NSInteger)size;
- (void)setMinmumErrorCorrection:(NSInteger)minmumErrorCorrection;

- (NSInteger)size;
- (NSInteger)errorCorrection;

@end

#endif
