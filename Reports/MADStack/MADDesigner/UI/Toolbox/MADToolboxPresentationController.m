//
//  MADToolboxPresentationController.m
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADToolboxPresentationController.h"

#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UISwipeGestureRecognizer.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIAccessibility.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIPopoverPresentationController.h>

#import "MADDimmingView.h"
#import "MADViewControllerProtocol.h"

@interface MADToolboxPresentationController() <UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, strong) UIGestureRecognizer *dismissGestureReconizer;
@property (nonatomic, readwrite, weak)   UIViewController <MADViewControllerProtocol> *designerViewController;
@property (nonatomic, readwrite, strong) MADDimmingView *dimmingView;

@end

@implementation MADToolboxPresentationController

- (void)dealloc { }

- (void)presentationTransitionDidEnd:(BOOL)completed {
	[super presentationTransitionDidEnd:completed];
	
}

- (void)dismissalTransitionDidEnd:(BOOL)completed {
	[super presentationTransitionDidEnd:completed];
	[self removeObserver: self
			  forKeyPath: NSStringFromSelector(@selector(passthroughContainer))];
	[self removeObserver: self
			  forKeyPath: NSStringFromSelector(@selector(passthroughViews))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary <NSKeyValueChangeKey, id> *)change
					   context:(void *)context {
	
	if ([keyPath isEqualToString:NSStringFromSelector(@selector(passthroughViews))]) {
		
		self.dimmingView.passthroughViews = self.passthroughViews;
		
	} else if ([keyPath isEqualToString:NSStringFromSelector(@selector(passthroughContainer))]) {
		
		self.dimmingView.passthroughContainer = self.passthroughContainer;
		self.dimmingView.passthroughContainers = self.passthroughContainers;
		self.dimmingView.container = self.container;
	}
}

- (instancetype)initWithPresentedViewController: (UIViewController *)presentedViewController
					   presentingViewController: (UIViewController *)presentingViewController; {
	
	if (self = [super initWithPresentedViewController: presentedViewController
							 presentingViewController: presentingViewController]) {
		
		MADDimmingView *dimmingView = [[MADDimmingView alloc] init];
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(dimmingViewTapped:)];
		tap.numberOfTapsRequired = 1;
		tap.numberOfTouchesRequired = 1;
		[dimmingView addGestureRecognizer:tap];
		
		self.dimmingView = dimmingView;
		[self addObserver: self forKeyPath: NSStringFromSelector(@selector(passthroughContainer)) options: (NSKeyValueObservingOptions)0 context: NULL];
		[self addObserver: self forKeyPath: NSStringFromSelector(@selector(passthroughViews)) options: (NSKeyValueObservingOptions)0 context: NULL];
		
		UISwipeGestureRecognizer *down = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(handleSwipeAway:)];
		down.direction = UISwipeGestureRecognizerDirectionDown;
		[presentedViewController.view addGestureRecognizer:down];
		self.dismissGestureReconizer = down;
		
		((UINavigationController *)presentedViewController).interactivePopGestureRecognizer.enabled = NO;
		//        presentedViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
	}
	
	return self;
}

- (void)handleSwipeAway:(UIGestureRecognizer *)gestureReconizer {
	[self dismiss];
}

- (void)presentationTransitionWillBegin {
	
	UINavigationController *navController = (UINavigationController *)self.presentingViewController;
	UITabBarController *tabBarController = navController.viewControllers.firstObject;
	UIViewController <MADViewControllerProtocol> *designer;
	if ([tabBarController isKindOfClass:[UITabBarController class]]) {
		designer = tabBarController.selectedViewController;
	} else {
		designer = (UIViewController <MADViewControllerProtocol> *)self.popoverPresentationControllerDelegate;
	}
	//    UIViewController <MADViewControllerProtocol> *designer = tabBarController.selectedViewController;
	self.designerViewController = designer;
	
	UIView *containerView = self.containerView;
	UIViewController *presentedViewController = self.presentedViewController;
	BOOL showOnSide = [self showOnSide];
	self.presentingViewController.modalTransitionStyle = showOnSide ? UIModalTransitionStyleFlipHorizontal : UIModalTransitionStyleCoverVertical;
	self.dimmingView.frame = containerView.bounds;
	self.dimmingView.alpha = 0.0000f;
	
	[containerView insertSubview:self.dimmingView atIndex:0];
	if (presentedViewController.transitionCoordinator) {
		
		[presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
			self.dimmingView.alpha = 1.0000f;
		} completion:nil];
		
	} else {
		self.dimmingView.alpha = 1.0000f;
	}
}

