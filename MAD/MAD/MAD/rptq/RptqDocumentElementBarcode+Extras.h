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

@class RptqQueryField;
@class MTBarcode;

@interface RptqDocumentElementBarcode (Extras)

    - (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne
                     fieldTwo:(RptqQueryField *)fieldTwo;
    + (instancetype)barcodeWithMtBarcode:(MTBarcode *)barcode
                           queryFieldOne:(RptqQueryField *)queryFieldOne
                           queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED;
    + (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentElementBarcode *)documentObject;
    + (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentElementBarcode *)documentObject
                                         input1:(NSString *)input1
                                         input2:(NSString *)input2;

@end

#endif
