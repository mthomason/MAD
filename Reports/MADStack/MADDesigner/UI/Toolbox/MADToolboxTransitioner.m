//
//  MADToolboxTransitioner.m
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxTransitioner.h"
#import "MADToolboxPresentationController.h"
#import "MADViewControllerProtocol.h"

@interface MADToolboxTransitioningDelegate ()

@property (nonatomic, strong, readwrite) UIPresentationController *presentationController;
@property (nonatomic, assign, readwrite) BOOL popoverStyle;

@end

@implementation MADToolboxTransitioningDelegate

- (void)setSourceRect:(CGRect)sourceRect {

    if (CGRectEqualToRect(sourceRect, self.sourceRect) == NO) {
        
        if (self.presentationController && [self.presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
            ((UIPopoverPresentationController *)self.presentationController).sourceRect = sourceRect;
        }
        _sourceRect = sourceRect;
        
    }
    
    [((UIPopoverPresentationController *)self.presentationController).containerView setNeedsLayout];
    
}

- (void)setPassthoughContainers:(NSSet *)passthoughContainers {
    
    if (_passthoughContainers != passthoughContainers) {
        _passthoughContainers = passthoughContainers;
        [self updatePassthroughViews];
    }
    
}

- (void)setPassthroughContainer:(UIView *)passthroughContainer {
    
    if (_passthroughContainer != passthroughContainer) {
        _passthroughContainer = passthroughContainer;
        [self updatePassthroughViews];
    }
    
}

- (void)setPassthroughViews:(NSSet *)passthroughViews {
    
    if (_passthroughViews != passthroughViews) {
        _passthroughViews = passthroughViews;
        [self updatePassthroughViews];
    }
    
}

- (void)updatePassthroughViews {
    if (self.popoverStyle) {
        
        NSArray *allElementViews =  self.passthroughViews.allObjects;
        NSArray *allContainerObjects = self.passthoughContainers.allObjects;
        NSArray *passthoughViews = [allElementViews arrayByAddingObjectsFromArray:allContainerObjects];
        NSArray *passthoughViewsWithBackground = [passthoughViews arrayByAddingObject:self.passthroughContainer];
        NSArray *passthroughViewsAll = [passthoughViewsWithBackground arrayByAddingObjectsFromArray:passthoughViewsWithBackground];
        ((UIPopoverPresentationController *)self.presentationController).passthroughViews = passthroughViewsAll;
        
        
    } else {
        
        ((MADToolboxPresentationController *)self.presentationController).passthroughContainers = self.passthoughContainers;
        ((MADToolboxPresentationController *)self.presentationController).passthroughViews = self.passthroughViews;
        ((MADToolboxPresentationController *)self.presentationController).passthroughContainer = self.passthroughContainer;
        
    }
}

- (UIPresentationController *)presentationControllerForPresentedViewController: (UIViewController *)presented
                                                      presentingViewController: (UIViewController *)presenting
                                                          sourceViewController: (UIViewController *)source {
    
    UIPresentationController *presentationController;
    if ((UIUserInterfaceSizeClassRegular == source.traitCollection.horizontalSizeClass &&
        UIUserInterfaceSizeClassRegular == source.traitCollection.verticalSizeClass) != NO) {
        self.popoverStyle = YES;
        
        presentationController = [[UIPopoverPresentationController alloc] initWithPresentedViewController: presented
                                                                                 presentingViewController: presenting];
        
        ((UIPopoverPresentationController *)presentationController).sourceView = self.sourceView;
        ((UIPopoverPresentationController *)presentationController).sourceRect = self.sourceRect;

        NSArray *allElementViews =  self.passthroughViews.allObjects;
        NSArray *allContainerObjects = self.passthoughContainers.allObjects;
        NSArray *passthoughViews = [allElementViews arrayByAddingObjectsFromArray:allContainerObjects];
        NSArray *passthoughViewsWithBackground = [passthoughViews arrayByAddingObject:self.passthroughContainer];
        ((UIPopoverPresentationController *)presentationController).passthroughViews = [passthoughViewsWithBackground arrayByAddingObjectsFromArray:passthoughViewsWithBackground];
        ((UIPopoverPresentationController *)presentationController).permittedArrowDirections = self.permittedArrowDirections;
        ((UIPopoverPresentationController *)presentationController).delegate = self.popoverPresentationControllerDelegate;

    } else {
        self.popoverStyle = NO;
        presentationController = [[MADToolboxPresentationController alloc] initWithPresentedViewController: presented
                                                                                  presentingViewController: presenting];
        
        ((MADToolboxPresentationController *)presentationController).container = self.container;
        ((MADToolboxPresentationController *)presentationController).passthroughContainers = self.passthoughContainers;
        ((MADToolboxPresentationController *)presentationController).passthroughViews = self.passthroughViews;
        ((MADToolboxPresentationController *)presentationController).passthroughContainer = self.passthroughContainer;
        ((MADToolboxPresentationController *)presentationController).popoverPresentationControllerDelegate = self.popoverPresentationControllerDelegate;
    }
    self.presentationController = presentationController;
    return self.presentationController;
}

- (MADToolboxAnimatedTransitioning *)animationController {
    MADToolboxAnimatedTransitioning *animationController = [[MADToolboxAnimatedTransitioning alloc] init];
    animationController.passthroughContainer = self.passthroughContainer;
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

- (BOOL)showOnSide {
    return YES;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    UITabBarController *tabBarController;
    UINavigationController *toolboxNavigationController;
    BOOL isToolboxVisible = self.isToolboxVisible;
    if (isToolboxVisible == NO) {
        tabBarController = (UITabBarController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        toolboxNavigationController = (UINavigationController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    } else {
        tabBarController = (UITabBarController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        toolboxNavigationController = (UINavigationController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    }
    
    UIView *containerView = transitionContext.containerView;
    
    BOOL showOnSide = [((MADToolboxPresentationController *)toolboxNavigationController.presentationController) showOnSide];

    if (isToolboxVisible) {
        [containerView addSubview:toolboxNavigationController.view];
    }
    
    CGRect appearedFrame = [transitionContext finalFrameForViewController:toolboxNavigationController];
    CGRect dismissedFrame = appearedFrame;
    
    if (showOnSide) {
        dismissedFrame.origin.x += dismissedFrame.size.width;
    } else {
        dismissedFrame.origin.y += dismissedFrame.size.height;
    }
    
    CGRect initialFrame = isToolboxVisible ? dismissedFrame : appearedFrame;
    CGRect finalFrame = isToolboxVisible ? appearedFrame : dismissedFrame;

    toolboxNavigationController.view.frame = initialFrame;

    UINavigationController *designerNavigationController = (UINavigationController *)tabBarController.selectedViewController;
    UIViewController <MADViewControllerProtocol> *designer = designerNavigationController.viewControllers.firstObject;
    [designer setHidesStatusBar: isToolboxVisible];
    [UIView animateWithDuration: [self transitionDuration:transitionContext]
                          delay: 0
         usingSpringWithDamping: 300.0
          initialSpringVelocity: 5.0
                        options: UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{
                         
                         [tabBarController setNeedsStatusBarAppearanceUpdate];
                         toolboxNavigationController.view.frame = finalFrame;

                     }
                     completion: ^(BOOL finished) {
                         
                         [designer.view setNeedsLayout];    // Give designer scroll view a chance to update insets
                         
                         if (isToolboxVisible == NO) {
                             [toolboxNavigationController.view removeFromSuperview];
                         }

                         [transitionContext completeTransition:YES];
                         
                    }];
}

@end
