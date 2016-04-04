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
#import "MUIViewControllerDelegate.h"

#import <CoreData/CoreData.h>

#import <MAD/MADConstants.h>
#import <MAD/MTReportViewerPrintPageRenderer.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTReportFormatter.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MTDataTableFast.h>
#import <MAD/MTQuery.h>
#import <MAD/MTActivityItemProviderPdf.h>
#import <MAD/MADNotificationDidFormatPage.h>
#import <MAD/MADNotificationDidReadRows.h>
#import <MAD/MTKeyChain.h>

#import <MADFoundation/MTDataTable.h>
#import <MADDataStructures/MTPair.h>
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

NSString * const MADImageBarButtonItemMadViewer = @"UIBarButtonItemMadViewer";
NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";


static NSString * const MADTextNoCache = @"No Cache";

static const CGFloat MADSliderPaginationWidth = 40.0000f;
static const CGFloat MADBarButtonItemsMargin = 8.0000f;

@interface MADViewerController ()
    <UIPopoverControllerDelegate,
        UIPrintInteractionControllerDelegate,
        UIStateRestoring,
        MADOperationObserver,
        MADPageSliderProtocol,
        MTPrintingProtocol,
        MTActivityReportPrintPreviewDelegate,
        MTTabBarImageProtocol,
        MTActivityItemProviderDelegate>

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

    @property (nonatomic, weak) MADPageSlider *toolbarSlider;
    @property (nonatomic, weak) MADLabelStatus *labelStatus;
    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemActivity;

    @property (nonatomic, strong) MTReportViewerPrintPageRenderer *printPageRendererReport;
    @property (nonatomic, strong) MTActivityItemProviderPdf *activityItemProviderPdf;

#pragma mark Controllers

    @property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

#pragma mark Identifiers

    @property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdRefresh;

#pragma mark Viewer State

    @property (atomic, assign, getter=isRefreshing) bool refreshing;
    @property (nonatomic, assign) bool didRefreshBeforeReaload;
    @property (nonatomic, assign) bool activityExporting;
    @property (nonatomic, assign) bool startedRefresh;
    @property (nonatomic, assign) bool pageIsAnimating;
    @property (nonatomic, assign) bool updatingOfTimerIsPaused;

    @property (nonatomic, strong) MADOperationQueue *refreshQueue;
    @property (nonatomic, strong) MADRefreshReloadOperation *refreshReloadOperation;

@end

@implementation MADViewerController

#pragma mark - MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors {
    if ([operation isKindOfClass:[MADRefreshReloadOperation class]]) {
        MADocument *operationDocument = ((MADRefreshReloadOperation *)operation).document;
        [operationDocument finishRefresh:((MADRefreshReloadOperation *)operation).completedSuccessfully];
        if (((MADRefreshReloadOperation *)operation).completedSuccessfully) {

            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                
                self.lastCacheDate = [NSDate date];
                [self setDisplayActive];
                [self reload];
                [self timerDealloc];
                [self uiUpdateTimeSinceLastRefresh: NULL];
                [self setDisplayActive];

            }];
        }
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    _document = nil;
    _lastCacheDate = nil;
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        _timerLabelTimeSinceRefreh = nil;
    }
}

- (void)timerDealloc {
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        _timerLabelTimeSinceRefreh = nil;
    }
}

#pragma mark - MTPrintingProtocol

- (MTReportViewerPrintPageRenderer *)printPageRender {
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

#pragma mark - Initalize

- (instancetype)init {
    if (self = [super init]) { [self initalize]; }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { [self initalize]; }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) { [self initalize]; }
    return self;
}

- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options {
    if (self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options]) { [self initalize]; }
    return self;
}

- (void)initalize {
    
    self.activityExporting = false;
    self.didRefreshBeforeReaload = false;
    
    
    MADDateFromTimeFormatter *dateTimeFormatter = [MADDateFromTimeFormatter new];
    self.dateTimeFormatter = dateTimeFormatter;

    self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitCausesPageTurn;

}

#pragma mark - MADPageSliderDelegate

- (void)sliderDidChangeToPage:(NSUInteger)page {
    [self moveToPageAtIndex:page];
}

