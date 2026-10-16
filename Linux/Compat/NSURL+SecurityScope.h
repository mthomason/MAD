//
//  NSURL+SecurityScope.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's sandbox grants a document URL through security-scoped bookmarks;
//  GNUstep's NSURL has no such calls.  Off Apple a plain filesystem path needs
//  no access grant, so starting one answers NO (Apple's answer for a URL that
//  is not security-scoped) and stopping is a no-op.  Non-Apple only.
//

#ifndef MADCompat_NSURL_SecurityScope_h
#define MADCompat_NSURL_SecurityScope_h

#if !__APPLE__
#import <Foundation/NSURL.h>

@interface NSURL (MADCompatSecurityScope)

- (BOOL)startAccessingSecurityScopedResource;
- (void)stopAccessingSecurityScopedResource;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSURL_SecurityScope_h */
