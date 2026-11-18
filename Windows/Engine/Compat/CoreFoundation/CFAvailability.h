//
//  CFAvailability.h
//  Linux/Compat/CoreFoundation
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The availability-and-enum spellings Apple's CF headers carry.  GNUstep has
//  none of them, and the frameworks use CF_ENUM for a handful of typed enums
//  -- "typedef CF_ENUM(int64_t, Foo) { ... }" -- which without the macro is a
//  syntax error.  Apple's C spelling is the plain one below; the availability
//  annotations are no-ops where there is one platform to be available on.
//
//  Non-Apple only; nothing on Apple sees it.
//

#ifndef MADCompat_CoreFoundation_CFAvailability_h
#define MADCompat_CoreFoundation_CFAvailability_h

#if !__APPLE__

#define CF_ENUM(_type, _name) _type _name; enum
#define CF_OPTIONS(_type, _name) _type _name; enum
#define CF_CLOSED_ENUM(_type, _name) _type _name; enum

#define CF_AVAILABLE(_mac, _ios)
#define CF_AVAILABLE_IOS(_ios)
#define CF_AVAILABLE_MAC(_mac)
#define CF_DEPRECATED(_macIntro, _macDep, _iosIntro, _iosDep, ...)
#define CF_SWIFT_NAME(_name)

#endif /* !__APPLE__ */

#endif /* MADCompat_CoreFoundation_CFAvailability_h */
