//
//  MADPrintPageElementBarcode.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MAD_MADDocumentObjectBarcode_h
#define Reports_MAD_MADDocumentObjectBarcode_h

#import "MADPrintPageElement.h"

@class MADDocumentObjectDataReference;

@interface MADPrintPageElementBarcode : MADPrintPageElementText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

@end

#endif
