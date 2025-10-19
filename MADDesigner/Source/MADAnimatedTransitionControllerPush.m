//
//  MADAnimatedTransitionControllerPush.m
//  MAD Designer
//
//  Created by Michael on 1/19/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAnimatedTransitionControllerPush.h"

@implementation MADAnimatedTransitionControllerPush

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)context {
	return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)context {
	UIViewController *toViewController = [context viewControllerForKey:UITransitionContextToViewControllerKey];
	UIViewController *fromViewController = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
	
	UIView *containerView = [context containerView];
	
	CGRect finalFrameForToVC = [context finalFrameForViewController:toViewController];
	CGRect initialFrameForFromVC = [context initialFrameForViewController:fromViewController];
	
	CGRect initialFrameForToVC = CGRectMake(finalFrameForToVC.origin.x + finalFrameForToVC.size.width,
											finalFrameForToVC.origin.y,
											finalFrameForToVC.size.width,
											finalFrameForToVC.size.height);
	
	CGRect finalFrameForFromVC = CGRectMake(initialFrameForFromVC.origin.x - initialFrameForFromVC.size.width,
											initialFrameForFromVC.origin.y,
											initialFrameForFromVC.size.width,
											initialFrameForFromVC.size.height);
	
	[containerView addSubview:toViewController.view];
	toViewController.view.frame = initialFrameForToVC;
	
	[UIView animateWithDuration:[self transitionDuration:context]
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut // Or your preferred curve
					 animations:^{
		fromViewController.view.frame = finalFrameForFromVC;
		toViewController.view.frame = finalFrameForToVC;
	} completion:^(BOOL finished) {
		BOOL wasCancelled = [context transitionWasCancelled];
		if (!wasCancelled) {
			// Only remove fromViewController's view if the transition was not cancelled.
			// If cancelled, fromViewController's view should remain.
			[fromViewController.view removeFromSuperview];
		}
		// UIKit handles viewDidAppear/Disappear calls after completeTransition is called.
		[context completeTransition:!wasCancelled];
	}];
}

@end
