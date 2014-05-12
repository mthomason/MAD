//
//  MTViewControllerActivitySpinner.m
//  MAD
//
//  Created by Michael Thomason on 9/18/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerActivitySpinner.h"

@interface MTViewControllerActivitySpinner ()

@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;

@end

@implementation MTViewControllerActivitySpinner

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self activitySpinner] startAnimating];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self activitySpinner] stopAnimating];
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [UIView animateWithDuration:0.4000f animations:^{
        [[viewControllerFrom view] setAlpha:0.0000f];
    } completion:^(BOOL finished) {
        [[viewControllerFrom view] removeFromSuperview];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    
}

- (void)animationEnded:(BOOL)transitionCompleted { }

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4000f;
}

@end
