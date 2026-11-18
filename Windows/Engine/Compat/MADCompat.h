//
//  MADCompat.h
//  Windows/Engine/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The Windows build's prelude (see Windows/Engine/build.ps1, which
//  force-includes this one header -- a single -include, because the compiler
//  de-duplicates repeated ones).
//
//  It carries the real platform gaps, the same role as the Linux prelude in
//  Linux/Compat/MADCompat.h, with these Windows differences:
//
//    * the NSData+ReadingOptions shim is omitted: the pinned GNUstep master
//      already carries NSDataReadingOptions and -options:error: (Linux's
//      gnustep-base 1.31.1 release did not), so the shim's re-declaration
//      would be a duplicate interface on Windows.
//    * the 64-bit byte-order block (#include <endian.h> + htonll/ntohll) is
//      dropped: neither MADDataStructures nor MADFoundation uses it, and the
//      MAD layer defines its own htonll/ntohll statically where it needs them
//      (MADSectionRepresentation.m).  <endian.h> does not exist on Windows.
//    * strlcpy/strlcat are both provided (the UCRT has neither; MADQueryCacheAddRow
//      reaches for strlcat, and madtar.m reaches for strlcpy).
//    * the S_IS* / S_IR* POSIX mode macros are defined: the UCRT's <sys/stat.h>
//      carries S_IF* but not the S_IS* predicates or the S_IRWXU permission bits
//      the archive code uses.
//
//  The Objective-C shim imports are guarded with __OBJC__ so the one pure-C
//  translation unit in the build (MAD/Source/madmath.c) can share the prelude
//  without the ObjC categories.
//

#ifndef MADCompat_h
#define MADCompat_h

// M_PI and friends: the UCRT only defines them under _USE_MATH_DEFINES, and
// this prelude runs before every translation unit's own <math.h> include.
#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES
#endif

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/types.h>

// strlcat/strlcpy are BSD/Apple spellings.  Modern glibc (2.38+) declares
// them, which is why the Linux build needs no shim; the Windows UCRT does not.
//  A static inline here keeps the call sites working without a source edit or a
// link symbol.
static inline size_t strlcpy(char *dst, const char *src, size_t dstsize) {
	size_t slen = 0;
	while (src[slen] != '\0') slen++;
	if (dstsize > 0) {
		size_t n = (slen < dstsize - 1) ? slen : dstsize - 1;
		memcpy(dst, src, n);
		dst[n] = '\0';
	}
	return slen;
}

static inline size_t strlcat(char *dst, const char *src, size_t dstsize) {
	size_t dlen = 0;
	while (dlen < dstsize && dst[dlen] != '\0') dlen++;
	size_t slen = 0;
	while (src[slen] != '\0') slen++;
	if (dlen == dstsize) return dstsize + slen;
	size_t n = dstsize - dlen - 1;
	if (slen < n) n = slen;
	memcpy(dst + dlen, src, n);
	dst[dlen + n] = '\0';
	return dlen + slen;
}

// arc4random / arc4random_uniform are BSD/Apple (glibc 2.36+ has them, so the
// Linux build needs no shim; the UCRT does not).  They back random-geometry
// helpers (CGGeometry+Extras, MTMath), not security, so a rand()-backed
// fallback is enough.  Deterministic under a CLI run (no srand), which is fine:
// the .mad data path never reaches them.
static inline uint32_t arc4random(void) {
	return ((uint32_t)rand() << 15) ^ (uint32_t)rand();
}

static inline uint32_t arc4random_uniform(uint32_t upper_bound) {
	if (upper_bound < 2) return 0;
	return arc4random() % upper_bound;
}

// gmtime_r/localtime_r are POSIX (glibc has them, the UCRT has only the C11
// gmtime_s/localtime_s with the argument order reversed).  MADReportExportSource
// reaches gmtime_r to spell an export's date deterministically.  Function-like
// macros rather than functions: they expand only at the call site (where the
// source has already included <time.h>), and a static-inline gmtime_r here was
// observed to crash clang 20.1.8's dealloc codegen on an unrelated MAD file.
#ifndef gmtime_r
#define gmtime_r(timer, result) (gmtime_s((result), (timer)) == 0 ? (result) : NULL)
#endif
#ifndef localtime_r
#define localtime_r(timer, result) (localtime_s((result), (timer)) == 0 ? (result) : NULL)
#endif

// The UCRT's <sys/stat.h> defines S_IFMT/S_IFDIR/S_IFREG but not the S_IS*
// predicates (or S_IFCHR/S_IFLNK/S_IFBLK).  The archive code (madtar.m,
// MADCompatFileCopy.h) uses S_ISDIR/S_ISREG/S_ISCHR/S_ISLNK/S_ISBLK; a .mad
// archive only ever holds regular files and directories, so the missing kinds
// answer "no" (Windows has no such special files to represent here).
#ifndef S_ISDIR
#define S_ISDIR(m) (((m) & S_IFMT) == S_IFDIR)
#endif
#ifndef S_ISREG
#define S_ISREG(m) (((m) & S_IFMT) == S_IFREG)
#endif
#ifndef S_ISCHR
#define S_ISCHR(m) 0
#endif
#ifndef S_ISLNK
#define S_ISLNK(m) 0
#endif
#ifndef S_ISBLK
#define S_ISBLK(m) 0
#endif

// The POSIX permission bits madtar.m passes to mkdir(2).  The mode is advisory
// on Windows (mkdir is dropped to _mkdir), but the spellings must resolve.
#ifndef S_IRWXU
#define S_IRWXU 0700
#endif
#ifndef S_IRGRP
#define S_IRGRP 0040
#endif
#ifndef S_IXGRP
#define S_IXGRP 0010
#endif
#ifndef S_IROTH
#define S_IROTH 0004
#endif
#ifndef S_IXOTH
#define S_IXOTH 0001
#endif

// The UCRT has no ssize_t or mode_t; GNUstep's dispatch layer provides mode_t
// (as int, guarded by HAVE_MODE_T).  Define both here -- ahead of every
// translation unit -- so the archive code's read/write return type and the
// entry filetype both resolve.  HAVE_MODE_T tells GNUstep not to redefine it.
#ifdef _WIN32
#ifndef _SSIZE_T_DEFINED
#define _SSIZE_T_DEFINED
typedef __int64 ssize_t;
#endif
#ifndef HAVE_MODE_T
#define HAVE_MODE_T 1
typedef int mode_t;
#endif
#endif

#ifdef __OBJC__

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

#endif /* __OBJC__ */

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
