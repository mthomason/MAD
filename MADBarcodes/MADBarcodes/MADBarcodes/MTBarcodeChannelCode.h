//
//  MTBarcodeChannelCode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeChannelCode_h
#define Barcodes_MTBarcodeChannelCode_h

#import <MADBarcodes/MTBarcode.h>

@interface MTBarcodeChannelCode : MTBarcode

- (void)setNumberOfChannels:(NSInteger)numberOfChannels;
- (NSInteger)numberOfChannels;

@end

#endif
