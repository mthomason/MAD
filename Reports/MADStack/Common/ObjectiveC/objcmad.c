//
//  objcmad.c
//  MAD
//
//  Created by Michael Thomason on 3/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "objcmad.h"

void mad_swizzle_selectors(Class origionalClass, SEL originalSelector,
                           Class swizzledClass, SEL swizzledSelector, dispatch_once_t *onceToken) {
    
    dispatch_once(onceToken, ^{
        
        Method originalMethod = class_getInstanceMethod(origionalClass, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
        
        IMP swizzledMethodImplementation            = method_getImplementation(swizzledMethod);
        const char *swizzledMethodTypeEncoding      = method_getTypeEncoding(swizzledMethod);
        BOOL didAddMethod = class_addMethod(origionalClass, originalSelector,
                                            swizzledMethodImplementation,
                                            swizzledMethodTypeEncoding);
        
        if (didAddMethod) {
        
            IMP origionalMethodImplementation            = method_getImplementation(originalMethod);
            const char *origionalMethodTypeEncoding      = method_getTypeEncoding(originalMethod);
            class_replaceMethod(swizzledClass, swizzledSelector, origionalMethodImplementation,
                                origionalMethodTypeEncoding);
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
    });
    
}
