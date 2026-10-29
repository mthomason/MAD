//
//  MADViewHelpers.h
//  MADCocoaExtensions
//
//  Created by Michael on 7/20/20.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADViewHelpers_h
#define MADViewHelpers_h

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIView.h>

static inline enum UIViewAutoresizing MADViewAutoresizingFlexable(void);

void MADViewSafeAreaInserts(UIView *view, UIEdgeInsets *safeAreaInsets);

static inline enum UIViewAutoresizing MADViewAutoresizingFlexable(void) {
	return UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}
#endif

#endif /* MADViewHelpers_h */
