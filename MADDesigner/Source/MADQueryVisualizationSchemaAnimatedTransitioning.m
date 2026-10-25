//
//  MADQueryVisualizationSchemaAnimatedTransitioning.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQueryVisualizationSchemaAnimatedTransitioning.h"
#import <UIKit/UIPresentationController.h>
#import "MADAffineTransformSwing.h"
#import "MADQueryVisualizationSchemaPresentationController.h"

@implementation MADQueryVisualizationSchemaAnimatedTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
													  presentingViewController:(UIViewController *)presenting
														  sourceViewController:(UIViewController *)source {
	return [[MADQueryVisualizationSchemaPresentationController alloc] initWithPresentedViewController:presented
																			 presentingViewController:presenting];
}

- (MADQueryVisualizationSchemaAnimatedTransitioning *)animationController {
	MADQueryVisualizationSchemaAnimatedTransitioning *animationController = [[MADQueryVisualizationSchemaAnimatedTransitioning alloc] init];
	return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
																   presentingController:(UIViewController *)presenting
																	   sourceController:(UIViewController *)source {	
	MADQueryVisualizationSchemaAnimatedTransitioning *animationController = [self animationController];
	return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	MADQueryVisualizationSchemaAnimatedTransitioning *animationController = [self animationController];
	return animationController;
}

@end

@implementation MADQueryVisualizationSchemaAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
	return 0.30;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
	UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	CGPoint center = viewControllerFrom.view.center;
	[UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
		viewControllerFrom.view.bounds = CGRectZero;
		viewControllerFrom.view.center = center;
		viewControllerFrom.view.transform = MADAffineTransformSwing();
	} completion:^(BOOL __unused finished) {
		[transitionContext completeTransition:![transitionContext transitionWasCancelled]];
	}];
}

@end
