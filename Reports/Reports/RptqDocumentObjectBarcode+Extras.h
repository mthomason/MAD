//
//  RptqDocumentObjectBarcode+Extras.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectBarcode.h"
#import "MTBarcode.h"

@interface RptqDocumentObjectBarcode (Extras)

+ (RptqDocumentObjectBarcode *)barcodeWithMtBarcode:(MTBarcode *)barcode queryFieldOne:(RptqQueryField *)queryFieldOne queryFieldTwo:(RptqQueryField *)queryFieldTwo;

@end
