//
//  NSOperation+Name.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's NSOperation carries a `name` property (iOS 4+/macOS 10.6+) and a
//  `cancelled` one spelling the same thing as -isCancelled; GNUstep's has
//  neither, and the MAD operation classes set and read both throughout.  This
//  category supplies them on non-Apple platforms only -- associated-object
//  storage for the name, no queue integration (GNUstep has none to integrate
//  with).  It reaches the Linux build's Objective-C translation units through
//  MADCompat.h; nothing on Apple sees it.
//

#ifndef MADCompat_NSOperation_Name_h
#define MADCompat_NSOperation_Name_h

#if !__APPLE__
#import <Foundation/NSOperation.h>

@interface NSOperation (MADCompatName)
@property (nullable, copy) NSString *name;
@property (readonly, getter=isCancelled) BOOL cancelled;
@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSOperation_Name_h */
