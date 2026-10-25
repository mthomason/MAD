//
//  MADPrintPageElement+Constructor.h
//  MAD
//
//  Created by Michael on 9/2/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDocumentObject_Constructor_h
#define MAD_MADDocumentObject_Constructor_h

#import "MADPrintPageElement.h"

@interface MADPrintPageElement (Constructor)

+ (instancetype)newDocumentObject:(__kindof MADDocumentObjectDataReference *)definition;

@end

#endif
