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
#import "MADRefreshReloadOperation.h"

#import "MADPromptOperationDisplayError.h"

#import "MADOperationObserver.h"
#import "MADLabelTitle.h"
#import "MADIdentifiersStoryboards.h"

static NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";
static NSString * const MADStoryboardIDViewerController = @"MADIdentifierStoryboardViewerViewController";
static NSString * const MADTextNoCache = @"No Cache";

static const CGFloat MADBarButtonItemsMargin = 8.0000f;

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

    @property (nonatomic, assign) NSUInteger numberOfPages;
    @property (nonatomic, assign) NSUInteger currentPageIndex;

    @property (nonatomic, assign, readwrite) CGFloat zoomScale;

    @property (nonatomic, strong) NSDate *lastCacheDate;

#pragma mark Timer (Updates last refresh date on tick)

    @property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;

#pragma mark User Interface

    @property (nonatomic, strong) MADPageSlider *pageSlider;
    @property (nonatomic, weak) MADLabelStatus *labelStatus;
    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemActivity;
    @property (nonatomic, strong) UIBarButtonItem *barButtonLabelStatus;

    @property (nonatomic, strong) NSMutableArray *toolbarItemsActive;

    @property (nonatomic, strong) MTReportViewerPrintPageRenderer *printPageRendererReport;
    @property (nonatomic, strong) MTActivityItemProviderPdf *activityItemProviderPdf;

#pragma mark Controllers

    @property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

#pragma mark Identifiers

    @property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdRefresh;

#pragma mark Viewer State

    @property (nonatomic, assign, getter=isRefreshing) BOOL refreshing;
    @property (nonatomic, assign) BOOL didRefreshBeforeReaload;
    @property (nonatomic, assign) BOOL activityExporting;
    @property (nonatomic, assign) BOOL startedRefresh;
    @property (nonatomic, assign) BOOL pageIsAnimating;
    @property (nonatomic, assign) BOOL updatingOfTimerIsPaused;

    @property (nonatomic, strong) MADOperationQueue *refreshQueue;

    //@property (readonly) MADTabBarController *tabBarController;

@end

@implementation MADViewerController {
    BOOL _isFirstAppearance;
    BOOL _firstTimeViewWillLayoutSubviews;
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
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

#pragma mark - Initalize

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
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

    }
    return self;
}

#pragma mark -
#pragma mark UIViewController Standard Callbacks

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%s", __PRETTY_FUNCTION__);

    id blankPage;
    NSArray *pages;
    
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
    
    self.currentPageIndex = 0;
    
    blankPage = [[UIViewController alloc] init];
    pages = [[NSArray alloc] initWithObjects:blankPage, nil];
    
    //[self setViewControllers: pages
    //               direction: UIPageViewControllerNavigationDirectionForward
    //                animated: NO
    //              completion: ^(BOOL finished) {
    //}];
    
    [self.labelStatus updatePageStatus: self.numberOfPages
                      currentPageIndex: self.currentPageIndex];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.presentationController.delegate = self;
    
    [self setToolbarItems: self.toolbarItemsActive animated: animated];
    
    MADPageSlider *pageSlider = self.pageSlider;
    [self.view addSubview: pageSlider];
    [self.view bringSubviewToFront: pageSlider];

    [self updateNavigationPrompt:animated];
    [self.navigationController.toolbar setNeedsLayout];
    
    MADocument *document = self.document;
    // MARK: Reporting feature (number of results in main query)
    document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;


    RptqDocument *activeDocumentModel = document.activeDocumentModel;

    [document resetMainQueryWithDocumentModel:activeDocumentModel];
    [document activeDocumentModel];
    [document prepareForQuery];
    [document.reportFormatter loadFromCacheWithSize: document.paper.paperSize];
    
    MTReportViewerPrintPageRenderer *printPageRenderer =
        [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                               dataTable: document.mainDataTable];
    self.printPageRendererReport = printPageRenderer;
        
    [self updateNumberOfPages];
    
    
    self.refreshing = NO;
    self.startedRefresh = NO;
    
    [self updateRecordsRead];
    
    document.reportFormatter.didRefresh = NO;
    
    if (self.printPageRendererReport == nil) {
        [document activeDocumentModel];
        
        MTReportViewerPrintPageRenderer *prtingPageRendererReport =
            [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                                   dataTable: document.mainDataTable];
        self.printPageRendererReport = prtingPageRendererReport;
    }
    
    [_pageSlider setNeedsLayout];
    
    if (_isFirstAppearance) {
        _isFirstAppearance = NO;
        MADPageViewAttributes *pageAttributes;
        pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPageNumber: self.currentPageNumber
                                                               totalNumberOfPages: self.numberOfPages
                                                                contentSizeInital: document.paper.paperSize];
        CGRect bounds = self.view.bounds;
        MADReportPageViewController *pageOne =
        [MADReportPageViewController newReportPageViewControllerWithDocument: document
                                                              pageAttributes: pageAttributes];
        pageOne.view.frame = bounds;
        pageOne.delegate = self;
        
        NSArray *viewControllers = [[NSArray alloc] initWithObjects: pageOne, nil];
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: animated
                      completion: ^(BOOL finished) {
                            
                        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self updateTimeSinceLastRefresh:self];
    [self.pageSlider setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSArray *emptyArray = [[NSArray alloc] init];
    [self setToolbarItems: emptyArray animated: animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.tabBarController.navigationItem setRightBarButtonItem:nil];
    // FIXME: This has to be cleared, or the cache grows, and grows.
    [self timerDealloc];
    _pageSlider.sliderDelegate = nil;
    [_pageSlider removeFromSuperview];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    [self.view bringSubviewToFront:self.pageSlider];
    self.labelStatus.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 44.0000f);
    
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return self;
}

