//
//  MADBarcodeMaxicodeIso16023.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcodeMaxicodeIso16023_h
#define Barcodes_MADBarcodeMaxicodeIso16023_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeMaxicodeIso16023 : MADBarcode

- (void)setPrimaryDataString:(NSString *)primaryData;
- (void)setEncodingMode:(NSInteger)encodingMode;
- (NSInteger)encodingMode;

@end

#endif
