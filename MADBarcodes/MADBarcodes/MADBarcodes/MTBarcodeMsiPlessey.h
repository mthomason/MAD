//
//  MTBarcodeMsiPlessey.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeMsiPlessey_h
#define Barcodes_MTBarcodeMsiPlessey_h

#import "MTBarcode.h"

@interface MTBarcodeMsiPlessey : MTBarcode

- (NSInteger)checkpointDigit;
- (void)setCheckDigit:(NSInteger)checkDigit;

@end

#endif
