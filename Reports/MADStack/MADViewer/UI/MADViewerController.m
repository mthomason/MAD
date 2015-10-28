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
#import "MUIViewControllerDelegate.h"
#import "MADProgressView.h"

#import "MADNavigationBarTitleView.h"
#import "MTReportViewerReportPageView.h"

#import "UIApplication+Extras.h"
#import "MTActivityReportPrintPreview.h"
#import "MTReportViewerReportPageViewController.h"

#import "MTSliderPageVertical.h"

#import "UIPageViewController+Extras.h"
#import "UIViewController+UI.h"
#import "UIViewController+tabBarItem.h"

#import "NSDate+Extras.h"

#import "MTStoreKitController+Features.h"

#import "MADLabelStatus.h"

NSString * const MADImageBarButtonItemMadViewer = @"UIBarButtonItemMadViewer";
NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";

static NSString * const MADTextFormattingPage = @"Formatting page %@.";
static NSString * const MADTextPageXofY = @"\nPage %1@ of %2@ pages.";
static NSString * const MADTextReadRecords = @"\nRead %@ records.";

static const CGFloat MADSliderPaginationWidth = 40.0000f;
static const CGFloat MADBarButtonItemsMargin = 8.0000f;

@interface MADViewerController ()
    <UIPopoverControllerDelegate,
        UIPrintInteractionControllerDelegate,
        UIStateRestoring,
        MTPrintingProtocol,
        MTActivityReportPrintPreviewDelegate,
        MTTabBarImageProtocol,
        MTActivityItemProviderDelegate>

@property (nonatomic, strong) MTReportViewerPrintPageRenderer *printPageRendererReport;
@property (nonatomic, strong) MTSliderPageVertical *pageSlider;
@property (nonatomic, strong) MADLabelStatus *labelStatus;
@property (nonatomic, strong) MTActivityItemProviderPdf *activityItemProviderPdf;

@property (nonatomic, strong) UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemActivity;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, strong) NSDate *lastCacheDate;
@property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;

@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, strong) UIToolbar *toolbarSideRight;

@property (nonatomic, strong) UIBarButtonItem *barButtonLabelStatus;

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
    
    self.activityExporting = false;
    self.didRefreshBeforeReaload = false;
    
    MTSliderPageVertical *vertSlider = [[MTSliderPageVertical alloc] init];
    [vertSlider addTarget:self action:@selector(handleSliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [vertSlider addTarget:self action:@selector(handleSliderDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *sliderTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTapSlider:)];
    [vertSlider addGestureRecognizer:sliderTapped];
    
    UIToolbar *vertToolbar = [[UIToolbar alloc] init];
    
    vertSlider.transform = CGAffineTransformRotate(vertSlider.transform, 1.0000f / 2.0000f * (CGFloat)M_PI);
    vertToolbar.transform = CGAffineTransformRotate(vertSlider.transform, 3.0000f / 2.0000f * (CGFloat)M_PI);
    
    self.pageSlider = vertSlider;
    self.toolbarSideRight = vertToolbar;
    
    MADLabelStatus *labelStatus = [[MADLabelStatus alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 30.0000f, 44.0000f)];
    UIBarButtonItem *barButtonLabelStatus = [[UIBarButtonItem alloc] initWithCustomView:labelStatus];
    self.barButtonLabelStatus = barButtonLabelStatus;
    self.labelStatus = labelStatus;
    
    UIBarButtonItem *barButtonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.barButtonItemRefresh = barButtonRefresh;
    
    UIProgressView *progressView = [[MADProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.progress = 0.0000f;
    self.progressView = progressView;

    [self.toolbarSideRight addSubview:self.pageSlider];
    
    self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitCausesPageTurn;
}

#pragma mark - UIViewController Standard Callbacks

- (NSString *)title {
    return [MADViewerController MADViewer];
}

+ (NSString *)MADViewer {
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [NSString stringWithFormat: @"MAD %@", localizedSuffix];
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
    [self updatePageStatus];
    
    UIViewController *blankPage = [[UIViewController alloc] init];
    NSArray *blankPageArray = @[blankPage];

    [self setViewControllers: blankPageArray direction: UIPageViewControllerNavigationDirectionForward
                    animated: NO completion: ^(BOOL finished) { }];
    
    [self.view addSubview:self.toolbarSideRight];
    [self.view bringSubviewToFront:self.toolbarSideRight];
    
    NSMutableArray *toolbarItems = self.toolbarItems.mutableCopy;
    [toolbarItems insertObject: self.barButtonLabelStatus atIndex: 0];
    [self setToolbarItems: toolbarItems animated: NO];
    
    UIImage *blank = [UIImage new];
    [self.toolbarSideRight setBackgroundImage:blank forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self.toolbarSideRight setShadowImage:blank forToolbarPosition:UIToolbarPositionAny];
    self.toolbarSideRight.backgroundColor = [UIColor tintColorWhiteAlpha];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self updateNavigationPrompt:previousTraitCollection != nil];
}

- (void)updateNavigationPrompt:(BOOL)animated {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [UIView setAnimationsEnabled:animated];
        self.tabBarController.navigationItem.prompt = self.document.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:YES];
    } else {
        self.tabBarController.navigationItem.prompt = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateNavigationPrompt:animated];
    [self.navigationController.toolbar setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // MARK: Reporting feature (number of results in main query)
    MADocument *mad = self.document;
    mad.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;

    [mad initalizeMainQuery:[mad activeDocumentModel]];
    [self reload];
    [self layoutSubviewSliderPagination];
    [self updateLateRefreshedLabel:self];
    
    if ([self printPageRendererReport] == nil) {
        [self.document activeDocumentModel];    // Initalizes the report formatter, if not already done... Important!
        MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: self.document.reportFormatter
                                                                                                                           dataTable: self.document.mainDataTable];
        [self setPrintPageRendererReport: prtingPageRendererReport];
    }
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
    [self.view bringSubviewToFront:self.toolbarSideRight];
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

- (NSShadow *)statusLabelShadow {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0000f
                                         green:0.00000f
                                          blue:0.0000f
                                         alpha:0.8000f];
    shadow.shadowOffset = CGSizeMake(0.0000f, 1.0000f);
    shadow.shadowBlurRadius = 5.0000f;
    return shadow;
}


