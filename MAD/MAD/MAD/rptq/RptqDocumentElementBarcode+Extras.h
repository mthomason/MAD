//
//  RptqDocumentElementBarcode+Extras.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElementBarcode_Extras_h
#define Reports_RptqDocumentElementBarcode_Extras_h

#import "RptqDocumentElementBarcode.h"
#import <MADBarcodes/MTBarcodeProtocol.h>

@class MTBarcode;

@interface RptqDocumentElementBarcode (Extras)
    <MTBarcodeProtocol>

    - (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne
                     fieldTwo:(RptqQueryField *)fieldTwo;
    + (instancetype)barcodeWithMtBarcode:(MTBarcode *)barcode
                           queryFieldOne:(RptqQueryField *)queryFieldOne
                           queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED;

@end

#endif