#pragma mark - UIViewController Standard Callbacks

- (NSString *)title {
    return [MADViewerController MADViewer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADOperationQueue *refreshQueue = [[MADOperationQueue alloc] init];
    self.refreshQueue = refreshQueue;
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UIColor *whiteColor = [MADColorEverydayApps newColorWhite];
    self.navigationController.toolbar.tintColor = whiteColor;
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = self.title;
    self.navigationItem.titleView = titleView;

    self.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.refreshing = false;
    self.updatingOfTimerIsPaused = false;
    self.pageIsAnimating = false;
    self.startedRefresh = false;
    self.timerLabelTimeSinceRefreh = nil;
    self.lastCacheDate = nil;
    
    self.dataSource = self;
    self.delegate = self;
    
    self.currentPageIndex = 0;
    [self.labelStatus updatePageStatus:self.numberOfPages currentPageIndex:self.currentPageIndex];
    
    UIViewController *blankPage = [[UIViewController alloc] init];
    NSArray *blankPageArray = @[blankPage];
    [self setViewControllers: blankPageArray direction: UIPageViewControllerNavigationDirectionForward
                    animated: NO completion: ^(BOOL finished) { }];

    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    MADPageSlider *pageSlider = [[MADPageSlider alloc] initWithEffect:effect];
    pageSlider.sliderDelegate = self;
    [self.view addSubview:pageSlider];
    [self.view bringSubviewToFront:pageSlider];
    self.toolbarSlider = pageSlider;
    
    NSMutableArray *toolbarItems = self.toolbarItems.mutableCopy;
    MADLabelStatus *labelStatus = [[MADLabelStatus alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 30.0000f, 44.0000f)];
    UIBarButtonItem *barButtonLabelStatus = [[UIBarButtonItem alloc] initWithCustomView:labelStatus];
    [toolbarItems insertObject: barButtonLabelStatus atIndex: 0];
    [self setToolbarItems: toolbarItems animated: NO];
    self.labelStatus = labelStatus;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self layoutSubviewSliderPagination];
    [self updateNavigationPrompt:animated];
    [self.navigationController.toolbar setNeedsLayout];
    
    MADocument *document = self.document;
    // MARK: Reporting feature (number of results in main query)
    document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
    RptqDocument *activeDocumentModel = [document activeDocumentModel];
    [document initalizeMainQuery:activeDocumentModel];

    [self loadFromCache: document.paper.paperSize];
    
    if (self.printPageRendererReport == nil) {
        [document activeDocumentModel];    // Initalizes the report formatter, if not already done... Important!
        MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                                                                                           dataTable: document.mainDataTable];
        self.printPageRendererReport = prtingPageRendererReport;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self layoutSubviewSliderPagination];
    [self uiUpdateTimeSinceLastRefresh:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // FIXME: This has to be cleared, or the cache grows, and grows.
    [self setPrintPageRendererReport:nil];
    [self timerDealloc];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat nonSliderButtonsWidth = CGSizeZero.width;
    NSUInteger counter = 0;
    for (UIBarButtonItem *barButtonItem in [[self.navigationController toolbar] items]) {
        NSString *viewSelector = NSStringFromSelector(@selector(view));
        UIView *view = [barButtonItem valueForKey:viewSelector];
        if (view != nil) {
            nonSliderButtonsWidth += (view ? view.frame.size.width : CGSizeZero.width) + MADBarButtonItemsMargin;
        } else {
            nonSliderButtonsWidth += barButtonItem.width;
        }
        counter++;
    }
    [self.view bringSubviewToFront:self.toolbarSlider];
    self.labelStatus.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 44.0000f);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    BOOL shouldReprocess = ( (/*[self.tabBarController.selectedViewController isEqual: self.navigationController] && */self.activityExporting == false)
                            && [self shouldReprocess] );
    
    if (shouldReprocess) {
        [self reloadStepOne];
        [self reloadStepTwo:self.document.paper.paperSize];
        [self reloadStepThree];
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //    MADReportPageViewController *pageViewController = [self currentPageviewController];
        //    [pageViewController.view setNeedsDisplay];
        [self.navigationItem.titleView sizeToFit];
        [self layoutSubviewSliderPagination];
        [self.toolbarSlider setNeedsLayout];
        [self.navigationController.toolbar setNeedsLayout];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        [self.navigationController.toolbar setNeedsLayout];
        [self.navigationItem.titleView sizeToFit];
        [self layoutSubviewSliderPagination];
        [self.toolbarSlider setNeedsLayout];
        //    MADReportPageViewController *pageViewController = [self currentPageviewController];
        //    [pageViewController.view setNeedsDisplay];
    }];
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
}

