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

// Apple renamed -isConcurrent to -isAsynchronous; GNUstep kept only the old
// spelling as a stub that always answers NO (nothing ever sets the flag behind
// it), and its own bookkeeping -- queue scheduling and the -dealloc check that
// keeps it from re-removing the isFinished KVO observer it deregistered when
// the operation finished -- consults -isConcurrent.  So the old name must
// answer what a class says about the new one: the MAD operation classes
// override -isAsynchronous to manage their own state, and without this GNUstep
// raises NSInvalidArgumentException out of -dealloc.  A subclass that
// overrides -isConcurrent itself still wins over this category method.
- (BOOL)isConcurrent {
	return [self isAsynchronous];
}

// The default Apple gives: a plain operation is neither asynchronous nor
// concurrent; a subclass that overrides -isAsynchronous wins over this.
- (BOOL)isAsynchronous {
	return NO;
}

@end

#endif /* !__APPLE__ */
