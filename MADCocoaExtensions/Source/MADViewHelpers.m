//
//  MADViewHelpers.c
//  MADCocoaExtensions
//
//  Created by Michael on 7/20/20.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#include "MADViewHelpers.h"

void MADViewSafeAreaInserts(UIView *view, UIEdgeInsets *safeAreaInsets) {
	if (@available(iOS 11.0, tvOS 11.0, *)) {
		*safeAreaInsets = view.safeAreaInsets;
	} else {
		*safeAreaInsets = UIEdgeInsetsZero;
	}
}
