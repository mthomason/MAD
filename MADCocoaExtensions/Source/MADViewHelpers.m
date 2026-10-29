//
//  MADViewHelpers.c
//  MADCocoaExtensions
//
//  Created by Michael on 7/20/20.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#include "MADViewHelpers.h"

#if TARGET_OS_IPHONE
void MADViewSafeAreaInserts(UIView *view, UIEdgeInsets *safeAreaInsets) {
	if (@available(iOS 11.0, tvOS 11.0, *)) {
		*safeAreaInsets = view.safeAreaInsets;
	} else {
		*safeAreaInsets = UIEdgeInsetsZero;
	}
}
#endif
