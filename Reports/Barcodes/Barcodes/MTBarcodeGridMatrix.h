//
//  MTBarcodeGridMatrix.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcode.h"

@interface MTBarcodeGridMatrix : MTBarcode

- (MTBarcodeSizingMode)sizingMode;
- (void)enableAutomaticResizing;
- (void)setSize:(NSInteger)size;
- (void)setMinmumErrorCorrection:(NSInteger)minmumErrorCorrection;

- (NSInteger)size;
- (NSInteger)errorCorrection;

@end
