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
    return .70;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
    [toViewController beginAppearanceTransition:YES animated:YES];

    [[transitionContext containerView] addSubview:toView];
    
    toView.alpha = 0.0000f;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        toView.alpha = 1.0000f;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        [toViewController endAppearanceTransition];
    }];
}


@end
