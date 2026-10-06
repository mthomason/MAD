//
//  NSOperation+Name.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's NSOperation carries a `name` property (iOS 4+/macOS 10.6+);
//  GNUstep's does not, and the MAD operation classes set and log it
//  throughout.  This category supplies it on non-Apple platforms only --
//  associated-object storage, no queue integration (GNUstep has none to
//  integrate with).  It reaches the Linux build's Objective-C translation
//  units through MADCompat.h; nothing on Apple sees it.
//

#ifndef MADCompat_NSOperation_Name_h
#define MADCompat_NSOperation_Name_h

#if !__APPLE__
#import <Foundation/NSOperation.h>

@interface NSOperation (MADCompatName)
@property (nullable, copy) NSString *name;
@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSOperation_Name_h */
