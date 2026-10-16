//
//  NSURL+FileSystem.m
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//

#import "NSURL+FileSystem.h"

#if !__APPLE__

@implementation NSURL (MADCompatFileSystem)

- (const char *)fileSystemRepresentation {
	return self.path.fileSystemRepresentation;
}

@end

#endif /* !__APPLE__ */
