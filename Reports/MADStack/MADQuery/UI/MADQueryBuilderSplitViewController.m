//
//  MTQueryBuilderContainerController.m
//  MTQueryBuilderContainerController
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

    //@property (nonatomic, strong) UIBarButtonItem *barButtonItemRevealQuery;
    //@property (nonatomic, strong) UIBarButtonItem *barButtonItemDone;

    @property (nonatomic, strong) UIPopoverController *popover;

    @property (nonatomic, assign) BOOL localEditing;
    @property (nonatomic, assign) BOOL setupDetail;
    @property (nonatomic, assign) BOOL setupInitalLayout;

    //@property (readonly) MADTabBarController *tabBarController;

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

- (void)dealloc {
    //_barButtonItemDone.target = nil;
    //_barButtonItemEdit.target = nil;
    //NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        

        _setupDetail = NO;
        _setupInitalLayout = NO;
        _localEditing = NO;
        self.delegate = self;

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

    //id redraw = NSLocalizedString(TextRedraw, TextRedraw);
    
    //id barButtonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
    //                                                                     target: self.parentViewController
    //                                                                     action: @selector(done:)];
    //self.barButtonItemDone = barButtonItemDone;
    
    //id barButtonItemRevealQuery = [[UIBarButtonItem alloc] initWithTitle: redraw
    //                                                               style: UIBarButtonItemStylePlain
    //                                                              target: self
    //                                                              action: @selector(redrawQueryVisualization:)];
    //self.barButtonItemRevealQuery = barButtonItemRevealQuery;

    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    
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
        
        //navigationController.navigationBar.tintColor = whiteColor.copy;
        //navigationController.navigationItem.titleView.tintColor = whiteColor.copy;

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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //UIView *titleView = self.navigationItem.titleView;
    //[titleView sizeToFit];
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

/*- (UINavigationItem *)navigationItem {
    UINavigationItem *navigationItem = [super navigationItem];
    if (navigationItem.titleView == nil) {
        
        //MADLabelTitle *titleView;
        UIBarButtonItem *editButton, *doneButton;
        NSString *title;

        title = self.title;
        //titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
        //titleView.text = title.copy;
        
        navigationItem.leftItemsSupplementBackButton = YES;
        navigationItem.hidesBackButton = NO;

        //navigationItem.titleView = titleView;

        doneButton = _barButtonItemDone;
        navigationItem.leftBarButtonItem = doneButton;
        
        editButton = self.editButtonItem;
        editButton.target = self;
        editButton.action = @selector(edit:);
        navigationItem.rightBarButtonItem = editButton;
        

    }
    return navigationItem;
}*/

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
    
    //MADQueryViewController *queryBuilderController;
    
    //queryBuilderController = self.queryBuilderController;
    //[queryBuilderController reloadMainDocumentAnimated: animated];
    
    NSNumber *animateObject = [[NSNumber alloc] initWithBool:animated];
    
    //[[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
    //    if (isLicensedUser == NO) {
    //        NSInvocationOperation *operation;
    //        operation = [[NSInvocationOperation alloc] initWithTarget:self
    //                                                         selector:@selector(layoutForUnlicensedUser:)
    //                                                           object:animateObject];
    //        [[NSOperationQueue mainQueue] addOperation:operation];
    //    }
    //}];
}

- (void)layoutForUnlicensedUser:(NSNumber *)animated {

    BOOL animate;
    NSMutableArray<__kindof UIBarButtonItem *> *toolbarItemsLimited;
    NSArray<__kindof UIBarButtonItem *> *toolbarItemsFull, *toolbarItemsPremium;
    UIBarButtonItem *barButtonItemRevealQuery;
    
    animate = animated.boolValue;
    
    //barButtonItemRevealQuery = self.barButtonItemRevealQuery;
    
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
    //UINavigationController *detailNavigationController;
    //detailNavigationController = self.detailNavigationController;
    //[detailNavigationController popToRootViewControllerAnimated:animated];
    
    self.viewControllerDelegate = nil;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //[self.navigationItem setLeftBarButtonItem:nil animated:animated];
    //[self.navigationItem setRightBarButtonItem:nil animated:animated];
    _detailNavigationController = nil;
    _queryBuilderController = nil;
    _queryBuilderControllerAdvanced = nil;
    //NSArray *viewControllers = [[NSArray alloc] init];
    //[self setViewControllers:viewControllers animated]
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

/*- (IBAction)done:(id)sender {
    NSError *error = nil;
    MADocument *document = self.document;
    [document.managedObjectContext save:&error];
    if (error != nil) {
        [document.managedObjectContext save:&error];
    }
    [self.viewControllerDelegate viewControllerDidFinish:self];
}*/

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
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    void (^transition)(id<UIViewControllerTransitionCoordinatorContext>);
    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) {
            //[self.view setNeedsDisplay];
        };
    } else {
        transition = ^(id<UIViewControllerTransitionCoordinatorContext>context) { };
    }
    //UIView *toView = [coordinator viewForKey:UITransitionContextToViewKey];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        //[toView setNeedsDisplay];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    }];
    
}


/*- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
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

/*- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }];
}*/

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    //self.presentationController
    
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
        UIViewController *childViewController;
        NSArray<__kindof UIViewController *> *childViewControllers = self.childViewControllers;
        for (childViewController in childViewControllers) {
            if ([childViewController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)]) {
                [((id <MADViewControllerDocumentProtocol>)childViewController) setDocument: self.document];
            }
        }
    }
}

//- (void)done:(id)sender {
//    if (self.navigationController respondsToSelector:@selector(done:)) {
//        [self.navigationController done:sender];
//    }
//}

@end