- (void)presentationTransitionWillBegin {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return 3.0;
}

// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    //UIViewController *viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    //CGPoint center = viewControllerFrom.view.center;
    self.pageSlider.alpha = 0.0f;
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:transitionDuration animations:^{
        //NSLog(@"%s", __PRETTY_FUNCTION__);
        self.pageSlider.alpha = 1.0f;
        //viewControllerFrom.view.bounds = CGRectZero;
        //viewControllerFrom.view.center = center;
        //viewControllerFrom.view.transform = CGAffineTransformSwing();
    } completion:^(BOOL finished) {
        //NSLog(@"%s", __PRETTY_FUNCTION__);
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

#pragma mark -
#pragma mark UIContentContainer

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
    
    //short circuit
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
}

// This is used for percent driven interactive transitions, as well as for
// container controllers that have companion animations that might need to
// synchronize with the main animation.
//- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
//    super t
//}
// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
//- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext;

/*
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        //UIView * __weak backgroundView = self.collectionView.backgroundView;
        NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, NSStringFromCGSize(size));
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            //            [self.collectionView setNeedsDisplay];
            NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);
            
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);
            
        }];
    }
    
}

//- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
//    if (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
//        [self.collectionView.collectionViewLayout invalidateLayout];
//    }
//}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, newCollection);
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);
        
    }];
    
}
*/


- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
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

/*- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
    NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, newCollection);
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);
        
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, context);
        
        
    }];
}*/

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    /*if (_firstTimeViewWillLayoutSubviews) {
        _firstTimeViewWillLayoutSubviews = NO;
        
        MADocument *document = self.document;
        MADPageViewAttributes *pageAttributes;
        pageAttributes = [[MADPageViewAttributes alloc] initWithCurrentPageNumber: self.currentPageNumber
                                                               totalNumberOfPages: self.numberOfPages
                                                                contentSizeInital: document.paper.paperSize];
        CGRect bounds = self.view.bounds;
        MADReportPageViewController *pageOne =
        [MADReportPageViewController newReportPageViewControllerWithDocument: document
                                                              pageAttributes: pageAttributes];
        pageOne.view.frame = bounds;
        pageOne.delegate = self;
        NSArray *viewControllers = [[NSArray alloc] initWithObjects: pageOne, nil];
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO completion: nil];
    }*/
}

#pragma mark - MTPrintingProtocol

- (MTReportViewerPrintPageRenderer *)printPageRenderer {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    return [MADViewerController MADViewer];
}

- (NSString *)title {
    if (_title == nil) {
        NSString *title = [self.class MADViewer];
        _title = title.copy;
    }
    return _title;
}

#pragma mark - properties

#pragma mark - MTTabBarImageProtocol

+ (UIImage *)newTabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemMadViewer8];
}

- (nullable MADReportPageViewController *)visiblePageViewController {
    return self.viewControllers.count > 0 ? self.viewControllers[0] : nil;
}

