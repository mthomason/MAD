//
//  MADBarcodeDataMatrixIso16022.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeDataMatrixIso16022_h
#define Barcodes_MADBarcodeDataMatrixIso16022_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeDataMatrixIso16022 : MADBarcode

- (void)setSymbolSize:(NSInteger)symbolSize;
- (NSInteger)symbolSize;
- (void)suppressRectangularSymbolsInAutomaticMode:(BOOL)suppress;
- (BOOL)suppressRectangularSymbols;

@end

#endif
