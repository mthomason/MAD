//
//  UIView+Animations.h
//  Reports
//
//  Created by Michael Thomason on 2/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIView_Animations_h
#define Reports_UIView_Animations_h

#import <UIKit/UIView.h>

static inline UIViewAutoresizing MADViewAutoresizingFlexable();
static inline UIViewAutoresizing MADViewAutoresizingFlexable() {
    return UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

#endif
