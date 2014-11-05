//
//  MADToolboxTransitioner.m
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxTransitioner.h"
#import "MADToolboxPresentationController.h"

@interface MADToolboxTransitioningDelegate ()

@property (nonatomic, strong) UIPresentationController *presentationController;

@end

@implementation MADToolboxTransitioningDelegate

- (void)setSourceRect:(CGRect)sourceRect {
    if (CGRectEqualToRect(sourceRect, self.sourceRect) == NO) {
        if (self.presentationController && [self.presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
            ((UIPopoverPresentationController *)self.presentationController).sourceRect = sourceRect;
            [((UIPopoverPresentationController *)self.presentationController).containerView setNeedsLayout];
        }
        _sourceRect = sourceRect;
    }
}

- (UIPresentationController *)presentationControllerForPresentedViewController: (UIViewController *)presented
                                                      presentingViewController: (UIViewController *)presenting
                                                          sourceViewController: (UIViewController *)source {
    
    UIPresentationController *presentationController;
    if ((UIUserInterfaceSizeClassRegular == source.traitCollection.horizontalSizeClass &&
        UIUserInterfaceSizeClassRegular == source.traitCollection.verticalSizeClass) != NO) {
        
        presentationController = [[UIPopoverPresentationController alloc] initWithPresentedViewController: presented
                                                                                 presentingViewController: presenting];
        
        ((UIPopoverPresentationController *)presentationController).sourceView = self.sourceView;
        ((UIPopoverPresentationController *)presentationController).sourceRect = self.sourceRect;

        NSArray *allPassthoughViews =  self.passthroughViews.allObjects;
        ((UIPopoverPresentationController *)presentationController).passthroughViews = allPassthoughViews;
        ((UIPopoverPresentationController *)presentationController).permittedArrowDirections = self.permittedArrowDirections;
        ((UIPopoverPresentationController *)presentationController).delegate = self.popoverPresentationControllerDelegate;

    } else {
        presentationController = [[MADToolboxPresentationController alloc] initWithPresentedViewController: presented
                                                                                  presentingViewController: presenting];
        
        ((MADToolboxPresentationController *)presentationController).passthroughViews = self.passthroughViews;
        ((MADToolboxPresentationController *)presentationController).passthroughContainer = self.passthroughContainer;
        ((MADToolboxPresentationController *)presentationController).popoverPresentationControllerDelegate = self.popoverPresentationControllerDelegate;
    }
    self.presentationController = presentationController;
    return self.presentationController;
}

- (MADToolboxAnimatedTransitioning *)animationController {
    MADToolboxAnimatedTransitioning *animationController = [[MADToolboxAnimatedTransitioning alloc] init];
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting
                                                                       sourceController:(UIViewController *)source {
    
    MADToolboxAnimatedTransitioning *animationController = [self animationController];
    animationController.toolboxVisible = YES;
    
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {

    MADToolboxAnimatedTransitioning *animationController = [self animationController];
    animationController.toolboxVisible = NO;
    
    return animationController;
}

@end

@implementation MADToolboxAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = [fromViewController view];
    UIViewController *toViewController   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = [toViewController view];
    
    UIView *containerView = [transitionContext containerView];
    
    BOOL isToolboxVisible = self.isToolboxVisible;

    if(isToolboxVisible) {
        [containerView addSubview:toView];
    }
    
    UIViewController *animatingVC = isToolboxVisible ? toViewController : fromViewController;
    UIView *animatingView = [animatingVC view];
    
    CGRect appearedFrame = [transitionContext finalFrameForViewController:animatingVC];
    
    CGRect dismissedFrame = appearedFrame;
    dismissedFrame.origin.x += dismissedFrame.size.width;
    
    CGRect initialFrame = isToolboxVisible ? dismissedFrame : appearedFrame;
    CGRect finalFrame = isToolboxVisible ? appearedFrame : dismissedFrame;

    animatingView.frame = initialFrame;
    
    [UIView animateWithDuration: [self transitionDuration:transitionContext]
                          delay: 0
         usingSpringWithDamping: 300.0
          initialSpringVelocity: 5.0
                        options: UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{
                         animatingView.frame = finalFrame;
                    }
                     completion: ^(BOOL finished){
                         
                         if (self.toolboxVisible == NO) {

                             [fromView removeFromSuperview];
                             
                         }

                         [transitionContext completeTransition:YES];
                    }];
}

@end
