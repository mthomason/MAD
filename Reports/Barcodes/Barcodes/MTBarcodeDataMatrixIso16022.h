//
//  MTBarcodeDataMatrixIso16022.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcode.h"

@interface MTBarcodeDataMatrixIso16022 : MTBarcode

- (void)setSymbolSize:(NSInteger)symbolSize;
- (NSInteger)symbolSize;
- (void)suppressRectangularSymbolsInAutomaticMode:(BOOL)suppress;
- (BOOL)suppressRectangularSymbols;

@end
