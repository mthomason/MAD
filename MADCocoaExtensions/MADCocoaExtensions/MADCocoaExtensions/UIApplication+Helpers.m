//
//  UIApplication+Helpers.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/6/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIApplication+Helpers.h"

@implementation MADStackViewController

+ (instancetype)topViewController NS_RETURNS_NOT_RETAINED {
    id viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([viewController isKindOfClass:([UINavigationController  class])]) {
        if (((UINavigationController *)viewController).visibleViewController != nil) {
            viewController = ((UINavigationController *)viewController).visibleViewController;
        }
    }
    return viewController;
}

@end
