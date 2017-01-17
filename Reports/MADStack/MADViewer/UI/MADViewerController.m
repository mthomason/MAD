//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADViewerController.h"

#import <MAD/MADActivityItemProviderDelegate.h>

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIAccessibility.h>
#import <UIKit/UIPopoverController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIAccessibilityConstants.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIPrintInteractionController.h>
#import <UIKit/UILocalNotification.h>
#import <UIKit/UITabBarItem.h>
#import <UIKit/UIPopoverPresentationController.h>
#import <UIKit/UIDocumentInteractionController.h>
#import <UIKit/UIViewControllerTransitioning.h>

#import <CoreData/CoreData.h>

#import <MADDataStructures/MTPair.h>

#import <MAD/MTDataTable.h>

#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/UIView+Animations.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MAD/MTReportViewerPrintPageRenderer.h>

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>

#import <MAD/MTReportFormatter.h>

#import <MAD/MADDatabaseConnection.h>

#import <MAD/MTDataTableFast.h>

#import <MAD/MTActivityItemProviderPdf.h>
#import <MAD/MADNotificationDidFormatPage.h>
#import <MAD/MADNotificationDidReadRows.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MTPaper.h>

#import "MTPrintingProtocol.h"
#import "MUIViewControllerDelegate.h"

#import "MADTabBarController.h"

#import "MTActivityReportPrintPreview.h"

#import "MTReportViewerReportPageView.h"
#import "MTReportViewerReportPageViewController.h"

#import "MADSliderPageVertical.h"
#import "MADLabelStatus.h"
#import "MADNavigationBarTitleView.h"

#import "UIApplication+Extras.h"
#import "UIViewController+tabBarItem.h"
#import "NSDate+Extras.h"

#import "MTStoreKitController+Features.h"
#import "MADPageSlider.h"
#import "MADPageViewAttributes.h"

#import "MADOperationQueue.h"
#import "MADOperationRefreshReload.h"

#import "MADPromptOperationDisplayError.h"

#import "MADOperationObserver.h"
#import "MADLabelTitle.h"
#import "MADIdentifiersStoryboards.h"
#import "MADDocumentScroller.h"

static NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";
static NSString * const MADStoryboardIDViewerController = @"MADIdentifierStoryboardViewerViewController";
static NSString * const MADTextNoCache = @"No Cache";

static const CGFloat MADBarButtonItemsMargin = 8.0000f;

//#pragma mark - Attributes
//#pragma mark Display Varables
//
//@interface MADOperationRenderOnViewert : NSOperation
//    - (instancetype)initWithDocument:(MADocument *)document;
//    @property (readonly, nonatomic, weak) MADocument *document;
//@end


#pragma mark - Attributes
#pragma mark Display Varables

@interface MADOperationLoadDocument : NSOperation
    - (instancetype)initWithDocument:(MADocument *)document;
    @property (readonly, nonatomic, weak) MADocument *document;
@end

#pragma mark - Attributes
#pragma mark Display Varables

@interface MADOperationLoadPrintPageRender : NSOperation
    - (instancetype)initWithDocument:(MADocument *)document;
    @property (readonly, nonatomic, weak) MADocument *document;
    @property (readonly, nonatomic, weak) MTReportViewerPrintPageRenderer *printPageRenderer;
@end

@interface MADViewerController ()
    <UIPopoverPresentationControllerDelegate,
        UIPopoverControllerDelegate,
        UIStateRestoring,
        UIPageViewControllerDelegate,
        UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate,
        UIViewControllerTransitioningDelegate,
        UIViewControllerAnimatedTransitioning,
        MADOperationObserver,
        MADPageSliderProtocol,
        MTPrintingProtocol,
        MTActivityReportPrintPreviewDelegate,
        MADActivityItemProviderDelegate>

    @property (nonatomic, strong) MADDateFromTimeFormatter *dateTimeFormatter;

#pragma mark - Attributes
#pragma mark Display Varables

    @property (nonatomic, assign, readwrite) CGFloat zoomScale;

    @property (nonatomic, strong) NSDate *lastCacheDate;

#pragma mark Timer (Updates last refresh date on tick)

    @property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;

#pragma mark User Interface

    @property (nonatomic, strong)   MADPageSlider *pageSlider;
    @property (nonatomic, weak)     MADLabelStatus *labelStatus;

    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemActivity;
    @property (nonatomic, strong) UIBarButtonItem *barButtonLabelStatus;

    @property (nonatomic, strong) NSMutableArray *toolbarItemsActive;

    @property (nonatomic, strong) MTReportViewerPrintPageRenderer *printPageRendererReport;
    @property (nonatomic, strong) MTActivityItemProviderPdf *activityItemProviderPdf;

#pragma mark Controllers

    @property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

#pragma mark Identifiers

    @property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdRefresh;

    @property (nonatomic, strong) MADOperationQueue *refreshQueue;

    @property (nonatomic, strong) NSOperationQueue *loadDocumentViewerQueue;

@end

@implementation MADViewerController {
    MADReportPosition _currentLocation;
    BOOL _isFirstAppearance;
    BOOL _firstTimeViewWillLayoutSubviews;
    BOOL _refreshing;
    BOOL _didRefreshBeforeReaload;
    BOOL _activityExporting;
    BOOL _startedRefresh;
    BOOL _pageIsAnimating;
    BOOL _updatingOfTimerIsPaused;
}

@synthesize document = _document;
@synthesize title = _title;

#pragma mark - Static helpers

+ (void)setNavigationBarAppearanceTinted {
    NSArray <Class <UIAppearanceContainer>> *classes;
    Class thisClass = self;
    classes = [[NSArray alloc] initWithObjects: thisClass, nil];
    UINavigationBar *appearanceProxy;
    appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
    appearanceProxy.barTintColor = nil;
    appearanceProxy.tintColor = [MADColorEverydayApps newColorWhite];
}

+ (void)setNavigationBarAppearanceHighlighted {
    NSArray <Class <UIAppearanceContainer>> *classes;
    Class thisClass = self;
    classes = [[NSArray alloc] initWithObjects: thisClass, nil];
    UINavigationBar *appearanceProxy;
    appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:classes];
    appearanceProxy.barTintColor = [MADColorEverydayApps newColorAnalogous4];
    appearanceProxy.tintColor = [MADColorEverydayApps newColorRed];
}

