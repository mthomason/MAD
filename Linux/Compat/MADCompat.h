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
#import "NSURL+FileSystem.h"
#import "NSData+ReadingOptions.h"
#import "NSKeyedUnarchiver+TopLevel.h"
#import "NSCoder+TopLevel.h"
#import "NSUndoManager+Handler.h"
#import "NSValue+Geometry.h"

// Apple's MacTypes.h carries the legacy scalar names the layout and driver
// classes use; GNUstep has no MacTypes.h.  The ones the frameworks reach for,
// and only off Apple, so Apple's own definitions are never shadowed.
typedef double Float64;
typedef signed char SInt8;
typedef short SInt16;
typedef int SInt32;
typedef long long SInt64;
typedef unsigned char UInt8;
typedef unsigned short UInt16;
typedef unsigned int UInt32;
typedef unsigned long long UInt64;
typedef unsigned char Boolean;

// Apple's Foundation defines this ARC attribute for methods returning a
// pointer into an object's insides; GNUstep's does not.  The declaration it
// marks here returns a void *, so the attribute's autorelease elision does
// not apply either way.
#ifndef NS_RETURNS_INNER_POINTER
#define NS_RETURNS_INNER_POINTER
#endif

// The double-underscore nullability spellings come from Apple's headers;
// GNUstep's do not carry them.  clang understands the single-underscore forms.
#ifndef __nullable
#define __nullable _Nullable
#endif
#ifndef __nonnull
#define __nonnull _Nonnull
#endif

// 64-bit byte-order conversion is a BSD extension Apple's headers carry and
// glibc spells differently.  Only the two the frameworks call.
#if !__APPLE__
#include <endian.h>
#ifndef htonll
#define htonll(x) htobe64(x)
#endif
#ifndef ntohll
#define ntohll(x) be64toh(x)
#endif
#endif

#endif /* MADCompat_h */
