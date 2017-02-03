//
//  MADAnimatedTransitioningNavigationPop.m
//  MAD Designer
//
//  Created by Michael on 1/8/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADAnimatedTransitioningNavigationCrossFadePop.h"

@implementation MADAnimatedTransitioningNavigationCrossFadePop

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)context {
    return 0.5000;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)context {
    UIViewController *fromViewController;
    fromViewController = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UIView *toView = [context viewForKey: UITransitionContextToViewKey];
    UIView *fromView = [context viewForKey: UITransitionContextFromViewKey];
    [[context containerView] addSubview:toView];
    [[context containerView] insertSubview:toView belowSubview:fromView];

    [UIView animateWithDuration:[self transitionDuration:context] animations:^{
        fromViewController.view.alpha = 0.0000f;
    } completion:^(BOOL finished) {
        [context completeTransition:![context transitionWasCancelled]];
    }];
}

@end
