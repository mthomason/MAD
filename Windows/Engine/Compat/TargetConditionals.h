//
//  TargetConditionals.h
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Off-Apple stub for <TargetConditionals.h> so headers and sources that
//  distinguish iOS (TARGET_OS_IPHONE) from macOS (TARGET_OS_OSX) compile
//  cleanly on Linux where every Apple target macro evaluates to 0.
//

#ifndef MADCompat_TargetConditionals_h
#define MADCompat_TargetConditionals_h

#ifndef TARGET_OS_MAC
#define TARGET_OS_MAC 0
#endif

#ifndef TARGET_OS_OSX
#define TARGET_OS_OSX 0
#endif

#ifndef TARGET_OS_IPHONE
#define TARGET_OS_IPHONE 0
#endif

#ifndef TARGET_OS_IOS
#define TARGET_OS_IOS 0
#endif

#ifndef TARGET_OS_SIMULATOR
#define TARGET_OS_SIMULATOR 0
#endif

#ifndef TARGET_OS_MACCATALYST
#define TARGET_OS_MACCATALYST 0
#endif

#endif /* MADCompat_TargetConditionals_h */
