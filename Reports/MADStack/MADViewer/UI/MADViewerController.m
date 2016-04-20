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

#import <MAD/MTReportViewerPrintPageRenderer.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MTDataTableFast.h>

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

#import "MADPromptOperationDisplayError.h"
#import "MADBlockOperation.h"


static NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";
static NSString * const MADTextNoCache = @"No Cache";

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

        if (((MADRefreshReloadOperation *)operation).completedSuccessfully) {

            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                
                MADocument *document = self.document;
                self.lastCacheDate = [NSDate date];
                [self setDisplayActive];
                
                [self reloadWithSize:document.paper.paperSize];
                
                [self timerDealloc];

                [self uiUpdateTimeSinceLastRefresh: NULL];

                [self setDisplayActive];
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

- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style
                  navigationOrientation:(UIPageViewControllerNavigationOrientation)orientation
                                options:(NSDictionary *)options {

    if (self = [super initWithTransitionStyle: style navigationOrientation: orientation
                                      options: options]) {
        [self initalize];
    }

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
    [self setViewControllers: blankPageArray direction: UIPageViewControllerNavigationDirectionForward animated: NO completion: ^(BOOL finished) { }];

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
    
    [self updateNavigationPrompt:animated];
    [self.navigationController.toolbar setNeedsLayout];
    
    MADocument *document = self.document;
    // MARK: Reporting feature (number of results in main query)
    document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;


    RptqDocument *activeDocumentModel = [document activeDocumentModel];

    [document initalizeMainQuery:activeDocumentModel];
    [document activeDocumentModel];
    [document prepareForQuery];
    document.reportFormatter.didRefresh = NO;
    [document.reportFormatter loadFromCacheWithSize: document.paper.paperSize];
    
    MTReportViewerPrintPageRenderer *printPageRender =
        [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
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
    
    MADReportPageViewController *pageOne =
        [MADReportPageViewController newReportPageViewControllerWithDocument: document
                                                              pageAttributes: pageAttributes
                                                                       frame: self.view.bounds
                                                                 andDelegate: self];
    
    NSArray *viewControllers = @[pageOne];
    [self setViewControllers: viewControllers
                   direction: UIPageViewControllerNavigationDirectionForward
                    animated: NO completion: nil];
    
    self.refreshing = false;
    self.startedRefresh = false;
    
    [self uiUpdateRecordsRead];
    
    document.reportFormatter.didRefresh = NO;
    
    if (self.printPageRendererReport == nil) {
        [document activeDocumentModel];
        
        MTReportViewerPrintPageRenderer *prtingPageRendererReport =
            [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                                   dataTable: document.mainDataTable];
        self.printPageRendererReport = prtingPageRendererReport;
    }
    
    [self.toolbarSlider setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self uiUpdateTimeSinceLastRefresh:self];
    [self.toolbarSlider setNeedsLayout];
    }

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // FIXME: This has to be cleared, or the cache grows, and grows.
    [self timerDealloc];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
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
    [self.view bringSubviewToFront:self.toolbarSlider];
    self.labelStatus.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 44.0000f);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

        [self.navigationController.toolbar setNeedsLayout];
        [self.navigationItem.titleView sizeToFit];
        [self.toolbarSlider setNeedsLayout];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        [self.navigationController.toolbar setNeedsLayout];
        [self.navigationItem.titleView sizeToFit];
        [self.toolbarSlider setNeedsLayout];
        
    }];
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection: newCollection withTransitionCoordinator: coordinator];
}

#pragma mark - properties

#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage { return [UIImage imageNamed:MADImageBarButtonItemMadViewer8]; }

- (nullable MADReportPageViewController *)visiblePageViewController { return self.viewControllers.count > 0 ? self.viewControllers[0] : nil; }

- (bool)moveToPageAtIndex:(NSUInteger)index {
    bool result = false;
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
    
        [self.view bringSubviewToFront: self.toolbarSlider];
 
        NSArray *viewControllers = [[NSArray alloc] initWithObjects:pageOne, nil];
        self.updatingOfTimerIsPaused = false;
        self.refreshing = false;
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO completion:^(BOOL finished) {
        
            if (finished) {
                [pageOne.view setNeedsDisplay];
            }

        }];
        result = true;
    }
    return result;
}

- (MADReportPageViewController *)currentPageviewController {
    return [self pageViewControllerAtIndex: self.currentPageIndex];
}

- (MADReportPageViewController *)pageViewControllerAtIndex:(NSUInteger)index {
    return index < self.viewControllers.count ? self.viewControllers[index] : self.viewControllers.lastObject;
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? self.navigationController : self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error];
    NSAssert(success, @"Failed to delete file.");
    
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

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        [self setPageingEnabled:        YES];
        [self setTabBarItemsEnabled:    YES];
        self.toolbarSlider.enabled =    YES;
        self.barButtonItemActivity.enabled = YES;
        self.refreshing = false;
        self.updatingOfTimerIsPaused = false;

        UIBarButtonItem *barButtonItemRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
        barButtonItemRefresh.enabled = YES;
        [self.tabBarController.navigationItem setRightBarButtonItem:barButtonItemRefresh animated:YES];
        
    }];
}