#pragma mark - properties

#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage { return [UIImage imageNamed:MADImageBarButtonItemMadViewer8]; }

- (void)layoutSubviewSliderPagination {
    self.toolbarSlider.frame = CGRectMake(self.view.frame.size.width - MADSliderPaginationWidth, CGPointZero.y, MADSliderPaginationWidth, self.view.frame.size.height);
    self.toolbarSlider.pageSlider.frame = CGRectMake(CGPointZero.x, CGPointZero.y, MADSliderPaginationWidth, self.view.frame.size.height);
}

- (nullable MADReportPageViewController *)visiblePageViewController {
    return self.viewControllers.count > 0 ? self.viewControllers[0] : nil;
}

- (BOOL)moveToPageAtIndex:(NSUInteger)index {
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
        
        MADReportPageViewController *pageOne = [[MADReportPageViewController alloc] initWithDocument: self.document
                                                                                  andPageAttributtes: pageAttributes];

        pageOne.view.frame = self.view.bounds;
        pageOne.view.backgroundColor = self.view.backgroundColor;
        pageOne.delegate = self;
        
        __block MADViewerController *reportViewer = self;
        [self.view bringSubviewToFront:self.toolbarSlider];
        NSArray *viewControllers = @[pageOne];
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO completion:^(BOOL finished) {
                            if (finished) {
                                [reportViewer.view bringSubviewToFront:reportViewer.toolbarSlider];
                                [pageOne.view setNeedsDisplay];
                                reportViewer.updatingOfTimerIsPaused = false;
                                reportViewer.refreshing = false;
                                reportViewer = nil;
                            }
                        }];
        result = YES;
    }
    return result;
}

- (MADReportPageViewController *)currentPageviewController {
    return [self pageViewControllerAtIndex: self.currentPageIndex];
}

- (MADReportPageViewController *)pageViewControllerAtIndex:(NSUInteger)index {
    MADReportPageViewController *result = nil;
    if (index < self.viewControllers.count) {
        result = self.viewControllers[index];
    } else {
        result = self.viewControllers.lastObject;
    }
    return result;
}

- (BOOL)shouldReprocess {
    return self.refreshing == false && self.startedRefresh == false && self.activityExporting == false;
}

- (void)redrawWithFrame:(CGRect)frame {
    if ([self shouldReprocess]) {
        [self setDisplayActive];
        [self reloadWithSize: self.document.paper.paperSize /*frame.size*/];
    }
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? self.navigationController : self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    
    // FIXME: Delete preview
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error];
    [self redrawWithFrame:self.view.frame];
}

#pragma mark - Report Notifications

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
    [self.labelStatus updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    NSNumber *rowNumber = sender.userInfo[MADDatabaseNumberOfRowsReadKey];
    [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

#pragma mark - UI Updates

- (void)setDisplayActive {
    
    [self setPageingEnabled:YES];
    
    UIColor *red = [MADColorEverydayApps newColorRed];
    self.toolbarSlider.tintColor = red;
    
    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = YES;
    }
    
    self.toolbarSlider.enabled = YES;
    self.barButtonItemActivity.enabled = YES;
    self.refreshing = false;
    self.updatingOfTimerIsPaused = false;
    
    UIBarButtonItem *barButtonItemRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    barButtonItemRefresh.enabled = YES;
    [self.tabBarController.navigationItem setRightBarButtonItem:barButtonItemRefresh animated:YES];
}

- (void)setDisplayInactive {
    
    [self setPageingEnabled:NO];
    
    UIColor *tintColor = [UIColor lightGrayColor];
    self.toolbarSlider.tintColor = tintColor;
    
    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = NO;
    }
    
    self.toolbarSlider.enabled = NO;
    self.barButtonItemActivity.enabled = NO;
    self.refreshing = true;
    self.updatingOfTimerIsPaused = false;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = NO;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    
    [self.tabBarController.navigationItem setRightBarButtonItem: barButtonItem animated: YES];
    
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    NSError *error = nil;
    MADocument *document = self.document;
    [document.managedObjectContext save:&error];
    if (error != nil) {
        [document.managedObjectContext save:&error];
    }
    [self.viewControllerDelegate viewControllerDidFinish: self];
}

