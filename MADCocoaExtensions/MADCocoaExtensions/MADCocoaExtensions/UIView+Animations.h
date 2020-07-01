//
//  UIView+Animations.h
//  Reports
//
//  Created by Michael Thomason on 2/20/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

//#ifndef Reports_UIView_Animations_h
//#define Reports_UIView_Animations_h

#import <UIKit/UIView.h>

static inline enum UIViewAutoresizing MADViewAutoresizingFlexable(void);
static inline enum UIViewAutoresizing MADViewAutoresizingFlexable(void) {
    return UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

//#endif