- (void)setDisplayInactive {

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        [self setPageingEnabled:        NO];
        [self setTabBarItemsEnabled:    NO];
        self.toolbarSlider.enabled =    NO;
        self.barButtonItemActivity.enabled = NO;
        self.refreshing = true;
        self.updatingOfTimerIsPaused = false;

        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
        [activityIndicator startAnimating];
        activityIndicator.hidden = NO;
        activityIndicator.hidesWhenStopped = NO;
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        
        [self.tabBarController.navigationItem setRightBarButtonItem: barButtonItem animated: YES];
        
    }];
}

- (void)setPageingEnabled:(BOOL)enabled {
    NSArray *gestureRecognizers = self.gestureRecognizers;
    [gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer * _Nonnull gestureRecognizer, NSUInteger idx, BOOL * _Nonnull stop) {
        gestureRecognizer.enabled = enabled;
    }];
}

- (void)setTabBarItemsEnabled:(BOOL)enabled {
    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    [tabBarItems enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UITabBarItem * _Nonnull tabBarItem, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            tabBarItem.enabled = enabled;
        }];
    }];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    NSError *error = nil;
    MADocument *document = self.document;
    [document.managedObjectContext save:&error];
    if (error != nil) { [document.managedObjectContext save:&error]; }
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
    
    MADViewerController * __weak weakself = self;
    UIActivityViewControllerCompletionWithItemsHandler activityCompletionHandler =
    ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
        MADViewerController *sself = weakself;
        
        sself.toolbarSlider.enabled = YES;
        sself.activityExporting = false;
        
        if (completed || (!completed && activityType == nil)) {
            [sself.tabBarController enableTabBarItems];
        } else {

            if (activityType.length > 0) {  // Long running activity

                if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {

                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];

                    if (sharedController) {
                        sharedController.delegate = sself;
                        
                        MTReportViewerPrintPageRenderer *printPageRender = [sself.document printerPrintPageRender];
                        sharedController.printPageRenderer = printPageRender;
                        sharedController.delegate = self.document;
                        
                        
                        if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {

                            [MADViewerController setNavigationBarAppearanceHighlighted];
                            
                            MADViewerController * __weak weakself2 = sself;
                            [sharedController presentAnimated:YES completionHandler:
                                ^(UIPrintInteractionController *printInteractionController,
                                            BOOL animatinCompleted, NSError *error) {
                            
                                if (animatinCompleted) {
                                    MADViewerController *sself2 = weakself2;
                                    [MADViewerController setNavigationBarAppearanceTinted];

                                    sself2.toolbarSlider.enabled = YES;
                                    sself2.activityExporting = false;
                                    [sself2.tabBarController enableTabBarItems];
                                }
                                
                            }];
                            
                        }
                        
                        
                    }
                }
            } else {
                [sself.tabBarController enableTabBarItems];
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
    [self.tabBarController disableTabBarItems];
}

