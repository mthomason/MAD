//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarController.h"

#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIResponder.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UITabBarItem.h>

#import "MADNavigationController.h"

#import "MADQueryBuilderSplitViewController.h"

@interface MADTabBarController ()
    <UITabBarControllerDelegate>

@end

@implementation MADTabBarController {
    BOOL _navigationItemInitialized;
    NSUInteger _lastSelectedIndex;
}

@synthesize document = _document;

+ (instancetype)newTabBarController:(MADocument *)document prompt:(NSString *)prompt {
    
    UIStoryboard *storyboard;
    id controller;
    storyboard = [UIStoryboard storyboardWithName: @"MADDesigner"
                                           bundle: [NSBundle mainBundle]];
    controller = [storyboard instantiateViewControllerWithIdentifier: @"MADIdentifierTabBarController"];
    return controller;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canResignFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(done:)) {
        return YES;
    }
    return NO;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _navigationItemInitialized = NO;
        _lastSelectedIndex = NSNotFound;
    }
    return self;
}

- (void)setViewControllerDelegate:(id <MADViewControllerStandardProtocol>)delegate {
    if (_viewControllerDelegate != delegate) {
        _viewControllerDelegate = delegate;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;

    self.view.backgroundColor = [UIColor purpleColor];
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    MADocument *document = self.document;
    
    MADQueryBuilderSplitViewController *splitViewController;
    MADNavigationController *navControllerViewer;
    MADNavigationController *navControllerDesigner;
    
    NSMutableArray <__kindof UIViewController *> *tabBarViewControllers;
    tabBarViewControllers = [[NSMutableArray <__kindof UIViewController *> alloc] initWithCapacity: 3];
    
    splitViewController =  [MADQueryBuilderSplitViewController newQueryBuilderSplitViewController:document];
    [tabBarViewControllers addObject: splitViewController];
    
    navControllerDesigner = [MADNavigationController newNavigationController:MADNavigationControllerTypeDesigner];
    navControllerDesigner.document = document;
    [tabBarViewControllers addObject: navControllerDesigner];
    
    navControllerViewer = [MADNavigationController newNavigationController:MADNavigationControllerTypeViewer];
    navControllerViewer.document = document;
    [tabBarViewControllers addObject: navControllerViewer];

    id <MADViewControllerStandardProtocol> delegate;
    delegate = self.viewControllerDelegate;

    navControllerViewer.viewControllerDelegate = delegate;
    splitViewController.viewControllerDelegate = delegate;
    [self setViewControllers: tabBarViewControllers animated: animated];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    void (^transition)(id<UIViewControllerTransitionCoordinatorContext>);
    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) {
            [self.view setNeedsDisplay];
        };
    } else {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) { };
    }
    UIView *toView = [coordinator viewForKey:UITransitionContextToViewKey];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [toView setNeedsDisplay];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

    }];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    UINavigationItem *navigationItem = self.navigationItem;

    if (navigationItem.leftBarButtonItem)
        [navigationItem setLeftBarButtonItem: nil animated: animated];

    if (navigationItem.rightBarButtonItem)
        [navigationItem setRightBarButtonItem: nil animated: animated];

    for (id viewController in self.viewControllers) {
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            [((UINavigationController *)viewController) dismissViewControllerAnimated:animated completion:^{
                
            }];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    [self setViewControllers: nil animated: animated];
    [self.navigationItem setLeftBarButtonItem:nil animated:animated];
    [self.navigationItem setRightBarButtonItem:nil animated:animated];;
}

- (id <UILayoutSupport>)topLayoutGuide {
    UINavigationController __weak *navigationController = self.navigationController;
    return navigationController.topLayoutGuide;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

#pragma mark -
#pragma mark MADViewControllerStandardProtocol

- (void)viewControllerDidFinish:(id)sender {
    [self.viewControllerDelegate viewControllerDidFinish: nil];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController
    shouldSelectViewController:(UIViewController *)viewController {
    
    if ([viewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
        id document = ((id <MADViewControllerDocumentProtocol>)tabBarController).document;
        if (document && [tabBarController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
            ((id <MADViewControllerDocumentProtocol>)viewController).document = document;
        }
    }
    
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController {
    const int8_t MADIndexQuery = 0;
    const int8_t MADIndexDesigner = 1;
    const int8_t MADIndexViewer = 2;

    _lastSelectedIndex = tabBarController.selectedIndex;
    switch (tabBarController.selectedIndex) {
        case MADIndexQuery:
            tabBarController.edgesForExtendedLayout = UIRectEdgeAll;
            break;
        case MADIndexDesigner:
            tabBarController.edgesForExtendedLayout = UIRectEdgeAll;
            break;
        case MADIndexViewer:
            tabBarController.edgesForExtendedLayout = UIRectEdgeBottom;
            break;
            
        default:
            break;
    }
}

- (nullable id <UIViewControllerInteractiveTransitioning>)tabBarController:(UITabBarController *)tabBarController
                               interactionControllerForAnimationController: (id <UIViewControllerAnimatedTransitioning>)animationController {
    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController
                     animationControllerForTransitionFromViewController:(UIViewController *)fromVC
                                                       toViewController:(UIViewController *)toVC  {
    /*NSArray *viewControllers = tabBarController.viewControllers;
    if ([viewControllers indexOfObject:toVC] > [viewControllers indexOfObject:fromVC]) {
        // The incoming view controller succeeds the outgoing view controller,
        // slide towards the left.
        return [[MADDesignerAnimatedTransitioning alloc] init];
    } else {
        return nil;
    }*/
    return nil;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    UIView *fromView;
    UIView *toView;
    
    // In iOS 8, the viewForKey: method was introduced to get views that the
    // animator manipulates.  This method should be preferred over accessing
    // the view of the fromViewController/toViewController directly.
    //if ([transitionContext respondsToSelector:@selector(viewForKey:)]) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    //} else {
    //    fromView = fromViewController.view;
    //    toView = toViewController.view;
    //}
    
    CGRect fromFrame = [transitionContext initialFrameForViewController:fromViewController];
    CGRect toFrame = [transitionContext finalFrameForViewController:toViewController];
    
    // Based on the configured targetEdge, derive a normalized vector that will
    // be used to offset the frame of the view controllers.
    CGVector offset;
    //if (self.targetEdge == UIRectEdgeLeft)
    //    offset = CGVectorMake(-1.f, 0.f);
    //else if (self.targetEdge == UIRectEdgeRight)
    offset = CGVectorMake(1.f, 0.f);
    //else
    //    NSAssert(NO, @"targetEdge must be one of UIRectEdgeLeft, or UIRectEdgeRight.");
    
    // The toView starts off-screen and slides in as the fromView slides out.
    fromView.frame = fromFrame;
    toView.frame = CGRectOffset(toFrame, toFrame.size.width * offset.dx * -1,
                                toFrame.size.height * offset.dy * -1);
    
    // We are responsible for adding the incoming view to the containerView.
    [containerView addSubview:toView];
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:transitionDuration animations:^{
        fromView.frame = CGRectOffset(fromFrame, fromFrame.size.width * offset.dx,
                                      fromFrame.size.height * offset.dy);
        toView.frame = toFrame;
    } completion:^(BOOL finished) {
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        // When we complete, tell the transition context
        // passing along the BOOL that indicates whether the transition
        // finished or not.
        [transitionContext completeTransition:!wasCancelled];
    }];
}

#pragma mark -
#pragma mark Helpers

- (void)disableTabBarItems {
    NSArray *tabBarItems = self.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = NO;
    }
}

- (void)enableTabBarItems {
    NSArray *tabBarItems = self.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = YES;
    }
}

@end
