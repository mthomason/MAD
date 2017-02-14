//
//  MADExplorerAnimated.m
//  MAD Designer
//
//  Created by Michael on 1/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADExplorerAnimated.h"
#import <UIKit/UITabBarController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIToolbar.h>

#import "MADExplorerController.h"

@implementation MADExplorerAnimatedCrossFadePop {
    BOOL _hideToolbar;
}

- (instancetype)initToolbar:(BOOL)showToolbar {
    if (self = [super init]) {
        _hideToolbar = !showToolbar;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.7000;
}

@end


@implementation MADExplorerAnimatedCrossFadePush {
    BOOL _hideToolbar;
}

- (instancetype)initToolbar:(BOOL)showToolbar {
    if (self = [super init]) {
        _hideToolbar = !showToolbar;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.7000;
}

@end

@implementation MADExplorerAnimated

static inline CGRect CGRectTabBar(CGRect rect, BOOL pushing);
static inline CGRect CGRectTabBarOffscreen(CGRect rect);
static inline CGRect CGRectTabBarOnscreen(CGRect rect);

static inline CGRect CGRectTabBar(CGRect rect, BOOL pushing)  {
    return pushing ? CGRectTabBarOnscreen(rect) : CGRectTabBarOffscreen(rect);
}

static inline CGRect CGRectTabBarOffscreen(CGRect rect)  {
    return CGRectOffset(rect, CGSizeZero.width, rect.size.height);
}

static inline CGRect CGRectTabBarOnscreen(CGRect rect)  {
    return CGRectOffset(rect, CGSizeZero.width, rect.size.height);
}

+ (instancetype)newFileExplorerAnimatedShowToolbar:(BOOL)showToolbar pushing:(BOOL)pushing {
    id instance = pushing ? [[MADExplorerAnimatedCrossFadePush alloc] initToolbar:showToolbar] :
                            [[MADExplorerAnimatedCrossFadePop alloc] initToolbar:showToolbar];
    return instance;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 1.70;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromViewController, *toViewController;
    UIView *toView;
    
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    BOOL pushingFileExplorer = NO, poppingFileExplorer = NO,
    pushingTabBarController = NO, poppingTabBarController = NO;
    if ([toViewController isKindOfClass:[MADExplorerController class]]) {
        pushingFileExplorer = YES;
        poppingFileExplorer = NO;
    }
    
    if ([fromViewController isKindOfClass:[MADExplorerController class]]) {
        pushingFileExplorer = NO;
        poppingFileExplorer = YES;
    }
    
    if ([toViewController isKindOfClass:[UITabBarController class]]) {
        pushingTabBarController = YES;
        poppingTabBarController = NO;
    } else if ([fromViewController isKindOfClass:[UITabBarController class]]) {
        pushingTabBarController = NO;
        poppingTabBarController = YES;
    }
    
    toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
    [[transitionContext containerView] addSubview:toView];
    
    void(^animationToolbarPushing)(UINavigationController *, BOOL);
    animationToolbarPushing = ^(UINavigationController *navigationController, BOOL pushFileExplorder){
        if (pushFileExplorder) {
            navigationController.toolbar.alpha = 0.0;
            [navigationController setToolbarHidden: NO animated:NO];
        }
    };
    
    void(^animationToolbarPopping)(UINavigationController *, BOOL);
    animationToolbarPopping = ^(UINavigationController *navigationController, BOOL popFileExplorder){
        if (popFileExplorder) {
            navigationController.toolbar.alpha = 1.0;
            [navigationController setToolbarHidden: NO animated:NO];
        }
    };
    
    
    animationToolbarPushing(toViewController.navigationController, pushingFileExplorer);
    animationToolbarPopping(fromViewController.navigationController, poppingFileExplorer);
    
    toView.alpha = 0.0;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{

        toView.alpha = 1.0;
        if (pushingFileExplorer) {
            toViewController.navigationController.toolbar.alpha = 1.0;
        } else if (poppingFileExplorer) {
            fromViewController.navigationController.toolbar.alpha = 0.0;
        }
        [toViewController.view setNeedsLayout];
        
    } completion:^(BOOL finished) {
        if (finished) {
            BOOL canceled;
            id fromView = [transitionContext viewForKey: UITransitionContextFromViewKey];

            if (!(canceled = [transitionContext transitionWasCancelled])) {
                if (pushingFileExplorer) {
                    [toViewController.navigationController setToolbarHidden: NO animated:NO];
                } else if (poppingFileExplorer) {
                    [fromViewController.navigationController setToolbarHidden: YES animated:NO];
                }
                [fromView removeFromSuperview];
            }
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            
        }
    }];
}

@end
