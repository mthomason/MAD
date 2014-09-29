//
//  MTBarcodeDataMatrixIso16022.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeDataMatrixIso16022_h
#define Barcodes_MTBarcodeDataMatrixIso16022_h

#import "MTBarcode.h"

@interface MTBarcodeDataMatrixIso16022 : MTBarcode

- (void)setSymbolSize:(NSInteger)symbolSize;
- (NSInteger)symbolSize;
- (void)suppressRectangularSymbolsInAutomaticMode:(BOOL)suppress;
- (BOOL)suppressRectangularSymbols;

@end

#endif
