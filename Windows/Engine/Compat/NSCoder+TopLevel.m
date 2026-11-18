//
//  NSCoder+TopLevel.m
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSCoder+TopLevel.h"

#if !__APPLE__
#import <Foundation/NSError.h>

@implementation NSCoder (MADCompatTopLevel)

- (id)decodeTopLevelObjectOfClasses:(NSSet *)classes forKey:(NSString *)key error:(NSError **)error {
	(void)classes;
	id object = [self decodeObjectForKey:key];
	if (error != NULL && object == nil) {
		// The classic call answers failure by returning nil; the error is the
		// shim's own, there being no Apple one to pass through.
		*error = [NSError errorWithDomain:@"MADCompatNSCoder" code:1 userInfo:nil];
	}
	return object;
}

@end

#endif /* !__APPLE__ */
