//
//  MADStandard.h
//  MADExplorer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDocumentObjectTypeDescriptor_h
#define MAD_MADDocumentObjectTypeDescriptor_h

#import <Foundation/NSObject.h>

@interface MADStandard : NSObject

+ (NSString *)standardStringForDouble:(double)d;
+ (NSString *)standardStringForUnsignedLong:(unsigned long)ul;
+ (NSString *)standardStringForFileSize:(unsigned long long)filesize;

@end

#endif
