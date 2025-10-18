//
//  RptqDocumentElementBarcode+Extras.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqDocumentElementBarcode_Extras_h
#define Reports_RptqDocumentElementBarcode_Extras_h

#import <MAD/RptqDocumentElementBarcode.h>
#import <MADBarcodes/MTBarcodeProtocol.h>

@class MTBarcode;

@interface RptqDocumentElementBarcode (Extras) <MTBarcodeProtocol>

- (void)updateWithBarcode:(MTBarcode *)barcode
				 field1ID:(NSManagedObjectID *)field1ID
				 field2ID:(NSManagedObjectID *)field2ID;
+ (instancetype)barcodeWithMtBarcode:(MTBarcode *)barcode
					   queryFieldOne:(RptqQueryField *)queryFieldOne
					   queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED;

@end

#endif