- (BOOL)moveToPageAtIndex:(NSUInteger)index {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL result = NO;
    if ((unsigned long)index != self.currentPageIndex && index != NSNotFound) {
        
        MADReportPageViewController *visiblePageViewController = [self visiblePageViewController];
        self.currentPageIndex = index;
        
        [self.labelStatus updatePageStatus:self.numberOfPages currentPageIndex:self.currentPageIndex];

        MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
        pageAttributes.pageNumber = index + 1;
        pageAttributes.numberOfPages = self.numberOfPages;
        pageAttributes.zoomScaleInital = visiblePageViewController.documentScroller.zoomScale;
        pageAttributes.contentOffsetInital = visiblePageViewController.documentScroller.contentOffset;
        pageAttributes.contentSizeInital = visiblePageViewController.documentScroller.contentSize;
        pageAttributes.contentScaleFactor = visiblePageViewController.documentView.contentScaleFactor;
        
        MADReportPageViewController *pageOne =
            [[MADReportPageViewController alloc] initWithDocument: self.document
                                               andPageAttributtes: pageAttributes];

        pageOne.view.frame = self.view.bounds;
        pageOne.view.backgroundColor = self.view.backgroundColor;
        pageOne.delegate = self;
    
        [self.view bringSubviewToFront: self.pageSlider];
 
        NSArray *viewControllers = [[NSArray alloc] initWithObjects:pageOne, nil];
        self.updatingOfTimerIsPaused = NO;
        self.refreshing = NO;
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

- (MADReportPageViewController *)currentPageviewController {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    MADReportPageViewController *currentPageviewController;
    currentPageviewController = [self pageViewControllerAtIndex: self.currentPageIndex];
    return currentPageviewController;
}

- (MADReportPageViewController *)pageViewControllerAtIndex:(NSUInteger)index {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return index < self.viewControllers.count ? self.viewControllers[index] :
                                                self.viewControllers.lastObject;
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ?
                self.navigationController : self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error];
    NSAssert(success, @"Failed to delete file.");
    
}

#pragma mark - Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
    [self.labelStatus updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
    [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

#pragma mark - UI Updates

- (void)setDisplayActive {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        self.pageingEnabled = YES;
        self.tabBarItemsEnabled = YES;
        self.pageSlider.enabled = YES;
        self.barButtonItemActivity.enabled = YES;
        self.refreshing = NO;
        self.updatingOfTimerIsPaused = NO;

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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        self.pageingEnabled = NO;
        self.tabBarItemsEnabled = NO;
        self.pageSlider.enabled = NO;
        self.barButtonItemActivity.enabled = NO;
        self.refreshing = YES;
        self.updatingOfTimerIsPaused = NO;

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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSArray *gestureRecognizers = self.gestureRecognizers;
    [gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer * _Nonnull gestureRecognizer, NSUInteger idx, BOOL * _Nonnull stop) {
        gestureRecognizer.enabled = enabled;
    }];
}

- (void)setTabBarItemsEnabled:(BOOL)enabled {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSArray <UITabBarItem *> *tabBarItems = self.tabBarController.tabBar.items;
    [tabBarItems enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UITabBarItem * _Nonnull tabBarItem, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            tabBarItem.enabled = enabled;
        }];
    }];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);

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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.activityExporting = YES;
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
    UIActivityViewControllerCompletionWithItemsHandler activityCompletionHandler =
    ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
        MADViewerController *sself = weakself;
        
        sself.pageSlider.enabled = YES;
        sself.activityExporting = NO;
        
        if (completed || (!completed && activityType == nil)) {
            [(MADTabBarController *)sself.tabBarController enableTabBarItems];
            
        } else {

            if (activityType.length > 0) {  // Long running activity

                if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {

                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];

                    if (sharedController) {
                        
                        id document = sself.document;
                        MTReportViewerPrintPageRenderer *printPageRenderer;
                        printPageRenderer = [MTReportViewerPrintPageRenderer newReportViewerPrintPageRenderer: document];
                        
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
                                    sself2.activityExporting = NO;
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
    activityViewController.completionWithItemsHandler = activityCompletionHandler;
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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.didRefreshBeforeReaload = YES;
    self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    
    if (self.isRefreshing == NO) {
        self.startedRefresh = YES;
        self.refreshing = YES;
        [self setDisplayInactive];

        MADocument *document = self.document;

        [self addObserverDidReadRowsToDatabase:document.database];
        
        MADRefreshReloadOperation *refreshOperation;
        refreshOperation = [[MADRefreshReloadOperation alloc] initWithDocument:document viewController:self
                                                            databaseConnection:document.database.databaseConnection];
        [refreshOperation addObserver:self];
        [self.refreshQueue addOperation:refreshOperation];
        
    }
}

- (void)addObserverDidReadRowsToDatabase:(MTDatabase *)database {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reportDocumentDidReadRows:)
                                                 name: MADNotificationDidReadRowsName
                                               object: database];
}

