//
//  MADQueryVisualizationSchemaAnimatedTransitioning.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationSchemaAnimatedTransitioning.h"
#import "CGAffineTransform+Common.h"

@implementation MADQueryVisualizationSchemaAnimatedTransitioning

// This is used for percent driven interactive transitions, as well as for container controllers that have companion animations that might need to
// synchronize with the main animation.
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.30;
}

// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    //UIViewController *viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGPoint center = viewControllerFrom.view.center;

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        viewControllerFrom.view.bounds = CGRectZero;
        viewControllerFrom.view.center = center;
        viewControllerFrom.view.transform = CGAffineTransformSwing();
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