+ (void)setNavigationBarAppearanceTinted {
    [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = nil;
    [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [MADColorEverydayApps newColorWhite];
}

+ (void)setNavigationBarAppearanceHighlighted {
    [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = [MADColorEverydayApps newColorAnalogous4];
    [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [MADColorEverydayApps newColorRed];
}

- (IBAction)refresh:(id)sender {
    
    self.didRefreshBeforeReaload = true;
    self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    
    if (self.isRefreshing == false) {
        self.startedRefresh = true;
        self.refreshing = true;
        [self setDisplayInactive];

        MADocument *document = self.document;

        [self addObserverDidReadRowsToDatabase:document.database];
        
        MADRefreshReloadOperation *refreshReloadOperation =
            [[MADRefreshReloadOperation alloc] initWithDocument:document viewController:self
                                             databaseConnection:document.database.databaseConnection];
        [refreshReloadOperation addObserver:self];
        [self.refreshQueue addOperation:refreshReloadOperation];
        self.refreshReloadOperation = refreshReloadOperation;
        
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

- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller withCompletionHandler:(void (^)(BOOL))completionHandler {
    
    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        completionHandler(YES);
    } else {
        [self.popoverControllerActivity dismissPopoverAnimated:YES];
        completionHandler(YES);
    }
}

#pragma mark - Load data

- (void)reloadWithSize:(CGSize)viewBounds {

    MADocument *document = self.document;

    if (self.backgroundTaskIdRefresh == UIBackgroundTaskInvalid) {
        self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    }
    
    [self setDisplayInactive];
    [document prepareForQuery];

    [self watchFormatter: document.reportFormatter];
    
    document.reportFormatter.didRefresh = self.startedRefresh;
    [document.reportFormatter formatForSize:viewBounds contentChanged: NO];
    
    MTReportViewerPrintPageRenderer *printPageRender =
        [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: document.reportFormatter
                                                               dataTable: document.mainDataTable];
    self.printPageRendererReport = printPageRender;
    [self ignoreFormatter: document.reportFormatter];


    [self uiUpdateNumberOfPages];
    
    MADPageViewAttributes *pageAttributes = [[MADPageViewAttributes alloc] init];
    pageAttributes.pageNumber = self.currentPageNumber;
    pageAttributes.numberOfPages = self.numberOfPages;
    
    // FIXME: Don't reset the display size to the paper size.
    pageAttributes.contentSizeInital = document.paper.paperSize;
    pageAttributes.zoomScaleInital = 1.0000f;
    pageAttributes.contentScaleFactor = 0.0;
    
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        MADReportPageViewController *pageOne =
            [MADReportPageViewController newReportPageViewControllerWithDocument: document
                                                                  pageAttributes: pageAttributes
                                                                           frame: self.view.bounds
                                                                     andDelegate: self];
        
        NSArray *viewControllers = @[pageOne];
        
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO completion: nil];
        
    }];
    
    self.refreshing = false;
    self.startedRefresh = false;
    
    [self uiUpdateRecordsRead];
    
    document.reportFormatter.didRefresh = NO;
    
    if (self.backgroundTaskIdRefresh != UIBackgroundTaskInvalid) {
        
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        
        if (self.didRefreshBeforeReaload) {
            NSString *body = NSLocalizedString(@"Refresh completed.", @"Refresh completed.");
            notification.alertBody = body;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            self.didRefreshBeforeReaload = false;
        }
        
        NSNumber *bgtask = @(self.backgroundTaskIdRefresh);
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

#pragma mark - UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
       viewControllerAfterViewController:(MADReportPageViewController *)pageViewControllerLast {
    
    MADReportPageViewController *result = nil;

    if (viewerViewController.pageIsAnimating == false) {
        NSUInteger visiblePageNumber = 0;
        pageViewControllerLast.view.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                                       UIViewAutoresizingFlexibleWidth;
        pageViewControllerLast.view.translatesAutoresizingMaskIntoConstraints = YES;
        
        if (pageViewControllerLast != nil &&
            [pageViewControllerLast respondsToSelector:@selector(pageNumber)]) {
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

- (void)pageViewController:(MADViewerController *)pageViewController
        didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    
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

- (UIPageViewControllerSpineLocation)pageViewController:(MADViewerController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {

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
                                                  target: self selector: @selector(uiUpdateTimeSinceLastRefresh:)
                                                userInfo: nil repeats: NO];
    self.timerLabelTimeSinceRefreh = t;
}

- (void)uiUpdateRecordsRead {

    NSNumber *numberOfResults = @(self.document.mainDataTable.rowCounter);
    [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];

}

- (void)uiUpdateNumberOfPages {
    self.numberOfPages = self.document.reportFormatter.numberOfPages;
    [self uiUpdateNumberOfPages: (self.numberOfPages > 0 ? (self.numberOfPages - 1) : 0)];
    [self setDisplayActive];
}

- (void)uiUpdateNumberOfPages:(NSUInteger)numberOfPages {
    [self updateNumberOfPages:(NSUInteger)numberOfPages];
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
                        MADViewerController *sself = weakself;
                        
                        MADocument *document = sself.document;
                        document.activityDelegate = sself;
                        
                        UIPrintPageRenderer *printPageRender = [document printerPrintPageRender];
                        sharedController.printPageRenderer = printPageRender;
                        sharedController.delegate = document;
                        MADViewerController * __weak weakself2 = sself;
                        
                        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
                            ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
                            
                            MADViewerController *sself2 = weakself2;
                            
                            sself2.toolbarSlider.enabled = YES;
                            [sself2.tabBarController enableTabBarItems];
                        };
                        
                        [sharedController presentFromBarButtonItem:sself.barButtonItemActivity animated:YES completionHandler:completionHandler];
                    }
                });
            });
        });
    });
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController { return YES; }

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self.tabBarController enableTabBarItems];
}

- (UIViewController *)activeViewController { return self; }

#pragma mark - UIAccessibility

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {

    switch (direction) {

        case UIAccessibilityScrollDirectionNext:
        case UIAccessibilityScrollDirectionRight:
            return [self moveToPageAtIndex: self.currentPageIndex + 1 ] ? YES : NO;
            break;
            
        case UIAccessibilityScrollDirectionPrevious:
        case UIAccessibilityScrollDirectionLeft:
            return [self moveToPageAtIndex: self.currentPageIndex - 1 ] ? YES : NO;
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
