//
//  UIViewController+ui.m
//  MAD
//
//  Created by Michael Thomason on 6/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIViewController+ui.h"

@implementation UIViewController (ui)

- (void)disableTabBarItems {
    for (UITabBarItem *item in [[[self tabBarController] tabBar] items]) {
        [item setEnabled:NO];
    }
}

- (void)enableTabBarItems {
    for (UITabBarItem *item in [[[self tabBarController] tabBar] items]) {
        [item setEnabled:YES];
    }
}

@end
