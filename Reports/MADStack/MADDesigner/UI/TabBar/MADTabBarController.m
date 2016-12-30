//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarController.h"

#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarItem.h>

#import "MADNavigationBarTitleView.h"

#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryVisualizationViewController.h"
#import "MADDesignerViewController.h"
#import "MADViewerController.h"
#import "MADStoryboard.h"

#import "MADStoryboard.h"
#import "MADTabBarController.h"

static NSString * const TabBar = @"MADIdentifierStoryboardMainTabBarController";

const int8_t MADIndexQuery = 0;
const int8_t MADIndexDesigner = 1;
const int8_t MADIndexViewer = 2;

@interface MADTabBarController ()
    <UITabBarControllerDelegate>

    @property (nonatomic, assign) NSUInteger lastSelectedIndex;
    @property (nonatomic, copy) NSString *promptNavigationItem;

    @property (nonatomic, assign, getter=isNavigationItemInitalized) BOOL navigationItemInitalized;

@end

@implementation MADTabBarController

@synthesize document = _document;

- (void)dealloc {
    _promptNavigationItem = nil;
}

+ (nullable instancetype)newTabBarController:(MADocument __weak *)document prompt:(NSString *)prompt {
    UIStoryboard *designer;
    id tabBarController;
    
    designer = [MADStoryboard newStoryboardDesigner];
    tabBarController = [designer instantiateViewControllerWithIdentifier:TabBar];
    
    if (tabBarController) {
        ((MADTabBarController *) tabBarController).document = document;
        ((MADTabBarController *) tabBarController).promptNavigationItem = prompt ?
                                                                            prompt.copy : @"";
    }
    
    return tabBarController;
}

- (UINavigationItem *)navigationItem {
    UINavigationItem *navigationItem;
    if ((navigationItem = [super navigationItem]) != nil) {
        if (!_navigationItemInitalized) {
            id newPrompt = _promptNavigationItem.copy;
            navigationItem.prompt = newPrompt;
        }
    }
    return navigationItem;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _navigationItemInitalized = NO;
        _lastSelectedIndex = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    MADocument *document = self.document;
    NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    //self.lastSelectedIndex = NSNotFound;
    //for (UIViewController *viewController in self.viewControllers) {
    //    if ([viewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
    //        ((id <MADViewControllerDocumentProtocol>)viewController).document = document;
    //    }
    //}
    self.view.backgroundColor = [UIColor purpleColor];
    //self.delegate = self;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.delegate = self;
    
    UIBarButtonItem *buttonDismiss;
    buttonDismiss= [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                 target: self
                                                                 action: @selector(viewControllerDidFinish:)];

    [self.navigationItem setLeftBarButtonItem:buttonDismiss animated:animated];

    
    /*if (self.viewControllers.count > 0) {
        UIViewController *vc = self.viewControllers.firstObject;
        NSString *title = vc.title.copy;
        [self showTitleWithText: title];
    }*/
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    UINavigationItem *navigationItem = self.navigationItem;
    MADQueryBuilderSplitViewController *querySplitViewController;
    UINavigationController *detailNavigationController;

    if (navigationItem.leftBarButtonItem)
        [navigationItem setLeftBarButtonItem: nil animated: animated];

    if (navigationItem.rightBarButtonItem)
        [navigationItem setRightBarButtonItem: nil animated: animated];
    
    querySplitViewController = self.querySplitViewController;
    detailNavigationController = querySplitViewController.detailNavigationController;
    [detailNavigationController popToRootViewControllerAnimated:animated];

    detailNavigationController = nil, querySplitViewController = nil;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    self.delegate = nil;
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (id <UILayoutSupport>)topLayoutGuide {
    id <UILayoutSupport> topLayoutGuide = self.navigationController.topLayoutGuide;
    return topLayoutGuide;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

- (void)viewControllerDidFinish:(id)sender {
    
    id <MADViewControllerStandardProtocol> viewControllerDelegate;
    viewControllerDelegate = _viewControllerDelegate;
    [viewControllerDelegate viewControllerDidFinish:nil];
    
}

#pragma mark - UITabBarControllerDelegate

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
    
    if (tabBarController.selectedIndex != self.lastSelectedIndex) {
        NSString *title = viewController.title.copy;
        [self showTitleWithText: title];
    }
    
    self.lastSelectedIndex = tabBarController.selectedIndex;
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

#pragma mark - helpers

- (void)showTitleWithText:(NSString *)text {
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    NSString *title = text.copy;
    titleView.text = title;
    self.navigationItem.titleView = titleView;
}

- (MADQueryBuilderSplitViewController *)querySplitViewController {
    MADQueryBuilderSplitViewController *topViewController = ((MADQueryBuilderSplitViewController *)self.viewControllers[MADIndexQuery]);
    return topViewController;
}

- (MADDesignerViewController *)designerViewController {
    UINavigationController *navigationController = self.viewControllers[MADIndexDesigner];
    MADDesignerViewController *topViewController = (MADDesignerViewController *)navigationController.topViewController;
    return topViewController;
}

- (MADViewerController *)viewerViewController {
    UINavigationController *navigationController = ((UINavigationController *)self.viewControllers[MADIndexViewer]);
    MADViewerController *topViewController = (MADViewerController *)navigationController.topViewController;
    return topViewController;
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
