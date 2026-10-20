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
#import <MADBarcodes/MADBarcodeProtocol.h>

@class MADBarcode;

@interface RptqDocumentElementBarcode (Extras) <MADBarcodeProtocol>

- (void)updateWithBarcode:(MADBarcode *)barcode
				 field1ID:(int64_t)field1ID
				 field2ID:(int64_t)field2ID;
+ (instancetype)barcodeWithMtBarcode:(MADBarcode *)barcode
					   queryFieldOne:(RptqQueryField *)queryFieldOne
					   queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED;

@end

#endif