- (void)dismissalTransitionWillBegin {
	if (self.presentedViewController.transitionCoordinator) {
		typeof(self) __weak weakself = self;
		[self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
			weakself.dimmingView.alpha = 0.0;
		} completion:nil];
		
	} else {
		self.dimmingView.alpha = 0.0;
	}
}

- (UIModalPresentationStyle)adaptivePresentationStyle {
	return UIModalPresentationCustom;
}

- (CGSize)sizeForChildContentContainer:(id <UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
	return [self showOnSide] ?
		CGSizeMake(MAX(floor(parentSize.width / 3.0), self.presentedViewController.preferredContentSize.width) , parentSize.height) :
		CGSizeMake(MAX(parentSize.width, self.presentedViewController.preferredContentSize.width), MIN(self.presentedViewController.preferredContentSize.height, floor(parentSize.height / 2.0)));
}

- (void)containerViewWillLayoutSubviews {
	[super containerViewWillLayoutSubviews];
	self.dimmingView.frame = self.containerView.bounds;
	self.presentedView.frame = [self frameOfPresentedViewInContainerView];
}

- (void)containerViewDidLayoutSubviews {
	[super containerViewDidLayoutSubviews];
}

- (BOOL)shouldPresentInFullscreen { return YES; }

- (BOOL)showOnSide {
	return self.presentingViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (CGRect)frameOfPresentedViewInContainerView {
	CGRect containerBounds = self.containerView.bounds;
	UIEdgeInsets safeAreaInsets = self.containerView.safeAreaInsets;
	CGSize contentSize = [self sizeForChildContentContainer:(UIViewController<UIContentContainer> *)self.presentedViewController
									withParentContainerSize:containerBounds.size];
	CGRect presentedViewFrame = CGRectZero;
	BOOL showOnSide = [self showOnSide];
	
	if (showOnSide) {
		// Side presentation (landscape)
		presentedViewFrame.size.width = contentSize.width;
		presentedViewFrame.size.height = containerBounds.size.height - safeAreaInsets.top - safeAreaInsets.bottom;
		presentedViewFrame.origin.x = containerBounds.size.width - contentSize.width - safeAreaInsets.right;
		presentedViewFrame.origin.y = safeAreaInsets.top;
	} else {
		// Bottom presentation (portrait)
		presentedViewFrame.size.width = containerBounds.size.width - safeAreaInsets.left - safeAreaInsets.right;
		presentedViewFrame.size.height = contentSize.height;
		presentedViewFrame.origin.x = safeAreaInsets.left;
		presentedViewFrame.origin.y = containerBounds.size.height - contentSize.height - safeAreaInsets.bottom;
	}
	
	return presentedViewFrame;
}

- (void)dimmingViewTapped:(UIGestureRecognizer *)gesture {
	if (gesture.state == UIGestureRecognizerStateEnded) {
		if ([self.popoverPresentationControllerDelegate presentationControllerShouldDismiss:(UIPopoverPresentationController *)self]) {
			[self dismiss];
		}
	}
}


- (void)dismiss {
	[((UIViewController <MADViewControllerProtocol> *)self.designerViewController) setHidesStatusBar: NO];
	[self.presentingViewController dismissViewControllerAnimated: YES
													  completion: ^{
		[self.popoverPresentationControllerDelegate presentationControllerShouldDismiss:(UIPopoverPresentationController *)self];
	}];
}

- (BOOL)accessibilityPerformEscape {
	[self dismiss];
	NSString *announcement = NSLocalizedString(@"Dismissing toolbox.", @"Dismissing toolbox.");
	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
	return YES;
}

@end
