//
//  MADBarcodeMsiPlessey.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcodeMsiPlessey_h
#define Barcodes_MADBarcodeMsiPlessey_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeMsiPlessey : MADBarcode

- (NSInteger)checkpointDigit;
- (void)setCheckDigit:(NSInteger)checkDigit;

@end

#endif
