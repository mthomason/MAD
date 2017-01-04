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

#import <UIKit/UIStoryboard.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIPopoverController.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UIStoryboardPopoverSegue.h>
#import <UIKit/UIImage.h>

#import <MAD/MADocument.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADNavigationBarTitleView.h"

#import "MADQueryViewController.h"
#import "MADViewControllerSQL.h"

#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MADQueryVisualizationViewController.h"

static NSString * const TextTitleFormat = @"MAD %@";
static NSString * const TextTitleQuery = @"Query";

static NSString * const SplitViewController = @"MADIdentifierQueryBuilderSplitViewController";

static NSString * const MADStoryboardQuery = @"MADQuery";
static NSString * const TextRedraw = @"Redraw";

@interface MADQueryBuilderSplitViewController ()
    <UISplitViewControllerDelegate, UIPopoverControllerDelegate>

    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemEdit;
    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSQL;

    @property (nonatomic, strong) UIBarButtonItem *barButtonItemRevealQuery;
    @property (nonatomic, strong) UIBarButtonItem *barButtonItemDone;

    @property (nonatomic, strong) UIPopoverController *popover;

    @property (nonatomic, assign) BOOL localEditing;
    @property (nonatomic, assign) BOOL setupDetail;
    @property (nonatomic, assign) BOOL setupInitalLayout;

    //@property (readonly) MADTabBarController *tabBarController;

@end

@implementation MADQueryBuilderSplitViewController

@synthesize document = _document;
@synthesize title = _title;

+ (void)initialize {
    [super initialize];
    
    if (self != [MADQueryBuilderSplitViewController self]) return;
        
    @autoreleasepool {
        UIBarButtonItem *appearance;
        appearance = [UIBarButtonItem appearanceWhenContainedIn:[self class], nil];
        
        UIColor *white =  [MADColorEverydayApps newColorWhite];
        appearance.tintColor = white;
    }
}

- (void)dealloc {

}

+ (instancetype)newQueryBuilderSplitViewController:(MADocument *)document {
    id bundle = [NSBundle mainBundle];
    id storybard = [UIStoryboard storyboardWithName: MADStoryboardQuery bundle: bundle];
    id controller = [storybard instantiateViewControllerWithIdentifier:SplitViewController];
    [((typeof(self))controller) setDocument: document];
    return controller;
}

- (NSString *)title {
    if (_title == nil) {
        NSString *localizedSuffix = NSLocalizedString(TextTitleQuery, TextTitleQuery);
        id title = [[NSString alloc] initWithFormat: TextTitleFormat, localizedSuffix];
        _title = title;
    }
    return _title;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        

        _setupDetail = NO;
        _setupInitalLayout = NO;
        _localEditing = NO;
        
    }
    return self;
}

/*- (UINavigationController *)navigationController {
    UINavigationController *navigationController;
    navigationController = [super navigationController];
    if (navigationController != nil) {
        
    }
    return navigationController;
}*/

- (void)viewDidLoad {
    [super viewDidLoad];

    id redraw = NSLocalizedString(TextRedraw, TextRedraw);
    
    id barButtonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                         target: self
                                                                         action: @selector(done:)];
    self.barButtonItemDone = barButtonItemDone;
    
    id barButtonItemRevealQuery = [[UIBarButtonItem alloc] initWithTitle: redraw
                                                                   style: UIBarButtonItemStylePlain
                                                                  target: self
                                                                  action: @selector(redrawQueryVisualization:)];
    self.barButtonItemRevealQuery = barButtonItemRevealQuery;

    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    self.delegate = self;
    
    /*UITabBarController *tabBarController = self.tabBarController;
    UINavigationItem *navigationItem = tabBarController.navigationItem;

    NSURL *fileURL = _document.fileURL;
    NSString *lastPathComponent = fileURL.lastPathComponent;
    navigationItem.prompt = lastPathComponent.copy;*/


    //self.queryBuilderControllerAdvanced.document = document;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!_setupInitalLayout) {

        UIColor *whiteColor;
        UINavigationController *navigationController;
        UIBarButtonItem *buttonSQL;

        whiteColor = [UIColor whiteColor];
        navigationController = self.navigationController;
        buttonSQL = _barButtonItemSQL;

        buttonSQL.tintColor = whiteColor.copy;
        
        navigationController.navigationBar.tintColor = whiteColor.copy;
        navigationController.navigationItem.titleView.tintColor = whiteColor.copy;

        [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
            if (isLicensedUser == NO) {
                NSNumber *animateObject;
                animateObject = [[NSNumber alloc] initWithBool: NO];
                [[NSOperationQueue mainQueue] performSelectorOnMainThread: @selector(layoutForUnlicensedUser:)
                                                               withObject: animateObject
                                                            waitUntilDone: NO];
            }
        }];

        _setupInitalLayout = YES;
    }
}

- (void)viewDidLayoutSubviews {

    UIView *titleView = self.navigationItem.titleView;
    [titleView sizeToFit];
    
    [super viewDidLayoutSubviews];
}

- (UINavigationItem *)navigationItem {
    UINavigationItem *navigationItem = [super navigationItem];
    if (navigationItem && navigationItem.titleView == nil) {
        
        MADLabelTitle *titleView;
        UIBarButtonItem *editButton, *doneButton;
        NSString *title;

        title = self.title;
        titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
        titleView.text = title.copy;
        
        navigationItem.leftItemsSupplementBackButton = YES;
        navigationItem.hidesBackButton = NO;

        navigationItem.titleView = titleView;

        doneButton = _barButtonItemDone;
        navigationItem.leftBarButtonItem = doneButton;
        
        editButton = self.editButtonItem;
        editButton.target = self;
        editButton.action = @selector(edit:);
        navigationItem.rightBarButtonItem = editButton;
        

    }
    return navigationItem;
}

