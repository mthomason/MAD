//
//  MADDocumentObjectBarcode.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectBarcode_h
#define Reports_MAD_MADDocumentObjectBarcode_h

#import "MADDocumentObject.h"

@class MADDocumentObjectDataReference;

@interface MADDocumentObjectBarcode : MADDocumentObject

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

@end

#endif
