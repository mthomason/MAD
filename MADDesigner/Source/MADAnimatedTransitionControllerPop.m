//
//  MADAnimatedTransitionControllerPop.m
//  MAD Designer
//
//  Created by Michael on 1/19/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAnimatedTransitionControllerPop.h"

@implementation MADAnimatedTransitionControllerPop

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)context {
	return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)context {
	UIViewController *toViewController = [context viewControllerForKey:UITransitionContextToViewControllerKey];
	UIViewController *fromViewController = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
	
	UIView *containerView = [context containerView];
	
	CGRect finalFrameForToVC = [context finalFrameForViewController:toViewController];
	CGRect initialFrameForFromVC = [context initialFrameForViewController:fromViewController];
	
	// `toViewController` (the one appearing) starts off-screen to the left
	CGRect initialFrameForToVC = CGRectMake(finalFrameForToVC.origin.x - finalFrameForToVC.size.width,
											finalFrameForToVC.origin.y,
											finalFrameForToVC.size.width,
											finalFrameForToVC.size.height);
	
	// `fromViewController` (the one disappearing) ends off-screen to the right
	CGRect finalFrameForFromVC = CGRectMake(initialFrameForFromVC.origin.x + initialFrameForFromVC.size.width,
											initialFrameForFromVC.origin.y,
											initialFrameForFromVC.size.width,
											initialFrameForFromVC.size.height);
	
	// Add the `toViewController`'s view to the container view, below the `fromViewController`'s view
	[containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
	toViewController.view.frame = initialFrameForToVC;
	
	[UIView animateWithDuration:[self transitionDuration:context]
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut // Or your preferred curve
					 animations:^{
		fromViewController.view.frame = finalFrameForFromVC;
		toViewController.view.frame = finalFrameForToVC;
	} completion:^(BOOL __unused finished) {
		BOOL wasCancelled = [context transitionWasCancelled];
		if (!wasCancelled) {
			// Only remove fromViewController's view if the transition was not cancelled.
			// If it was cancelled, fromViewController is still the active VC.
			// toViewController.view will be removed by UIKit if cancelled (or if !wasCancelled and toViewController.view was added, it remains)
			// [fromViewController.view removeFromSuperview]; // This line can sometimes be problematic if the transition is cancelled, UIKit might handle it.
			// However, for non-interactive transitions, if !wasCancelled, fromVC is definitely gone.
			// If interactive and cancelled, fromVC should remain.
			// The default UINavigationController transitions remove the fromView only if not cancelled.
			// It's generally safer to let UIKit manage fromViewController.view's removal if the transition is interactive.
			// For a simple non-interactive animator like this, explicitly removing it when not cancelled is fine.
		}
		// If the transition was cancelled, UIKit will put `fromViewController.view` back.
		// If it wasn't cancelled, `fromViewController.view` should be gone or be cleaned up.
		// The key is `completeTransition`.
		// If `wasCancelled` is true, UIKit restores the state. If `fromViewController.view` was removed above,
		// and the transition is cancelled, UIKit will add it back.
		// Thus, it's okay to conditionally remove `fromViewController.view` when `!wasCancelled`.
		if (!wasCancelled) {
			[fromViewController.view removeFromSuperview];
		}
		
		[context completeTransition:!wasCancelled];
	}];
}

@end