- (void)removeObserverDidReadRowsFromDatabase:(MTDatabase *)database {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver: self name: MADNotificationDidReadRowsName
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
    NSLog(@"%s", __PRETTY_FUNCTION__);

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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        completion(YES);
    } else {
        [self.popoverControllerActivity dismissPopoverAnimated:YES];
        completion(YES);
    }
}

#pragma mark - Load data

- (void)reloadWithSize:(CGSize)viewBounds {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.backgroundTaskIdRefresh == UIBackgroundTaskInvalid) {
        self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    }
    
    [self setDisplayInactive];

    MADocument * __unsafe_unretained document = self.document;

    //typedef typeof(self) MADSelf;
    
    typeof(self) __weak weakself = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        typeof(self) sself = weakself;
        
        [document prepareForQuery];
        
        [sself watchFormatter: document.reportFormatter];
        
        document.reportFormatter.didRefresh = sself.startedRefresh;
        [document.reportFormatter formatForSize:viewBounds contentChanged: NO];
        
        MTReportViewerPrintPageRenderer *printPageRenderer =
        [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                               dataTable: document.mainDataTable];
        sself.printPageRendererReport = printPageRenderer;
        
        [sself ignoreFormatter: document.reportFormatter];
        
        
        [sself updateNumberOfPages];
        
        MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
        pageAttributes.pageNumber = sself.currentPageNumber;
        pageAttributes.numberOfPages = sself.numberOfPages;
        
        // FIXME: Don't reset the display size to the paper size.
        pageAttributes.contentSizeInital = document.paper.paperSize;
        pageAttributes.zoomScaleInital = 1.0000f;
        pageAttributes.contentScaleFactor = 0.0;
        
        
        typeof(self) __weak weakself2 = sself;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            typeof(self) sself2 = weakself2;
            if (sself2) {
                MADReportPageViewController *pageOne =
                [MADReportPageViewController newReportPageViewControllerWithDocument: document
                                                                      pageAttributes: pageAttributes];
                pageOne.view.frame = sself2.view.bounds;
                pageOne.delegate = sself2;

                NSArray *viewControllers = [[NSArray alloc] initWithObjects:pageOne, nil];
                
                [sself2 setViewControllers: viewControllers
                                 direction: UIPageViewControllerNavigationDirectionForward
                                  animated: NO completion: nil];
                
                [sself2 setDisplayActive];
            }
        }];
        
        sself.refreshing = NO;
        sself.startedRefresh = NO;
        
        [sself updateRecordsRead];
        
        document.reportFormatter.didRefresh = NO;
        
        if (sself.backgroundTaskIdRefresh != UIBackgroundTaskInvalid) {
            
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            
            if (sself.didRefreshBeforeReaload) {
                NSString *body = NSLocalizedString(@"Refresh completed.", @"Refresh completed.");
                notification.alertBody = body;
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                sself.didRefreshBeforeReaload = NO;
            }
            
            NSNumber *bgtask;
            bgtask = [[NSNumber alloc] initWithUnsignedInteger: sself.backgroundTaskIdRefresh];
            sself.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
            [[UIApplication sharedApplication] handoffBackground:bgtask];
        }

    });
}

#pragma mark - Post Report Notifications

- (void)watchFormatter:(MTReportFormatter *)formatter {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reportFormatterDidFormatPage:)
                                                 name: MADNotificationDidFormatPagesName
                                               object: formatter];
}

- (void)ignoreFormatter:(MTReportFormatter *)formatter {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MADNotificationDidFormatPagesName
                                                  object: formatter];
}

