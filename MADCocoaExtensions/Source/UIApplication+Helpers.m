//
//  UIApplication+Helpers.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/6/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "UIApplication+Helpers.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIWindow.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIWindowScene.h>

@implementation UIApplication (Helpers)

- (UIWindow *)safeKeyWindow {
	for (UIScene *scene in self.connectedScenes) {
		if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
			for (UIWindow *window in ((UIWindowScene *)scene).windows) {
				if (window.isKeyWindow) {
					return window;
				}
			}
		}
	}
	return nil;
}

+ (__kindof UIViewController *)topViewController NS_RETURNS_NOT_RETAINED {
	UIWindow *keyWindow = [[UIApplication sharedApplication] safeKeyWindow];
	__kindof UIViewController *viewController = [keyWindow rootViewController];
	if ([viewController isKindOfClass:([UINavigationController  class])]) {
		if (((UINavigationController *)viewController).visibleViewController != nil) {
			viewController = ((UINavigationController *)viewController).visibleViewController;
		}
	}
	return viewController;
}

+ (NSString *)version {
	return CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
}

- (UIBackgroundTaskIdentifier)requestBackgroundTask {
	__block UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
	bgTask = [self beginBackgroundTaskWithExpirationHandler:^{
		[self endBackgroundTask:bgTask];
		bgTask = UIBackgroundTaskInvalid;
	}];
	return bgTask;
}

@end
#endif
