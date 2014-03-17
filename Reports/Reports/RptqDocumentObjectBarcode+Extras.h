//
//  RptqDocumentObjectBarcode+Extras.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectBarcode.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import "MTBarcode.h"

@interface RptqDocumentObjectBarcode (Extras)

- (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne fieldTwo:(RptqQueryField *)fieldTwo;

+ (RptqDocumentObjectBarcode *)barcodeWithMtBarcode:(MTBarcode *)barcode queryFieldOne:(RptqQueryField *)queryFieldOne queryFieldTwo:(RptqQueryField *)queryFieldTwo;
+ (MTBarcode *)barcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject;

@end