+ (instancetype)newViewerController:(MADocument *)document {
    UIStoryboard *storyboard;
    id bundle, controller;
    
    bundle = [NSBundle mainBundle];
    storyboard = [UIStoryboard storyboardWithName: MADStoryboardDesigner bundle: bundle];
    controller = [storyboard instantiateViewControllerWithIdentifier: MADStoryboardIDViewerController];
    [((typeof(self))controller) setDocument: document];
    return controller;
}

+ (void)initialize {
    [super initialize];
    if (self == [MADViewerController self]) {
        @autoreleasepool {
            
        }
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if (_timerLabelTimeSinceRefreh.valid) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        _timerLabelTimeSinceRefreh = nil;
    }
    //[_toolbarItemsActive removeAllObjects];
}

- (void)timerDealloc {
    NSTimer *timer = self.timerLabelTimeSinceRefreh;
    if (timer != nil) {
        if ([timer respondsToSelector:@selector(isValid)]) {
            if (timer.valid) {
                [timer invalidate];
            }
        }
        timer = nil;
        self.timerLabelTimeSinceRefreh = nil;
    }
}

#pragma mark - Initialize

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        //NSLog(@"%s", __PRETTY_FUNCTION__);
        _isFirstAppearance = YES;
        _firstTimeViewWillLayoutSubviews = YES;
        _activityExporting = NO;
        _didRefreshBeforeReaload = NO;
        _refreshing = NO;
        _activityExporting = NO;
        _startedRefresh = NO;
        _pageIsAnimating = NO;
        _updatingOfTimerIsPaused = NO;
        
        MADOperationQueue *refreshQueue = [[MADOperationQueue alloc] init];
        self.refreshQueue = refreshQueue;
        
        CGRect boundsStatusLabel = CGRectMake(CGPointZero.x, CGPointZero.y, 30.0000f, 44.0000f);
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        MADPageSlider *pageSlider = [[MADPageSlider alloc] initWithEffect:effect];
        self.pageSlider = pageSlider;

        
        MADLabelStatus *labelStatus;
        labelStatus = [[MADLabelStatus alloc] initWithFrame: boundsStatusLabel];

        UIBarButtonItem *barButtonLabelStatus;
        barButtonLabelStatus = [[UIBarButtonItem alloc] initWithCustomView:labelStatus];
        
        self.barButtonLabelStatus = barButtonLabelStatus;
        self.labelStatus = labelStatus;
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.name = @"Load Document Viewer";
        queue.maxConcurrentOperationCount = 1;
        queue.qualityOfService = NSOperationQualityOfServiceUserInitiated;
        self.loadDocumentViewerQueue = queue;

    }
    return self;
}

#pragma mark -
#pragma mark UIViewController Standard Callbacks

- (void)viewDidLoad {
    [super viewDidLoad];
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSMutableArray *toolbarItems;
    NSArray *emptyArray = [[NSArray alloc] init];
    toolbarItems = self.toolbarItems.mutableCopy;
    [toolbarItems insertObject: self.barButtonLabelStatus atIndex: 0];
    [self setToolbarItems: emptyArray animated: NO];
    self.toolbarItemsActive = toolbarItems;

    self.pageSlider.sliderDelegate = self;
    
    self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitCausesPageTurn;
    
    self.view.backgroundColor = [UIColor lightGrayColor];

    UIColor *whiteColor = [MADColorEverydayApps newColorWhite];
    self.navigationController.toolbar.tintColor = whiteColor;
    
    MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
    titleView.text = self.title;
    self.navigationItem.titleView = titleView;

    self.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.dataSource = self;
    self.delegate = self;
    
    _currentLocation = MADReportPositionMake(0, 0);
    
    _refreshing = NO;
    _startedRefresh = NO;

    MADocument *document = self.document;
    
    MADOperationLoadDocument *opLoadDoc;
    MADOperationLoadPrintPageRender *opLoadPtr;
    NSInvocationOperation *invokeUpdateNumberOfPages, *invokeUpdateRecordsRead, *invokePageSliderNeedsLayout,
                          *invokeSetDisplayActive, *invokeReloadWithSize, *invokeTimerDealloc,
                          *invokeTimeSinceLastUpdate, *invokeRemoveObserver, *invokesetLastCacheDate;

    opLoadDoc = [[MADOperationLoadDocument alloc] initWithDocument: document];
    opLoadPtr = [[MADOperationLoadPrintPageRender alloc] initWithDocument: document];
    
    [opLoadPtr addDependency:opLoadDoc];

    
    invokeUpdateNumberOfPages = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateNumberOfPages) object:nil];
    [invokeUpdateNumberOfPages addDependency:opLoadPtr];
    
    invokeUpdateRecordsRead = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateRecordsRead) object:nil];
    [invokeUpdateRecordsRead addDependency:opLoadPtr];
    
    invokePageSliderNeedsLayout = [[NSInvocationOperation alloc] initWithTarget:_pageSlider selector:@selector(setNeedsLayout) object:nil];
    [invokePageSliderNeedsLayout addDependency:opLoadPtr];

    invokesetLastCacheDate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setLastCacheDate:) object:[NSDate date]];
    [invokesetLastCacheDate addDependency:opLoadPtr];
    
    invokeSetDisplayActive = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setDisplayActive) object:nil];
    [invokeSetDisplayActive addDependency:opLoadPtr];
    
    invokeReloadWithSize = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(reloadWithSize:) object:[NSValue valueWithCGSize:document.paper.paperSize]];
    [invokeReloadWithSize addDependency:opLoadPtr];
    
    invokeTimerDealloc = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(timerDealloc) object:nil];
    [invokeTimerDealloc addDependency:opLoadPtr];
    
    invokeTimeSinceLastUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateTimeSinceLastRefresh:) object:nil];
    [invokeTimeSinceLastUpdate addDependency:opLoadPtr];
    
    invokeRemoveObserver = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(removeObserverDidReadRowsFromDatabase:) object:document.database];
    [invokeRemoveObserver addDependency:opLoadPtr];

    
    [[NSOperationQueue mainQueue] addOperation:opLoadDoc];
    [[NSOperationQueue mainQueue] addOperation:opLoadPtr];
    [[NSOperationQueue mainQueue] addOperation:invokeUpdateNumberOfPages];
    [[NSOperationQueue mainQueue] addOperation:invokeUpdateRecordsRead];
    [[NSOperationQueue mainQueue] addOperation:invokePageSliderNeedsLayout];
    [[NSOperationQueue mainQueue] addOperation:invokesetLastCacheDate];
    [[NSOperationQueue mainQueue] addOperation:invokeSetDisplayActive];
    [[NSOperationQueue mainQueue] addOperation:invokeReloadWithSize];
    [[NSOperationQueue mainQueue] addOperation:invokeTimerDealloc];
    [[NSOperationQueue mainQueue] addOperation:invokeTimeSinceLastUpdate];
    [[NSOperationQueue mainQueue] addOperation:invokeRemoveObserver];

}

