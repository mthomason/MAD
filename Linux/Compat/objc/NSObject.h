//
//  NSObject.h
//  Linux/Compat/objc
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's runtime headers declare NSObject; GNUstep's Foundation does, and
//  its objc/ directory does not.  The frameworks import <objc/NSObject.h>
//  for the class alone, so off Apple the name resolves to Foundation's.
//

#ifndef MADCompat_objc_NSObject_h
#define MADCompat_objc_NSObject_h

#if !__APPLE__
#import <Foundation/NSObject.h>
#endif

#endif /* MADCompat_objc_NSObject_h */
