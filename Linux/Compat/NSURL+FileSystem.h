//
//  NSURL+FileSystem.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's NSURL converts itself to the file system's byte representation;
//  GNUstep's stops at NSString's version of the same call.  The shim answers
//  through the path, which is where GNUstep keeps it.  Non-Apple only.
//

#ifndef MADCompat_NSURL_FileSystem_h
#define MADCompat_NSURL_FileSystem_h

#if !__APPLE__
#import <Foundation/NSURL.h>
#import <Foundation/NSString.h>

@interface NSURL (MADCompatFileSystem)

- (const char *)fileSystemRepresentation;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSURL_FileSystem_h */
