//
//  MTBarcodeMaxicodeIso16023.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeMaxicodeIso16023_h
#define Barcodes_MTBarcodeMaxicodeIso16023_h

#import "MTBarcode.h"

@interface MTBarcodeMaxicodeIso16023 : MTBarcode

- (void)setPrimaryDataString:(NSString *)primaryData;
- (void)setEncodingMode:(NSInteger)encodingMode;
- (NSInteger)encodingMode;

@end

#endif