- (IBAction)activity:(id)sender {
    self.activityExporting = true;
    self.toolbarSlider.enabled = NO;
    
    MTActivityItemProviderPdf *activityItemProviderPdf = [self activityItemProviderPdf];
    activityItemProviderPdf.delegate = self;
    NSArray *activityItems = @[activityItemProviderPdf];
    [self setActivityItemProviderPdf:activityItemProviderPdf];
    
    MTActivityReportPrintPreview *printPreview = [[MTActivityReportPrintPreview alloc] init];
    printPreview.delegate = self;
    
    NSArray *applicationActivities = @[printPreview];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:applicationActivities];
    
    MADViewerController * __block __weak weakself = self;
    UIActivityViewControllerCompletionWithItemsHandler activityViewControllerCompletionWithItemsHandler =
    ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
        if (completed || (!completed && activityType == nil)) {
            weakself.toolbarSlider.enabled = YES;
            weakself.activityExporting = false;
            [weakself.tabBarController enableTabBarItems];
        } else {
            if (activityType.length > 0) {  // Long running activity
                if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
                    if (sharedController) {
                        sharedController.delegate = weakself;
                        
                        MTReportViewerPrintPageRenderer *printPageRender = [self.document printerPrintPageRender];
                        sharedController.printPageRenderer = printPageRender;
                        sharedController.delegate = self.document;
                        
                        MADViewerController * __weak weakself = self;
                        
                        if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
                            [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = [MADColorEverydayApps newColorAnalogous4];
                            [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [MADColorEverydayApps newColorRed];
                            [sharedController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                                [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = nil;
                                [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [MADColorEverydayApps newColorWhite];
                                weakself.toolbarSlider.enabled = YES;
                                weakself.activityExporting = false;
                                [weakself.tabBarController enableTabBarItems];
                            }];
                        }
                        
                        
                    }
                }
                weakself.toolbarSlider.enabled = YES;
                weakself.activityExporting = false;
            } else {
                weakself.toolbarSlider.enabled = YES;
                weakself.activityExporting = false;
                [weakself.tabBarController enableTabBarItems];
            }
        }
    };
    activityViewController.completionWithItemsHandler = activityViewControllerCompletionWithItemsHandler;
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *ppc = activityViewController.popoverPresentationController;
    ppc.barButtonItem = sender;
    
    MADViewerController * __weak weakSelf = self;
    [self presentViewController:activityViewController animated:YES completion:^{
        weakSelf.presentedViewController.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorAnalogous4];
    }];
    [self.tabBarController disableTabBarItems];
}

- (IBAction)reload {
    MADViewerController * __weak blockself = self;
    CGSize size = self.document.paper.paperSize;
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [blockself reloadWithSize:size];
        });
    });
}