- (void)relaodByBlocks {
    NSInvocationOperation *invokeUpdateNumberOfPages, *invokeUpdateRecordsRead, *invokePageSliderNeedsLayout,
    *invokeSetDisplayActive, *invokeReloadWithSize, *invokeTimerDealloc,
    *invokeTimeSinceLastUpdate, *invokeRemoveObserver, *invokesetLastCacheDate;
    
    MADocument *document = self.document;

    invokeUpdateNumberOfPages = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateNumberOfPages) object:nil];
    
    invokeUpdateRecordsRead = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateRecordsRead) object:nil];
    [invokeUpdateRecordsRead addDependency:invokeUpdateNumberOfPages];
    
    invokePageSliderNeedsLayout = [[NSInvocationOperation alloc] initWithTarget:_pageSlider selector:@selector(setNeedsLayout) object:nil];
    [invokePageSliderNeedsLayout addDependency:invokeUpdateRecordsRead];
    
    invokesetLastCacheDate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setLastCacheDate:) object:[NSDate date]];
    [invokesetLastCacheDate addDependency:invokePageSliderNeedsLayout];
    
    invokeSetDisplayActive = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setDisplayActive) object:nil];
    [invokeSetDisplayActive addDependency:invokesetLastCacheDate];
    
    invokeReloadWithSize = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(reloadWithSize:) object:[NSValue valueWithCGSize:document.paper.paperSize]];
    [invokeReloadWithSize addDependency:invokeSetDisplayActive];
    
    invokeTimerDealloc = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(timerDealloc) object:nil];
    [invokeTimerDealloc addDependency:invokeReloadWithSize];
    
    invokeTimeSinceLastUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateTimeSinceLastRefresh:) object:nil];
    [invokeTimeSinceLastUpdate addDependency:invokeTimerDealloc];
    
    invokeRemoveObserver = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(removeObserverDidReadRowsFromDatabase:) object:document.database];
    [invokeRemoveObserver addDependency:invokeTimeSinceLastUpdate];
    
    
    [[NSOperationQueue mainQueue] addOperation:invokeUpdateNumberOfPages];
    [[NSOperationQueue mainQueue] addOperation:invokeUpdateRecordsRead];
    [[NSOperationQueue mainQueue] addOperation:invokePageSliderNeedsLayout];
    [[NSOperationQueue mainQueue] addOperation:invokesetLastCacheDate];
    [[NSOperationQueue mainQueue] addOperation:invokeSetDisplayActive];
    [[NSOperationQueue mainQueue] addOperation:invokeReloadWithSize];
    [[NSOperationQueue mainQueue] addOperation:invokeTimerDealloc];
    [[NSOperationQueue mainQueue] addOperation:invokeTimeSinceLastUpdate];
    [[NSOperationQueue mainQueue] addOperation:invokeRemoveObserver];
    
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        [document regenThumbnail];
    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    self.presentationController.delegate = self;
    
    MADPageSlider *pageSlider = self.pageSlider;
    [self.view addSubview: pageSlider];
    [self.view bringSubviewToFront: pageSlider];

    [self updateNavigationPrompt:animated];
    [self.navigationController.toolbar setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    id page;
    NSArray *pages;
    if (self.loadDocumentViewerQueue.operationCount > 0) {
        //NSLog(@"Loading a blank");
        page = [[UIViewController alloc] init];
    } else {
        //NSLog(@"Loading a document");
        MADocument *document = self.document;
        MADPageViewAttributes *pageAttributes;
        CGSize paperSize = document.paper.paperSize;
        NSUInteger pageNumber = self.currentPageNumber, pageCount = _currentLocation.totalPages;;
        pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPageNumber: pageNumber
                                                               totalNumberOfPages: pageCount
                                                                contentSizeInital: paperSize];
        page =
        [MADDocumentPageController newReportPageViewControllerWithDocument: document
                                                              pageAttributes: pageAttributes];

        ((MADDocumentPageController *)page).view.frame = self.view.bounds;
        ((MADDocumentPageController *)page).delegate = self;

    }
    
    pages = [[NSArray alloc] initWithObjects:page, nil];
    [self setViewControllers: pages
                   direction: UIPageViewControllerNavigationDirectionForward
                    animated: animated
                  completion: ^(BOOL finished) { }];

    [self setToolbarItems: self.toolbarItemsActive animated:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self updateTimeSinceLastRefresh:self];
    
    UIBarButtonItem *barButtonItemRefresh;
    barButtonItemRefresh= [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
                                                                        target: self
                                                                        action: @selector(refresh:)];
    barButtonItemRefresh.enabled = YES;
    [self.tabBarController.navigationItem setRightBarButtonItem: barButtonItemRefresh
                                                       animated: YES];

    UIBarButtonItem *barButtonItemDone;
    barButtonItemDone= [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                        target: self
                                                                        action: @selector(done:)];
    barButtonItemDone.enabled = YES;
    [self.tabBarController.navigationItem setLeftBarButtonItem: barButtonItemDone
                                                      animated: YES];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    NSArray *emptyArray = [[NSArray alloc] init];
    [self setToolbarItems: emptyArray animated: animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.tabBarController.navigationItem setRightBarButtonItem:nil];
    // FIXME: This has to be cleared, or the cache grows, and grows.
    [self timerDealloc];
    _pageSlider.sliderDelegate = nil;
    [_pageSlider removeFromSuperview];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    CGFloat nonSliderButtonsWidth = CGSizeZero.width;
    NSUInteger counter = 0;
    
    NSArray<UIBarButtonItem *> *items = self.navigationController.toolbar.items;
    for (UIBarButtonItem *barButtonItem in items) {
        NSString *viewSelector = NSStringFromSelector(@selector(view));
        UIView *view = [barButtonItem valueForKey:viewSelector];
        if (view != nil) {
            nonSliderButtonsWidth += (view ? view.frame.size.width : CGSizeZero.width) + MADBarButtonItemsMargin;
        } else {
            nonSliderButtonsWidth += barButtonItem.width;
        }
        counter++;
    }
    [self.pageSlider setNeedsLayout];
    [self.view bringSubviewToFront:self.pageSlider];
    self.labelStatus.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 44.0000f);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return self;
}

