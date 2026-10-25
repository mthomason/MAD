//
//  objcmad.h
//  MAD
//
//  Created by Michael Thomason on 3/30/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_objcmad_h
#define MAD_objcmad_h

#import <objc/runtime.h>
#import <dispatch/dispatch.h>

void mad_swizzle_selectors(Class origionalClass, SEL originalSelector,
						   Class swizzledClass, SEL swizzledSelector,
						   dispatch_once_t *onceToken);

#endif