- (IBAction)refresh:(id)sender {
    
    self.didRefreshBeforeReaload = true;
    self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    
    if (self.isRefreshing == false) {
        self.startedRefresh = true;
        self.refreshing = true;
        [self setDisplayInactive];

        MADRefreshReloadOperation *refreshReloadOperation = [[MADRefreshReloadOperation alloc] initWithDocument:self.document viewController:self databaseConnection:self.document.mainDatabase.databaseConnection];
        [refreshReloadOperation addObserver:self];
        [self.refreshQueue addOperation:refreshReloadOperation];
        self.refreshReloadOperation = refreshReloadOperation;
        
        //[self.refreshQueue waitUntilAllOperationsAreFinished];
        
        /*
        MADocument *document = self.document;
        MTDatabase *database = document.mainDatabase;
        [self addObserverDidReadRowsToDatabase:database];
        
        NSString *connectionString = document.mainDatabase.databaseConnection.connectionString;
        
        NSError *error = nil;
        
        bool success = false;
        
        [document prepairForRefresh];
        
        
        NSURL *cacheUrl = document.urlDataTableCache.copy;
        MTQuery * __weak wMainQuery = document.mainQuery;
        MTDatabase * __weak wMainDatabase = document.mainDatabase;
        MTDataTableFast * __weak wMainDataTable = document.mainDataTable;
        __block bool didRefresh = false;
        
        NSBlockOperation *operationRefresh = [NSBlockOperation blockOperationWithBlock:^{
            
            MTQuery *squery = wMainQuery;
            MTDatabase *sdatabase = wMainDatabase;
            
            NSError * __autoreleasing eerror = NULL;
            didRefresh = [sdatabase executeQuery:squery withError:&eerror];
            [wMainDataTable cacheWithUrl:cacheUrl];
            return;
            
        }];
        
        NSOperationQueue *queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 1;
        [queue addOperation:operationRefresh];
        [queue waitUntilAllOperationsAreFinished];
        */
        //[self.document finishRefresh:YES];
        
        
        
        //if (success) {
        
        
           /*
        } else {
            
            MADViewerController * __weak weakself2 = self;
            [NSError presentError: error
                 onViewController: weakself2
                       completion:^(BOOL presentErrorSuccess) {
                           if (presentErrorSuccess) {
                               __strong MADViewerController *strongself2 = weakself2;
                               MADViewerController * __weak weakself3 = strongself2;
                               [[MTKeyChain sharedObject] deleteKey: connectionString usingViewController: weakself3];
                           }
                       }];
            
        }*/
        
        //[self removeObserverDidReadRowsFromDatabase:database];
        
        
        
        
        
    }
}

- (void)addObserverDidReadRowsToDatabase:(MTDatabase *)database {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reportDocumentDidReadRows:)
                                                 name: MADNotificationDidReadRowsName object: database];
}

- (void)removeObserverDidReadRowsFromDatabase:(MTDatabase *)database {
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
    NSString *temporaryDirectoryPath = NSTemporaryDirectory();
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
    NSURL *urlEmpty = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    MTActivityItemProviderPdf *activityItemProviderPdf = [[MTActivityItemProviderPdf alloc] initWithPlaceholderItem:urlEmpty];
    activityItemProviderPdf.document = self.document;
    return activityItemProviderPdf;
}

#pragma mark - UIDocumentInteractionController

- (UIViewController *)previewViewControllerForInteractionController: (UIDocumentInteractionController *) controller {
    return self;
}

- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller
                  withCompletionHandler:(void (^)(BOOL))completionHandler {
    
    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        completionHandler(YES);
    } else {
        [self.popoverControllerActivity dismissPopoverAnimated:YES];
        completionHandler(YES);
    }
}

#pragma mark - Load data

- (void)loadFromCache:(CGSize)viewBounds {
    
    MADocument *document = self.document;
    [document activeDocumentModel];
    [document prepareForQuery];
    
    document.reportFormatter.didRefresh = NO;
    [document.reportFormatter loadFromCacheWithSize: viewBounds];
    
    MTReportViewerPrintPageRenderer *printPageRender =  [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                                                                               dataTable: document.mainDataTable];
    self.printPageRendererReport = printPageRender;
    
    [self uiUpdateNumberOfPages];
    
    MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
    pageAttributes.pageNumber = self.currentPageNumber;
    pageAttributes.numberOfPages = self.numberOfPages;
    pageAttributes.zoomScaleInital = 1.0000f;
    pageAttributes.contentSizeInital = document.paper.paperSize;
    pageAttributes.contentOffsetInital = CGPointZero;
    pageAttributes.contentScaleFactor = 0.0;

    MADReportPageViewController *pageOne = [MADReportPageViewController PageViewControllerWithDocument: document
                                                                                        pageAttributes: pageAttributes
                                                                                                 frame: self.view.bounds
                                                                                           andDelegate: self];
    
    NSArray *viewControllers = @[pageOne];
    
    [self setViewControllers: viewControllers direction: UIPageViewControllerNavigationDirectionForward
                    animated: NO completion: nil];
    
    self.refreshing = false;
    self.startedRefresh = false;
    [self uiUpdateRecordsRead];
    document.reportFormatter.didRefresh = NO;
    
}

