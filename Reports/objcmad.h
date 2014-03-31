//
//  objcmad.h
//  MAD
//
//  Created by Michael Thomason on 3/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_objcmad_h
#define MAD_objcmad_h

#import <objc/runtime.h>
#import <dispatch/dispatch.h>

void mad_swizzle_selectors(Class class, SEL originalSelector, SEL swizzledSelector, dispatch_once_t *onceToken);


#endif
