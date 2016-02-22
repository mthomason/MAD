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
#import <CoreData/CoreData.h>
#import <MAD/MADConstants.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTReportFormatter.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MTQuery.h>
#import <MAD/MTActivityItemProviderPdf.h>
#import <MAD/MTNotificationDidFormatPage.h>
#import <MAD/MTNotificationDidReadRows.h>
#import <MAD/MTKeyChain.h>
#import <MADDataStructures/MADDataStructures.h>
#import <MADFoundation/MTDataTable.h>

#import "MTActivityReportPrintPreview.h"

#import "MUIViewControllerDelegate.h"

#import "MTReportViewerReportPageView.h"
#import "MTReportViewerReportPageViewController.h"

#import "MADSliderPageVertical.h"
#import "MADProgressView.h"
#import "MADLabelStatus.h"
#import "MADNavigationBarTitleView.h"

#import "UIApplication+Extras.h"
#import "UIPageViewController+Extras.h"
#import "UIViewController+UI.h"
#import "UIViewController+tabBarItem.h"
#import "NSDate+Extras.h"
#import "MTStoreKitController+Features.h"
#import "MADPageSlider.h"
#import <MAD/MTPaper.h>

NSString * const MADImageBarButtonItemMadViewer = @"UIBarButtonItemMadViewer";
NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";


static NSString * const MADTextNoCache = @"No Cache";

static const CGFloat MADSliderPaginationWidth = 40.0000f;
static const CGFloat MADBarButtonItemsMargin = 8.0000f;

@interface MADViewerController ()
    <UIPopoverControllerDelegate,
        UIPrintInteractionControllerDelegate,
        UIStateRestoring,
        MADPageSliderProtocol,
        MTPrintingProtocol,
        MTActivityReportPrintPreviewDelegate,
        MTTabBarImageProtocol,
        MTActivityItemProviderDelegate>

@property (nonatomic, strong) MADPageSlider *slider;
@property (nonatomic, strong) MTReportViewerPrintPageRenderer *printPageRendererReport;
@property (nonatomic, strong) MADLabelStatus *labelStatus;
@property (nonatomic, strong) MTActivityItemProviderPdf *activityItemProviderPdf;

@property (nonatomic, strong) UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemActivity;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, strong) NSDate *lastCacheDate;
@property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;

@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, strong) UIProgressView *progressView; // FIXME: Not implmented.
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdRefresh;

@property (atomic, assign, getter=isRefreshing) bool refreshing;
@property (nonatomic, assign) bool didRefreshBeforeReaload;
@property (nonatomic, assign) bool activityExporting;
@property (nonatomic, assign) bool startedRefresh;
@property (nonatomic, assign) bool pageIsAnimating;
@property (nonatomic, assign) bool updatingOfTimerIsPaused;

@end

@implementation MADViewerController

@synthesize document;

#pragma mark - Dealloc