- (void)reloadStepOne {
    if (self.backgroundTaskIdRefresh == UIBackgroundTaskInvalid) {
        self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    }
    
    [self setDisplayInactive];
    [self.document prepareForQuery];
}

- (void)reloadStepTwo:(CGSize)size {

    MADocument *document = self.document;
    [self watchFormatter: document.reportFormatter];
    
    document.reportFormatter.didRefresh = self.startedRefresh;
    [document.reportFormatter formatForSize:size contentChanged:self.startedRefresh];
    
    MTReportViewerPrintPageRenderer *printPageRender =  [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                                                                               dataTable: document.mainDataTable];
    self.printPageRendererReport = printPageRender;
    [self ignoreFormatter: document.reportFormatter];
    
}

- (void)reloadStepThree {
    [self uiUpdateNumberOfPages];
    
    MADocument *document = self.document;
    MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
    pageAttributes.pageNumber = self.currentPageNumber;
    pageAttributes.numberOfPages = self.numberOfPages;
    
    // FIXME: Don't reset the display size to the paper size.
    pageAttributes.contentSizeInital = document.paper.paperSize;
    pageAttributes.zoomScaleInital = 1.0000f;
    pageAttributes.contentScaleFactor = 0.0;
    
    MADReportPageViewController *pageOne = [MADReportPageViewController PageViewControllerWithDocument: document pageAttributes: pageAttributes
                                                                                                 frame: self.view.bounds andDelegate: self];
    
    NSArray *viewControllers = @[pageOne];
    
    [self setViewControllers: viewControllers
                           direction: UIPageViewControllerNavigationDirectionForward
                            animated: NO completion: nil];
    
    self.refreshing = false;
    self.startedRefresh = false;
    [self uiUpdateRecordsRead];
    document.reportFormatter.didRefresh = NO;
    if (self.backgroundTaskIdRefresh != UIBackgroundTaskInvalid) {
        
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        if (self.didRefreshBeforeReaload) {
            notification.alertBody = NSLocalizedString(@"Refresh completed.", @"Refresh completed.");
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            self.didRefreshBeforeReaload = false;
        }
        
        NSNumber *bgtask = @(self.backgroundTaskIdRefresh);
        self.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
        [[UIApplication sharedApplication] handoffBackground:bgtask];
    }

}

