//
//  MADCompat.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The Windows build's Objective-C prelude (see Windows/Engine/CMakeLists.txt,
//  which force-includes this one header -- a single -include, because CMake
//  de-duplicates repeated ones).
//
//  It carries the real platform gaps, the same role as the Linux prelude in
//  Linux/Compat/MADCompat.h, with two Windows differences:
//
//    * the NSData+ReadingOptions shim is omitted: the pinned GNUstep master
//      already carries NSDataReadingOptions and -options:error: (Linux's
//      gnustep-base 1.31.1 release did not), so the shim's re-declaration
//      would be a duplicate interface on Windows.
//    * the 64-bit byte-order block (#include <endian.h> + htonll/ntohll) is
//      dropped: neither MADDataStructures nor MADFoundation uses it
//      (grep-verified), and <endian.h> does not exist on Windows.  The driver
//      layer (MAD) will need a Windows byte-order shim when it is ported.
//

#ifndef MADCompat_h
#define MADCompat_h

#import "NSOperation+Name.h"
#import "NSFileManager+Ubiquity.h"
#import "NSFileCoordinator+Presenter.h"
#import "NSURL+SecurityScope.h"
#import "NSURL+FileSystem.h"
#import "NSKeyedUnarchiver+TopLevel.h"
#import "NSCoder+TopLevel.h"
#import "NSUndoManager+Handler.h"
#import "NSValue+Geometry.h"
#import "NSPropertyListSerialization+Stream.h"

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

#endif /* MADCompat_h */