- (void)presentationTransitionWillBegin {
    //NSLog(@"%s", __PRETTY_FUNCTION__);2
}
- (void)presentationTransitionDidEnd:(BOOL)completed {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void)dismissalTransitionWillBegin {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void)dismissalTransitionDidEnd:(BOOL)completed {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark UIViewControllerContextTransitioning

// This is used for percent driven interactive transitions, as well as for container controllers that have companion animations that might need to
// synchronize with the main animation.
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return 3.0;
}

// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    //UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    self.pageSlider.alpha = 0.0f;
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:transitionDuration animations:^{
        //NSLog(@"%s", __PRETTY_FUNCTION__);
        self.pageSlider.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

#pragma mark -
#pragma mark UIContentContainer

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
    
    //short circuit
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, NSStringFromCGSize(size));
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);

        [self.navigationController.toolbar setNeedsLayout];
        [self.navigationItem.titleView sizeToFit];
        [self.pageSlider setNeedsLayout];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);
        [self.navigationController.toolbar setNeedsLayout];
        [self.navigationItem.titleView sizeToFit];
        [self.pageSlider setNeedsLayout];
        
    }];
}

#pragma mark - MTPrintingProtocol

- (MTReportViewerPrintPageRenderer *)printPageRenderer {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return self.printPageRendererReport;
}

#pragma mark - UIStateRestore

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
}

- (void)applicationFinishedRestoringState {
    [super applicationFinishedRestoringState];
}

#pragma mark -
#pragma mark MADPageSliderDelegate

- (void)sliderDidChangeToPage:(NSUInteger)page {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self moveToPageAtIndex:page];
}

#pragma mark -
#pragma mark Overrides

- (MADDateFromTimeFormatter *)dateTimeFormatter {
    if (_dateTimeFormatter == nil) {
        MADDateFromTimeFormatter *dateTimeFormatter = [[MADDateFromTimeFormatter alloc] init];
        _dateTimeFormatter = dateTimeFormatter;
    }
    return _dateTimeFormatter;
}

+ (NSString *)Title {
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    NSString *title = [[NSString alloc] initWithFormat: @"MAD %@", localizedSuffix];
    return title;
}

- (NSString *)title {
    if (_title == nil) {
        NSString *title = [self.class Title];
        _title = title.copy;
    }
    return _title;
}

#pragma mark - properties

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemMadViewer8];
}

- (nullable MADDocumentPageController *)visiblePageViewController {
    return self.viewControllers.count > 0 ? self.viewControllers[0] : nil;
}

- (BOOL)moveToPageAtIndex:(NSUInteger)index {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL result = NO;
    if ((unsigned long)index != _currentLocation.currentPage && index != NSNotFound) {
        
        MADDocumentPageController *visiblePageViewController = [self visiblePageViewController];
        _currentLocation.currentPage = index;
        
        [self.labelStatus updatePageStatus:_currentLocation.totalPages currentPageIndex:_currentLocation.currentPage];

        MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
        pageAttributes.pageNumber = index + 1;
        pageAttributes.numberOfPages = _currentLocation.totalPages;
        
        MADDocumentScroller *documentScroller = visiblePageViewController.documentScroller;
        pageAttributes.zoomScaleInital = documentScroller.zoomScale;
        pageAttributes.contentOffsetInital = documentScroller.contentOffset;
        pageAttributes.contentSizeInital = documentScroller.contentSize;
        pageAttributes.contentScaleFactor = visiblePageViewController.documentView.contentScaleFactor;
        
        MADDocumentPageController *pageOne =
            [[MADDocumentPageController alloc] initWithDocument: self.document
                                               andPageAttributtes: pageAttributes];

        pageOne.view.frame = self.view.bounds;
        pageOne.view.backgroundColor = self.view.backgroundColor;
        pageOne.delegate = self;
    
        [self.view bringSubviewToFront: self.pageSlider];
 
        NSArray *viewControllers = [[NSArray alloc] initWithObjects:pageOne, nil];
        _updatingOfTimerIsPaused = NO;
        _refreshing = NO;
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO completion:^(BOOL finished) {
        
            if (finished) {
                [pageOne.view setNeedsDisplay];
            }

        }];
        result = YES;
    }
    return result;
}

- (MADDocumentPageController *)currentPageviewController {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    MADDocumentPageController *currentPageviewController;
    currentPageviewController = [self pageViewControllerAtIndex: _currentLocation.currentPage];
    return currentPageviewController;
}

- (MADDocumentPageController *)pageViewControllerAtIndex:(NSUInteger)index {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return index < self.viewControllers.count ? self.viewControllers[index] :
                                                self.viewControllers.lastObject;
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
                self.navigationController : self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error];
    NSAssert(success, @"Failed to delete file.");
    
}

#pragma mark - Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
    [self.labelStatus updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
    [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

#pragma mark - UI Updates

- (void)setDisplayActive {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        self.pageingEnabled = YES;
        self.tabBarItemsEnabled = YES;
        self.pageSlider.enabled = YES;
        self.barButtonItemActivity.enabled = YES;
        self->_refreshing = NO;
        self->_updatingOfTimerIsPaused = NO;

        UIBarButtonItem *barButtonItemRefresh;
        barButtonItemRefresh= [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
                                                                            target: self
                                                                            action: @selector(refresh:)];
        barButtonItemRefresh.enabled = YES;
        [self.tabBarController.navigationItem setRightBarButtonItem: barButtonItemRefresh
                                                           animated: YES];
        
    }];
}

- (void)setDisplayInactive {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        self.pageingEnabled = NO;
        self.tabBarItemsEnabled = NO;
        self.pageSlider.enabled = NO;
        self.barButtonItemActivity.enabled = NO;
        self->_refreshing = YES;
        self->_updatingOfTimerIsPaused = NO;

        UIActivityIndicatorView *activityIndicator;
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
        activityIndicator.hidden = NO;
        activityIndicator.hidesWhenStopped = NO;
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [activityIndicator startAnimating];
        [self.tabBarController.navigationItem setRightBarButtonItem: barButtonItem animated: YES];
        
    }];
}

- (void)setPageingEnabled:(BOOL)enabled {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSArray *gestureRecognizers = self.gestureRecognizers;
    [gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer * _Nonnull gestureRecognizer, NSUInteger idx, BOOL * _Nonnull stop) {
        gestureRecognizer.enabled = enabled;
    }];
}

