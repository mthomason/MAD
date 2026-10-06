//
//  NSKeyedUnarchiver+TopLevel.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's +unarchiveTopLevelObjectWithData:error: does not exist in GNUstep,
//  which carries +unarchiveObjectWithData: and +unarchivedObjectOfClass::
//  instead (the latter does work here -- measured, and the toolchain probe's
//  report that neither exists came from a branch it never reached).  The shim
//  answers through the classic call, the same permissive path MAD's own
//  archives round trip on.  Non-Apple only.
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
