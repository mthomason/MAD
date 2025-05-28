//
//  UIApplication+Helpers.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/6/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UIApplication+Helpers.h"
#import <UIKit/UIWindow.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIWindowScene.h>

@implementation UIApplication (KeyWindowSafe)

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

@end
