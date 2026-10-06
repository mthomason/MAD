//
//  NSKeyedUnarchiver+TopLevel.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's +unarchiveTopLevelObjectWithData:error: (and
//  +unarchivedObjectOfClass:fromData:error:) do not exist in GNUstep, which
//  stops at the classic +unarchiveObjectWithData:.  The shim answers through
//  that classic call, which is the same permissive path MAD's own archives
//  round trip on (GNUstep has no secure coding to enforce).  Non-Apple only.
//

#ifndef MADCompat_NSKeyedUnarchiver_TopLevel_h
#define MADCompat_NSKeyedUnarchiver_TopLevel_h

#if !__APPLE__
#import <Foundation/NSKeyedArchiver.h>

@interface NSKeyedUnarchiver (MADCompatTopLevel)

+ (id)unarchiveTopLevelObjectWithData:(NSData *)data error:(NSError **)error;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSKeyedUnarchiver_TopLevel_h */