- (void)setTabBarItemsEnabled:(BOOL)enabled {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSArray <UITabBarItem *> *tabBarItems = self.tabBarController.tabBar.items;
    [tabBarItems enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UITabBarItem * _Nonnull tabBarItem, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            tabBarItem.enabled = enabled;
        }];
    }];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSError *error = nil;
    MADocument *document = self.document;
    [document.managedObjectContext save:&error];
    if (error != nil) { [document.managedObjectContext save:&error]; }
    
    
    id <MADViewControllerStandardProtocol> viewControllerDelegate;
    viewControllerDelegate = self.viewControllerDelegate;
    [viewControllerDelegate viewControllerDidFinish: self];
    viewControllerDelegate = nil;
}

- (IBAction)activity:(id)sender {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    _activityExporting = YES;
    self.pageSlider.enabled = NO;
    
    MTActivityItemProviderPdf *activityItemProviderPdf = self.activityItemProviderPdf;
    activityItemProviderPdf.delegate = self;
    NSArray *activityItems = [[NSArray alloc] initWithObjects: activityItemProviderPdf, nil];
    self.activityItemProviderPdf = activityItemProviderPdf;
    
    MTActivityReportPrintPreview *printPreview = [[MTActivityReportPrintPreview alloc] init];
    printPreview.delegate = self;
    
    NSArray *applicationActivities = [[NSArray alloc] initWithObjects: printPreview, nil];
    
    UIActivityViewController *activityViewController;
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                               applicationActivities:applicationActivities];
    
    MADViewerController * __weak weakself = self;

    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
        MADViewerController *sself = weakself;
        
        sself.pageSlider.enabled = YES;
        sself->_activityExporting = NO;
        
        if (completed || (!completed && activityType == nil)) {
            [(MADTabBarController *)sself.tabBarController enableTabBarItems];
            
        } else {
            
            if (activityType.length > 0) {  // Long running activity
                
                if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
                    
                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
                    
                    if (sharedController) {
                        
                        id document = sself.document;
                        MTReportViewerPrintPageRenderer *printPageRenderer;
                        printPageRenderer = [MTReportViewerPrintPageRenderer newReportViewerPrintPageRendererWithDataSource: document];
                        
                        sharedController.delegate = document;
                        sharedController.printPageRenderer = printPageRenderer;
                        
                        if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
                            
                            [MADViewerController setNavigationBarAppearanceHighlighted];
                            
                            MADViewerController * __weak weakself2 = sself;
                            [sharedController presentAnimated:YES completionHandler:
                             ^(UIPrintInteractionController *printInteractionController,
                               BOOL animatinCompleted, NSError *error) {
                                 
                                 if (animatinCompleted) {
                                     MADViewerController *sself2 = weakself2;
                                     [MADViewerController setNavigationBarAppearanceTinted];
                                     
                                     sself2.pageSlider.enabled = YES;
                                     sself2->_activityExporting = NO;
                                     [(MADTabBarController *)sself2.tabBarController enableTabBarItems];
                                 }
                                 
                             }];
                            
                        }
                        
                        
                    }
                }
            } else {
                [(MADTabBarController *)sself.tabBarController enableTabBarItems];
            }
        }
    };
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *ppc = activityViewController.popoverPresentationController;
    ppc.barButtonItem = sender;
    
    MADViewerController * __weak weakSelf = self;
    [self presentViewController:activityViewController animated:YES completion:^{
        weakSelf.presentedViewController.navigationController.navigationBar.barTintColor =
            [MADColorEverydayApps newColorAnalogous4];
    }];
    [(MADTabBarController *)self.tabBarController disableTabBarItems];
}

- (IBAction)refresh:(id)sender {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    self->_didRefreshBeforeReaload = YES;
    self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    
    if (_refreshing == NO) {
        self->_startedRefresh = YES;
        _refreshing = YES;
        
        [self setDisplayInactive];

        MADocument *document = self.document;

        [self addObserverDidReadRowsToDatabase:document.database];
        
        MADOperationRefreshReload *refreshOperation;
        refreshOperation = [[MADOperationRefreshReload alloc] initWithDocument:document viewController:self
                                                            databaseConnection:document.database.databaseConnection];
        [refreshOperation addObserver:self];
        [self.refreshQueue addOperation:refreshOperation];
        
        
    }
}

- (void)addObserverDidReadRowsToDatabase:(MTDatabase *)database {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reportDocumentDidReadRows:)
                                                 name: MADNotificationDidReadRowsName
                                               object: database];
}

- (void)removeObserverDidReadRowsFromDatabase:(MTDatabase *)database {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MADNotificationDidReadRowsName
                                                  object: database];
}


- (IBAction)zoomToActualSize:(id)sender {
    
}

- (IBAction)zoomToFit:(id)sender {
    
}

- (IBAction)zoomToFullScreen:(id)sender {
    
}

#pragma mark - Acivities

- (MTActivityItemProviderPdf *)activityItemProviderPdf {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    NSString *temporaryDirectoryPath = NSTemporaryDirectory();
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
    NSURL *urlEmpty = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    MTActivityItemProviderPdf *activityItemProviderPdf;
    activityItemProviderPdf= [[MTActivityItemProviderPdf alloc] initWithPlaceholderItem:urlEmpty];
    activityItemProviderPdf.document = self.document;
    return activityItemProviderPdf;
}

#pragma mark - UIDocumentInteractionController

- (UIViewController *)previewViewControllerForInteractionController: (UIDocumentInteractionController *) controller {
    return self;
}

- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller completion:(void (^)(BOOL))completion {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        completion(YES);
    } else {
        [self.popoverControllerActivity dismissPopoverAnimated:YES];
        completion(YES);
    }
}

#pragma mark - Load data

