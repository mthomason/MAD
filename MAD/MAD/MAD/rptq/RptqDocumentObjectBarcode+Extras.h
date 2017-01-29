//
//  RptqDocumentObjectBarcode+Extras.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectBarcode_Extras_h
#define Reports_RptqDocumentObjectBarcode_Extras_h

#import "RptqDocumentObjectBarcode+CoreDataClass.h"

@class RptqQueryField;
@class MTBarcode;

@interface RptqDocumentObjectBarcode (Extras)

    - (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne
                     fieldTwo:(RptqQueryField *)fieldTwo;
    - (NSString *)copyBarcodeTypeName;
    + (instancetype)barcodeWithMtBarcode:(MTBarcode *)barcode
                           queryFieldOne:(RptqQueryField *)queryFieldOne
                           queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED;
    + (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject;
    + (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject
                                         input1:(NSString *)input1
                                         input2:(NSString *)input2;

@end

#endif