- (void)dealloc {
    [self timerDealloc];
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
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options {
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    
    UIProgressView *progressView = [[MADProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.progress = 0.0000f;
    self.progressView = progressView;

    UIBarButtonItem *barButtonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.barButtonItemRefresh = barButtonRefresh;

    MADLabelStatus *labelStatus = [[MADLabelStatus alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 30.0000f, 44.0000f)];
    self.labelStatus = labelStatus;
    
    self.activityExporting = false;
    self.didRefreshBeforeReaload = false;
    
    MADPageSlider *pageSlider = [[MADPageSlider alloc] init];
    pageSlider.sliderDelegate = self;
    self.slider = pageSlider;
    
    self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitCausesPageTurn;
}

#pragma mark - MADPageSliderDelegate

- (void)sliderDidChangeToPage:(NSInteger)page {
    [self moveToPageAtIndex:page];
}

#pragma mark - UIViewController Standard Callbacks

- (NSString *)title {
    return [MADViewerController MADViewer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.view.backgroundColor = backgroundColor;
    
    UIColor *whiteColor = [UIColor tintColorWhite];
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
    
    [self.view addSubview:self.slider];
    [self.view bringSubviewToFront:self.slider];
    
    NSMutableArray *toolbarItems = self.toolbarItems.mutableCopy;
    UIBarButtonItem *barButtonLabelStatus = [[UIBarButtonItem alloc] initWithCustomView:self.labelStatus];
    [toolbarItems insertObject: barButtonLabelStatus atIndex: 0];
    [self setToolbarItems: toolbarItems animated: NO];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateNavigationPrompt:animated];
    [self.navigationController.toolbar setNeedsLayout];
    
    // MARK: Reporting feature (number of results in main query)
    self.document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
    [self.document initalizeMainQuery:[self.document activeDocumentModel]];
    [self loadFromCache: self.document.paper.paperSize /*self.view.bounds.size*/];
    
    if ([self printPageRendererReport] == nil) {
        [self.document activeDocumentModel];    // Initalizes the report formatter, if not already done... Important!
        MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: self.document.reportFormatter
                                                                                                                           dataTable: self.document.mainDataTable];
        [self setPrintPageRendererReport: prtingPageRendererReport];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self layoutSubviewSliderPagination];
    [self updateLateRefreshedLabel:self];

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
    [self.navigationController.toolbar setNeedsLayout];
    [self.view bringSubviewToFront:self.slider];
    [self layoutSubviewSliderPagination];
    self.labelStatus.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 44.0000f);
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    UIImageView *snapshotViewBeforeRotation = nil, *snapshotViewAfterRotation = nil;
    if ([self.tabBarController.selectedViewController isEqual: self.navigationController] && self.activityExporting == false) {
        
        CGRect frameBeforeRotation, frameAfterRotation;

        MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
        MTReportViewerReportPageView *displayView = (MTReportViewerReportPageView *)pageViewController.view;

        frameBeforeRotation = displayView.frame;
        
        snapshotViewBeforeRotation = captureSnapshotOfView(displayView);

        [displayView insertSubview:snapshotViewBeforeRotation aboveSubview:displayView];
        [displayView setNeedsDisplay];
        
        frameAfterRotation = displayView.bounds;
        [self redrawWithFrame:frameAfterRotation];
        
        pageViewController = [self currentPageviewController];
        displayView = (MTReportViewerReportPageView *)pageViewController.view;
        
        [UIView setAnimationsEnabled:NO];
        snapshotViewAfterRotation = captureSnapshotOfView(displayView);
        
        CGRect framePreservingHeight = CGRectMake(frameBeforeRotation.origin.x, frameBeforeRotation.origin.y,
                                                  frameBeforeRotation.size.width, snapshotViewAfterRotation.frame.size.height);
        
        snapshotViewAfterRotation.frame = framePreservingHeight;
        
        UIImage *imageBeforeRotation = [snapshotViewBeforeRotation.image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
        UIImage *imageAfterRotation = [snapshotViewAfterRotation.image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
        
        [UIView setAnimationsEnabled:YES];
        
        if (imageAfterRotation.size.height < imageBeforeRotation.size.height) {
            snapshotViewAfterRotation.alpha = 0.0000f;
            [displayView insertSubview:snapshotViewAfterRotation aboveSubview:snapshotViewBeforeRotation];
            snapshotViewAfterRotation.alpha = 1.0000f;
        } else {
            [displayView insertSubview:snapshotViewAfterRotation aboveSubview:snapshotViewBeforeRotation];
            snapshotViewBeforeRotation.alpha = 0.0000f;
        }
        
        snapshotViewAfterRotation.frame = frameAfterRotation;
        framePreservingHeight = CGRectMake(frameAfterRotation.origin.x, frameAfterRotation.origin.y, frameAfterRotation.size.width, snapshotViewAfterRotation.frame.size.height);
        snapshotViewBeforeRotation.frame = framePreservingHeight;
        
        if ([displayView respondsToSelector:@selector(setDrawBlankPage:)]) {
            ((MTReportViewerReportPageView *)displayView).drawBlankPage = true;
        }
        
        [displayView setNeedsDisplay];
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.navigationItem.titleView sizeToFit];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.navigationItem.titleView sizeToFit];

        if (self.activityExporting == false) {
            
            MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
            UIView *displayView = [pageViewController view];
            
            if (displayView) {
                if ([displayView respondsToSelector:@selector(setDrawBlankPage:)]) {
                    ((MTReportViewerReportPageView *)displayView).drawBlankPage = false;
                }
            }
            [displayView setNeedsDisplay];
            
            [snapshotViewBeforeRotation removeFromSuperview];
            [snapshotViewAfterRotation removeFromSuperview];
        }
        
    }];
    
}

#pragma mark - add controls

- (void)addProgressViewToView {
    self.progressView.progress = 0.0000f;
    [self.view addSubview:self.progressView];
    [self.view bringSubviewToFront:self.progressView];
}