- (void)reloadWithSize:(NSValue *)viewBoundsWrapper {
    CGSize viewBounds = [viewBoundsWrapper CGSizeValue];

    if (self.backgroundTaskIdRefresh == UIBackgroundTaskInvalid) {
        self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    }
    
    [self setDisplayInactive];

    MADocument *document = self.document;
    
    [document prepareForQuery];
    
    [self watchFormatter: document.reportFormatter];
    
    document.reportFormatter.didRefresh = self->_startedRefresh;
    [document.reportFormatter formatForSize:viewBounds contentChanged: NO];
    
    MTReportViewerPrintPageRenderer *printPageRenderer =
    [[MTReportViewerPrintPageRenderer alloc] initWithDataSource:document];
    self.printPageRendererReport = printPageRenderer;
    
    [self ignoreFormatter: document.reportFormatter];
    [self updateNumberOfPages];
    
    MADPageViewAttributes *pageAttributes;
    pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPageNumber: self.currentPageNumber
                                                           totalNumberOfPages: _currentLocation.totalPages
                                                            contentSizeInital: document.paper.paperSize];
    
    if (self) {
        MADDocumentPageController *pageOne =
        [MADDocumentPageController newReportPageViewControllerWithDocument: document
                                                              pageAttributes: pageAttributes];
        pageOne.view.frame = self.view.bounds;
        pageOne.delegate = self;
        
        NSArray *viewControllers = [[NSArray alloc] initWithObjects:pageOne, nil];
        
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO
                      completion: nil];
        
        [self setDisplayActive];
    }
    
    _refreshing = NO;
    _startedRefresh = NO;
    
    [self updateRecordsRead];
    
    document.reportFormatter.didRefresh = NO;
    
    if (self.backgroundTaskIdRefresh != UIBackgroundTaskInvalid) {
        
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        
        if (_didRefreshBeforeReaload) {
            NSString *body = NSLocalizedString(@"Refresh completed.", @"Refresh completed.");
            notification.alertBody = body;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            _didRefreshBeforeReaload = NO;
        }
        
        NSNumber *bgtask;
        bgtask = [[NSNumber alloc] initWithUnsignedInteger: self.backgroundTaskIdRefresh];
        self.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
        [[UIApplication sharedApplication] handoffBackground:bgtask];
    }
}

#pragma mark - Post Report Notifications

- (void)watchFormatter:(MTReportFormatter *)formatter {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reportFormatterDidFormatPage:)
                                                 name: MADNotificationDidFormatPagesName
                                               object: formatter];
}

- (void)ignoreFormatter:(MTReportFormatter *)formatter {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MADNotificationDidFormatPagesName
                                                  object: formatter];
}

#pragma mark -
#pragma mark UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
       viewControllerAfterViewController:(MADDocumentPageController *)pageViewControllerLast {
    MADDocumentPageController *result = nil;

    if (viewerViewController->_pageIsAnimating == NO) {
        NSUInteger visiblePageNumber = 0;
        pageViewControllerLast.view.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                                       UIViewAutoresizingFlexibleWidth;
        pageViewControllerLast.view.translatesAutoresizingMaskIntoConstraints = YES;
        
        if (pageViewControllerLast != nil &&
            [pageViewControllerLast respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerLast.pageViewAttributes.pageNumber;
        }
        
        if (visiblePageNumber + 1 <= _currentLocation.totalPages) {
            
            UIScrollView *documentScroller = pageViewControllerLast.documentScroller;

            MADPageViewAttributes *pageAttributes;
            pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPageNumber: visiblePageNumber - 1
                                                                   totalNumberOfPages: _currentLocation.totalPages
                                                                    contentSizeInital: documentScroller.contentSize];
            pageAttributes.zoomScaleInital = documentScroller.zoomScale;
            pageAttributes.contentOffsetInital = documentScroller.contentOffset;
            pageAttributes.contentScaleFactor = pageViewControllerLast.documentView.contentScaleFactor;

            result = [[MADDocumentPageController alloc] initWithDocument: self.document
                                                        andPageAttributtes: pageAttributes];
            result.delegate = self;
            result.view.backgroundColor = self.view.backgroundColor;
            result.view.frame = self.view.bounds;
            result.view.autoresizingMask = MADViewAutoresizingFlexable();
            result.view.translatesAutoresizingMaskIntoConstraints = YES;
        }
    }
    return result;
    
}

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
      viewControllerBeforeViewController:(MADDocumentPageController *)pageViewControllerPrevious {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    MADDocumentPageController *result = nil;
    
    if (viewerViewController->_pageIsAnimating == NO) {
        
        NSUInteger visiblePageNumber = 0;
        
        if (pageViewControllerPrevious != nil && [pageViewControllerPrevious respondsToSelector:@selector(pageNumber)]) {
        
            visiblePageNumber = pageViewControllerPrevious.pageViewAttributes.pageNumber;
            
        }
        if (visiblePageNumber - 1 > 0) {
            
            UIScrollView *documentScroller = pageViewControllerPrevious.documentScroller;
            //MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
            MADPageViewAttributes *pageAttributes;
            pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPageNumber: visiblePageNumber - 1
                                                                   totalNumberOfPages: _currentLocation.totalPages
                                                                    contentSizeInital: documentScroller.contentSize];
            pageAttributes.zoomScaleInital = documentScroller.zoomScale;
            pageAttributes.contentOffsetInital = documentScroller.contentOffset;
            pageAttributes.contentScaleFactor = pageViewControllerPrevious.documentView.contentScaleFactor;

            result = [[MADDocumentPageController alloc] initWithDocument: self.document
                                                        andPageAttributtes: pageAttributes];
            result.view.backgroundColor = self.view.backgroundColor;

            result.delegate =  self;
            result.view.frame = self.view.bounds;
            result.view.autoresizingMask = MADViewAutoresizingFlexable();
            result.view.translatesAutoresizingMaskIntoConstraints = YES;
        }
        
    }

    return result;
}

#pragma mark -
#pragma mark UIPageViewControllerDelegate

- (void)pageViewController:(MADViewerController *)pageViewController
        didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {

    if (completed || finished) {
        pageViewController->_pageIsAnimating = NO;

        if (pageViewController.viewControllers.count > 0) {
            MADDocumentPageController *viewController = pageViewController.viewControllers[0];
            pageViewController->_currentLocation.currentPage = viewController.pageViewAttributes.pageNumber - 1;
            [self.labelStatus updatePageStatus: _currentLocation.totalPages
                              currentPageIndex: _currentLocation.currentPage];
            [pageViewController.pageSlider.pageSlider setValue: pageViewController->_currentLocation.currentPage
                                                      animated: YES];
        }

    }

}

- (UIPageViewControllerSpineLocation)pageViewController:(MADViewerController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    pageViewController->_pageIsAnimating = NO;
    return UIPageViewControllerSpineLocationMin;

}

- (void)pageViewController:(MADViewerController *)pageViewController
                            willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    pageViewController->_pageIsAnimating = YES;
}

#pragma mark - Status Label

