//
//  MADCompat.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  The Linux build's Objective-C prelude (see Linux/CMakeLists.txt, which
//  force-includes this one header -- a single -include, because CMake
//  de-duplicates repeated ones).
//
//  It supplies what Apple's toolchain gave the sources implicitly:
//    * Foundation and dispatch, which the framework's headers only import
//      piecemeal (Apple's Foundation re-exported the rest);
//    * NSOperation's `name` property, which GNUstep does not have.
//
//  Making the framework's headers self-contained is Phase C cleanup; until
//  then, this is what the Linux translation units see first.
//

#ifndef MADCompat_h
#define MADCompat_h

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "NSOperation+Name.h"

#endif /* MADCompat_h */
