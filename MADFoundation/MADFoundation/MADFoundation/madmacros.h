//
//  madmacros.h
//  MADFoundation
//
//  Created by Michael on 5/27/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFoundation_madmacros_h
#define MADFoundation_madmacros_h

#ifndef SUPPRESS_AVAILABILITY_BEGIN
#define SUPPRESS_AVAILABILITY_BEGIN \
	_Pragma("clang diagnostic push") \
	_Pragma("clang diagnostic ignored \"-Wunguarded-availability-new\"")
#endif

#ifndef SUPPRESS_AVAILABILITY_END
#define SUPPRESS_AVAILABILITY_END \
	_Pragma("clang diagnostic pop")
#endif

#ifndef AVAILABLE_IOS_GUARD
#define AVAILABLE_IOS_GUARD(version, condition, codeIfAvailable, codeIfUnavailable) \
	SUPPRESS_AVAILABILITY_BEGIN \
	if (@available(iOS version, *)) { \
		if (condition) { \
			codeIfAvailable \
		} else { \
			codeIfUnavailable \
		} \
	} else { \
		codeIfUnavailable \
	} \
	SUPPRESS_AVAILABILITY_END
#endif

#ifndef AVAILABLE_GUARD
#define AVAILABLE_GUARD(OS_VERSION, CONDITIONS, CODE_IF_AVAILABLE, CODE_IF_UNAVAILABLE) \
	SUPPRESS_AVAILABILITY_BEGIN \
	if (@available(OS_VERSION, *)) { \
		if (CONDITIONS) { \
			CODE_IF_AVAILABLE \
		} else { \
			CODE_IF_UNAVAILABLE \
		} \
	} else { \
		CODE_IF_UNAVAILABLE \
	} \
	SUPPRESS_AVAILABILITY_END
#endif


#endif

