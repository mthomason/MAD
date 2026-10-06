//
//  NSKeyedUnarchiver+TopLevel.m
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//

#import "NSKeyedUnarchiver+TopLevel.h"

#if !__APPLE__
#import <Foundation/NSError.h>

@implementation NSKeyedUnarchiver (MADCompatTopLevel)

+ (id)unarchiveTopLevelObjectWithData:(NSData *)data error:(NSError **)error {
	id object = [self unarchiveObjectWithData:data];
	if (error != NULL && object == nil) {
		// The classic call answers failure by returning nil; the error is the
		// shim's own, there being no Apple one to pass through.
		*error = [NSError errorWithDomain:@"MADCompatKeyedUnarchiver" code:1 userInfo:nil];
	}
	return object;
}

@end

#endif /* !__APPLE__ */