- (void)removeProgressViewFromView {
    [self.progressView removeFromSuperview];
}

#pragma mark - properties

#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage { return [UIImage imageNamed:MADImageBarButtonItemMadViewer8]; }

- (void)layoutSubviewSliderPagination {
    self.slider.frame = CGRectMake(self.view.frame.size.width - MADSliderPaginationWidth, CGPointZero.y,
                                             MADSliderPaginationWidth, self.view.frame.size.height);
    self.slider.pageSlider.frame = CGRectMake(CGPointZero.x, CGPointZero.y,
                                       MADSliderPaginationWidth, self.view.frame.size.height);
}

- (BOOL)moveToPageAtIndex:(NSUInteger)index {
    BOOL result = NO;
    if ((unsigned long)index != self.currentPageIndex && index != NSNotFound) {
        self.currentPageIndex = index;
        [self.labelStatus updatePageStatus:self.numberOfPages currentPageIndex:self.currentPageIndex];
        MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                              pageNumber: index + 1
                                                                 ofPages: self.numberOfPages];
        //MTReportViewerReportPageViewController *pageOne = [self currentPageviewController];
        pageOne.view.frame = self.view.bounds;
        pageOne.delegate = self;
        
        __block MADViewerController *reportViewer = self;
        [self.view bringSubviewToFront:self.slider];
        NSArray *viewControllers = @[pageOne];
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO completion:^(BOOL finished) {
                            if (finished) {
                                [reportViewer.view bringSubviewToFront:reportViewer.slider];
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

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    [self.document.managedObjectContext save:&error];
    if (error != nil) {
        [self.document.managedObjectContext save:&error];
    }
    [self.viewControllerDelegate viewControllerDidFinish: self];
}

- (MTReportViewerReportPageViewController *)currentPageviewController {
    return [self pageViewControllerAtIndex: self.currentPageIndex];
}

- (MTReportViewerReportPageViewController *)pageViewControllerAtIndex:(NSUInteger)index {
    MTReportViewerReportPageViewController *result = nil;
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

- (void)drawPage:(NSUInteger)pageIndex inRect:(CGRect)printableRect {
    [self.printPageRendererReport drawPageAtIndex: pageIndex inRect: printableRect];
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
    NSNumber *rowNumber = sender.userInfo[MTDatabaseNumberOfRowsReadKey];
    [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

#pragma mark - UI Updates

- (void)setDisplayActive {
    
    [self setPageingEnabled:YES];
    
    UIColor *red = [UIColor tintColorRed];
    self.slider.pageSlider.tintColor = red;
    
    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = YES;
    }
    
    self.slider.pageSlider.enabled = YES;
    self.barButtonItemRefresh.enabled = YES;
    self.barButtonItemActivity.enabled = YES;
    self.refreshing = false;
    self.updatingOfTimerIsPaused = false;
    
    [self.tabBarController.navigationItem setRightBarButtonItem:self.barButtonItemRefresh animated:YES];
    
}

- (void)setDisplayInactive {
    
    [self setPageingEnabled:NO];
    
    UIColor *tintColor = [UIColor lightGrayColor];
    self.slider.pageSlider.tintColor = tintColor;
    
    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = NO;
    }
    
    self.slider.pageSlider.enabled = NO;
    self.barButtonItemRefresh.enabled = NO;
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

- (void)updateNumberOfPages {
    self.numberOfPages = self.document.reportFormatter.numberOfPages;
    self.maxNumberOfPages = self.numberOfPages > 0 ? (self.numberOfPages - 1) : 0;
    [self setDisplayActive];
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender {
    
    self.didRefreshBeforeReaload = true;
    self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    
    if (self.isRefreshing == false) {
        self.startedRefresh = true;
        self.refreshing = true;
        [self setDisplayInactive];
        
        MTDatabase *database = self.document.mainDatabase;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver: self
                               selector: @selector(reportDocumentDidReadRows:)
                                   name: MTNotificationDidReadRowsName
                                 object: database];
        
        
        __weak __block MADViewerController *weakself = self;
        [self.document refresh:^(BOOL success, NSError *error) {
            __strong MADViewerController *strongself = weakself;
            
            if (success) {
                strongself.lastCacheDate = [NSDate date];
            } else {
                
                __weak MADViewerController *weakself2 = strongself;
                [NSError presentError: error
                     onViewController: strongself
                           completion:^(BOOL success) {
                               __strong MADViewerController *strongself2 = weakself2;
                               [[MTKeyChain sharedObject] deleteKey: self.document.mainDatabase.databaseConnection.connectionString
                                                usingViewController: strongself2];
                           }];
                
                
            }
            
            [notificationCenter removeObserver: weakself
                                          name: MTNotificationDidReadRowsName
                                        object: database];
            [weakself setDisplayActive];
            [weakself reload];
            [weakself timerDealloc];
            [weakself updateLateRefreshedLabel:weakself];
        }];
    }
}

- (MTActivityItemProviderPdf *)activityItemProviderPdf {
    NSString *temporaryDirectoryPath = NSTemporaryDirectory();
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
    NSURL *urlEmpty = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    MTActivityItemProviderPdf *activityItemProviderPdf = [[MTActivityItemProviderPdf alloc] initWithPlaceholderItem:urlEmpty];
    activityItemProviderPdf.document = self.document;
    return activityItemProviderPdf;
}

- (void)showPrintDialog {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakself = self;

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
                            __weak MADViewerController *weakself2 = weakself;
                            void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
                            ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
                                weakself2.slider.pageSlider.enabled = YES;
                                [weakself2 enableTabBarItems];
                            };
                            [sharedController presentFromBarButtonItem:weakself.barButtonItemActivity animated:YES
                                        completionHandler:completionHandler];
                        }
                    });
                });
            });
        });
    }
}

