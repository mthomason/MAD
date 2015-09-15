//
//  BarcodeInterface.h
//  Barcodes
//
//  Created by Michael Thomason on 2/15/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTBarcodeProtocol_h
#define Barcodes_MTBarcodeProtocol_h

#import <Foundation/Foundation.h>

@protocol MTBarcodeProtocol <NSObject>

@required

- (void)initSampleData;

@optional

@end

#endif
