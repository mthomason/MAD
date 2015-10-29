//
//  UIPageViewController+Extras.m
//  MAD
//
//  Created by Michael Thomason on 6/10/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIPageViewController+Extras.h"

@implementation UIPageViewController (Extras)

- (void)setPageingEnabled:(BOOL)enabled {
    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
            gestureRecognizer.enabled = enabled;
    }
}

@end