- (void)reloadWithSize:(CGSize)viewBounds {
    
    [self reloadStepOne];

    MADViewerController * __weak blockViewer = self;

    //dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    //dispatch_async(queuePriorityBackground, ^{
        
        MADViewerController * __strong strongViewer = blockViewer;
        [strongViewer reloadStepTwo:viewBounds];
        MADViewerController * __weak blockViewer2 = strongViewer;
        
    //    dispatch_sync(dispatch_get_main_queue(), ^{
            
            MADViewerController * __strong strongViewer2 = blockViewer2;
            [strongViewer2 reloadStepThree];
            
   //     });
   // });
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

#pragma mark - UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
       viewControllerAfterViewController:(MADReportPageViewController *)pageViewControllerLast {
    
    MADReportPageViewController *result = nil;
    if (viewerViewController.pageIsAnimating == false) {
        NSUInteger visiblePageNumber = 0;
        pageViewControllerLast.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        pageViewControllerLast.view.translatesAutoresizingMaskIntoConstraints = YES;
        if (pageViewControllerLast != nil && [pageViewControllerLast respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerLast.pageViewAttributes.pageNumber;
        }
        if (visiblePageNumber + 1 <= self.numberOfPages) {
            
            MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
            pageAttributes.pageNumber = visiblePageNumber + 1;
            pageAttributes.numberOfPages = self.numberOfPages;
            pageAttributes.zoomScaleInital = pageViewControllerLast.documentScroller.zoomScale;
            pageAttributes.contentOffsetInital = pageViewControllerLast.documentScroller.contentOffset;
            pageAttributes.contentSizeInital = pageViewControllerLast.documentScroller.contentSize;
            pageAttributes.contentScaleFactor = pageViewControllerLast.documentView.contentScaleFactor;

            result = [[MADReportPageViewController alloc] initWithDocument:self.document andPageAttributtes:pageAttributes];
            result.delegate = self;
            result.view.backgroundColor = self.view.backgroundColor;
            result.view.frame = self.view.bounds;
            result.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            result.view.translatesAutoresizingMaskIntoConstraints = YES;
        }
    }
    return result;
    
}

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
      viewControllerBeforeViewController:(MADReportPageViewController *)pageViewControllerPrevious {
    
    MADReportPageViewController *result = nil;
    if (viewerViewController.pageIsAnimating == false) {
        
        NSUInteger visiblePageNumber = 0;
        if (pageViewControllerPrevious != nil && [pageViewControllerPrevious respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerPrevious.pageViewAttributes.pageNumber;
        }
        if (visiblePageNumber - 1 > 0) {
            
            MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
            pageAttributes.pageNumber = visiblePageNumber - 1;
            pageAttributes.numberOfPages = self.numberOfPages;
            pageAttributes.zoomScaleInital = pageViewControllerPrevious.documentScroller.zoomScale;
            pageAttributes.contentOffsetInital = pageViewControllerPrevious.documentScroller.contentOffset;
            pageAttributes.contentSizeInital = pageViewControllerPrevious.documentScroller.contentSize;
            pageAttributes.contentScaleFactor = pageViewControllerPrevious.documentView.contentScaleFactor;

            result = [[MADReportPageViewController alloc] initWithDocument:self.document andPageAttributtes:pageAttributes];
            result.view.backgroundColor = self.view.backgroundColor;

            result.delegate =  self;
            result.view.frame = self.view.bounds;
            result.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            result.view.translatesAutoresizingMaskIntoConstraints = YES;
        }
        
    }

    return result;
}

/*- (NSInteger)presentationCountForPageViewController:(MADViewerController *)pageViewController {
    return pageViewController.numberOfPages;
}

- (NSInteger)presentationIndexForPageViewController:(MADViewerController *)pageViewController {
    return pageViewController.currentPageIndex;
}*/

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(MADViewerController *)pageViewController didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    if (completed || finished) {
        pageViewController.pageIsAnimating = false;
        if (pageViewController.viewControllers.count > 0) {
            MADReportPageViewController *viewController = pageViewController.viewControllers[0];
            [pageViewController setCurrentPageIndex: viewController.pageViewAttributes.pageNumber - 1];
            [self.labelStatus updatePageStatus:self.numberOfPages currentPageIndex:self.currentPageIndex];
            [pageViewController.toolbarSlider.pageSlider setValue: pageViewController.currentPageIndex animated: YES];
        }
    }

}

- (UIPageViewControllerSpineLocation)pageViewController:(MADViewerController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    pageViewController.pageIsAnimating = false;
    return UIPageViewControllerSpineLocationMin;
}

- (void)pageViewController:(MADViewerController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    pageViewController.pageIsAnimating = true;
}

#pragma mark - Status Label

- (void)uiUpdateTimeSinceLastRefresh:(id)sender {

    MADLabelStatus *labelStatus = self.labelStatus;
    MTDateResolution resolution;
    if (self.lastCacheDate == nil) {    // No Cache exist, so return quickly.

        NSURL *cachedDataUrl = [self.document cachedDataUrl];
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedDataUrl.path error:&error];
        if (error == nil) {
            self.lastCacheDate = attributes.fileModificationDate;
        }

        if (self.lastCacheDate == nil) {    // Find last cache date
            NSString *noCache = NSLocalizedString(MADTextNoCache, MADTextNoCache);
            [labelStatus updateStatusWithTime:noCache];
            return;
        }
        
    }

    MTPair *dateStringAndInterval = [self.dateTimeFormatter stringWithTimeIntervalSinceDate:self.lastCacheDate];
    [labelStatus updateStatusWithTime:dateStringAndInterval.former];
    resolution = ((NSNumber *)dateStringAndInterval.latter).shortValue;

    if (self.timerLabelTimeSinceRefreh != nil) {
        if ([self.timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([self.timerLabelTimeSinceRefreh isValid]) {
                [self.timerLabelTimeSinceRefreh invalidate];
            }
        }
        self.timerLabelTimeSinceRefreh = nil;
    }
    
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: [MADDateFromTimeFormatter timeIntervalForResolution:resolution]
                                                  target: self selector: @selector(uiUpdateTimeSinceLastRefresh:) userInfo:nil
                                                 repeats: NO];
    self.timerLabelTimeSinceRefreh = t;
}

- (void)uiUpdateRecordsRead {
    if ([NSThread isMainThread]) {
        NSNumber *numberOfResults = @([self.document.mainDataTable numberOfRows]);
        [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self uiUpdateRecordsRead];
        });
    }
}

