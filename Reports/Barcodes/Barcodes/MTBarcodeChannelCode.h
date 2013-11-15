//
//  MTBarcodeChannelCode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBarcode.h"

@interface MTBarcodeChannelCode : MTBarcode

- (void)setNumberOfChannels:(NSInteger)numberOfChannels;
- (NSInteger)numberOfChannels;

@end
