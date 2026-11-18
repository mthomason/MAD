//
//  NSURL+FileSystem.m
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSURL+FileSystem.h"

#if !__APPLE__

@implementation NSURL (MADCompatFileSystem)

- (const char *)fileSystemRepresentation {
	// GNUstep's NSString -fileSystemRepresentation returns a GSNativeChar*:
	// UTF-16 (unichar) on Windows, UTF-8 (char) elsewhere.  The URL contract
	// here is const char*, so answer UTF-8 explicitly rather than masquerading
	// a UTF-16 buffer as a C string (which broke sqlite3_open_v2's path).
	return self.path.UTF8String;
}

@end

#endif /* !__APPLE__ */
