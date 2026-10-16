//
//  MADToolboxTransitioner.m
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADToolboxTransitioner.h"
#import "MADToolboxPresentationController.h"
#import "MADViewControllerProtocol.h"
#import <MADFoundation/madlog.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIPopoverPresentationController.h>

@interface MADToolboxTransitioningDelegate ()

@property (nonatomic, strong, readwrite) UIPresentationController *presentationController;
@property (nonatomic, assign, readwrite) BOOL popoverStyle;

@end

@implementation MADToolboxTransitioningDelegate

- (MADToolboxAnimatedTransitioning *)animationController {
	MADToolboxAnimatedTransitioning *animationController = [[MADToolboxAnimatedTransitioning alloc] init];
	animationController.passthroughContainer = self.passthroughContainer;
	return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
																   presentingController:(UIViewController *)presenting
																	   sourceController:(UIViewController *)source {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	MADToolboxAnimatedTransitioning *animationController = [self animationController];
	animationController.toolboxVisible = YES;
	return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	MADToolboxAnimatedTransitioning *animationController = [self animationController];
	animationController.toolboxVisible = NO;
	
	return animationController;
}

- (void)setSourceRect:(CGRect)sourceRect {
	if (CGRectEqualToRect(sourceRect, self.sourceRect) == NO) {
		if (_presentationController &&
			[_presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
			((UIPopoverPresentationController *)_presentationController).sourceRect = sourceRect;
		}
		_sourceRect = sourceRect;
	}
	[((UIPopoverPresentationController *)_presentationController).containerView setNeedsLayout];
}

- (void)setPassthroughContainers:(NSSet *)passthroughContainers {
	if (_passthroughContainers != passthroughContainers) {
		_passthroughContainers = passthroughContainers;
	}
}

- (void)setPassthroughContainer:(UIView *)passthroughContainer {
	if (_passthroughContainer != passthroughContainer) {
		_passthroughContainer = passthroughContainer;
	}
}

- (void)setPassthroughViews:(NSSet *)passthroughViews {
	if (_passthroughViews != passthroughViews) {
		_passthroughViews = passthroughViews;
		[self updatePassthroughViews];
	}
}

- (void)updatePassthroughViews {
	UIView *passthroughContainer = _passthroughContainer;
	if (self.popoverStyle) {
		NSSet *allElements = [_passthroughViews setByAddingObjectsFromSet:_passthroughContainers];
		allElements = [allElements setByAddingObject:passthroughContainer];
		((UIPopoverPresentationController *)_presentationController).passthroughViews = allElements.allObjects;
	} else {
		((MADToolboxPresentationController *)_presentationController).passthroughContainers = _passthroughContainers;
		((MADToolboxPresentationController *)_presentationController).passthroughViews = _passthroughViews;
		((MADToolboxPresentationController *)_presentationController).passthroughContainer = passthroughContainer;
	}
}

- (UIPresentationController *)presentationControllerForPresentedViewController: (UIViewController *)presented
													  presentingViewController: (UIViewController *)presenting
														  sourceViewController: (UIViewController *)source {
	MADLogDebug("%s", __PRETTY_FUNCTION__);

	UIView *passthroughContainer = _passthroughContainer;
	id <UIPopoverPresentationControllerDelegate> popoverPresentationControllerDelegate = _popoverPresentationControllerDelegate;
	
	UIPresentationController *presentationController = nil;
	if ((UIUserInterfaceSizeClassRegular == source.traitCollection.horizontalSizeClass &&
		 UIUserInterfaceSizeClassRegular == source.traitCollection.verticalSizeClass) != NO) {
		_popoverStyle = YES;
		
		presentationController = [[UIPopoverPresentationController alloc] initWithPresentedViewController: presented
																				 presentingViewController: presenting];
		
		((UIPopoverPresentationController *)presentationController).sourceView = self.sourceView;
		((UIPopoverPresentationController *)presentationController).sourceRect = self.sourceRect;
		
		NSArray <UIView *> *allElementViews =  self.passthroughViews.allObjects;
		NSArray <UIView *> *allContainerObjects = self.passthroughContainers.allObjects;
		NSArray <UIView *> *passthroughViews = [allElementViews arrayByAddingObjectsFromArray:allContainerObjects];
		NSArray <UIView *> *passthroughViewsAll = [passthroughViews arrayByAddingObject:passthroughContainer];
		
		((UIPopoverPresentationController *)presentationController).passthroughViews = passthroughViewsAll;
		((UIPopoverPresentationController *)presentationController).permittedArrowDirections = self.permittedArrowDirections;
		((UIPopoverPresentationController *)presentationController).delegate = popoverPresentationControllerDelegate;
		
	} else {
		_popoverStyle = NO;
		presentationController = [[MADToolboxPresentationController alloc] initWithPresentedViewController: presented
																				  presentingViewController: presenting];
		
		((MADToolboxPresentationController *)presentationController).container = self.container;
		((MADToolboxPresentationController *)presentationController).passthroughContainers = self.passthroughContainers;
		((MADToolboxPresentationController *)presentationController).passthroughViews = self.passthroughViews;
		((MADToolboxPresentationController *)presentationController).passthroughContainer = passthroughContainer;
		((MADToolboxPresentationController *)presentationController).popoverPresentationControllerDelegate = popoverPresentationControllerDelegate;
	}
	_presentationController = presentationController;
	return _presentationController;
}

@end

@implementation MADToolboxAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
	return 0.5;
}

- (BOOL)showOnSide {
	return YES;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)context {
	MADLogDebug("%s", __PRETTY_FUNCTION__);

	UITabBarController *tabBarController = nil;
	UINavigationController *toolboxNavigationController = nil;
	UINavigationController *navController = nil;
	
	BOOL isToolboxVisible = _toolboxVisible;
	if (isToolboxVisible == NO) {
		navController = [context viewControllerForKey:UITransitionContextToViewControllerKey];
		tabBarController = navController.viewControllers.lastObject;
		toolboxNavigationController = (UINavigationController *)[context viewControllerForKey:UITransitionContextFromViewControllerKey];
	} else {
		navController = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
		tabBarController = navController.viewControllers.lastObject;
		toolboxNavigationController = (UINavigationController *)[context viewControllerForKey:UITransitionContextToViewControllerKey];
	}
	
	BOOL showOnSide = [((MADToolboxPresentationController *)toolboxNavigationController.presentationController) showOnSide];
	
	if (isToolboxVisible) {
		[context.containerView addSubview:toolboxNavigationController.view];
	}
	
	// Get the container view's safe area insets
	UIEdgeInsets safeAreaInsets = context.containerView.safeAreaInsets;
	
	// Calculate the final frame respecting safe areas
	CGRect appearedFrame = [context finalFrameForViewController:toolboxNavigationController];
	if (CGRectIsEmpty(appearedFrame)) {
		appearedFrame = context.containerView.bounds;
	}
	
	// Adjust for safe areas based on orientation and presentation side
	if (showOnSide) {
		// Side presentation (landscape)
		appearedFrame.size.width -= safeAreaInsets.right;
		appearedFrame.origin.x += safeAreaInsets.left;
		
		// Ensure we don't go under the top/bottom safe areas
		appearedFrame.origin.y = safeAreaInsets.top;
		appearedFrame.size.height = context.containerView.bounds.size.height - safeAreaInsets.top - safeAreaInsets.bottom;
	} else {
		// Bottom presentation (portrait)
		appearedFrame.size.height -= safeAreaInsets.bottom;
		appearedFrame.origin.y += safeAreaInsets.top;
		
		// Ensure we don't go under the left/right safe areas
		appearedFrame.origin.x = safeAreaInsets.left;
		appearedFrame.size.width = context.containerView.bounds.size.width - safeAreaInsets.left - safeAreaInsets.right;
	}
	
	// Calculate dismissed frame based on presentation style
	CGRect dismissedFrame = appearedFrame;
	if (showOnSide) {
		dismissedFrame.origin.x += dismissedFrame.size.width;
	} else {
		dismissedFrame.origin.y += dismissedFrame.size.height;
	}
	
	// Set initial and final frames
	CGRect initialFrame = isToolboxVisible ? dismissedFrame : appearedFrame;
	CGRect finalFrame = isToolboxVisible ? appearedFrame : dismissedFrame;
	
	toolboxNavigationController.view.frame = initialFrame;
	toolboxNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	UINavigationController *selectedConroller = (UINavigationController *)tabBarController.selectedViewController;
	UIViewController <MADViewControllerProtocol> *designer = (UIViewController <MADViewControllerProtocol> *)selectedConroller.topViewController;
	[designer setHidesStatusBar: isToolboxVisible];
	
	typeof(toolboxNavigationController) __weak weakNavController = toolboxNavigationController;
	[UIView animateWithDuration: [self transitionDuration:context]
						  delay: 0.0
		 usingSpringWithDamping: 300.0
		  initialSpringVelocity: 5.0
						options: UIViewAnimationOptionAllowUserInteraction |
	 UIViewAnimationOptionBeginFromCurrentState
					 animations: ^{
		[tabBarController setNeedsStatusBarAppearanceUpdate];
		weakNavController.view.frame = finalFrame;
	} completion: ^(BOOL __unused finished) {
		[designer.view setNeedsLayout];
		if (isToolboxVisible == NO) {
			[weakNavController.view removeFromSuperview];
		}
		[context completeTransition:YES];
	}];
}

@end
