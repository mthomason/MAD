//
//  MADAnimatedTransitionControllerPush.m
//  MAD Designer
//
//  Created by Michael on 1/19/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADAnimatedTransitionControllerPush.h"

@implementation MADAnimatedTransitionControllerPush

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *toViewController = [transitionContext viewControllerForKey: UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey: UITransitionContextFromViewControllerKey];
    CGRect toFrameFinal = [transitionContext finalFrameForViewController:toViewController];
    CGRect fromFrameFinal = [transitionContext finalFrameForViewController:fromViewController];
    CGRect toFrameInital = [transitionContext initialFrameForViewController:toViewController];
    CGRect fromFrameInital = [transitionContext initialFrameForViewController:fromViewController];
    
    toFrameInital = CGRectMake(toFrameFinal.origin.x + toFrameFinal.size.width, toFrameFinal.origin.y, toFrameFinal.size.width, toFrameFinal.size.height);
    fromFrameFinal = CGRectMake(fromFrameInital.origin.x - fromFrameInital.size.width, fromFrameInital.origin.y, fromFrameInital.size.width, fromFrameInital.size.height);

    [[transitionContext containerView] addSubview:toViewController.view];
    toViewController.view.frame = toFrameInital;

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromViewController.view.frame = fromFrameFinal;
        toViewController.view.frame = [transitionContext containerView].frame;
    } completion:^(BOOL finished) {
        
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        if (!wasCancelled) {
            [fromViewController.view removeFromSuperview];
        }
        [toViewController viewDidAppear:!wasCancelled];

        [transitionContext completeTransition:!wasCancelled];
    }];
}

@end
