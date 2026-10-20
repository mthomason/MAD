//
//  MADBarcodeChannelCode.h
//  Barcodes
//
//  Created by Michael Thomason on 11/10/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MADBarcodeChannelCode_h
#define Barcodes_MADBarcodeChannelCode_h

#import <MADBarcodes/MADBarcode.h>

@interface MADBarcodeChannelCode : MADBarcode

- (void)setNumberOfChannels:(NSInteger)numberOfChannels;
- (NSInteger)numberOfChannels;

@end

#endif
