//
//  MADDocumentObjectDataReferenceBarcode.h
//  MAD
//
//  Created by Michael on 5/18/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDocumentObjectDataReferenceBarcode_h
#define MAD_MADDocumentObjectDataReferenceBarcode_h

#import "MADDocumentObjectDataReference.h"

NS_ASSUME_NONNULL_BEGIN

@interface MADDocumentObjectDataReferenceBarcode : MADDocumentObjectDataReference

@property (nonatomic, copy, readonly) NSString *fieldKey1;
@property (nonatomic, copy, readonly) NSString *fieldKey2;
@property (nonatomic, strong, readonly) id <MADBarcodeProtocol> barcode;
- (NSString *)formattedStringForValue1:(id)value;
- (NSString *)formattedStringForValue2:(id)value;

@end

NS_ASSUME_NONNULL_END

#endif
