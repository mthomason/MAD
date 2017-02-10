//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarController.h"

#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIResponder.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UITabBarItem.h>

#import "MADDesignerAnimatedTransitioning.h"
#import "MADDesignerViewController.h"
#import "MADLabelTitle.h"
#import "MADNavigationController.h"
#import "MADNavigationBarTitleView.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryVisualizationViewController.h"
#import "MADViewerController.h"


const int8_t MADIndexQuery = 0;
const int8_t MADIndexDesigner = 1;
const int8_t MADIndexViewer = 2;

@interface MADTabBarController ()
    <UITabBarControllerDelegate>

    @property (nonatomic, strong) NSMutableArray <__kindof UIViewController *> *tabBarViewControllers;

    @property (nonatomic, copy) NSString *promptNavigationItem;

    @property (nonatomic, strong) MADDesignerViewController *designerViewController;
    @property (nonatomic, strong) MADQueryBuilderSplitViewController *querySplitViewController;
    @property (nonatomic, strong) MADNavigationController *navControllerViewer;

@end

@implementation MADTabBarController {
    BOOL _navigationItemInitialized;
    NSUInteger _lastSelectedIndex;
}

@synthesize document = _document;

+ (instancetype)newTabBarController:(MADocument *)document prompt:(NSString *)prompt {
    
    UIStoryboard *storyboard;
    id bundle, tabBarController;

    bundle = [NSBundle mainBundle];
    storyboard = [UIStoryboard storyboardWithName: @"MADStoryboardDesigner" bundle: bundle];
    tabBarController = [storyboard instantiateViewControllerWithIdentifier: @"MADIdentifierTabBarController"];
    
    if (tabBarController) {
        ((MADTabBarController *) tabBarController).document = document;
        ((MADTabBarController *) tabBarController).promptNavigationItem = prompt ? prompt.copy : @"";
    }
    
    return tabBarController;
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

- (void)dealloc {
    _promptNavigationItem = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        _navigationItemInitialized = NO;
        _lastSelectedIndex = NSNotFound;
        
        NSMutableArray <__kindof UIViewController *> *tabBarViewControllers;
        tabBarViewControllers = [[NSMutableArray <__kindof UIViewController *> alloc] initWithCapacity: 3];
        self.tabBarViewControllers = tabBarViewControllers;
        
    }
    return self;
}

- (UINavigationItem *)navigationItem {
    UINavigationItem *navigationItem = [super navigationItem];
    if (!_navigationItemInitialized) {
        id newPrompt = _promptNavigationItem.copy;
        navigationItem.prompt = newPrompt;
        _navigationItemInitialized = YES;
    }
    return navigationItem;
}

- (void)setViewControllerDelegate:(id <MADViewControllerStandardProtocol>)delegate {

    if (_viewControllerDelegate != delegate) {
        //_designerViewController.delegate = delegate;
        //_querySplitViewController.viewControllerDelegate = delegate;
        _viewControllerDelegate = delegate;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;

    self.view.backgroundColor = [UIColor purpleColor];
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    MADocument *document = self.document;
    
    MADQueryBuilderSplitViewController *splitViewController;
    MADDesignerViewController *designerViewController;
    MADNavigationController *navControllerViewer;
    
    splitViewController =  [MADQueryBuilderSplitViewController newQueryBuilderSplitViewController:document];
    self.querySplitViewController = splitViewController;
    [self.tabBarViewControllers addObject: splitViewController];
    //UINavigationController *navigationControllerSplit = [[UINavigationController alloc] initWithRootViewController:_querySplitViewController];
    //[navigationControllerSplit setToolbarHidden:NO animated:NO];
    
    designerViewController = [MADDesignerViewController newDesignerViewController:document];
    [self.tabBarViewControllers addObject: designerViewController];
    self.designerViewController = designerViewController;
    
    navControllerViewer = [MADNavigationController newNavigationController:MADNavigationControllerTypeViewer];
    navControllerViewer.document = document;
    [self.tabBarViewControllers addObject: navControllerViewer];

    id <MADViewControllerStandardProtocol> delegate;
    delegate = self.viewControllerDelegate;

    self.navControllerViewer = navControllerViewer;
    navControllerViewer.viewControllerDelegate = delegate;
    // navControllerViewer
    self.querySplitViewController.viewControllerDelegate = delegate;
    self.designerViewController.delegate = delegate;

    [self showTitleWithText:splitViewController.title];
    [self setViewControllers: self.tabBarViewControllers animated: animated];
    UIBarButtonItem *buttonDismiss;
    buttonDismiss= [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                 target: self
                                                                 action: @selector(done:)];
    [self.navigationItem setLeftBarButtonItem:buttonDismiss animated:animated];
    
    /*if (self.viewControllers.count > 0) {
        UIViewController *vc = self.viewControllers.firstObject;
        NSString *title = vc.title.copy;
        [self showTitleWithText: title];
    }*/
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //id barButtonItemRevealQuery = [[UIBarButtonItem alloc] initWithTitle: @"Redraw"
    //                                                               style: UIBarButtonItemStylePlain
    //                                                              target: self.querySplitViewController
    //                                                              action: @selector(redrawQueryVisualization:)];
    //self.barButtonItemRevealQuery = barButtonItemRevealQuery;
    //[self setToolbarItems:@[barButtonItemRevealQuery] animated:YES];
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
    //[self.view setNeedsLayout];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
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
    
    self.designerViewController.delegate = nil;

    [self setViewControllers: nil animated: animated];
    [self.navigationItem setLeftBarButtonItem:nil animated:animated];
    [self.navigationItem setRightBarButtonItem:nil animated:animated];;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.tabBarViewControllers removeAllObjects];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
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
    
    if (tabBarController.selectedIndex != _lastSelectedIndex) {
        [self showTitleWithText: viewController.title];
    }
    
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

//- (void)done:(id)sender {
//    [self viewControllerDidFinish:sender];
//}

#pragma mark -
#pragma mark Helpers

- (void)showTitleWithText:(NSString *)text {
    MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
    titleView.text = text.copy;
    self.navigationItem.titleView = titleView;
}

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
