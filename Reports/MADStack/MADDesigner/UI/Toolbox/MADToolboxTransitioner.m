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
        
        if (_presentationController &&
            [_presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
            ((UIPopoverPresentationController *)_presentationController).sourceRect = sourceRect;
        }
        _sourceRect = sourceRect;
        
    }
    
    [((UIPopoverPresentationController *)_presentationController).containerView setNeedsLayout];
    
}

- (void)setPassthroughContainers:(NSSet *)passthroughContainers {
    
    if (_passthroughContainers != passthroughContainers) {
        _passthroughContainers = passthroughContainers;
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

    UIView *passthroughContainer = _passthroughContainer;

    if (self.popoverStyle) {
        
        NSArray *allElementViews =  _passthroughViews.allObjects;
        NSArray *allContainerObjects = _passthroughContainers.allObjects;
        
        NSArray *passthroughViews = [allElementViews arrayByAddingObjectsFromArray:allContainerObjects];
        NSArray *passthroughViewsWithBackground = [passthroughViews arrayByAddingObject:passthroughContainer];
        NSArray *passthroughViewsAll = [passthroughViewsWithBackground arrayByAddingObjectsFromArray:passthroughViewsWithBackground];
        ((UIPopoverPresentationController *)_presentationController).passthroughViews = passthroughViewsAll;
        
        
    } else {
        
        ((MADToolboxPresentationController *)_presentationController).passthroughContainers = _passthroughContainers;
        ((MADToolboxPresentationController *)_presentationController).passthroughViews = _passthroughViews;
        ((MADToolboxPresentationController *)_presentationController).passthroughContainer = passthroughContainer;
        
    }
}

- (UIPresentationController *)presentationControllerForPresentedViewController: (UIViewController *)presented
                                                      presentingViewController: (UIViewController *)presenting
                                                          sourceViewController: (UIViewController *)source {
    
    UIPresentationController *presentationController;
    UIView *passthroughContainer = _passthroughContainer;
    id <UIPopoverPresentationControllerDelegate> popoverPresentationControllerDelegate;
    popoverPresentationControllerDelegate = _popoverPresentationControllerDelegate;
    
    if ((UIUserInterfaceSizeClassRegular == source.traitCollection.horizontalSizeClass &&
        UIUserInterfaceSizeClassRegular == source.traitCollection.verticalSizeClass) != NO) {
        _popoverStyle = YES;
        
        presentationController = [[UIPopoverPresentationController alloc] initWithPresentedViewController: presented
                                                                                 presentingViewController: presenting];
        
        ((UIPopoverPresentationController *)presentationController).sourceView = self.sourceView;
        ((UIPopoverPresentationController *)presentationController).sourceRect = self.sourceRect;

        NSArray *allElementViews =  self.passthroughViews.allObjects;
        NSArray *allContainerObjects = self.passthroughContainers.allObjects;
        NSArray *passthroughViews = [allElementViews arrayByAddingObjectsFromArray:allContainerObjects];
        NSArray *passthroughViewsWithBackground = [passthroughViews arrayByAddingObject:passthroughContainer];
        ((UIPopoverPresentationController *)presentationController).passthroughViews = [passthroughViewsWithBackground arrayByAddingObjectsFromArray:passthroughViewsWithBackground];
        ((UIPopoverPresentationController *)presentationController).permittedArrowDirections = self.permittedArrowDirections;
        ((UIPopoverPresentationController *)presentationController).delegate = popoverPresentationControllerDelegate;

    } else {
        _popoverStyle = NO;
        presentationController = [[MADToolboxPresentationController alloc] initWithPresentedViewController: presented
                                                                                  presentingViewController: presenting];
        
        ((MADToolboxPresentationController *)presentationController).container = self.container;
        ((MADToolboxPresentationController *)presentationController).passthroughContainers = self.passthroughContainers;
        ((MADToolboxPresentationController *)presentationController).passthroughViews = self.passthroughViews;
        ((MADToolboxPresentationController *)presentationController).passthroughContainer = passthroughContainer;
        ((MADToolboxPresentationController *)presentationController).popoverPresentationControllerDelegate = popoverPresentationControllerDelegate;
    }
    _presentationController = presentationController;
    return _presentationController;
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

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)context {
    
    UITabBarController *tabBarController;
    UINavigationController *toolboxNavigationController, *navController;
    
    BOOL isToolboxVisible = _toolboxVisible;
    if (isToolboxVisible == NO) {
        navController = [context viewControllerForKey:UITransitionContextToViewControllerKey];
        tabBarController = navController.viewControllers.firstObject;
        toolboxNavigationController = (UINavigationController *)[context viewControllerForKey:UITransitionContextFromViewControllerKey];
    } else {
        navController = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
        tabBarController = navController.viewControllers.firstObject;
        toolboxNavigationController = (UINavigationController *)[context viewControllerForKey:UITransitionContextToViewControllerKey];
    }
    
    UIView *containerView = context.containerView;
    
    BOOL showOnSide = [((MADToolboxPresentationController *)toolboxNavigationController.presentationController) showOnSide];

    if (isToolboxVisible) {
        [containerView addSubview:toolboxNavigationController.view];
    }
    
    CGRect appearedFrame = [context finalFrameForViewController:toolboxNavigationController];
    CGRect dismissedFrame = appearedFrame;
    
    if (showOnSide) {
        dismissedFrame.origin.x += dismissedFrame.size.width;
    } else {
        dismissedFrame.origin.y += dismissedFrame.size.height;
    }
    
    CGRect initialFrame = isToolboxVisible ? dismissedFrame : appearedFrame;
    CGRect finalFrame = isToolboxVisible ? appearedFrame : dismissedFrame;

    toolboxNavigationController.view.frame = initialFrame;

    UIViewController <MADViewControllerProtocol> *designer;
    designer = tabBarController.selectedViewController;
    [designer setHidesStatusBar: isToolboxVisible];
    
    typeof(toolboxNavigationController) __weak weakNavController = toolboxNavigationController;
    [UIView animateWithDuration: [self transitionDuration:context]
                          delay: 0.0000f
         usingSpringWithDamping: 300.0000f
          initialSpringVelocity: 5.0000f
                        options: UIViewAnimationOptionAllowUserInteraction |
                                    UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{

        [tabBarController setNeedsStatusBarAppearanceUpdate];
        weakNavController.view.frame = finalFrame;

    } completion: ^(BOOL finished) {
        
        [designer.view setNeedsLayout];    // Give designer scroll view a chance to update insets
                         
        if (isToolboxVisible == NO) {
            [weakNavController.view removeFromSuperview];
        }

        [context completeTransition:YES];
    }];
}

@end
