//
//  UIViewController+Utilities.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UIViewController+Utilities.h"
#import <UIKit/UISplitViewController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIWindow.h>

@implementation UIViewController (Utilities)

+ (instancetype)copyTopmostViewController:(UIViewController *)vc {
	
	if (vc.presentedViewController) {
		
		return [UIViewController copyTopmostViewController:vc.presentedViewController];
		
	} else if ([vc isKindOfClass:[UISplitViewController class]]) {
		
		UISplitViewController* svc = (UISplitViewController *) vc;
		
		if (svc.viewControllers.count > 0)
			return [UIViewController copyTopmostViewController:svc.viewControllers.lastObject];
		else
			return vc;
		
	} else if ([vc isKindOfClass:[UINavigationController class]]) {
		
		UINavigationController* svc = (UINavigationController *) vc;
		if (svc.viewControllers.count > 0)
			return [UIViewController copyTopmostViewController:svc.topViewController];
		else
			return vc;
		
	} else if ([vc isKindOfClass:[UITabBarController class]]) {
		
		UITabBarController* svc = (UITabBarController *) vc;
		if (svc.viewControllers.count > 0)
			return [UIViewController copyTopmostViewController:svc.selectedViewController];
		else
			return vc;
		
	} else {
		return vc;
	}
}

+ (instancetype)copyTopmostViewController {
	UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
	return [UIViewController copyTopmostViewController:viewController];
	
}

@end