- (void)updateTimeSinceLastRefresh:(id)sender {
    MADLabelStatus *labelStatus = self.labelStatus;
    MTDateResolution resolution;
    
    if (self.lastCacheDate == nil) {    // No Cache exist, so return quickly.
        NSError *error = nil;
        NSString *path = self.document.urlDataTableCache.path;
        NSDictionary *attributes =
            [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        if (error == nil) {
            self.lastCacheDate = attributes.fileModificationDate;
        }

        if (self.lastCacheDate == nil) {    // Find last cache date
            NSString *noCache = NSLocalizedString(MADTextNoCache, MADTextNoCache);
            [labelStatus updateStatusWithTime:noCache];
            return;
        }
        
    }

    MTPair *dateStringAndInterval;
    dateStringAndInterval = [self.dateTimeFormatter stringWithTimeIntervalSinceDate:self.lastCacheDate];
    [labelStatus updateStatusWithTime:dateStringAndInterval.former];
    resolution = ((NSNumber *)dateStringAndInterval.latter).shortValue;

    if (self.timerLabelTimeSinceRefreh != nil) {
        if ([self.timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ((self.timerLabelTimeSinceRefreh).valid) {
                [self.timerLabelTimeSinceRefreh invalidate];
            }
        }
        self.timerLabelTimeSinceRefreh = nil;
    }
    
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: [MADDateFromTimeFormatter timeIntervalForResolution:resolution]
                                                  target: self selector: @selector(updateTimeSinceLastRefresh:)
                                                userInfo: nil repeats: NO];
    self.timerLabelTimeSinceRefreh = t;
}

- (void)updateRecordsRead {
    NSNumber *numberOfResults;
    numberOfResults = [[NSNumber alloc] initWithUnsignedInteger: self.document.dataTable.rowCounter];
    [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];

}

- (void)updateNumberOfPages {
    _currentLocation.totalPages = self.document.reportFormatter.numberOfPages;
    [self updateNumberOfPages: (_currentLocation.totalPages > 0 ? (_currentLocation.totalPages - 1) : 0)];
    [self setDisplayActive];
}

- (void)updateNumberOfPages:(NSUInteger)numberOfPages {
    MADPageSlider *slider = self.pageSlider;
    if (round(slider.maximumValue) != round(numberOfPages)) {
        slider.maximumValue = numberOfPages;
    }
    [self.labelStatus updatePageStatus: _currentLocation.totalPages
                      currentPageIndex: _currentLocation.currentPage];

}

#pragma mark -
#pragma mark MTActivityItemProviderDelegate

// ???: Why is it like this?

- (void)showPrintDialog {

    MADViewerController * __weak weakself = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [weakself.popoverControllerActivity dismissPopoverAnimated:YES];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
                    
                    if (sharedController) {
                        MADViewerController *sself = weakself;
                        
                        MADocument *document = sself.document;
                        document.activityDelegate = sself;
                        
                        UIPrintPageRenderer *printPageRenderer;
                        printPageRenderer = [MTReportViewerPrintPageRenderer newReportViewerPrintPageRendererWithDataSource: document];
                        sharedController.printPageRenderer = printPageRenderer;
                        sharedController.delegate = document;
                        
                        MADViewerController * __weak weakself2 = sself;
                        
                        ;
                        
                        [sharedController presentFromBarButtonItem: sself.barButtonItemActivity
                                                          animated: YES
                                                 completionHandler: ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
                            
                            MADViewerController *sself2 = weakself2;
                            
                            sself2.pageSlider.enabled = YES;
                            [(MADTabBarController *)sself2.tabBarController enableTabBarItems];
                        }];
                    }
                });
            });
        });
    });
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [(MADTabBarController *)self.tabBarController enableTabBarItems];
}

- (UIViewController *)activeViewController { return self; }

#pragma mark - UIAccessibility

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    switch (direction) {

        case UIAccessibilityScrollDirectionNext:
        case UIAccessibilityScrollDirectionRight:
            return [self moveToPageAtIndex: _currentLocation.currentPage + 1 ];
            break;
            
        case UIAccessibilityScrollDirectionPrevious:
        case UIAccessibilityScrollDirectionLeft:
            return [self moveToPageAtIndex: _currentLocation.currentPage - 1 ];
            break;
            
        default:
            return NO;
            break;
    }
}

- (BOOL)accessibilityPerformEscape {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.viewControllerDelegate viewControllerDidFinish:nil];
    return YES;
}

- (BOOL)isAccessibilityElement {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return NO;
}

#pragma mark -
#pragma mark Traits

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self updateNavigationPrompt:previousTraitCollection != nil];
}

#pragma mark -
#pragma mark Helpers

- (void)updateNavigationPrompt:(BOOL)animated {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [UIView setAnimationsEnabled:animated];
        self.tabBarController.navigationItem.prompt = self.document.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:YES];
    } else {
        self.tabBarController.navigationItem.prompt = nil;
    }
}

- (NSUInteger)currentPageNumber {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return _currentLocation.currentPage + 1;
}

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    
    if ([operation isKindOfClass:[MADOperationRefreshReload class]]) {
        
        if (((MADOperationRefreshReload *)operation).completedSuccessfully) {
            
            [self relaodByBlocks];
            
        }
        
        //MADOperationQueue *operationQueue = [[MADOperationQueue alloc] init];
        //for (NSError *error in errors) {
        //    MADPromptOperationDisplayError *operationErrorDisplay =
        //    [[MADPromptOperationDisplayError alloc] initWithError:error viewController:self];
        //    [operationQueue addOperation:operationErrorDisplay];
        //
        //}
        
    }
}

#pragma mark -
#pragma mark MADViewControllerDocumentProtocol

- (void)setDocument:(MADocument *)document {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    if (_document != document) {
        _document = document;
    }
}

#pragma mark -
#pragma mark UIAccessibilityContainer

/*
- (NSInteger)accessibilityElementCount {
    return 1;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return self.parentViewController.view;
}

- (NSArray *)accessibilityElements {
    self.parentViewController.view.isAccessibilityElement = YES;
    self.parentViewController.view.accessibilityLabel = @"Report";
    NSArray *elements = @[self.parentViewController.view];
    return elements;
}*/

