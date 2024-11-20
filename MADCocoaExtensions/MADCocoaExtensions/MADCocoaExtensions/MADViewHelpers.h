//
//  MADViewHelpers.h
//  MADCocoaExtensions
//
//  Created by Michael on 7/20/20.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#ifndef MADViewHelpers_h
#define MADViewHelpers_h

#import <UIKit/UIView.h>

static inline enum UIViewAutoresizing MADViewAutoresizingFlexable(void);

void MADViewSafeAreaInserts(UIView *view, UIEdgeInsets *safeAreaInsets);

static inline enum UIViewAutoresizing MADViewAutoresizingFlexable(void) {
    return UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

#endif /* MADViewHelpers_h */
