//
//  NSURL+SecurityScope.m
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSURL+SecurityScope.h"

#if !__APPLE__

@implementation NSURL (MADCompatSecurityScope)

- (BOOL)startAccessingSecurityScopedResource {
	return NO;
}

- (void)stopAccessingSecurityScopedResource {
}

@end

#endif /* !__APPLE__ */