- (void)handleGestureTapSlider:(UIGestureRecognizer *)tap {
    UISlider *slider = (UISlider *)tap.view;
    if (slider.highlighted == NO) {
        CGPoint pt = [tap locationInView: slider];
        float percentage = (float)(pt.x / slider.bounds.size.width);
        float delta = percentage * (slider.maximumValue - slider.minimumValue);
        float value = slider.minimumValue + delta;
        [slider setValue:value animated:YES];
        [self handleSliderDidFinishDrag:slider];
        [self handleSliderChangedPage:slider];
    }
}

- (void)handleSliderChangedPage:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [self moveToPageAtIndex:lroundf(slider.value)];
}

- (void)handleSliderDidFinishDrag:(UISlider *)sender {
    sender.value = lroundf(sender.value);               // Sets your slider to this value
}

#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage { return [UIImage imageNamed:MADImageBarButtonItemMadViewer8]; }

- (void)layoutSubviewSliderPagination {
    self.toolbarSideRight.frame = CGRectMake(self.view.frame.size.width - MADSliderPaginationWidth,
                                             CGPointZero.y,
                                             MADSliderPaginationWidth,
                                             self.view.frame.size.height);
    self.pageSlider.frame = CGRectMake(CGPointZero.x,
                                       CGPointZero.y,
                                       MADSliderPaginationWidth,
                                       self.view.frame.size.height);
}

