//
//  MADTabBarController.m
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBarController.h"

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarItem.h>

#import "MADNavigationController.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADNavigationBarTitleView.h"

#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryVisualizationViewController.h"
#import "MADDesignerViewController.h"
#import "MADViewerController.h"

#import "MADIdentifiersStoryboards.h"

#import "MADLabelTitle.h"

static NSString * const MADIdentifierTabBarController = @"MADIdentifierTabBarController";

const int8_t MADIndexQuery = 0;
const int8_t MADIndexDesigner = 1;
const int8_t MADIndexViewer = 2;

@interface MADTabBarController ()
    <UITabBarControllerDelegate>

    @property (nonatomic, strong) NSMutableArray <__kindof UIViewController *> *tabBarViewControllers;
    @property (nonatomic, assign, getter=isNavigationItemInitalized) BOOL navigationItemInitalized;
    @property (nonatomic, assign) NSUInteger lastSelectedIndex;

    @property (nonatomic, copy) NSString *promptNavigationItem;

    @property (nonatomic, strong) MADDesignerViewController *designerViewController;
    @property (nonatomic, strong) MADQueryBuilderSplitViewController *querySplitViewController;
    @property (nonatomic, strong) MADNavigationController *navControllerViewer;

@end

@implementation MADTabBarController

@synthesize document = _document;

+ (instancetype)newTabBarController:(MADocument *)document prompt:(NSString *)prompt {
    
    UIStoryboard *storyboard;
    id bundle, tabBarController;

    bundle = [NSBundle mainBundle];
    storyboard = [UIStoryboard storyboardWithName: MADStoryboardDesigner bundle: bundle];
    tabBarController = [storyboard instantiateViewControllerWithIdentifier: MADIdentifierTabBarController];
    
    if (tabBarController) {
        ((MADTabBarController *) tabBarController).document = document;
        ((MADTabBarController *) tabBarController).promptNavigationItem = prompt ? prompt.copy : @"";
    }
    
    return tabBarController;
}

- (void)dealloc {
    _promptNavigationItem = nil;
    _viewControllerDelegate = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        _navigationItemInitalized = NO;
        _lastSelectedIndex = NSNotFound;
        
        NSMutableArray <__kindof UIViewController *> *tabBarViewControllers;
        tabBarViewControllers = [[NSMutableArray <__kindof UIViewController *> alloc] initWithCapacity: 3];
        self.tabBarViewControllers = tabBarViewControllers;
        
    }
    return self;
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
    [self.tabBarViewControllers addObject: splitViewController];
    self.querySplitViewController = splitViewController;
    
    designerViewController = [MADDesignerViewController newDesignerViewController:document];
    [self.tabBarViewControllers addObject: designerViewController];
    self.designerViewController = designerViewController;
    
    navControllerViewer = [MADNavigationController newNavigationController:MADNavigationControllerTypeViewer];
    navControllerViewer.document = document;
    [self.tabBarViewControllers addObject: navControllerViewer];
    self.navControllerViewer = navControllerViewer;
 
    id <MADViewControllerStandardProtocol> delegate = self.viewControllerDelegate;
    self.querySplitViewController.viewControllerDelegate = delegate;
    self.designerViewController.delegate = delegate;

    [self setViewControllers: self.tabBarViewControllers animated: animated];
    
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
    UINavigationController *detailNavigationController;

    if (navigationItem.leftBarButtonItem)
        [navigationItem setLeftBarButtonItem: nil animated: animated];

    if (navigationItem.rightBarButtonItem)
        [navigationItem setRightBarButtonItem: nil animated: animated];
    
    self.designerViewController.delegate = nil;

    id emptyArray = [[NSArray alloc] init];
    [self setViewControllers: emptyArray animated: animated];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.tabBarController.navigationItem setRightBarButtonItem:nil animated:animated];;
    [self.tabBarViewControllers removeAllObjects];
    //self.delegate = nil;
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

#pragma mark -
#pragma mark Helpers

- (void)showTitleWithText:(NSString *)text {
    MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
    NSString *title = text.copy;
    titleView.text = title;
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