- (IBAction)activity:(id)sender {
    self.activityExporting = true;
    self.slider.pageSlider.enabled = NO;
    
    MTActivityItemProviderPdf *activityItemProviderPdf = [self activityItemProviderPdf];
    activityItemProviderPdf.delegate = self;
    NSArray *activityItems = @[activityItemProviderPdf];
    [self setActivityItemProviderPdf:activityItemProviderPdf];
    
    MTActivityReportPrintPreview *printPreview = [[MTActivityReportPrintPreview alloc] init];
    printPreview.delegate = self;

    NSArray *applicationActivities = @[printPreview];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:applicationActivities];
    
    __weak __block MADViewerController *weakself = self;
    UIActivityViewControllerCompletionWithItemsHandler activityViewControllerCompletionWithItemsHandler =
                ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
        if (completed || (completed == NO && activityType == nil)) {
            weakself.slider.pageSlider.enabled = YES;
            weakself.activityExporting = false;
            [weakself enableTabBarItems];
        } else {
            if (activityType.length > 0) {  // Long running activity
                if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
                    if (sharedController) {
                        sharedController.delegate = weakself;
                        UIPrintPageRenderer *printPageRender = [self.document printerPrintPageRender];
                        sharedController.printPageRenderer = printPageRender;
                        sharedController.delegate = self.document;
                        __weak MADViewerController *weakself = self;
                        if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
                            [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = [UIColor tintColorAnalogous4];
                            [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [UIColor tintColorRed];
                            [sharedController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                                [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = nil;
                                [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [UIColor tintColorWhite];
                                weakself.slider.pageSlider.enabled = YES;
                                weakself.activityExporting = false;
                                [weakself enableTabBarItems];
                            }];
                        }
                    }
                }
                weakself.slider.pageSlider.enabled = YES;
                weakself.activityExporting = false;
            } else {    // Cancel button
                weakself.slider.pageSlider.enabled = YES;
                weakself.activityExporting = false;
                [weakself enableTabBarItems];
            }
        }
    };
    activityViewController.completionWithItemsHandler = activityViewControllerCompletionWithItemsHandler;
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;

    UIPopoverPresentationController *ppc = activityViewController.popoverPresentationController;
    ppc.barButtonItem = sender;
    
    __weak MADViewerController *weakSelf = self;
    [self presentViewController:activityViewController animated:YES completion:^{
        weakSelf.presentedViewController.navigationController.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
    }];
    [self disableTabBarItems];
}

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

- (void)reload {
    __weak MADViewerController *blockself = self;
    CGSize size = self.document.paper.paperSize;
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [blockself reloadWithSize:size /*blockself.view.bounds.size*/];
        });
    });
}

