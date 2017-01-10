//
//  MADAnimatedTransitioningNavigationPush.m
//  MAD Designer
//
//  Created by Michael on 1/8/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADAnimatedTransitioningNavigationCrossFadePush.h"

@implementation MADAnimatedTransitioningNavigationCrossFadePush

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    [[transitionContext containerView] addSubview:toViewController.view];
    
    toViewController.view.alpha = 0.0;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        toViewController.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}


@end
