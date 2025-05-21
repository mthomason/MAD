//
//  MADDocumentObjectDataReferenceBarcode.h
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectDataReferenceBarcode_h
#define MAD_MADDocumentObjectDataReferenceBarcode_h

#import "MADDocumentObjectDataReference.h"

NS_ASSUME_NONNULL_BEGIN

@interface MADDocumentObjectDataReferenceBarcode : MADDocumentObjectDataReference

@property (nonatomic, copy, readonly) NSString *fieldKey1;
@property (nonatomic, copy, readonly) NSString *fieldKey2;
@property (nonatomic, strong, readonly) id <MTBarcodeProtocol> barcode;
- (NSString *)formattedStringForValue1:(id)value;
- (NSString *)formattedStringForValue2:(id)value;

@end

NS_ASSUME_NONNULL_END

#endif
