//
//  MADPrintPageElementBarcode.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectBarcode_h
#define Reports_MAD_MADDocumentObjectBarcode_h

#import "MADPrintPageElement.h"

@class MADDocumentObjectDataReference;

@interface MADPrintPageElementBarcode : MADPrintPageElementText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

@end

#endif