#pragma mark -
#pragma mark UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
       viewControllerAfterViewController:(MADReportPageViewController *)pageViewControllerLast {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MADReportPageViewController *result = nil;

    if (viewerViewController.pageIsAnimating == NO) {
        NSUInteger visiblePageNumber = 0;
        pageViewControllerLast.view.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                                       UIViewAutoresizingFlexibleWidth;
        pageViewControllerLast.view.translatesAutoresizingMaskIntoConstraints = YES;
        
        if (pageViewControllerLast != nil &&
            [pageViewControllerLast respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerLast.pageViewAttributes.pageNumber;
        }
        
        if (visiblePageNumber + 1 <= self.numberOfPages) {
            
            UIScrollView *documentScroller = pageViewControllerLast.documentScroller;
            
            MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
            pageAttributes.pageNumber = visiblePageNumber + 1;
            pageAttributes.numberOfPages = self.numberOfPages;
            pageAttributes.zoomScaleInital = documentScroller.zoomScale;
            pageAttributes.contentOffsetInital = documentScroller.contentOffset;
            pageAttributes.contentSizeInital = documentScroller.contentSize;
            pageAttributes.contentScaleFactor = pageViewControllerLast.documentView.contentScaleFactor;

            result = [[MADReportPageViewController alloc] initWithDocument:self.document
                                                        andPageAttributtes:pageAttributes];
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
      viewControllerBeforeViewController:(MADReportPageViewController *)pageViewControllerPrevious {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MADReportPageViewController *result = nil;
    
    if (viewerViewController.pageIsAnimating == NO) {
        
        NSUInteger visiblePageNumber = 0;
        
        if (pageViewControllerPrevious != nil && [pageViewControllerPrevious respondsToSelector:@selector(pageNumber)]) {
        
            visiblePageNumber = pageViewControllerPrevious.pageViewAttributes.pageNumber;
            
        }
        if (visiblePageNumber - 1 > 0) {
            
            UIScrollView *documentScroller = pageViewControllerPrevious.documentScroller;
            MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
            pageAttributes.pageNumber = visiblePageNumber - 1;
            pageAttributes.numberOfPages = self.numberOfPages;
            pageAttributes.zoomScaleInital = documentScroller.zoomScale;
            pageAttributes.contentOffsetInital = documentScroller.contentOffset;
            pageAttributes.contentSizeInital = documentScroller.contentSize;
            pageAttributes.contentScaleFactor = pageViewControllerPrevious.documentView.contentScaleFactor;

            result = [[MADReportPageViewController alloc] initWithDocument:self.document andPageAttributtes:pageAttributes];
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

//- (NSInteger)presentationCountForPageViewController:(MADViewerController *)pageViewController {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    return (NSInteger)pageViewController.numberOfPages;
//}

//- (NSInteger)presentationIndexForPageViewController:(MADViewerController *)pageViewController {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    return (NSInteger)pageViewController.currentPageIndex;
//}

- (void)pageViewController:(MADViewerController *)pageViewController
        didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (completed || finished) {
        pageViewController.pageIsAnimating = NO;

        if (pageViewController.viewControllers.count > 0) {
            MADReportPageViewController *viewController = pageViewController.viewControllers[0];
            pageViewController.currentPageIndex = viewController.pageViewAttributes.pageNumber - 1;
            [self.labelStatus updatePageStatus: self.numberOfPages
                              currentPageIndex: self.currentPageIndex];
            [pageViewController.pageSlider.pageSlider setValue: pageViewController.currentPageIndex
                                                      animated: YES];
        }

    }

}

- (UIPageViewControllerSpineLocation)pageViewController:(MADViewerController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    pageViewController.pageIsAnimating = NO;
    return UIPageViewControllerSpineLocationMin;

}

- (void)pageViewController:(MADViewerController *)pageViewController
                            willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    pageViewController.pageIsAnimating = YES;
}

#pragma mark - Status Label

- (void)updateTimeSinceLastRefresh:(id)sender {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MTDataTableFast *mainDataTable;
    NSNumber *numberOfResults;
    mainDataTable = self.document.mainDataTable;
    numberOfResults = [[NSNumber alloc] initWithUnsignedInteger: mainDataTable.rowCounter];
    [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];

}

- (void)updateNumberOfPages {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.numberOfPages = self.document.reportFormatter.numberOfPages;
    [self updateNumberOfPages: (self.numberOfPages > 0 ? (self.numberOfPages - 1) : 0)];
    [self setDisplayActive];
}

- (void)updateNumberOfPages:(NSUInteger)numberOfPages {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MADPageSlider *slider = self.pageSlider;
    if (round(slider.maximumValue) != round(numberOfPages)) {
        slider.maximumValue = numberOfPages;
    }
    [self.labelStatus updatePageStatus: self.numberOfPages
                      currentPageIndex: self.currentPageIndex];

}

#pragma mark -
#pragma mark MTActivityItemProviderDelegate

// ???: Why is it like this?

- (void)showPrintDialog {
    NSLog(@"%s", __PRETTY_FUNCTION__);

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
                        printPageRenderer = [MTReportViewerPrintPageRenderer newReportViewerPrintPageRenderer: document];
                        sharedController.printPageRenderer = printPageRenderer;
                        sharedController.delegate = document;
                        
                        MADViewerController * __weak weakself2 = sself;
                        
                        void (^completion)(UIPrintInteractionController *, BOOL, NSError *) =
                            ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
                            
                            MADViewerController *sself2 = weakself2;
                            
                            sself2.pageSlider.enabled = YES;
                            [(MADTabBarController *)sself2.tabBarController enableTabBarItems];
                        };
                        
                        [sharedController presentFromBarButtonItem:sself.barButtonItemActivity animated:YES completionHandler:completion];
                    }
                });
            });
        });
    });
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [(MADTabBarController *)self.tabBarController enableTabBarItems];
}

