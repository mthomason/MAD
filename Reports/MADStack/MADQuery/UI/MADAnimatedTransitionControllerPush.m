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
    
    UIViewController *toViewController, *fromViewController;
    toViewController = [context viewControllerForKey: UITransitionContextToViewControllerKey];
    fromViewController = [context viewControllerForKey: UITransitionContextFromViewControllerKey];
    CGRect toFrameFinal = [context finalFrameForViewController:toViewController];
    CGRect fromFrameFinal;
    CGRect toFrameInital;
    CGRect fromFrameInital = [context initialFrameForViewController:fromViewController];
    
    toFrameInital = CGRectMake(toFrameFinal.origin.x + toFrameFinal.size.width,
                               toFrameFinal.origin.y,
                               toFrameFinal.size.width, toFrameFinal.size.height);
    fromFrameFinal = CGRectMake(fromFrameInital.origin.x - fromFrameInital.size.width,
                                fromFrameInital.origin.y,
                                fromFrameInital.size.width, fromFrameInital.size.height);

    [[context containerView] addSubview:toViewController.view];
    toViewController.view.frame = toFrameInital;

    [UIView animateWithDuration:[self transitionDuration:context] animations:^{
        fromViewController.view.frame = fromFrameFinal;
        toViewController.view.frame = [context containerView].frame;
    } completion:^(BOOL finished) {
        
        BOOL wasCancelled = [context transitionWasCancelled];
        if (!wasCancelled) {
            [fromViewController.view removeFromSuperview];
        }
        [toViewController viewDidAppear:!wasCancelled];

        [context completeTransition:!wasCancelled];
    }];
}

@end
