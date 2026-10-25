//
//  MADBarcodeDatabarExpandedStacked.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeDatabarExpandedStacked_h
#define Barcodes_MADBarcodeDatabarExpandedStacked_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeDatabarExpandedStacked : MADBarcode

- (NSInteger)numberOfDataColumns;
- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns;

@end

#endif
