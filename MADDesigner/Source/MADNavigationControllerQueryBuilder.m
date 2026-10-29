//
//  MADNavigationControllerQueryBuilder.m
//  MAD
//
//  Created by Michael Thomason on 10/18/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADNavigationControllerQueryBuilder.h"
#import "MADViewControllerDocumentProtocol.h"
#import "MADQueryViewController.h"
#import "MADAnimatedTransitionControllerPop.h"
#import "MADAnimatedTransitionControllerPush.h"
#import "MADThemeManager.h"

#import <Foundation/NSObject.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIResponder.h>
#import <UIKit/UIWindow.h>

@interface MADNavigationControllerQueryBuilder () <UINavigationControllerDelegate>
	@property (nonatomic, weak) IBOutlet UIToolbar *bottomToolbar;

@end

@implementation MADNavigationControllerQueryBuilder {
	BOOL _firstTimeLayout;
}

@synthesize document = _document;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		_firstTimeLayout = YES;
		self.delegate = self;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.hidesBarsWhenVerticallyCompact = NO;
	[MADThemeManager applyAppearanceToNavigationController:self traitCollection:self.traitCollection];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	[MADThemeManager applyAppearanceToNavigationController:self traitCollection:self.traitCollection];
}

#pragma mark - Navigation

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
	id result = [super popViewControllerAnimated:animated];;
	return result;
}

- (void)pushViewController:(UIViewController *)viewController
				  animated:(BOOL)animated {
	[super pushViewController: viewController animated: animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setToolbarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	/*if (self.childViewControllers.count <= 0) {
		MADQueryViewController *madQueryViewController = [MADQueryViewController newQueryViewController:_document];
		self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		self.modalPresentationStyle = UIModalPresentationCustom;
		madQueryViewController.modalPresentationStyle = UIModalPresentationNone;
		madQueryViewController.providesPresentationContextTransitionStyle = YES;
		[self pushViewController:madQueryViewController animated:YES];
	}*/
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (self.isBeingDismissed) {
		[self setViewControllers:@[] animated:animated];
	}
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	for (UIViewController *vc in self.childViewControllers) {
		[vc.view setNeedsLayout];
	}
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

- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated {
	BOOL toolbarsHidden = ![viewController isKindOfClass:[MADQueryViewController class]];
	if (self.toolbarHidden != toolbarsHidden) {
		[self setToolbarHidden:toolbarsHidden animated:animated];
	}
}

- (void)navigationController:(UINavigationController *)navigationController
	   didShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated {
	//[super navigationController:navigationController
	//      didShowViewController:viewController
	//                   animated:animated];
	//BOOL toolbarsHidden = ![viewController isKindOfClass:[MADQueryViewController class]];
	//if (self.toolbarHidden != toolbarsHidden) {
	//    [self setToolbarHidden:toolbarsHidden animated:animated];
	//}
}

- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
								   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController NS_AVAILABLE_IOS(7_0) {
	return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
											animationControllerForOperation:(UINavigationControllerOperation)operation
														 fromViewController:(UIViewController *)fromVC
														   toViewController:(UIViewController *)toVC  NS_AVAILABLE_IOS(7_0) {
	return [fromVC isKindOfClass:[MADQueryViewController class]] ? [[MADAnimatedTransitionControllerPush alloc] init] : [[MADAnimatedTransitionControllerPop alloc] init];
}

- (void)setDocument:(MADocument *)document {
	if (document != _document) {
		_document = document;
		UIViewController *childViewController;
		NSArray<__kindof UIViewController *> *childViewControllers = self.childViewControllers;
		for (childViewController in childViewControllers) {
			if ([childViewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
				[((id <MADViewControllerDocumentProtocol>)childViewController) setDocument: self.document];
			}
		}
	}
}

- (MADNavigationControllerType)controllerType {
	return MADNavigationControllerTypeQuery;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

@end
