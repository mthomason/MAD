//
//  MADExplorerAnimatedTransitioning.m
//  MAD Designer
//
//  Created by Michael on 8/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADExplorerAnimatedTransitioning.h"
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/UIView.h>
#import <MADCocoaExtensions/UIView+Animations.h>

@implementation MADExplorerAnimatedTransitioningDelegate

- (MADExplorerAnimatedTransitioning *)animationController {
    MADExplorerAnimatedTransitioning *animationController;
    animationController = [[MADExplorerAnimatedTransitioning alloc] init];
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting
                                                                       sourceController:(UIViewController *)source {
    MADExplorerAnimatedTransitioning *animationController = [self animationController];
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    MADExplorerAnimatedTransitioning *animationController = [self animationController];
    return animationController;
}

@end

@implementation MADExplorerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.70;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *viewControllerFrom, *viewControllerTo;
    UIView *viewTo, *viewFrom, *containerView;
    
    viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    viewTo = [transitionContext viewForKey:UITransitionContextToViewKey];
    viewFrom = [transitionContext viewForKey:UITransitionContextFromViewKey];


    CGRect initalFrameFrom = [transitionContext initialFrameForViewController:viewControllerFrom];
    CGRect initalFrameTo = [transitionContext initialFrameForViewController:viewControllerTo];
    CGRect finalFrameFrom = [transitionContext finalFrameForViewController:viewControllerFrom];
    CGRect finalFrameTo = [transitionContext finalFrameForViewController:viewControllerTo];
    
    containerView = transitionContext.containerView;
    
    viewFrom.frame = initalFrameFrom;
    viewTo.frame = finalFrameTo;
    viewTo.backgroundColor = [UIColor clearColor];
    viewTo.layer.shadowPath = nil;
    viewTo.layer.shadowColor = nil;
    viewTo.tintColor = [UIColor whiteColor];
    
    //UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    //UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
    //visualEffectsView.frame = finalFrameTo;
    //viewTo addSubview:visualEffectsView];
    //visualEffectsView.autoresizingMask = MADViewAutoresizingFlexable();
    //viewTo.transform = transitionContext.targetTransform;;
    //[containerView addSubview:viewTo];
    [[transitionContext containerView] addSubview:viewControllerTo.view];
    
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0
                        options: UIViewAnimationOptionTransitionFlipFromRight |UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         
        viewControllerTo.view.transform = transitionContext.targetTransform;
                         //viewControllerFrom.view.bounds = CGRectZero;
        //UIView *viewContainer = [[viewTo subviews] objectAtIndex:0];
        //viewContainer.backgroundColor = [UIColor clearColor];
        //viewContainer.alpha = 0.0;
        //viewTo.alpha = 0.0;
        viewFrom.frame = finalFrameFrom;
        viewTo.frame = finalFrameTo;
        //viewControllerFrom.view.center = center;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
