//
//  MTBarcodePdf417Iso15438.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodePdf417Iso15438_h
#define Barcodes_MTBarcodePdf417Iso15438_h

#import <MADBarcodes/MTBarcode.h>

@interface MTBarcodePdf417Iso15438 : MTBarcode

- (void)setNumberOfColumns:(NSInteger)numberOfColumns;
- (void)setErrorCorrectionCapacity:(NSInteger)errorCorrectionCapacity;
- (void)setFormat:(NSInteger)format;
- (NSInteger)errorCorrectionCapacity;
- (NSInteger)format;
- (NSInteger)numberOfColumns;

@end

#endif