- (void)loadFromCache:(CGSize)viewBounds {
    
    [self.document activeDocumentModel];
    [self.document prepareForQuery];
    
    self.document.reportFormatter.didRefresh = NO;
    [self.document.reportFormatter loadFromCacheWithSize: viewBounds];
    
    MTReportViewerPrintPageRenderer *printPageRender =  [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: self.document.reportFormatter
                                                                                                               dataTable: self.document.mainDataTable];
    self.printPageRendererReport = printPageRender;
    
    [self updateNumberOfPages];
    
    MTReportViewerReportPageViewController *pageOne = [MTReportViewerReportPageViewController PageViewControllerWithDocument: self.document
                                                                                                                  pageNumber: self.currentPageNumber
                                                                                                                     ofPages: self.document.reportFormatter.numberOfPages
                                                                                                                       frame: self.view.bounds
                                                                                                                 andDelegate: self];
    NSArray *viewControllers = @[pageOne];
    
    [self setViewControllers: viewControllers
                           direction: UIPageViewControllerNavigationDirectionForward
                            animated: NO completion: nil];
    
    self.refreshing = false;
    self.startedRefresh = false;
    [self updateRecordsReadStatus];
    self.document.reportFormatter.didRefresh = NO;
    
}

- (void)reloadWithSize:(CGSize)viewBounds {
    
    if (self.backgroundTaskIdRefresh == UIBackgroundTaskInvalid) {
        self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    }
    
    [self setDisplayInactive];
    
    __weak MADViewerController *blockViewer = self;
    
    [self.document prepareForQuery];
    
    __weak MADocument *weakdoc = self.document;

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        
        [blockViewer watchFormatter: weakdoc.reportFormatter];

        weakdoc.reportFormatter.didRefresh = blockViewer.startedRefresh;
        [weakdoc.reportFormatter formatForSize:viewBounds contentChanged:blockViewer.startedRefresh];
        
        MTReportViewerPrintPageRenderer *printPageRender =  [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: weakdoc.reportFormatter
                                                                                                                   dataTable: weakdoc.mainDataTable];
        blockViewer.printPageRendererReport = printPageRender;
        [blockViewer ignoreFormatter: weakdoc.reportFormatter];

        __weak MADocument *doc2 = weakdoc;
        __weak MADViewerController *blockViewer2 = blockViewer;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [blockViewer2 updateNumberOfPages];
            
            MTReportViewerReportPageViewController *pageOne = [MTReportViewerReportPageViewController PageViewControllerWithDocument: blockViewer2.document
                                                                                                                          pageNumber: blockViewer2.currentPageNumber
                                                                                                                             ofPages: blockViewer2.numberOfPages
                                                                                                                               frame: blockViewer2.view.bounds
                                                                                                                         andDelegate: blockViewer2];

            NSArray *viewControllers = @[pageOne];
            
            [blockViewer2 setViewControllers: viewControllers
                                   direction: UIPageViewControllerNavigationDirectionForward
                                    animated: NO completion: nil];

            blockViewer2.refreshing = false;
            blockViewer2.startedRefresh = false;
            [blockViewer2 updateRecordsReadStatus];
            doc2.reportFormatter.didRefresh = NO;
            
            if (blockViewer2.backgroundTaskIdRefresh != UIBackgroundTaskInvalid) {
                
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                if (blockViewer2.didRefreshBeforeReaload) {
                    notification.alertBody = NSLocalizedString(@"Refresh completed.", @"Refresh completed.");
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                    blockViewer2.didRefreshBeforeReaload = false;
                }
                
                NSNumber *bgtask = @(blockViewer2.backgroundTaskIdRefresh);
                blockViewer2.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
                [[UIApplication sharedApplication] handoffBackground:bgtask];
            }
            
        });
    });
}

- (void)watchFormatter:(MTReportFormatter *)formatter {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reportFormatterDidFormatPage:)
                                                 name: MTNotificationDidFormatPagesName
                                               object: formatter];
}

- (void)ignoreFormatter:(MTReportFormatter *)formatter {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MTNotificationDidFormatPagesName
                                                  object: formatter];
}

#pragma mark - UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
       viewControllerAfterViewController:(MTReportViewerReportPageViewController *)pageViewControllerLast {
    
    MTReportViewerReportPageViewController *result = nil;
    if (viewerViewController.pageIsAnimating == false) {
        NSUInteger visiblePageNumber = 0;
        pageViewControllerLast.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        pageViewControllerLast.view.translatesAutoresizingMaskIntoConstraints = YES;
        if (pageViewControllerLast != nil && [pageViewControllerLast respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerLast.reportPageNumber;
        }
        if (visiblePageNumber + 1 <= self.numberOfPages) {
            result = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                           pageNumber: visiblePageNumber + 1
                                                                              ofPages: self.numberOfPages];
            result.delegate =  self;
            result.view.frame = self.view.bounds;
            result.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            result.view.translatesAutoresizingMaskIntoConstraints = YES;
        }
    }
    return result;
    
}