- (UINavigationController *)detailNavigationController {
    UINavigationController *detailController = nil;
    if (self.viewControllers.count > 0) {
        detailController = self.viewControllers[0];
        if (!_setupDetail) {
            id traits = [UITraitCollection traitCollectionWithHorizontalSizeClass: UIUserInterfaceSizeClassRegular];
            [self setOverrideTraitCollection:traits forChildViewController: detailController];
            detailController.navigationBarHidden = NO;
            _setupDetail = YES;
            if ([detailController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
                ((id <MADViewControllerDocumentProtocol>) detailController).document = _document;
            }
                
        }
    };
    return detailController;
}

- (MADQueryVisualizationViewController *)queryBuilderControllerAdvanced {
    MADQueryVisualizationViewController *queryVisulization = nil;
    if (self.viewControllers.count > 1) {
        queryVisulization = self.viewControllers[1];
        MADocument *document = _document;
        MADocument *documentQuery = queryVisulization.document;
        if (documentQuery != nil && documentQuery != document) {
            queryVisulization.document = document;
        }
    }
    return queryVisulization;
}

- (MADQueryViewController *)queryBuilderController {
    UINavigationController *detailNavigationController = self.detailNavigationController;
    MADQueryViewController *queryViewController = (MADQueryViewController *)detailNavigationController.topViewController;
    if (queryViewController && queryViewController.document == nil) {
        queryViewController.document = _document;
    }
    return queryViewController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MADQueryViewController *queryBuilderController;
    
    queryBuilderController = self.queryBuilderController;
    [queryBuilderController reloadMainDocumentAnimated: YES];
    
    NSNumber *animateObject = [[NSNumber alloc] initWithBool:animated];
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser == NO) {
            [[NSOperationQueue mainQueue] performSelectorOnMainThread: @selector(layoutForUnlicensedUser:)
                                                           withObject: animateObject
                                                        waitUntilDone: NO];
        }
    }];
}

- (void)layoutForUnlicensedUser:(NSNumber *)animated {

    BOOL animate;
    NSMutableArray<__kindof UIBarButtonItem *> *toolbarItemsLimited;
    NSArray<__kindof UIBarButtonItem *> *toolbarItemsFull, *toolbarItemsPremium;
    UIBarButtonItem *barButtonItemRevealQuery;
    
    animate = animated.boolValue;
    
    barButtonItemRevealQuery = self.barButtonItemRevealQuery;
    
    toolbarItemsFull = self.toolbarItems;
    toolbarItemsLimited = toolbarItemsFull.mutableCopy;
    toolbarItemsFull = nil;
    
    
    toolbarItemsPremium = [[NSArray alloc] initWithObjects: barButtonItemRevealQuery, nil];
    [toolbarItemsLimited removeObjectsInArray:toolbarItemsPremium];
    toolbarItemsPremium = nil;
    
    barButtonItemRevealQuery = nil;
    
    [self setToolbarItems: toolbarItemsLimited animated: animate];
    
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
        [(segue.destinationViewController) setDocument: document];
        [segue.destinationViewController reloadMainDocumentAnimated:YES];
    } else {
        if (self.popover != nil) {
            if ((self.popover).popoverVisible) {
                [self.popover dismissPopoverAnimated:YES];
            }
        }
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            ((UIStoryboardPopoverSegue *)segue).popoverController.delegate = self;
            self.popover = ((UIStoryboardPopoverSegue *)segue).popoverController;
            //[self.tabBarController disableTabBarItems];
        }
    }
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
    __block id <MADViewControllerStandardProtocol> viewControllerDelegate = _viewControllerDelegate;
    BOOL procDelegateFunction = [sender isKindOfClass:[NSNumber class]] && [sender boolValue] != NO;
    [self dismissViewControllerAnimated:YES completion:^{
        if (procDelegateFunction) {
            [viewControllerDelegate viewControllerDidFinish:nil];
        }
        viewControllerDelegate = nil;
    }];
    _viewControllerDelegate = nil;
}

/*
- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    if (!self.isViewLoaded) return;
        
    UIView *titleView = self.navigationItem.titleView;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [titleView sizeToFit];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [titleView sizeToFit];
    }];
    
}*/

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    /*
    typeof(__kindof UITabBarController) *tabBarController;
    tabBarController = self.tabBarController;
    
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
    
        BOOL animate = previousTraitCollection != nil;
        NSString *prompt = _document.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:animate];
        tabBarController.navigationItem.prompt = prompt.copy;
        [UIView setAnimationsEnabled:YES];
    
    } else {
        
        tabBarController.navigationItem.prompt = nil;
    }*/
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

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
    Protocol *documentProtocol = @protocol(MADViewControllerDocumentProtocol);
    if ([vc conformsToProtocol: documentProtocol]) {
        [(id <MADViewControllerDocumentProtocol>)vc setDocument:_document];
    }
    [super showViewController:vc sender:sender];
}

- (BOOL)splitViewController: (UISplitViewController *)splitViewController
         showViewController: (UIViewController *)vc
                     sender: (id)sender {
    
    Protocol *viewControllerDocumentProtocol = @protocol(MADViewControllerDocumentProtocol);
    if ([vc conformsToProtocol: viewControllerDocumentProtocol]) {
        [(id <MADViewControllerDocumentProtocol>)vc setDocument:_document];
    }
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
    //[self.tabBarController enableTabBarItems];
}

#pragma mark - Override

- (void)setDocument:(MADocument *)document {
    if (document != _document) {
        _document = document;
        //for (UIViewController *viewController in self.viewControllers) {
        //    if ([viewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
        //        ((id <MADViewControllerDocumentProtocol>) viewController).document = document;
        //    }
        //}
    }
}

@end
