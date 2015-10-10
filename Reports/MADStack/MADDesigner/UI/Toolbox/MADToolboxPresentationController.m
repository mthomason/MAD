//
//  MADToolboxPresentationController.m
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxPresentationController.h"
#import "MADToolboxTransitioner.h"
#import "MADDimmingView.h"
#import "MADViewControllerProtocol.h"

@interface MADToolboxPresentationController ()
    <UIGestureRecognizerDelegate>

    @property (nonatomic, strong) UIGestureRecognizer *dismissGestureReconizer;
    @property (nonatomic, weak) UIViewController <MADViewControllerProtocol> *designerViewController;

@end

@implementation MADToolboxPresentationController



+ (NSString *)keyPathPassthroughContainer {
    NSString *passthroughContainer = NSStringFromSelector(@selector(passthroughContainer));
    return passthroughContainer;
}

+ (NSString *)keyPathPassthroughViews {
    NSString *passthroughViews = NSStringFromSelector(@selector(passthroughViews));
    return passthroughViews;
}

- (void)dealloc { }

- (void)presentationTransitionDidEnd:(BOOL)completed {
    [super presentationTransitionDidEnd:completed];
    
}

- (void)dismissalTransitionDidEnd:(BOOL)completed {
    [super presentationTransitionDidEnd:completed];
    __weak MADToolboxPresentationController *weakself = self;
    [weakself removeObserver: weakself
                  forKeyPath: [MADToolboxPresentationController keyPathPassthroughContainer]];
    [weakself removeObserver: weakself
                  forKeyPath: [MADToolboxPresentationController keyPathPassthroughViews]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:[MADToolboxPresentationController keyPathPassthroughViews]]) {
        
        self.dimmingView.passthoughViews = self.passthroughViews;
        
    } else if ([keyPath isEqualToString:[MADToolboxPresentationController keyPathPassthroughContainer]]) {

        self.dimmingView.passthroughContainer = self.passthroughContainer;
        self.dimmingView.passthoughContainers = self.passthroughContainers;
        self.dimmingView.container = self.container;
    }
}

- (instancetype)initWithPresentedViewController: (UIViewController *)presentedViewController
                       presentingViewController: (UIViewController *)presentingViewController; {

    self = [super initWithPresentedViewController: presentedViewController
                         presentingViewController: presentingViewController];
    if (self) {

        MADDimmingView *dimmingView = [[MADDimmingView alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                              action: @selector(dimmingViewTapped:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [dimmingView addGestureRecognizer:tap];
        
        self.dimmingView = dimmingView;

        [self addObserver: self
               forKeyPath: [MADToolboxPresentationController keyPathPassthroughContainer]
                  options: 0
                  context: NULL];

        [self addObserver: self
               forKeyPath: [MADToolboxPresentationController keyPathPassthroughViews]
                  options: 0
                  context: NULL];

        
        UISwipeGestureRecognizer *down = [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                                                                   action: @selector(handleSwipeAway:)];
        down.direction = UISwipeGestureRecognizerDirectionDown;
        [presentedViewController.view addGestureRecognizer:down];
        self.dismissGestureReconizer = down;
        
        ((UINavigationController *)presentedViewController).interactivePopGestureRecognizer.enabled = NO;
//        presentedViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    }
    
    return self;
}

- (void)handleSwipeAway:(UIGestureRecognizer *)gestureReconizer {
    [self dismiss];
}

- (void)presentationTransitionWillBegin {

    UINavigationController *navController = (UINavigationController *)self.presentingViewController;;
    UITabBarController *tabBarController = navController.viewControllers.firstObject;
    UIViewController <MADViewControllerProtocol> *designer = tabBarController.selectedViewController;
    self.designerViewController = designer;
    
    UIView *containerView = self.containerView;
    UIViewController *presentedViewController = self.presentedViewController;
    BOOL showOnSide = [self showOnSide];
    self.presentingViewController.modalTransitionStyle = showOnSide ?
                                                        UIModalTransitionStyleFlipHorizontal :
                                                        UIModalTransitionStyleCoverVertical;
    self.dimmingView.frame = containerView.bounds;
    self.dimmingView.alpha = 0.0000f;

    [containerView insertSubview:self.dimmingView atIndex:0];
    
    if (presentedViewController.transitionCoordinator) {
        
        __weak MADToolboxPresentationController *weakself = self;
        [presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

            weakself.dimmingView.alpha = 1.0000f;

        } completion:nil];

    } else {
        self.dimmingView.alpha = 1.0000f;
    }
}

- (void)dismissalTransitionWillBegin {

    if (self.presentedViewController.transitionCoordinator) {

        __weak MADToolboxPresentationController *weakself = self;
        [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    
            weakself.dimmingView.alpha = 0.0;
        
        } completion:nil];
        
    } else {
        self.dimmingView.alpha = 0.0;
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyle {
    return UIModalPresentationCustom;
}

- (CGSize)sizeForChildContentContainer:(id <UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {

    return [self showOnSide] ?
        CGSizeMake(MAX(floor(parentSize.width / 3.0000f), self.presentedViewController.preferredContentSize.width) , parentSize.height) :
        CGSizeMake(MAX(parentSize.width, self.presentedViewController.preferredContentSize.width),
                   MIN(self.presentedViewController.preferredContentSize.height, floor(parentSize.height / 2.0000f)));
}

- (void)containerViewWillLayoutSubviews {
    [super containerViewWillLayoutSubviews];
    self.dimmingView.frame = self.containerView.bounds;
    self.presentedView.frame = [self frameOfPresentedViewInContainerView];
}

- (void)containerViewDidLayoutSubviews {
    [super containerViewDidLayoutSubviews];
}

- (BOOL)shouldPresentInFullscreen { return YES; }

- (BOOL)showOnSide {
    return self.presentingViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
}

- (CGRect)frameOfPresentedViewInContainerView {

    CGRect presentedViewFrame = CGRectZero;
    CGRect containerBounds = self.containerView.bounds;
    
    presentedViewFrame.size = [self sizeForChildContentContainer: (UIViewController<UIContentContainer> *)self.presentedViewController
                                         withParentContainerSize: containerBounds.size];
    
    presentedViewFrame.origin.x = [self showOnSide] ?
                                        containerBounds.size.width - presentedViewFrame.size.width :
                                        CGPointZero.x;
    
    presentedViewFrame.origin.y = [self showOnSide] ?
                                        CGPointZero.y :
                                        containerBounds.size.height - presentedViewFrame.size.height;
    
    
    return presentedViewFrame;
}

- (void)dimmingViewTapped:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if ([self.popoverPresentationControllerDelegate popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)self]) {
            [self dismiss];
        }
    }
}

- (void)dismiss {
    __weak MADToolboxPresentationController *weakself = self;
    [((UIViewController <MADViewControllerProtocol> *)self.designerViewController) setHidesStatusBar: NO];
    [self.presentingViewController dismissViewControllerAnimated: YES
                                                      completion: ^{
                                                          [weakself.popoverPresentationControllerDelegate popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)weakself];
                                                      }];
}

@end
