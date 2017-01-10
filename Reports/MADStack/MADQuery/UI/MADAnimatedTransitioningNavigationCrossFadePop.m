//
//  MADAnimatedTransitioningNavigationPop.m
//  MAD Designer
//
//  Created by Michael on 1/8/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADAnimatedTransitioningNavigationCrossFadePop.h"

@implementation MADAnimatedTransitioningNavigationCrossFadePop

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5000;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];

    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromViewController.view.alpha = 0.0000f;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
