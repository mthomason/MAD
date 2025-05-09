//
//  MTBarcodeDataMatrixIso16022.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeDataMatrixIso16022_h
#define Barcodes_MTBarcodeDataMatrixIso16022_h

#import <MADBarcodes/MTBarcode.h>

@interface MTBarcodeDataMatrixIso16022 : MTBarcode

- (void)setSymbolSize:(NSInteger)symbolSize;
- (NSInteger)symbolSize;
- (void)suppressRectangularSymbolsInAutomaticMode:(BOOL)suppress;
- (BOOL)suppressRectangularSymbols;

@end

#endif
