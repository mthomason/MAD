//
//  UIApplication+Helpers.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/6/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIApplication+Helpers.h"

@implementation UIApplication (Helpers)

+ (id)topViewController {
    id viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([viewController isKindOfClass:([UINavigationController  class])]) {
        id vvc = ((UINavigationController *)viewController).visibleViewController;
        if (vvc != nil) {
            viewController = vvc;
        }
    }
    return viewController;
}

@end
