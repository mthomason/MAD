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
#import "MADDesignerViewController.h"
#import "MADViewerController.h"
#import "MADDesignerStoryboard.h"

static NSString * const TabBar = @"MADIdentifierStoryboardMainTabBarController";

const int8_t MADIndexQuery = 0;
const int8_t MADIndexDesigner = 1;
const int8_t MADIndexViewer = 2;

@interface MADTabBarController ()
    <UITabBarControllerDelegate>

@property (nonatomic, assign) NSUInteger lastSelectedIndex;

@end

@implementation MADTabBarController

@synthesize document;

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

- (void)viewDidLoad {
    NSAssert(self.document != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    [super viewDidLoad];
    self.lastSelectedIndex = -1;
    self.delegate = self;
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController conformsToProtocol:@protocol(MADocumentProtocol)]) {
            ((id <MADocumentProtocol>)viewController).document = self.document;
        }
    }
    self.view.backgroundColor = [UIColor purpleColor];
    UIBarButtonItem *dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self action:@selector(viewControllerDidFinish:)];
    [self.navigationItem setLeftBarButtonItem:dismiss animated:NO];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.viewControllers.count > 0) {
        [self showTitleWithText: self.viewControllers[0].title];
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
    [self.viewControllerDelegate viewControllerDidFinish:sender];
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
    return (MADQueryBuilderSplitViewController *)self.viewControllers[MADIndexQuery];
}

- (MADDesignerViewController *)designerViewController {
    return (MADDesignerViewController *)((UINavigationController *)self.viewControllers[MADIndexDesigner]).topViewController;
}

- (MADViewerController *)viewerViewController {
    return (MADViewerController *)((UINavigationController *)self.viewControllers[MADIndexViewer]).topViewController;
}

- (void)disableTabBarItems {
    for (UITabBarItem *item in self.tabBar.items) {
        item.enabled = NO;
    }
}

- (void)enableTabBarItems {
    for (UITabBarItem *item in self.tabBar.items) {
        item.enabled = YES;
    }
}

+ (instancetype)TabBarControllerMain {
    UIStoryboard *designer = [MADDesignerStoryboard DesignerStoryboard];
    id controller = [designer instantiateViewControllerWithIdentifier:TabBar];
    return controller;
}

@end
