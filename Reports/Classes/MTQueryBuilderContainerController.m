//
//  MTQueryBuilderContainerController.m
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderContainerController.h"
#import <CoreData/CoreData.h>

#import "MADocument.h"
#import "MADNavigationBarTitleView.h"

#import "MTApplicationInstance.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MADQueryVisualizationViewController.h"
#import "MTShowSqlViewController.h"

#import "UIDevice+Hack.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "UIViewController+ui.h"
#import "MACloudManager.h"

@interface MTQueryBuilderContainerController ()
    <UISplitViewControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, weak) UIBarButtonItem *barButtonItemEditDone;
@property (nonatomic, weak) UIBarButtonItem *barButtonItemRevealQuery;
@property (nonatomic, weak) UIBarButtonItem *barButtonItemDone;

@property (nonatomic, strong) NSArray *toolbarItemsEditing;
@property (nonatomic, strong) NSArray *toolbarItemsEditingNot;

@property (nonatomic, strong) NSArray *constraintsViewWillAppear;

@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, assign) BOOL localEditing;
@end

@implementation MTQueryBuilderContainerController

- (NSString *)title {
    return NSLocalizedString(@"MAD Query", "MAD Query");
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationController.navigationItem.titleView.tintColor = [UIColor whiteColor];
        
        self.localEditing = NO;
    
        UIBarButtonItem *barButtonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                           target: self
                                                                                           action: @selector(done:)];
        self.navigationItem.leftBarButtonItem = barButtonItemDone;
        self.barButtonItemDone = barButtonItemDone;

        NSString *redraw = NSLocalizedString(@"Redraw", @"Redraw");
        
        UIBarButtonItem *barButtonItemRevealQuery = [[UIBarButtonItem alloc] initWithTitle: redraw
                                                                                     style: UIBarButtonItemStylePlain
                                                                                    target: self
                                                                                    action: @selector(redrawQueryVisualization:)];

        UIViewController *vc = self.viewControllers[0];
        UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithHorizontalSizeClass: UIUserInterfaceSizeClassRegular];
        [self setOverrideTraitCollection:traitCollection forChildViewController:vc];
        
        self.barButtonItemRevealQuery = barButtonItemRevealQuery;
        
        
        MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
        titleView.text = [MTApplicationInstance madQuery];
        self.navigationItem.titleView = titleView;
        
        
        self.editButtonItem.target = self;
        self.editButtonItem.action = @selector(edit:);
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    [super viewWillTransitionToSize: size
          withTransitionCoordinator: coordinator];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.prompt = [self.document.fileName stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocument];

    self.delegate = self;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    UINavigationController *navigationController = self.viewControllers[0];
    navigationController.navigationBarHidden = NO;
    
    MADQueryViewController *queryViewController = (MADQueryViewController *)navigationController.topViewController;
    queryViewController.document = self.document;
    self.queryBuilderController = queryViewController;
    
    MADQueryVisualizationViewController *queryVisualizationViewController = self.viewControllers[1];
    queryVisualizationViewController.document = self.document;
    self.queryBuilderControllerAdvanced = queryVisualizationViewController;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.queryBuilderController reloadDocument: self.document
                                       animated: YES];
    [self.queryBuilderControllerAdvanced reloadDocument:self.document animated:YES];
    
    __block MTQueryBuilderContainerController *blockSelf = self;
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser == NO) {
            NSArray *items = [self toolbarItems];
            NSMutableArray *mutableItems = [items mutableCopy];
            [mutableItems removeObject:blockSelf.barButtonItemRevealQuery];
            [blockSelf setToolbarItems:mutableItems];
            blockSelf = nil;
        }
    }];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.view removeConstraints:self.constraintsViewWillAppear];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:MNSSegueShowSql]) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) { //iPhone version handled in MADQueryViewController
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            [popoverController setDelegate:self];
            self.popover = popoverController;
            UINavigationController *navController = (UINavigationController *)popoverController.contentViewController;
            MTShowSqlViewController *showSqlViewController = (MTShowSqlViewController *)navController.topViewController;
            showSqlViewController.query = self.document.mainQuery;
            [self disableTabBarItems];
        }
        
    } else if (sender == self) {
        [segue.destinationViewController setDocument:self.document];
        [segue.destinationViewController reloadDocument:self.document animated:YES];
    } else {
        if ([self popover] != nil) {
            if ([[self popover] isPopoverVisible]) {
                [[self popover] dismissPopoverAnimated:YES];
            }
        }
        Class popoverSegueClass = [UIStoryboardPopoverSegue class];
        if ([segue isKindOfClass:popoverSegueClass]) {
            [[(UIStoryboardPopoverSegue *)segue popoverController] setDelegate:self];
            [self setPopover:[(UIStoryboardPopoverSegue *)segue popoverController]];
            [self disableTabBarItems];
        }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL leftIsGo = YES, rightIsGo = YES;
    NSString *segueCloseDesignerId = @"MTSegueCloseDesigner";
    if ([identifier isEqualToString:segueCloseDesignerId]) {
        leftIsGo = [self leftViewController] == nil ? YES :
                        [[self leftViewController] shouldPerformSegueWithIdentifier:identifier sender:sender];
        rightIsGo = [self rightViewController] == nil ? YES :
                        [[self rightViewController] shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
    return leftIsGo && rightIsGo;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];/*
    UIViewController *primaryViewController = self.viewControllers.count > 0 ? self.viewControllers[0] : nil;
    UIViewController *secondaryViewController = self.viewControllers.count > 1 ? self.viewControllers[1] : nil;
    if (primaryViewController) {
        NSMutableArray *subviews = [[NSMutableArray alloc] initWithArray:[primaryViewController.view subviews]];
        if (secondaryViewController) {
            [subviews addObjectsFromArray:[secondaryViewController.view subviews]];
            for (UIView *view in subviews) {
                if ([view isKindOfClass:[UIScrollView class]]) {
                    [(UIScrollView *)view setContentInset: UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)];
                    [(UIScrollView *)view setScrollIndicatorInsets: [(UIScrollView *)view contentInset]];
                }
            }
        }
    }*/
}

- (id)leftViewController {
    return self.queryBuilderController;
}

- (id)rightViewController {
    return self.queryBuilderControllerAdvanced;
}

- (IBAction)showReportDocumentList:(id)sender {
    [self.viewControllerDelegate viewControllerDidFinish:self animated:YES];
}

- (IBAction)showReportDesigner:(id)sender { }

- (IBAction)revealQuery:(id)sender { }

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    [self.document.managedObjectContext save:&error];
    if (error != nil) {
        [self.document.managedObjectContext save:&error];
    }
    [self.viewControllerDelegate viewControllerDidFinish:self animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];

}
- (IBAction)redrawQueryVisualization:(id)sender {
    [self.queryBuilderControllerAdvanced redraw];
}

