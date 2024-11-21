//
//  MADAnimatedTransitioningNavigationPush.m
//  MAD Designer
//
//  Created by Michael on 1/8/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAnimatedTransitioningNavigationCrossFadePush.h"

@implementation MADAnimatedTransitioningNavigationCrossFadePush

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)context {
	return .70;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)context {
	UIViewController *toViewController;
	toViewController = [context viewControllerForKey:UITransitionContextToViewControllerKey];
	UIView *toView = [context viewForKey:UITransitionContextToViewKey];
	
	[toViewController beginAppearanceTransition:YES animated:YES];

	[[context containerView] addSubview:toView];
	
	toView.alpha = 0.0000f;
	[UIView animateWithDuration:[self transitionDuration:context] animations:^{
		toView.alpha = 1.0000f;
	} completion:^(BOOL finished) {
		[context completeTransition:![context transitionWasCancelled]];
		[toViewController endAppearanceTransition];
	}];
}


@end
