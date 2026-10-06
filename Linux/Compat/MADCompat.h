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
//  It is now only the real platform gap: NSOperation's `name` property, which
//  GNUstep does not have.  The Foundation and dispatch imports it used to
//  carry are gone: MADFoundation's headers and sources import what they use
//  (see Linux/AGENTS.md for the check that keeps them that way).
//

#ifndef MADCompat_h
#define MADCompat_h

#import "NSOperation+Name.h"

#endif /* MADCompat_h */
