//
//  MADBarcodeChannelCode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MADBarcodeChannelCode_h
#define Barcodes_MADBarcodeChannelCode_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeChannelCode : MADBarcode

- (void)setNumberOfChannels:(NSInteger)numberOfChannels;
- (NSInteger)numberOfChannels;

@end

#endif
