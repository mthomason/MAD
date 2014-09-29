//
//  MTBarcodeChannelCode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeChannelCode_h
#define Barcodes_MTBarcodeChannelCode_h

#import "MTBarcode.h"

@interface MTBarcodeChannelCode : MTBarcode

- (void)setNumberOfChannels:(NSInteger)numberOfChannels;
- (NSInteger)numberOfChannels;

@end

#endif
