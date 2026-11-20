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
#import <Foundation/NSData.h>

@class MADDocumentObjectDataReference;

@interface MADPrintPageElementBarcode : MADPrintPageElementText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

/// The encoded symbol as PNG bytes, or nil when zint refuses the inputs.  The
/// page walk hands this to the line representation, which the formats embed;
/// MADBarcodes' render core produces it without Core Graphics.
- (NSData *)renderedImageData;

@end

#endif
