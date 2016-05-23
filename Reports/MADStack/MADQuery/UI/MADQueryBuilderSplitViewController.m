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

#import "MADQueryBuilderSplitViewController.h"

#import <CoreData/NSManagedObjectContext.h>

#import <MAD/MADocument.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADTabBarController.h"

#import "MADNavigationBarTitleView.h"

#import "MADQueryViewController.h"
#import "MADViewControllerSQL.h"

#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MADQueryVisualizationViewController.h"
#import "MADQueryVisualizationViewController+Designer.h"
#import "MADStoryboard.h"

static NSString * const SplitViewController = @"MADIdentifierQueryBuilderSplitViewController";

@interface MADQueryBuilderSplitViewController ()
    <UISplitViewControllerDelegate, UIPopoverControllerDelegate>

    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemEdit;
    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSQL;

    @property (nonatomic, weak) UIBarButtonItem *barButtonItemRevealQuery;
    @property (nonatomic, weak) UIBarButtonItem *barButtonItemDone;

    @property (nonatomic, strong) UIPopoverController *popover;
    @property (nonatomic, assign) BOOL localEditing;

@end

@implementation MADQueryBuilderSplitViewController

@synthesize document = _document;

+ (void)initialize {
    if (self == [MADQueryBuilderSplitViewController self]) {
        @autoreleasepool {
            Class thisClass = [MADQueryBuilderSplitViewController class];
            UIBarButtonItem *appearance = [UIBarButtonItem appearanceWhenContainedIn:thisClass, nil];
            UIColor *white =  [MADColorEverydayApps newColorWhite];
            appearance.tintColor = white;
        }
    }
}

- (void)dealloc { }

+ (instancetype)newQueryBuilderSplitViewController {
    UIStoryboard *storyboardQuery = [MADStoryboard newStoryboardQuery];
    id controller =  [storyboardQuery instantiateViewControllerWithIdentifier:SplitViewController];
    return controller;
}

- (NSString *)title {
    return [MADQueryBuilderSplitViewController MADQuery];
}

+ (NSString *)MADQuery {
    NSString *localizedSuffix = NSLocalizedString(@"Query", @"Query");
    return [NSString stringWithFormat: @"MAD %@", localizedSuffix];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        id redraw = NSLocalizedString(@"Redraw", @"Redraw");
        id whiteColor = [UIColor whiteColor];
        id traitCollection = [UITraitCollection traitCollectionWithHorizontalSizeClass: UIUserInterfaceSizeClassRegular];

        id barButtonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                             target: self
                                                                             action: @selector(done:)];
        id barButtonItemRevealQuery = [[UIBarButtonItem alloc] initWithTitle: redraw
                                                                       style: UIBarButtonItemStylePlain
                                                                      target: self
                                                                      action: @selector(redrawQueryVisualization:)];

        [self setOverrideTraitCollection:traitCollection forChildViewController:self.detailNavigationController];

        self.navigationController.navigationBar.tintColor = whiteColor;
        self.navigationController.navigationItem.titleView.tintColor = whiteColor;
        
        self.navigationItem.leftBarButtonItem = barButtonItemDone;
        self.navigationItem.rightBarButtonItem = self.editButtonItem;

        self.editButtonItem.target = self;
        self.editButtonItem.action = @selector(edit:);

        self.localEditing = NO;

        self.barButtonItemDone = barButtonItemDone;
        self.barButtonItemRevealQuery = barButtonItemRevealQuery;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;

    MADocument *doc = self.document;
    NSAssert(doc != nil, @"%s: Need a document", __PRETTY_FUNCTION__);
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = self.title.copy;
    self.navigationItem.titleView = titleView;
    
    NSString *lastPathComponent = doc.fileURL.lastPathComponent.copy;
    self.tabBarController.navigationItem.prompt = lastPathComponent;

    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    self.detailNavigationController.navigationBarHidden = NO;
    self.barButtonItemSQL.tintColor = [UIColor whiteColor];

    self.queryBuilderControllerAdvanced.document = doc;
}

- (UINavigationController *)detailNavigationController {
    return self.viewControllers.count > 0 ? self.viewControllers[0] : nil;
}

- (MADQueryVisualizationViewController *)queryBuilderControllerAdvanced {
    return self.viewControllers.count > 1 ? self.viewControllers[1] : nil;
}

- (MADQueryViewController *)queryBuilderController {
    return (MADQueryViewController *)self.detailNavigationController.topViewController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.queryBuilderController reloadMainDocumentAnimated: YES];
    
    MADQueryBuilderSplitViewController * __unsafe_unretained weakself = self;
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser == NO) {
            NSArray *items = [weakself toolbarItems];
            NSMutableArray *mutableItems = [items mutableCopy];
            [mutableItems removeObject:weakself.barButtonItemRevealQuery];
            [weakself setToolbarItems:mutableItems];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:MADSegueShowSql]) {
        MADocument *document = self.document;
        MADViewControllerSQL *viewController;
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
            viewController = (MADViewControllerSQL *)((UINavigationController *)segue.destinationViewController).topViewController;
        } else {
            viewController = segue.destinationViewController;
        }
        viewController.delegate = self;
        viewController.document = document;
        
    } else if (sender == self) {
        MADocument *document = self.document;
        [segue.destinationViewController setDocument:document];
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
            [self.tabBarController disableTabBarItems];
        }
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.navigationItem.titleView sizeToFit];
}

- (IBAction)showReportDocumentList:(id)sender {
    [self.viewControllerDelegate viewControllerDidFinish:self];
}

- (IBAction)done:(id)sender {
    NSError *error = nil;
    MADocument *document = self.document;
    [document.managedObjectContext save:&error];
    if (error != nil) {
        [document.managedObjectContext save:&error];
    }
    [self.viewControllerDelegate viewControllerDidFinish:self];
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
    MADQueryBuilderSplitViewController * __weak weakSelf = self;
    BOOL procDelegateFunction = [sender isKindOfClass:[NSNumber class]] && [sender boolValue];
    [self dismissViewControllerAnimated:YES completion:^{
        if (procDelegateFunction) {
            MADQueryBuilderSplitViewController *sself = weakSelf;
            [sself.viewControllerDelegate viewControllerDidFinish:sself];
        }
    }];
}

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        BOOL animate = previousTraitCollection != nil;
        [UIView setAnimationsEnabled:animate];
        self.tabBarController.navigationItem.prompt = self.document.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:YES];
    } else {
        self.tabBarController.navigationItem.prompt = nil;
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
    [self.tabBarController enableTabBarItems];
}

#pragma mark - Override

- (void)setDocument:(MADocument *)document {
    if (document != _document) {
        _document = document;
        for (UIViewController *viewController in self.viewControllers) {
            if ([viewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
                ((id <MADViewControllerDocumentProtocol>) viewController).document = document;
            }
        }
    }
}

@end
