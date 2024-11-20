//
//  MTBarcodeDatabarExpandedStacked.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeDatabarExpandedStacked_h
#define Barcodes_MTBarcodeDatabarExpandedStacked_h

#import "MTBarcode.h"

@interface MTBarcodeDatabarExpandedStacked : MTBarcode

- (NSInteger)numberOfDataColumns;
- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns;

@end

#endif
