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

#import "MADQueryBuilderContainerController.h"
#import "MADocument.h"
#import "MADNavigationBarTitleView.h"

#import "MTApplicationInstance.h"
#import "MADQueryViewController.h"
#import "MADViewControllerSQL.h"

#import "MTStoreKitController+NonRenewableLicensing.h"
#import "UIViewController+UI.h"

#import "UIColor+EverydayApps.h"

#import "MADQueryVisualizationViewController.h"
#import "MADQueryVisualizationViewController+Designer.h"

@interface MADQueryBuilderContainerController ()
    <UISplitViewControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSQL;

@property (nonatomic, weak) UIBarButtonItem *barButtonItemRevealQuery;
@property (nonatomic, weak) UIBarButtonItem *barButtonItemDone;

@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, assign) BOOL localEditing;

@end

@implementation MADQueryBuilderContainerController

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (NSString *)title {
    return NSLocalizedString(@"MAD Query", "MAD Query");
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);

    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        NSMutableArray *viewControllers = self.viewControllers.mutableCopy;
        MADQueryVisualizationViewController *queryVisualizationViewController = [MADQueryVisualizationViewController QueryVisualizationViewController];
        viewControllers[1] = queryVisualizationViewController;
        self.viewControllers = viewControllers;
        

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
        
        self.editButtonItem.target = self;
        self.editButtonItem.action = @selector(edit:);
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = [MTApplicationInstance madQuery];
    self.navigationItem.titleView = titleView;
    
    self.navigationItem.prompt = [MTApplicationInstance mainInstance].openDocument.fileURL.lastPathComponent;

    self.delegate = self;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    UINavigationController *navigationController = self.viewControllers[0];
    navigationController.navigationBarHidden = NO;
    
    MADQueryVisualizationViewController *queryVisualizationViewController = self.viewControllers[1];
    queryVisualizationViewController.document = [MTApplicationInstance mainInstance].openDocument;

    self.barButtonItemSQL.tintColor = [UIColor whiteColor];
    [UIBarButtonItem appearanceWhenContainedIn:[MADQueryBuilderContainerController class], nil].tintColor = [UIColor tintColorWhite];

}

- (MADQueryViewController *)queryBuilderController {
    return (MADQueryViewController *)((UINavigationController *)self.viewControllers[0]).topViewController;
}

- (MADQueryVisualizationViewController *)queryBuilderControllerAdvanced {
    return self.viewControllers[1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.queryBuilderController reloadMainDocumentAnimated: YES];
    
    __block MADQueryBuilderContainerController *blockSelf = self;
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
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:MADSegueShowSql]) {
        
        MADViewControllerSQL *viewController;
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
            viewController = (MADViewControllerSQL *)((UINavigationController *)segue.destinationViewController).topViewController;
        } else {
            viewController = segue.destinationViewController;
        }
        viewController.delegate = self;
        viewController.query = [MTApplicationInstance mainInstance].openDocument.mainQuery;
        
    } else if (sender == self) {
        [segue.destinationViewController setDocument:[MTApplicationInstance mainInstance].openDocument];
        [segue.destinationViewController reloadMainDocumentAnimated:YES];
    } else {
        if (self.popover != nil) {
            if ([self.popover isPopoverVisible]) {
                [self.popover dismissPopoverAnimated:YES];
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.navigationItem.titleView sizeToFit];
}

- (id)leftViewController {
    return self.queryBuilderController;
}

- (id)rightViewController {
    return self.queryBuilderControllerAdvanced;
}

- (IBAction)showReportDocumentList:(id)sender {
    [self.viewControllerDelegate viewControllerDidFinish:self];
}

- (IBAction)showReportDesigner:(id)sender { }

- (IBAction)revealQuery:(id)sender { }

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    [[MTApplicationInstance mainInstance].openDocument.managedObjectContext save:&error];
    if (error != nil) {
        [[MTApplicationInstance mainInstance].openDocument.managedObjectContext save:&error];
    }
    [self.viewControllerDelegate viewControllerDidFinish:self];
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

- (void)viewControllerDidFinish:(id)sender {
    __weak MADQueryBuilderContainerController *weakSelf = self;
    BOOL procDelegateFunction = [sender isKindOfClass:[NSNumber class]] && [sender boolValue];
    [self dismissViewControllerAnimated:YES completion:^{
        if (procDelegateFunction) {
            [weakSelf.viewControllerDelegate viewControllerDidFinish:weakSelf];
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
        self.navigationItem.prompt = [MTApplicationInstance mainInstance].openDocument.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:YES];
    } else {
        self.navigationItem.prompt = nil;
    }
}

#pragma mark - UISplitViewControllerDelegate

// This method allows a client to update any bar button items etc.
- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {

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

- (BOOL)splitViewController: (UISplitViewController *)splitViewController showViewController: (UIViewController *)vc sender: (id)sender {
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
