//
//  MADQueryFullTableEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryFullTableEnumerator_h
#define Reports_MADQueryFullTableEnumerator_h

#import <Foundation/NSEnumerator.h>

@class RptqDocument;

@interface MADQueryFullTableEnumerator : NSEnumerator

- (instancetype)initWithDocument:(RptqDocument *)document;

@end

#endif