- (IBAction)edit:(id)sender {
    self.localEditing = !self.localEditing;
    [self.queryBuilderController edit:sender];
    [self setEditing:self.localEditing animated:YES];
}

- (void)viewControllerDidFinish:(id)controller {
    [self viewControllerDidFinish:controller animated:YES];
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    __weak MTQueryBuilderContainerController *weakSelf = self;
    BOOL procDelegateFunction = [sender isKindOfClass:[NSNumber class]] && [sender boolValue];
    [self dismissViewControllerAnimated:animated completion:^{
        if (procDelegateFunction) {
            [weakSelf.viewControllerDelegate viewControllerDidFinish:weakSelf animated:YES];
        }
    }];
}

#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        BOOL animate = previousTraitCollection != nil;
        [UIView setAnimationsEnabled:animate];
        self.navigationItem.prompt = [self.document.fileName stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocument];
        [UIView setAnimationsEnabled:YES];
    } else {
        self.navigationItem.prompt = nil;
    }
}

#pragma mark - UISplitViewControllerDelegate

// This method allows a client to update any bar button items etc.
- (void)splitViewController:(UISplitViewController *)svc
    willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {

    switch (displayMode) {

        case UISplitViewControllerDisplayModeAutomatic:
            break;

        case UISplitViewControllerDisplayModePrimaryHidden:
            break;

        case UISplitViewControllerDisplayModeAllVisible:
            break;

        case UISplitViewControllerDisplayModePrimaryOverlay:
            break;

        default:
            break;
    }
}

- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)svc {

    return UISplitViewControllerDisplayModeAllVisible;

}

- (BOOL)splitViewController: (UISplitViewController *)splitViewController
         showViewController: (UIViewController *)vc
                     sender: (id)sender {
    [self.navigationController pushViewController:vc animated:YES];
    return YES;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
   showDetailViewController:(UIViewController *)vc
                     sender:(id)sender {


    return NO;
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return splitViewController.viewControllers[0];
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {
    return splitViewController.viewControllers[0];
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
    collapseSecondaryViewController:(UIViewController *)secondaryViewController
          ontoPrimaryViewController:(UIViewController *)primaryViewController {

    return YES; // Query visualization is not needed.
    
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController
        separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {

    return nil;

}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self enableTabBarItems];
}

@end
