//
//  MTBarcodeMaxicodeIso16023.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcode.h"

@interface MTBarcodeMaxicodeIso16023 : MTBarcode

- (void)setPrimaryDataString:(NSString *)primaryData;
- (void)setEncodingMode:(NSInteger)encodingMode;
- (NSInteger)encodingMode;

@end