#pragma mark -
#pragma mark Debugging

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    [debug appendFormat:@"Number of Pages:                  %lu\n", (unsigned long)_currentLocation.totalPages];
    [debug appendFormat:@"Current Page Index:               %lu\n", (unsigned long)_currentLocation.currentPage];
    [debug appendFormat:@"Zoom Scale:                       %f\n", self.zoomScale];
    [debug appendFormat:@"Last Cache Date:                  %@\n", self.lastCacheDate];
    [debug appendFormat:@"Timer Label Time Since Refreh:    %@\n", self.timerLabelTimeSinceRefreh];
    [debug appendFormat:@"Page Slider:                      %@\n", self.pageSlider];
    [debug appendFormat:@"Bar Button Item Activity:         %@\n", self.barButtonItemActivity];
    [debug appendFormat:@"Bar Button Label Status:          %@\n", self.barButtonLabelStatus];
    [debug appendFormat:@"Toolbar Items Active:             %@\n", self.toolbarItemsActive];
    [debug appendFormat:@"Print Page Renderer Report:       %@\n", self.printPageRendererReport];
    [debug appendFormat:@"Activity Item ProviderPdf:        %@\n", self.activityItemProviderPdf];
    [debug appendFormat:@"Popover Controller Activity:      %@\n", self.popoverControllerActivity];
    [debug appendFormat:@"Background Task Id Refresh:       %lu\n", (unsigned long)self.backgroundTaskIdRefresh];
    [debug appendFormat:@"Refreshing:                       %@\n", _refreshing ? @"Yes" : @"No"];
    [debug appendFormat:@"Did Refresh Before Reaload:       %@\n", _didRefreshBeforeReaload ? @"Yes" : @"No"];
    [debug appendFormat:@"Activity Exporting:               %@\n", _activityExporting ? @"Yes" : @"No"];
    [debug appendFormat:@"Started Refresh:                  %@\n", _startedRefresh ? @"Yes" : @"No"];
    [debug appendFormat:@"Page is Animating:                %@\n", _pageIsAnimating ? @"Yes" : @"No"];
    [debug appendFormat:@"Updating of Timer is Paused:      %@\n", _updatingOfTimerIsPaused ? @"Yes" : @"No"];
    [debug appendFormat:@"Refresh Queue:                    %@\n", self.refreshQueue];
    return debug;
}

@end



#pragma mark -
#pragma mark MADOperationRenderOnViewert
/*
@interface MADOperationRenderOnViewert ()
    @property (readwrite, nonatomic, weak) MADocument *document;
    @property (readwrite, nonatomic, weak) MTReportViewerPrintPageRenderer *printPageRenderer;
@end

@implementation MADOperationLoadDocument {
    BOOL _executing;
    BOOL _finished;
}

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        [self setDocument: document];
        _executing = NO;
    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isFinished { return _finished; }

- (BOOL)isExecuting { return _executing; }
- (void)executing {

    MADocument *document = self.document;
    self.lastCacheDate = [NSDate date];
    [self setDisplayActive];
    
    [self reloadWithSize:document.paper.paperSize];
    
    [self timerDealloc];
    
    [self updateTimeSinceLastRefresh: NULL];
    
    [self removeObserverDidReadRowsFromDatabase:document.database];
    
    
    
    MADocument *document = self.document;
    _executing = YES;
    
    if (![self isCancelled]) {
        document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
    }
    
    if (![self isCancelled]) {
        RptqDocument *activeDocumentModel = document.activeDocumentModel;
        [document resetMainQueryWithDocumentModel:activeDocumentModel];
    }
    
    if (![self isCancelled]) {
        [document prepareForQuery];
    }
    
    if (![self isCancelled]) {
        __block BOOL blockComplete = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [document.reportFormatter loadFromCacheWithSize: document.paper.paperSize];
            blockComplete = YES;
        });
        
        if (blockComplete) {
            _finished = YES;
            _executing = NO;
        }
        
    } else {
        _finished = YES;
        _executing = NO;
    }
}

@end
*/

#pragma mark -
#pragma mark MADOperationLoadPrintPageRender

@interface MADOperationLoadPrintPageRender ()
    @property (readwrite, nonatomic, weak) MADocument *document;
    @property (readwrite, nonatomic, weak) MTReportViewerPrintPageRenderer *printPageRenderer;
@end

@implementation MADOperationLoadPrintPageRender

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        [self setDocument: document];
    }
    return self;
}

- (void)main {

    MTReportViewerPrintPageRenderer *printPageRenderer;
    MADocument *document;

    if (!self.isCancelled) {
    
        document = self.document;
        printPageRenderer =
        [[MTReportViewerPrintPageRenderer alloc] initWithDataSource:document];
    
        self.printPageRenderer = printPageRenderer;
    }
    
    if (!self.isCancelled && printPageRenderer == nil) {

        [document activeDocumentModel];
        printPageRenderer =
        [[MTReportViewerPrintPageRenderer alloc] initWithDataSource:document];
        self.printPageRenderer = printPageRenderer;
    }
    
    if (!self.isCancelled) {
        document.reportFormatter.didRefresh = NO;
    }
}

@end

#pragma mark -
#pragma mark MADOperationLoadDocument

@interface MADOperationLoadDocument ()

    @property (readwrite, nonatomic, weak) MADocument *document;

@end

@implementation MADOperationLoadDocument {
    BOOL _executing;
    BOOL _finished;
}

static NSString * const MADOperatorSelectorIsReady      = @"isReady";
static NSString * const MADOperatorSelectorIsExecuting  = @"isExecuting";
static NSString * const MADOperatorSelectorIsFinished   = @"isFinished";

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (instancetype)initWithDocument:(MADocument *)document {
    if (self = [super init]) {
        [self setDocument: document];
        _executing = NO;
        _finished = NO;
    }
    return self;
}

/*- (void)start {
    
    // NSOperation.start() contains important logic that shouldn't be bypassed.
    [super start];
    
    // If the operation has been cancelled, we still need to enter the "Finished" state.
    if (self.cancelled) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = NO;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];

        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = YES;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    } else {
        [self main];
    }
}*/

- (BOOL)isAsynchronous {
    return NO;
}

- (BOOL)isFinished { return _finished; }

- (BOOL)isExecuting { return _executing; }

- (void)main {

    //[self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    //_executing = NO;
    //[self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];

    MADocument *document = self.document;
    
    if (![self isCancelled]) {
        document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
    }
    
    if (![self isCancelled]) {
        RptqDocument *activeDocumentModel = document.activeDocumentModel;
        [document resetMainQuery];
    }
    
    if (![self isCancelled]) {
        [document prepareForQuery];
    }
    
    if (![self isCancelled]) {
        __block BOOL blockComplete = NO;
        //dispatch_async(dispatch_get_main_queue(), ^{
            [document.reportFormatter loadFromCacheWithSize: document.paper.paperSize];
            blockComplete = YES;
        //});
        
        if (blockComplete) {
            
            [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
            _finished = YES;
            [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
            
            [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
            _executing = NO;
            [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        }
        
    } else {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = YES;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = NO;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
}

@end
