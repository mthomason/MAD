//
//  NSOperation+Name.h
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Apple's NSOperation carries a `name` property (iOS 4+/macOS 10.6+), a
//  `cancelled` one spelling the same thing as -isCancelled, and an
//  `asynchronous` one spelling the same thing as -isConcurrent (Apple renamed
//  it in macOS 10.6/iOS 4); GNUstep's has none of them, and the MAD operation
//  classes set and read the first two and override the third throughout.  This
//  category supplies them on non-Apple platforms only -- associated-object
//  storage for the name, and the old -isConcurrent name answering what the
//  class says about -isAsynchronous (GNUstep's own always answers NO).  It
//  reaches the Linux build's Objective-C translation units through
//  MADCompat.h; nothing on Apple sees it.
//

#ifndef MADCompat_NSOperation_Name_h
#define MADCompat_NSOperation_Name_h

#if !__APPLE__
#import <Foundation/NSOperation.h>

@interface NSOperation (MADCompatName)
@property (nullable, copy) NSString *name;
@property (readonly, getter=isCancelled) BOOL cancelled;
@property (readonly, getter=isAsynchronous) BOOL asynchronous;
@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSOperation_Name_h */
