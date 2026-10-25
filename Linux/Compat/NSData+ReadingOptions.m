//
//  NSData+ReadingOptions.m
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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

- (instancetype)initWithContentsOfURL:(NSURL *)url
							  options:(NSUInteger)readOptionsMask
								error:(NSError **)errorPtr {
	(void)readOptionsMask;
	if (errorPtr != NULL) *errorPtr = nil;
	return [self initWithContentsOfURL:url];
}

@end

#endif /* !__APPLE__ */
