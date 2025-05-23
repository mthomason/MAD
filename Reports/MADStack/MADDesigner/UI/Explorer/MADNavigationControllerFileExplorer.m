//
//  MADNavigationControllerFileExplorer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNavigationControllerFileExplorer.h"

#import "MADAnimatedTransitioningNavigationCrossFadePop.h"
#import "MADAnimatedTransitioningNavigationCrossFadePush.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADTransparentPresentationController.h"

#import "MADExplorerNavigationBar.h"
#import "MADExplorerToolbar.h"
#import "MADExplorerController.h"

#import "MADExplorerAnimated.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIBlurEffect.h>
#import <UIKit/UIImage.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UINavigationBarAppearance.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UIToolbarAppearance.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIResponder.h>

@interface MADNavigationControllerFileExplorer ()

@property (weak, nonatomic) IBOutlet MADExplorerNavigationBar *fileExplorerNavigationBar;
@property (weak, nonatomic) IBOutlet MADExplorerToolbar *fileExplorerToolBar;

@end

@implementation MADNavigationControllerFileExplorer

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.delegate = self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	
	UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
	UIToolbarAppearance *toolbarAppearance = [[UIToolbarAppearance alloc] init];
	
	UIBarButtonItemAppearance *navBarButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
	UIBarButtonItemAppearance *toolbarButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
	UIFont *buttonFont = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
	
	if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
		[navBarAppearance configureWithTransparentBackground];
		navBarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
		navBarAppearance.titleTextAttributes = @{
			NSForegroundColorAttributeName: [UIColor whiteColor]
		};
		navBarAppearance.largeTitleTextAttributes = @{
			NSForegroundColorAttributeName: [UIColor whiteColor]
		};
		
		[navBarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [UIColor systemBlueColor],
			NSFontAttributeName: buttonFont
		}];
		navBarAppearance.buttonAppearance = navBarButtonAppearance;
		navBarAppearance.doneButtonAppearance = navBarButtonAppearance;
		
		[toolbarAppearance configureWithTransparentBackground];
		toolbarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
		
		[toolbarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [UIColor systemBlueColor],
			NSFontAttributeName: buttonFont
		}];
		toolbarAppearance.buttonAppearance = toolbarButtonAppearance;
		toolbarAppearance.doneButtonAppearance = toolbarButtonAppearance;
		
	} else {

		[navBarAppearance configureWithOpaqueBackground];
		navBarAppearance.backgroundColor = [MADColorEverydayApps newColorBlue];
		navBarAppearance.titleTextAttributes = @{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite]
		};
		navBarAppearance.largeTitleTextAttributes = @{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite]
		};
		
		[navBarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorWhite],
			NSFontAttributeName: buttonFont
		}];
		navBarAppearance.buttonAppearance = navBarButtonAppearance;
		navBarAppearance.doneButtonAppearance = navBarButtonAppearance;
		
		[toolbarAppearance configureWithOpaqueBackground];
		toolbarAppearance.backgroundColor = [UIColor whiteColor];
		
		[toolbarButtonAppearance.normal setTitleTextAttributes:@{
			NSForegroundColorAttributeName: [MADColorEverydayApps newColorBlue],
			NSFontAttributeName: buttonFont
		}];

		toolbarAppearance.buttonAppearance = toolbarButtonAppearance;
		toolbarAppearance.doneButtonAppearance = toolbarButtonAppearance;
	}
	
	self.navigationBar.standardAppearance = navBarAppearance;
	self.navigationBar.compactAppearance = navBarAppearance;
	self.navigationBar.scrollEdgeAppearance = navBarAppearance;
	
	self.toolbar.standardAppearance = toolbarAppearance;
	if (@available(iOS 15.0, *)) {
		self.toolbar.scrollEdgeAppearance = toolbarAppearance;
	}
	[self.view setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear: animated];
	if (self.viewControllers.count == 1) {
		MADExplorerController *fileExplorer = [MADExplorerController newExplorerController];
		[self pushViewController:fileExplorer animated:YES];
	}
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(done:)) {
		return YES;
	}
	return NO;
}

- (void)done:(id)sender {
	[self.viewControllers[1] done:sender];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (MADNavigationControllerType)controllerType {
	return MADNavigationControllerTypeFileExplorer;
}

#pragma mark -
#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated {
	[self setToolbarHidden: NO animated: animated];
}

- (void)navigationController:(UINavigationController *)navigationController
	   didShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated { }

- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
								   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController {
	return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
											animationControllerForOperation:(UINavigationControllerOperation)operation
														 fromViewController:(UIViewController *)fromVC
														   toViewController:(UIViewController *)toVC  {

	id <UIViewControllerAnimatedTransitioning> animationController;
	BOOL toTabViewController = [toVC isKindOfClass:[UITabBarController class]];
	BOOL toFileExplorferViewController = [toVC isKindOfClass:[MADExplorerController class]];

	if (toTabViewController || toFileExplorferViewController) {
		toVC.modalPresentationStyle = UIModalPresentationCustom;
		switch (operation) {
			case UINavigationControllerOperationPush:
				animationController = [MADExplorerAnimated newFileExplorerAnimatedShowToolbar:toFileExplorferViewController
																					  pushing:YES];
				break;

			case UINavigationControllerOperationPop:
				animationController = [MADExplorerAnimated newFileExplorerAnimatedShowToolbar:toFileExplorferViewController
																					  pushing:NO];
				break;

			case UINavigationControllerOperationNone:
			default:
				break;
		}
	}
	return animationController;
}

@end
