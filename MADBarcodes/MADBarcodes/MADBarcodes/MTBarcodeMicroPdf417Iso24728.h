//
//  MTBarcodeMicroPdf417Iso24728.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeMicroPdf417Iso24728_h
#define Barcodes_MTBarcodeMicroPdf417Iso24728_h

#import "MTBarcode.h"

@interface MTBarcodeMicroPdf417Iso24728 : MTBarcode

- (NSInteger)numberOfDataColumns;
- (void)setNumberOfDataColumns:(NSInteger)numberOfDataColumns;

@end

#endif