- (void)uiUpdateNumberOfPages {
    self.numberOfPages = self.document.reportFormatter.numberOfPages;
    [self uiUpdateNumberOfPages: (self.numberOfPages > 0 ? (self.numberOfPages - 1) : 0)];
    [self setDisplayActive];
}

- (void)uiUpdateNumberOfPages:(NSUInteger)numberOfPages {
    if ([NSThread isMainThread]) {
        [self updateNumberOfPages:(NSUInteger)numberOfPages];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateNumberOfPages:(NSUInteger)numberOfPages];
        });
    }
}

- (void)updateNumberOfPages:(NSUInteger)numberOfPages {
    MADPageSlider *slider = self.toolbarSlider;
    if (round(slider.maximumValue) != round(numberOfPages)) {
        slider.maximumValue = numberOfPages;
    }
    [self.labelStatus updatePageStatus:self.numberOfPages currentPageIndex:self.currentPageIndex];
}

#pragma mark - MTActivityItemProviderDelegate

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
                        [self.document setActivityDelegate:weakself];
                        UIPrintPageRenderer *printPageRender = [self.document printerPrintPageRender];
                        sharedController.printPageRenderer = printPageRender;
                        sharedController.delegate = self.document;
                        MADViewerController * __weak weakself2 = weakself;
                        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
                        ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
                            weakself2.toolbarSlider.enabled = YES;
                            [weakself2.tabBarController enableTabBarItems];
                        };
                        [sharedController presentFromBarButtonItem:weakself.barButtonItemActivity animated:YES
                                                 completionHandler:completionHandler];
                    }
                });
            });
        });
    });
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self.tabBarController enableTabBarItems];
}

- (UIViewController *)activeViewController {
    return self;
}
/*
static UIImageView *captureSnapshotOfView (UIView *targetView);
static UIImageView *captureSnapshotOfView (UIView *targetView) {
    UIGraphicsBeginImageContextWithOptions(targetView.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [targetView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *snapshotView = [[UIImageView alloc] initWithImage:image];
    snapshotView.frame = targetView.frame;
    return snapshotView;
}*/

#pragma mark - UIAccessibility

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
    switch (direction) {
        case UIAccessibilityScrollDirectionNext:
        case UIAccessibilityScrollDirectionRight:
            return [self moveToPageAtIndex:self.currentPageIndex + 1];
            break;
        case UIAccessibilityScrollDirectionPrevious:
        case UIAccessibilityScrollDirectionLeft:
            return [self moveToPageAtIndex:self.currentPageIndex - 1];
            break;
        default:
            return NO;
            break;
    }
}

- (BOOL)accessibilityPerformEscape {
    [self.viewControllerDelegate viewControllerDidFinish:nil];
    return YES;
}

- (BOOL)isAccessibilityElement {
    return NO;
}

#pragma mark - Traits

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self updateNavigationPrompt:previousTraitCollection != nil];
}

#pragma mark - Helpers

- (void)updateNavigationPrompt:(BOOL)animated {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [UIView setAnimationsEnabled:animated];
        self.tabBarController.navigationItem.prompt = self.document.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:YES];
    } else {
        self.tabBarController.navigationItem.prompt = nil;
    }
}

- (NSUInteger)currentPageNumber { return self.currentPageIndex + 1; }

- (void)setPageingEnabled:(BOOL)enabled {
    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        gestureRecognizer.enabled = enabled;
    }
}

#pragma mark - Custom

+ (NSString *)MADViewer {
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [NSString stringWithFormat: @"MAD %@", localizedSuffix];
}

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

@end
