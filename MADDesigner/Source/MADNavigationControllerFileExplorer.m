//
//  MADNavigationControllerFileExplorer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADNavigationControllerFileExplorer.h"

#import "MADTransparentPresentationController.h"
#import "MADExplorerController.h"
#import "MADThemeManager.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIImage.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIResponder.h>

@interface MADNavigationControllerFileExplorer ()

@property (weak, nonatomic) IBOutlet UINavigationBar *fileExplorerNavigationBar;
@property (weak, nonatomic) IBOutlet UIToolbar *fileExplorerToolBar;
@property (nonatomic, copy) void (^popCompletionBlock)(void);

@end

@implementation MADNavigationControllerFileExplorer

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.delegate = self;
	[MADThemeManager applyAppearanceToNavigationController:self traitCollection:self.traitCollection];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	[MADThemeManager applyAppearanceToNavigationController:self traitCollection:self.traitCollection];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear: animated];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(done:)) {
		return YES;
	}
	return NO;
}

- (void)done:(id)sender {
	[self done:sender completion:nil];
}

- (void)done:(id)sender completion:(void (^)(void))completion {
	self.popCompletionBlock = completion;
	[self.viewControllers[0] done:sender];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

- (MADNavigationControllerType)controllerType {
	return MADNavigationControllerTypeFileExplorer;
}

#pragma mark -
#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated {
	BOOL shouldShowToolbar = ![viewController isKindOfClass:[UITabBarController class]];
	[self setToolbarHidden:!shouldShowToolbar animated:animated];
	if (self.popCompletionBlock) {
		self.popCompletionBlock();
		self.popCompletionBlock = nil;
	}
}

- (void)navigationController:(UINavigationController *)navigationController
	   didShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated { }

- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
								   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController {
	return nil;
}

@end