- (UIViewController *)pageViewController:(MADViewerController *)viewerViewController
      viewControllerBeforeViewController:(MTReportViewerReportPageViewController *)pageViewControllerPrevious {
    
    MTReportViewerReportPageViewController *result = nil;
    if (viewerViewController.pageIsAnimating == false) {
        NSUInteger visiblePageNumber = 0;
        if (pageViewControllerPrevious != nil && [pageViewControllerPrevious respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerPrevious.reportPageNumber;
        }
        if (visiblePageNumber - 1 > 0) {
            result = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                           pageNumber: visiblePageNumber - 1
                                                                              ofPages: self.numberOfPages];
            result.delegate =  self;
            result.view.frame = self.view.bounds;
            result.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            result.view.translatesAutoresizingMaskIntoConstraints = YES;
        }
    }
    return result;
}

- (NSInteger)presentationCountForPageViewController:(MADViewerController *)pageViewController {
    return pageViewController.numberOfPages;
}

- (NSInteger)presentationIndexForPageViewController:(MADViewerController *)pageViewController {
    return pageViewController.currentPageIndex;
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(MADViewerController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    
    if (completed || finished) {
        pageViewController.pageIsAnimating = false;
        if (pageViewController.viewControllers.count > 0) {
            MTReportViewerReportPageViewController *viewController = pageViewController.viewControllers[0];
            [pageViewController setCurrentPageIndex: viewController.reportPageNumber - 1];
            [self.labelStatus updatePageStatus:self.numberOfPages currentPageIndex:self.currentPageIndex];
            [pageViewController.slider.pageSlider setValue: pageViewController.currentPageIndex animated: YES];
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

- (void)updateLateRefreshedLabel:(id)sender {

    if (self.lastCacheDate == nil) {    // Find last cache date
        NSURL *cachedDataUrl = [self.document cachedDataUrl];
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedDataUrl.path error:&error];
        if (error == nil) {
            self.lastCacheDate = attributes.fileModificationDate;
        }
    }

    MTDateResolution resolution;
    if (self.lastCacheDate == nil) {    // No Cache exist, so return quickly.
        NSString *noCache = NSLocalizedString(MADTextNoCache, MADTextNoCache);
        [self.labelStatus updateStatusWithTime:noCache];
        return;
    } else {
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:self.lastCacheDate];
        [self.labelStatus updateStatusWithTime:dateStringAndInterval.former];
        resolution = ((NSNumber *)dateStringAndInterval.latter).integerValue;
    }
    if (self.timerLabelTimeSinceRefreh != nil) {
        if ([self.timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([self.timerLabelTimeSinceRefreh isValid]) {
                [self.timerLabelTimeSinceRefreh invalidate];
            }
        }
        self.timerLabelTimeSinceRefreh = nil;
    }
    
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: [NSDate timeIntervalForResolution:resolution]
                                                  target: self selector: @selector(updateLateRefreshedLabel:) userInfo:nil
                                                 repeats: NO];
    self.timerLabelTimeSinceRefreh = t;
}

- (void)updateRecordsReadStatus {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateRecordsReadStatus];
        });
    } else {
        NSNumber *numberOfResults = @([self.document.mainDataTable numberOfRows]);
        [self.labelStatus updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];
    }
}

- (void)setMaxNumberOfPages:(NSUInteger)numberOfPages {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf setMaxNumberOfPages:numberOfPages];
        });
    } else {
        if (round(self.slider.pageSlider.maximumValue) != round(numberOfPages)) {
            self.slider.pageSlider.maximumValue = numberOfPages;
        }
    }
    [self.labelStatus updatePageStatus:self.numberOfPages currentPageIndex:self.currentPageIndex];
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self enableTabBarItems];
}

- (UIViewController *)activeViewController {
    return self;
}

static UIImageView *captureSnapshotOfView (UIView *targetView) {
    UIGraphicsBeginImageContextWithOptions(targetView.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [targetView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *snapshotView = [[UIImageView alloc] initWithImage:image];
    snapshotView.frame = targetView.frame;
    return snapshotView;
}

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
