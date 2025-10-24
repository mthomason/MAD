//
//  MADToolboxPresentationController.m
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADToolboxPresentationController.h"
#import "MADDesignerViewController.h"
#import "MADDimmingView.h"
#import "MADViewControllerProtocol.h"
#import "madlog.h"
#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UISwipeGestureRecognizer.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIAccessibility.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIPopoverPresentationController.h>

@interface MADToolboxPresentationController() <UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, strong) UIGestureRecognizer *dismissGestureReconizer;
@property (nonatomic, readwrite, weak) UIViewController <MADViewControllerProtocol> *designerViewController;
@property (nonatomic, readwrite, strong) MADDimmingView *dimmingView;

@end

@implementation MADToolboxPresentationController

- (void)dealloc { }

- (void)presentationTransitionDidEnd:(BOOL)completed {
	[super presentationTransitionDidEnd:completed];
	MADLogDebug("%s", __PRETTY_FUNCTION__);
}

- (void)dismissalTransitionDidEnd:(BOOL)completed {
	[super presentationTransitionDidEnd:completed];
	MADLogDebug("%s", __PRETTY_FUNCTION__);

	[self removeObserver: self
			  forKeyPath: NSStringFromSelector(@selector(passthroughContainer))];
	[self removeObserver: self
			  forKeyPath: NSStringFromSelector(@selector(passthroughViews))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary <NSKeyValueChangeKey, id> *)change
					   context:(void *)context {
	MADLogDebug("%s", __PRETTY_FUNCTION__);

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

- (void)presentationTransitionWillBegin {
	MADLogDebug("%s", __PRETTY_FUNCTION__);

	UINavigationController *navController = (UINavigationController *)self.presentingViewController;
	UITabBarController *tabBarController = navController.viewControllers.firstObject;

	UIViewController <MADViewControllerProtocol> *designer = [tabBarController isKindOfClass:[UITabBarController class]] ?
		tabBarController.selectedViewController :
		(UIViewController <MADViewControllerProtocol> *)self.popoverPresentationControllerDelegate;

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
			self.dimmingView.alpha = 1.0;
		} completion:nil];
		
	} else {
		self.dimmingView.alpha = 1.0;
	}
}

- (void)dismissalTransitionWillBegin {
	MADLogDebug("%s", __PRETTY_FUNCTION__);

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
	UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
	if (@available(iOS 11.0, *)) {
		safeAreaInsets = self.containerView.safeAreaInsets;
	}
	
	if ([self showOnSide]) {
		CGFloat availableHeight = parentSize.height - safeAreaInsets.top - safeAreaInsets.bottom;
		CGFloat width = MAX(floor((parentSize.width - safeAreaInsets.left - safeAreaInsets.right) / 3.0),
							self.presentedViewController.preferredContentSize.width);
		return CGSizeMake(width, availableHeight);
	} else {
		CGFloat availableWidth = parentSize.width - safeAreaInsets.left - safeAreaInsets.right;
		CGFloat height = MIN(self.presentedViewController.preferredContentSize.height,
							 floor((parentSize.height - safeAreaInsets.top - safeAreaInsets.bottom) / 2.0));
		return CGSizeMake(availableWidth, height);
	}
}

- (void)containerViewWillLayoutSubviews {
	[super containerViewWillLayoutSubviews];
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	self.dimmingView.frame = self.containerView.bounds;
	self.presentedView.frame = [self frameOfPresentedViewInContainerView];
}

- (void)containerViewDidLayoutSubviews {
	[super containerViewDidLayoutSubviews];
	MADLogDebug("%s", __PRETTY_FUNCTION__);
}

- (BOOL)shouldPresentInFullscreen { return YES; }

- (BOOL)showOnSide {
	return self.presentingViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (CGRect)frameOfPresentedViewInContainerView {
	CGRect containerBounds = self.containerView.bounds;
	UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
	if (@available(iOS 11.0, *)) {
		safeAreaInsets = self.containerView.safeAreaInsets;
	}

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
	MADLogDebug("%s: gestureReconizer: %@", __PRETTY_FUNCTION__, gesture);
	if (gesture.state == UIGestureRecognizerStateEnded) {
		if ([self.popoverPresentationControllerDelegate presentationControllerShouldDismiss:(UIPopoverPresentationController *)self]) {
			[self dismiss];
		}
	}
}

- (void)handleSwipeAway:(UIGestureRecognizer *)gesture {
	MADLogDebug("%s: gestureReconizer: %@", __PRETTY_FUNCTION__, gesture);
	if (gesture.state == UIGestureRecognizerStateEnded) {
		if ([self.popoverPresentationControllerDelegate presentationControllerShouldDismiss:(UIPopoverPresentationController *)self]) {
			[self dismiss];
		}
	}
}

- (void)dismiss {
	id <UIAdaptivePresentationControllerDelegate> delegate = self.delegate;
	MADLogDebug("%s: presentingViewController: %@ presentedViewController: %@ delegate: %@", __PRETTY_FUNCTION__, self.presentingViewController, self.presentedViewController, delegate);
	if ([delegate isKindOfClass:[MADDesignerViewController class]]) {	// This is a fucking hack.  This presentation controller shouldn't know about `MADDesignerViewController`, but here we are.
		if ([delegate respondsToSelector:@selector(actionHideToolbox)]) {
			[(MADDesignerViewController *)delegate actionHideToolbox];
		}
	} else {
		[((UIViewController <MADViewControllerProtocol> *)self.designerViewController) setHidesStatusBar: NO];
		UIViewController *presentingViewController = self.presentingViewController;
		__weak MADToolboxPresentationController *weakSelf = self;
		[presentingViewController dismissViewControllerAnimated: YES
													 completion: ^{
			__strong MADToolboxPresentationController *strongSelf = weakSelf;
			if (strongSelf) {
				[strongSelf.popoverPresentationControllerDelegate presentationControllerShouldDismiss:(UIPopoverPresentationController *)strongSelf];
			}
		}];
	}
}

- (BOOL)accessibilityPerformEscape {
	[self dismiss];
	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Dismissing toolbox.", @"Dismissing toolbox."));
	return YES;
}

@end