- (UIViewController *)activeViewController { return self; }

#pragma mark - UIAccessibility

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    switch (direction) {

        case UIAccessibilityScrollDirectionNext:
        case UIAccessibilityScrollDirectionRight:
            return [self moveToPageAtIndex: self.currentPageIndex + 1 ];
            break;
            
        case UIAccessibilityScrollDirectionPrevious:
        case UIAccessibilityScrollDirectionLeft:
            return [self moveToPageAtIndex: self.currentPageIndex - 1 ];
            break;
            
        default:
            return NO;
            break;
    }
}

- (BOOL)accessibilityPerformEscape {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.viewControllerDelegate viewControllerDidFinish:nil];
    return YES;
}

- (BOOL)isAccessibilityElement {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return NO;
}

#pragma mark -
#pragma mark Traits

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self updateNavigationPrompt:previousTraitCollection != nil];
}

#pragma mark -
#pragma mark Helpers

- (void)updateNavigationPrompt:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [UIView setAnimationsEnabled:animated];
        self.tabBarController.navigationItem.prompt = self.document.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:YES];
    } else {
        self.tabBarController.navigationItem.prompt = nil;
    }
}

- (NSUInteger)currentPageNumber {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return self.currentPageIndex + 1;
}

#pragma mark -
#pragma mark Custom

+ (NSString *)MADViewer {
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [NSString stringWithFormat: @"MAD %@", localizedSuffix];
}

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    
    if ([operation isKindOfClass:[MADRefreshReloadOperation class]]) {
        
        if (((MADRefreshReloadOperation *)operation).completedSuccessfully) {
            
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                
                MADocument *document = self.document;
                self.lastCacheDate = [NSDate date];
                [self setDisplayActive];
                
                [self reloadWithSize:document.paper.paperSize];
                
                [self timerDealloc];
                
                [self updateTimeSinceLastRefresh: NULL];
                
                [self removeObserverDidReadRowsFromDatabase:document.database];
                
            }];
        }
        
        MADOperationQueue *operationQueue = [[MADOperationQueue alloc] init];
        for (NSError *error in errors) {
            MADPromptOperationDisplayError *operationErrorDisplay =
            [[MADPromptOperationDisplayError alloc] initWithError:error viewController:self];
            [operationQueue addOperation:operationErrorDisplay];
            
        }
        
    }
    
}

#pragma mark -
#pragma mark MADViewControllerDocumentProtocol

- (void)setDocument:(MADocument *)document {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    [debug appendFormat:@"Number of Pages:                  %lu\n", (unsigned long)self.numberOfPages];
    [debug appendFormat:@"Current Page Index:               %lu\n", (unsigned long)self.currentPageIndex];
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
    [debug appendFormat:@"Refreshing:                       %@\n", self.refreshing ? @"Yes" : @"No"];
    [debug appendFormat:@"Did Refresh Before Reaload:       %@\n", self.didRefreshBeforeReaload ? @"Yes" : @"No"];
    [debug appendFormat:@"Activity Exporting:               %@\n", self.activityExporting ? @"Yes" : @"No"];
    [debug appendFormat:@"Started Refresh:                  %@\n", self.startedRefresh ? @"Yes" : @"No"];
    [debug appendFormat:@"Page is Animating:                %@\n", self.pageIsAnimating ? @"Yes" : @"No"];
    [debug appendFormat:@"Updating of Timer is Paused:      %@\n", self.updatingOfTimerIsPaused ? @"Yes" : @"No"];
    [debug appendFormat:@"Refresh Queue:                    %@\n", self.refreshQueue];
    return debug;
}

@end
