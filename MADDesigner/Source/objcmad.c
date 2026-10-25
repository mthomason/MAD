//
//  objcmad.c
//  MAD
//
//  Created by Michael Thomason on 3/30/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "objcmad.h"

void mad_swizzle_selectors(Class origionalClass, SEL originalSelector,
						   Class swizzledClass, SEL swizzledSelector,
						   dispatch_once_t *onceToken) {
	
	dispatch_once(onceToken, ^{
		
		Method originalMethod = class_getInstanceMethod(origionalClass, originalSelector);
		Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
		
		if (!originalMethod || !swizzledMethod) return;
		
		BOOL didAddMethod = class_addMethod(origionalClass,
											originalSelector,
											method_getImplementation(swizzledMethod),
											method_getTypeEncoding(swizzledMethod));
		
		if (didAddMethod) {
			class_replaceMethod(swizzledClass,
								swizzledSelector,
								method_getImplementation(originalMethod),
								method_getTypeEncoding(originalMethod));
		} else {
			method_exchangeImplementations(originalMethod, swizzledMethod);
		}
	});
	
}
