//
//  NSData+ReadingOptions.m
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//

#import "NSData+ReadingOptions.h"

#if !__APPLE__

@implementation NSData (MADCompatReadingOptions)

+ (instancetype)dataWithContentsOfURL:(NSURL *)url
							  options:(NSUInteger)readOptionsMask
								error:(NSError **)errorPtr {
	(void)readOptionsMask;
	if (errorPtr != NULL) *errorPtr = nil;
	return [self dataWithContentsOfURL:url];
}

@end

#endif /* !__APPLE__ */
