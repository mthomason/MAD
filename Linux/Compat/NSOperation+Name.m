//
//  NSOperation+Name.m
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  See NSOperation+Name.h.  Built into the Linux madfoundation library only.
//

#if !__APPLE__
#import "NSOperation+Name.h"
#import <Foundation/NSString.h>
#import <objc/runtime.h>

@implementation NSOperation (MADCompatName)

- (NSString *)name {
	return objc_getAssociatedObject(self, @selector(name));
}

- (void)setName:(NSString *)name {
	objc_setAssociatedObject(self, @selector(name), [name copy], OBJC_ASSOCIATION_RETAIN);
}

@end

#endif /* !__APPLE__ */
