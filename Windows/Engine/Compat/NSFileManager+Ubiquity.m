//
//  NSFileManager+Ubiquity.m
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSFileManager+Ubiquity.h"

#if !__APPLE__

@implementation NSFileManager (MADCompatUbiquity)

- (NSURL *)URLForUbiquityContainerIdentifier:(NSString *)containerIdentifier {
	(void)containerIdentifier;
	return nil;
}

- (id)ubiquityIdentityToken {
	return nil;
}

- (BOOL)isUbiquitousItemAtURL:(NSURL *)url {
	(void)url;
	return NO;
}

- (BOOL)setUbiquitous:(BOOL)flag itemAtURL:(NSURL *)sourceURL
	  destinationURL:(NSURL *)destinationURL error:(NSError **)error {
	(void)flag;
	(void)sourceURL;
	(void)destinationURL;
	if (error != NULL) *error = nil;
	return NO;
}

@end

#endif /* !__APPLE__ */
