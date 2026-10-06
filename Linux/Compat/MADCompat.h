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
//  It carries the real platform gaps: NSOperation's `name` property and the
//  NSFileManager ubiquity methods, neither of which GNUstep has.  The
//  Foundation and dispatch imports it used to carry are gone: the frameworks'
//  headers and sources import what they use (see Linux/AGENTS.md for the
//  check that keeps them that way).
//

#ifndef MADCompat_h
#define MADCompat_h

#import "NSOperation+Name.h"
#import "NSFileManager+Ubiquity.h"
#import "NSFileCoordinator+Presenter.h"
#import "NSURL+SecurityScope.h"
#import "NSData+ReadingOptions.h"

#endif /* MADCompat_h */