- (BOOL)moveToPageAtIndex:(NSUInteger)index {
    BOOL result = NO;
    if ((unsigned long)index != self.currentPageIndex && index != NSNotFound) {
        self.currentPageIndex = index;
        [self updatePageStatus];
        MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                                                                pageNumber: self.currentPageIndex + 1
                                                                                                                   ofPages: self.numberOfPages];
        pageOne.view.frame = self.view.bounds;
        pageOne.delegate = self;
        
        __block MADViewerController *reportViewer = self;
        [self.view bringSubviewToFront:self.toolbarSideRight];
        NSArray *viewControllers = @[pageOne];
        [self setViewControllers: viewControllers
                       direction: UIPageViewControllerNavigationDirectionForward
                        animated: NO completion:^(BOOL finished) {
                            if (finished) {
                                [reportViewer.view bringSubviewToFront:reportViewer.toolbarSideRight];
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
        [self reloadWithSize:frame.size];
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

#pragma mark - Actions

- (void)setDisplayActive {
    
    [self setPageingEnabled:YES];

    UIColor *red = [UIColor tintColorRed];
    self.pageSlider.tintColor = red;

    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    UITabBarItem *item;
    for (item in tabBarItems) {
        item.enabled = YES;
    }
    
    self.pageSlider.enabled = YES;
    self.barButtonItemRefresh.enabled = YES;
    self.barButtonItemActivity.enabled = YES;
    
    self.refreshing = false;
    self.updatingOfTimerIsPaused = false;
    self.barButtonItemRefresh.enabled = YES;

    [self.tabBarController.navigationItem setRightBarButtonItem:self.barButtonItemRefresh animated:YES];

}

- (void)setDisplayInactive {
    
    [self setPageingEnabled:NO];
    
    self.pageSlider.enabled = NO;
    UIColor *tintColor = [UIColor lightGrayColor];
    self.pageSlider.tintColor = tintColor;
    
    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = NO;
    }

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
                
                NSDate *lastD = [NSDate date];
                strongself.lastCacheDate = lastD;
                
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

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSNumber *pageNumber = sender.userInfo[MTDatabaseNumberOfPagesFormattedKey];
    [self updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    NSNumber *rowNumber = sender.userInfo[MTDatabaseNumberOfRowsReadKey];
    [self updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
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
                                weakself2.pageSlider.enabled = YES;
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
    self.pageSlider.enabled = NO;
    
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
            weakself.pageSlider.enabled = YES;
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
                                weakself.pageSlider.enabled = YES;
                                weakself.activityExporting = false;
                                [weakself enableTabBarItems];
                            }];
                        }
                    }
                }
                weakself.pageSlider.enabled = YES;
                weakself.activityExporting = false;
            } else {    // Cancel button
                weakself.pageSlider.enabled = YES;
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
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [blockself reloadWithSize:blockself.view.bounds.size];
        });
    });
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
            
            NSUInteger numberOfPages = [self.document.reportFormatter numberOfPages];
            blockViewer2.numberOfPages = numberOfPages;
            blockViewer2.maxNumberOfPages = numberOfPages > 0 ? (numberOfPages - 1) : 0;
            [blockViewer2 setDisplayActive];
            
            MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                                                                    pageNumber: (blockViewer2.currentPageIndex + 1)
                                                                                                                       ofPages: numberOfPages];
            pageOne.view.frame = blockViewer2.view.bounds;
            pageOne.delegate = blockViewer2;
            NSArray *viewControllers = @[pageOne];
            
            [blockViewer2 setViewControllers: viewControllers
                                   direction: UIPageViewControllerNavigationDirectionForward
                                    animated: NO
                                  completion: nil];

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
            [pageViewController updatePageStatus];
            [pageViewController.pageSlider setValue: pageViewController.currentPageIndex animated: YES];
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
    if (self.lastCacheDate == nil) {
        
        NSURL *cachedDataUrl = [self.document cachedDataUrl];
        NSString *cachedDataPath = [cachedDataUrl path];
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedDataPath error:&error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            [self setLastCacheDate: lastD];
        }
    }
    
    if (self.lastCacheDate == nil) {
        [self.labelStatus updateStatusWithTime:@"No Cache"];
    } else {
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:self.lastCacheDate];
        NSString *display = [dateStringAndInterval former];
        [self.labelStatus updateStatusWithTime:display];
        
        MTDateResolution resolution = [[dateStringAndInterval latter] integerValue];
        
        NSTimeInterval updateLabelInSeconds;
        
        switch (resolution) {
            case MTDateResolutionDay:
                updateLabelInSeconds = 86400.0;
                break;
            case MTDateResolutionHour:
                updateLabelInSeconds = 3600.0;
                break;
            case MTDateResolutionMinute:
                updateLabelInSeconds = 60.0;
                break;
            case MTDateResolutionSecond:
                updateLabelInSeconds = 1.0;
                break;
            case MTDateResolutionMillisecond:
                updateLabelInSeconds = 0.1;
                break;
            default:
                updateLabelInSeconds = 86400;
                break;
        }
        
        if (self.timerLabelTimeSinceRefreh != nil) {
            if ([self.timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
                if ([self.timerLabelTimeSinceRefreh isValid]) {
                    [self.timerLabelTimeSinceRefreh invalidate];
                }
            }
            [self setTimerLabelTimeSinceRefreh:nil];
        }
        
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: updateLabelInSeconds target:self
                                                    selector: @selector(updateLateRefreshedLabel:) userInfo:nil
                                                     repeats: NO];
        [self setTimerLabelTimeSinceRefreh:t];
    }
}

- (void)updateRecordsReadStatus {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateRecordsReadStatus];
        });
    } else {
        NSNumber *numberOfResults = @([self.document.mainDataTable numberOfRows]);
        [self updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];
    }
}

- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs {
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(MADTextReadRecords, MADTextReadRecords);
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [self.labelStatus updateStatusWithRecordsRead:readRecords];
}

- (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs {
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(MADTextFormattingPage, MADTextFormattingPage);
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [self.labelStatus updateStatusWithRecordsRead:readRecords];
}

- (NSString *)localizedStringForInteger:(NSUInteger)integer {
    NSNumber *number = @(integer);
    return [NSNumberFormatter localizedStringFromNumber: number numberStyle: NSNumberFormatterDecimalStyle];
}

- (void)updatePageStatus {
    NSString *localizedPageOfPagesFormat = NSLocalizedString(MADTextPageXofY, MADTextPageXofY);
    NSString *startPage = [self localizedStringForInteger:self.currentPageIndex + 1];
    NSString *endPage = [self localizedStringForInteger:self.numberOfPages];
    NSString *localizedPageOfPages = [NSString stringWithFormat:localizedPageOfPagesFormat, startPage, endPage];
    [self.labelStatus updateStatusWithPageNumber:localizedPageOfPages];
}

- (void)setMaxNumberOfPages:(NSUInteger)numberOfPages {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf setMaxNumberOfPages:numberOfPages];
        });
    } else {
        if (round([self.pageSlider maximumValue]) != round(numberOfPages)) {
            [self.pageSlider setMaximumValue:numberOfPages];
        }
    }
    [self updatePageStatus];
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
