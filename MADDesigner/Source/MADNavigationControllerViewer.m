//
//  MADNavigationControllerViewer.m
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADNavigationControllerViewer.h"
#import "MADViewerController.h"
#import "MADThemeManager.h"

#import <UIKit/UITabBarController.h>
#import <UIKit/UITabBar.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIWindow.h>

@implementation MADNavigationControllerViewer

@synthesize document = _document;

- (void)dealloc {
	_viewControllerDelegate = nil;
	_document = nil;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor secondarySystemBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.viewControllers.count == 0) {
		MADViewerController *rootViewController = [MADViewerController newViewerController: _document];
		[self pushViewController:rootViewController animated:animated];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	UITabBar *tabBar = self.tabBarController.tabBar;
	if (!tabBar || tabBar.isHidden || self.isToolbarHidden || !self.view.window) {
		return;
	}
	CGRect tabBarFrame = [tabBar convertRect:tabBar.bounds toView:self.view];
	if (CGRectIsEmpty(tabBarFrame) || CGRectGetMinY(tabBarFrame) >= CGRectGetMaxY(self.view.bounds)) {
		return;
	}
	if (self.toolbar.superview == self.view) {
		CGRect toolbarFrame = self.toolbar.frame;
		CGFloat targetY = CGRectGetMinY(tabBarFrame) - CGRectGetHeight(toolbarFrame);
		if (fabs(toolbarFrame.origin.y - targetY) > 0.5) {
			toolbarFrame.origin.y = targetY;
			self.toolbar.frame = toolbarFrame;
		}
	} else {
		CGFloat bottomSafe = self.view.window.safeAreaInsets.bottom;
		CGFloat shiftY = CGRectGetMinY(tabBarFrame) - (CGRectGetMaxY(self.view.bounds) - bottomSafe) - 4.0;
		for (UIView *sub in self.view.subviews) {
			if ([NSStringFromClass(sub.class) containsString:@"FloatingBar"]) {
				CGRect f = sub.frame;
				if (fabs(f.origin.y - shiftY) > 0.5) {
					f.origin.y = shiftY;
					sub.frame = f;
				}
			}
		}
	}
}

+ (UIImage *)TabBarImage {
	return [MADViewerController TabBarImage];
}

- (NSString *)title {
	return self.viewControllers.count > 0 ? self.viewControllers.firstObject.title : [MADViewerController Title];
}

- (void)setDocument:(MADocument *)document {
	if (_document != document) {
		_document = document;
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[super dismissViewControllerAnimated:animated completion:completion];
	[self setViewControllers:@[] animated:animated];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	[MADThemeManager applyAppearanceToNavigationController:self traitCollection:self.traitCollection];
}

- (MADNavigationControllerType)controllerType {
	return MADNavigationControllerTypeViewer;
}

@end
