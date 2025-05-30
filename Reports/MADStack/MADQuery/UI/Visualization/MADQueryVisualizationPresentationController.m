//
//  MADQueryVisualizationPresentationController.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/9/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryVisualizationPresentationController.h"

@implementation MADQueryVisualizationPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController {
	if(self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController]) {

	}
	return self;
}

- (CGRect)frameOfPresentedViewInContainerView {
	return [super frameOfPresentedViewInContainerView];
}

- (void)presentationTransitionWillBegin {
	[super presentationTransitionWillBegin];
	
	[[[self presentedViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

	} completion:nil];
	
	[UIView animateWithDuration:1.0 animations:^{

	}];
}

- (void)containerViewWillLayoutSubviews { }

- (void)containerViewDidLayoutSubviews { }

- (void)dismissalTransitionWillBegin {
	[super dismissalTransitionWillBegin];

	[[[self presentedViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

	} completion:nil];
}

@end
