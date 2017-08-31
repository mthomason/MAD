//
//  MADQueryBuilderContainerController.m
//  MADQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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

#import "MADLabelTitle.h"

#import "MADQueryViewController.h"
#import "MADViewControllerSQL.h"

#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MADQueryVisualizationViewController.h"
#import "MADNavigationControllerQueryBuilder.h"

static NSString * const TextTitleFormat = @"MAD %@";
static NSString * const TextTitleQuery = @"Query";

static NSString * const SplitViewController = @"MADIdentifierQueryBuilderSplitViewController";

static NSString * const MADStoryboardQuery = @"MADQuery";
static NSString * const TextRedraw = @"Redraw";

@interface MADQueryBuilderSplitViewController ()
    <UISplitViewControllerDelegate, UIPopoverControllerDelegate>

    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemEdit;
    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSQL;

    @property (nonatomic, assign) BOOL localEditing;
    @property (nonatomic, assign) BOOL setupDetail;
    @property (nonatomic, assign) BOOL setupInitalLayout;

@end

@implementation MADQueryBuilderSplitViewController

@synthesize document = _document;
@synthesize title = _title;
@synthesize queryBuilderController =  _queryBuilderController;
@synthesize queryBuilderControllerAdvanced =  _queryBuilderControllerAdvanced;
@synthesize detailNavigationController =  _detailNavigationController;

+ (void)initialize {
    [super initialize];
    
    if (self != [MADQueryBuilderSplitViewController self]) {
        @autoreleasepool {
            UIBarButtonItem <UIAppearance> *appearanceProxy;
            NSArray <Class <UIAppearanceContainer>> *classes;
            classes = [[NSArray alloc] initWithObjects: self, nil];
            appearanceProxy = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:classes];
            appearanceProxy.tintColor = [UIColor whiteColor];
        }
    }
}

+ (instancetype)newQueryBuilderSplitViewController:(MADocument *)document {
    id bundle = [NSBundle mainBundle];
    id storybard = [UIStoryboard storyboardWithName: MADStoryboardQuery bundle: bundle];
    id controller = [storybard instantiateViewControllerWithIdentifier:SplitViewController];
    [((typeof(self))controller) setDocument: document];
    return controller;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        

        _setupDetail = NO;
        _setupInitalLayout = NO;
        _localEditing = NO;
        self.delegate = self;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
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

        _setupInitalLayout = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSArray *toolbarItems = [[NSArray alloc] initWithObjects:_barButtonItemSQL, nil];
    [self setToolbarItems:toolbarItems animated:YES];
    [self.detailNavigationController setToolbarItems:toolbarItems animated:animated];
    //[self.view setNeedsLayout];
}

+ (NSString *)Title {
    NSString *localizedSuffix = NSLocalizedString(TextTitleQuery, TextTitleQuery);
    id title = [[NSString alloc] initWithFormat: TextTitleFormat, localizedSuffix];
    return title;
}

- (NSString *)title {
    if (_title == nil) {
        _title = [self.class Title];
    }
    return _title;
}

- (UINavigationController *)detailNavigationController {
    if (_detailNavigationController == nil) {
        if (self.viewControllers.count > 0) {
            _detailNavigationController = self.viewControllers[0];
            if (!_setupDetail) {
                id traits = [UITraitCollection traitCollectionWithHorizontalSizeClass: UIUserInterfaceSizeClassRegular];
                [self setOverrideTraitCollection:traits forChildViewController: _detailNavigationController];
                _detailNavigationController.navigationBarHidden = NO;
                _setupDetail = YES;
            }
        }
    }
    return _detailNavigationController;
}

- (MADQueryVisualizationViewController *)queryBuilderControllerAdvanced {
    if (_queryBuilderControllerAdvanced == nil) {
        if (self.viewControllers.count > 1) {
            _queryBuilderControllerAdvanced = self.viewControllers[1];
        }
    }
    return _queryBuilderControllerAdvanced;
}

- (MADQueryViewController *)queryBuilderController {
    if (_queryBuilderController == nil) {
        MADNavigationControllerQueryBuilder *detailNavigationController;
        detailNavigationController = self.detailNavigationController;
        _queryBuilderController = (MADQueryViewController *)detailNavigationController.topViewController;
    }
    return _queryBuilderController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)layoutForUnlicensedUser:(NSNumber *)animated {

    BOOL animate;
    NSMutableArray<__kindof UIBarButtonItem *> *toolbarItemsLimited;
    NSArray<__kindof UIBarButtonItem *> *toolbarItemsFull, *toolbarItemsPremium;
    UIBarButtonItem *barButtonItemRevealQuery;
    
    animate = animated.boolValue;
    
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
    self.viewControllerDelegate = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _detailNavigationController = nil;
    _queryBuilderController = nil;
    _queryBuilderControllerAdvanced = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (sender == self) {
        MADocument *document = self.document;
        [(segue.destinationViewController) setDocument: document];
        [segue.destinationViewController reloadMainDocumentAnimated:YES];
    }
}

- (IBAction)showReportDocumentList:(id)sender {
    [self.viewControllerDelegate viewControllerDidFinish:self];
}

- (IBAction)redrawQueryVisualization:(id)sender {
    [self.queryBuilderControllerAdvanced redraw: YES];
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

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemDatabase8];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
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
    [self.navigationController presentViewController:vc animated:YES completion:^{
        
    }];//:vc animated:YES];

    return YES;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
   showDetailViewController:(UIViewController *)vc
                     sender:(id)sender {


    return NO;
}

- (void)presentationTransitionWillBegin {
    // Add a custom dimming view behind the presented view controller's view
    //[[self containerView] addSubview:_dimmingView];
    //[_dimmingView addSubview:[[self presentedViewController] view]];
    
    // Use the transition coordinator to set up the animations.
    id <UIViewControllerTransitionCoordinator> transitionCoordinator =
    [[self presentingViewController] transitionCoordinator];
    
    // Fade in the dimming view during the transition.
    [self.view setAlpha:0.0];
    [transitionCoordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         [self.view setAlpha:1.0];
     } completion:nil];
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

#pragma mark -
#pragma mark Override

- (void)setDocument:(MADocument *)document {
    if (document != _document) {
        _document = document;
        UIViewController *childViewController;
        NSArray<__kindof UIViewController *> *childViewControllers = self.childViewControllers;
        for (childViewController in childViewControllers) {
            if ([childViewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
                [((id <MADViewControllerDocumentProtocol>)childViewController) setDocument: self.document];
            }
        }
    }
}

@end
