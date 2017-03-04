//
//  MADQueryVisualizationPresentationController.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/9/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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
        //[[self dimmingView] setAlpha:1.0];
    } completion:nil];
    
    // Using a custom animation, animate in our jaguar print
    
    //[self moveJaguarPrintToPresentedPosition:NO];
    
    [UIView animateWithDuration:1.0 animations:^{
        //[self moveJaguarPrintToPresentedPosition:YES];
    }];
}

- (void)containerViewWillLayoutSubviews {
    //[[self dimmingView] setFrame:[[self containerView] bounds]];
    //[[self presentedView] setFrame:[self frameOfPresentedViewInContainerView]];
    //[self moveJaguarPrintToPresentedPosition:YES];
}

- (void)containerViewDidLayoutSubviews {
   /* CGPoint bigFlowerCenter = [[self dimmingView] frame].origin;
    bigFlowerCenter.x += [[[self bigFlowerImageView] image] size].width / 4.0;
    bigFlowerCenter.y += [[[self bigFlowerImageView] image] size].height / 4.0;
    
    [[self bigFlowerImageView] setCenter:bigFlowerCenter];
    
    CGRect carlFrame = [[self carlImageView] frame];
    carlFrame.origin.y = [[self dimmingView] bounds].size.height - carlFrame.size.height;
    
    [[self carlImageView] setFrame:carlFrame];*/
}

- (void)dismissalTransitionWillBegin {
    [super dismissalTransitionWillBegin];
    
    // In -dismissalTransitionWillBegin, we want to undo what we did in
    // -presentationTransitionWillBegin. Fade our dimming view's alpha back to 0
    [[[self presentedViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //[[self dimmingView] setAlpha:0.0];
    } completion:nil];
}

@end
