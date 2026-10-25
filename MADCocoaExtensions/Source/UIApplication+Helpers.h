//
//  UIApplication+Helpers.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/6/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADExtensions_UIApplication_Constructors_h
#define MADExtensions_UIApplication_Constructors_h

#import <UIKit/UIViewController.h>

@interface UIApplication (Helpers)

@property(nonatomic,readonly) UIWindow *safeKeyWindow;

+ (__kindof UIViewController *)topViewController NS_RETURNS_NOT_RETAINED;
+ (NSString *)version;
- (UIBackgroundTaskIdentifier)requestBackgroundTask;

@end

#endif
