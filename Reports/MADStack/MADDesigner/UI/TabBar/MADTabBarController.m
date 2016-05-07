//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarController.h"
#import "MADNavigationBarTitleView.h"

#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryVisualizationViewController.h"
#import "MADDesignerViewController.h"
#import "MADViewerController.h"
#import "MADStoryboard.h"

static NSString * const TabBar = @"MADIdentifierStoryboardMainTabBarController";

const int8_t MADIndexQuery = 0;
const int8_t MADIndexDesigner = 1;
const int8_t MADIndexViewer = 2;

@interface MADTabBarController ()
    <UITabBarControllerDelegate>

@property (nonatomic, assign) NSUInteger lastSelectedIndex;

@end

@implementation MADTabBarController

@synthesize document = _document;

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    MADocument *document = self.document;
    NSAssert(document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    self.lastSelectedIndex = NSNotFound;
    self.delegate = self;
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
            ((id <MADViewControllerDocumentProtocol>)viewController).document = document;
        }
    }
    self.view.backgroundColor = [UIColor purpleColor];

    UIBarButtonItem *dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                             target: self
                                                                             action: @selector(viewControllerDidFinish:)];
    [self.navigationItem setLeftBarButtonItem:dismiss animated:NO];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.viewControllers.count > 0) {
        UIViewController *vc = self.viewControllers.firstObject;
        NSString *title = vc.title.copy;
        [self showTitleWithText: title];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (id <UILayoutSupport>)topLayoutGuide { return self.navigationController.topLayoutGuide; }

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

- (void)viewControllerDidFinish:(id)sender {
    [self.querySplitViewController.detailNavigationController popToRootViewControllerAnimated:YES];
    [self.viewControllerDelegate viewControllerDidFinish:nil];
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    
    if (tabBarController.selectedIndex != self.lastSelectedIndex) {
        [self showTitleWithText: viewController.title];
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
    titleView.text = text;
    self.navigationItem.titleView = titleView;
}

- (MADQueryBuilderSplitViewController *)querySplitViewController {
    MADQueryBuilderSplitViewController *topViewController = ((MADQueryBuilderSplitViewController *)self.viewControllers[MADIndexQuery]);
    return topViewController;
}

- (MADDesignerViewController *)designerViewController {
    UINavigationController *navigationController = ((UINavigationController *)self.viewControllers[MADIndexDesigner]);
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

+ (instancetype)TabBarControllerMain {
    UIStoryboard *designer = [MADStoryboard newStoryboardDesigner];
    id controller = [designer instantiateViewControllerWithIdentifier:TabBar];
    return controller;
}

@end
