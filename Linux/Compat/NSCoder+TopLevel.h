//
//  NSCoder+TopLevel.h
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Apple's NSCoder gained the secure-coding decoders
//  (-decodeTopLevelObjectOfClasses:forKey:error: and its sibling) with
//  NSSecureCoding; GNUstep's stops at the classic -decodeObjectForKey:.  The
//  shim answers through that classic call, which is the path GNUstep's
//  archives are written on -- it has no secure coding to enforce.  Non-Apple
//  only; nothing on Apple sees it.
//

#ifndef MADCompat_NSCoder_TopLevel_h
#define MADCompat_NSCoder_TopLevel_h

#if !__APPLE__
#import <Foundation/NSCoder.h>

@interface NSCoder (MADCompatTopLevel)

- (id)decodeTopLevelObjectOfClasses:(NSSet *)classes forKey:(NSString *)key error:(NSError **)error;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSCoder_TopLevel_h */
