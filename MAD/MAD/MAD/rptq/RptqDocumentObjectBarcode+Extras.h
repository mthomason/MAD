//
//  RptqDocumentObjectBarcode+Extras.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectBarcode_Extras_h
#define Reports_RptqDocumentObjectBarcode_Extras_h

#import "RptqDocumentObjectBarcode.h"

@class RptqQueryField;
@class MTBarcode;

@interface RptqDocumentObjectBarcode (Extras)

    - (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne fieldTwo:(RptqQueryField *)fieldTwo;

    + (instancetype)barcodeWithMtBarcode:(MTBarcode *)barcode queryFieldOne:(RptqQueryField *)queryFieldOne queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED;
    + (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject;

@end

#endif
