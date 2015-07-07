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
#import "MADConstants.h"
#import "MADNavigationBarTitleView.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTReportViewerReportPageView.h"

#import "UIDevice+Hack.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "UIApplication+Extras.h"
#import "MADocument.h"
#import "MTActivityItemProviderPdf.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "NSError+Constructors.h"
#import "MTReportFormatter.h"
#import "MTQuery.h"
#import "MTPaper.h"
#import "MTPair.h"
#import "MTActivityReportPrintPreview.h"
#import "MTReportViewerReportPageViewController.h"

#import "MTSliderPageVertical.h"

#import "UIPageViewController+Extras.h"
#import "UIViewController+UI.h"
#import "UIViewController+tabBarItem.h"
#import "MTDataTable.h"

#import "MTNotificationDidFormatPage.h"
#import "MTNotificationDidReadRows.h"
#import "UIColor+EverydayApps.h"
#import "NSDate+Extras.h"

#import "MADModelNavigationController.h"

#import "MTKeyChain.h"
#import "MTDatabaseConnection.h"
#import "MTStoreKitController+Features.h"

NSString * const MADImageBarButtonItemMadViewer = @"UIBarButtonItemMadViewer";
NSString * const MADImageBarButtonItemMadViewer8 = @"UIBarButtonItemMadViewer8";

@interface MADViewerController ()
    <UIPopoverControllerDelegate,
        MTPrintingProtocol,
        MTActivityReportPrintPreviewDelegate,
        MTTabBarImageProtocol,
        UIPrintInteractionControllerDelegate,
        MTActivityItemProviderDelegate, UIStateRestoring>

@property (nonatomic, strong) MTReportViewerPrintPageRenderer *printPageRendererReport;

@property (nonatomic, strong) IBOutlet UIView *sliderView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemSliderView;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemPrint;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemSendToPdf;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemDone;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemActivity;

@property (nonatomic, strong) IBOutlet UILabel *labelDateLastRefreshed;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusLabelWidthConstraint;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, assign) CGRect lastLayoutBounds;

@property (nonatomic, strong) NSDate *lastCacheDate;
@property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;

@property (nonatomic, assign) BOOL startedRefresh;
@property (nonatomic, assign) BOOL pageIsAnimating;
@property (atomic,    assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL updatingOfTimerIsPaused;

@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, strong) UIImageView *snapshotBeforeRotation;
@property (nonatomic, strong) UIImageView *snapshotAfterRotation;

@property (nonatomic, assign) CGRect frameBeforeRotation;
@property (nonatomic, assign) CGRect frameAfterRotation;

@property (nonatomic, strong) MTSliderPageVertical *pageSlider;

@property (nonatomic, strong) UIToolbar *toolbarSideRight;

@property (nonatomic, strong) UIBarButtonItem *barButtonLabelStatus;

@property (nonatomic, strong) UILabel *labelStatus;

@property (nonatomic, strong) NSAttributedString *statusMessage1;
@property (nonatomic, strong) NSAttributedString *statusMessage2;
@property (nonatomic, strong) NSAttributedString *statusMessage3;

@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) NSAttributedString *lineReturnString;

@property (nonatomic, strong) MTReportFormatter *printingReportFormatter;
@property (nonatomic, strong) MTActivityItemProviderPdf *activityItemProviderPdf;

@property (nonatomic, assign) BOOL shouldShowPrintDialog;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdRefresh;

@property (nonatomic, assign) BOOL didRefreshBeforeReaload;
@property (nonatomic, assign) BOOL activityExporting;

//- (instancetype)init NS_DESIGNATED_INITIALIZER;
//- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
//- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;
//- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options NS_DESIGNATED_INITIALIZER;

@end

@implementation MADViewerController

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
    //self.restorationClass = self;
    
    self.activityExporting = NO;
    self.didRefreshBeforeReaload = NO;
    NSAttributedString *lineReturnString = [[NSAttributedString alloc] initWithString:@"\n"];
    self.lineReturnString = lineReturnString;
    [self initializeVerticalSlider];
    [self initalizeLabelStatus];
    [self initalizeStatusMessages];
    [self initalizeProgressBar];
    [self.toolbarSideRight addSubview:self.pageSlider];
}

- (void)initalizeProgressBar {
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.trackTintColor = [UIColor tintColorRed];
    progressView.tintColor = [UIColor tintColorBlue];
    progressView.progress = 0.0000f;
    self.progressView = progressView;
}

- (void)initializeVerticalSlider {
    MTSliderPageVertical *vertSlider = [[MTSliderPageVertical alloc] init];
    vertSlider.maximumValue = 0.0000f;
    vertSlider.minimumValue = 0.0000f;
    vertSlider.continuous = YES;
    vertSlider.tintColor = [UIColor tintColorRed];
    vertSlider.value = 0.0000f;
    
    [vertSlider addTarget:self action:@selector(sliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [vertSlider addTarget:self action:@selector(sliderPageDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *sliderTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [vertSlider addGestureRecognizer:sliderTapped];

    UIToolbar *vertToolbar = [[UIToolbar alloc] init];

    vertSlider.transform = CGAffineTransformRotate(vertSlider.transform, 1.0000f / 2.0000f * M_PI);
    vertToolbar.transform = CGAffineTransformRotate(vertSlider.transform, 3.0000f / 2.0000f * M_PI);
    
    self.pageSlider = vertSlider;
    self.toolbarSideRight = vertToolbar;

}

- (void)initalizeLabelStatus {
    UILabel *labelStatus = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 30.0000f, 44.0000f)];
    [labelStatus setNumberOfLines:3];
    labelStatus.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    UIBarButtonItem *barButtonLabelStatus = [[UIBarButtonItem alloc] initWithCustomView:labelStatus];
    self.barButtonLabelStatus = barButtonLabelStatus;
    self.labelStatus = labelStatus;
}

- (void)initalizeStatusMessages {
    NSAttributedString *statusMessage1 = [NSAttributedString new];
    NSAttributedString *statusMessage2 = [NSAttributedString new];
    NSAttributedString *statusMessage3 = [NSAttributedString new];
    self.statusMessage1 = statusMessage1;
    self.statusMessage2 = statusMessage2;
    self.statusMessage3 = statusMessage3;
}

#pragma mark - UIViewController Standard Callbacks

- (NSString *)title {
    return NSLocalizedString(@"MAD Viewer", "MAD Viewer");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    

    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = [MTApplicationInstance madViewer];
    self.navigationItem.titleView = titleView;
    
    _timerLabelTimeSinceRefreh = nil;
    
    self.isRefreshing = NO;
    self.updatingOfTimerIsPaused = NO;
    
    _lastCacheDate = nil;
    
    self.labelDateLastRefreshed.text = @"";

    self.pageIsAnimating = NO;
    self.startedRefresh = NO;
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.dataSource = self;
    self.delegate = self;
    
    self.currentPageIndex = 0;
    [self updatePageStatus];
    
    UIViewController *blankPage = [[UIViewController alloc] init];
    NSArray *blankPageArray = @[blankPage];

    [self setViewControllers: blankPageArray
                   direction: UIPageViewControllerNavigationDirectionForward
                    animated: NO
                  completion: ^(BOOL finished) { }];
    
    [self addPageSliderToView];
    
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithArray: [self toolbarItems]];
    [toolbarItems insertObject: [self barButtonLabelStatus] atIndex: 0];
    [self setToolbarItems: toolbarItems animated: NO];
    
    [self setTintColorForToolbar:self.navigationController.toolbar];
    [self setTintColorForSidebar:self.toolbarSideRight];
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self updateNavigationPrompt:previousTraitCollection != nil];
}

- (void)updateNavigationPrompt:(BOOL)animated {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [UIView setAnimationsEnabled:animated];
        self.navigationItem.prompt = [MTApplicationInstance mainInstance].openDocument.fileURL.lastPathComponent;
        [UIView setAnimationsEnabled:YES];
    } else {
        self.navigationItem.prompt = nil;
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
    [MTApplicationInstance mainInstance].openDocument.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;

    [[MTApplicationInstance mainInstance].openDocument initalizeMainQuery];
    [self reload];
    [self layoutSubviewSliderPagination];
    [self updateLateRefreshedLabel:self];
    
    if ([self printPageRendererReport] == nil) {
        [[MTApplicationInstance mainInstance].openDocument activeDocumentModel];    // Initalizes the report formatter, if not already done... Important!
        MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: [MTApplicationInstance mainInstance].openDocument.reportFormatter
                                                                                                                           dataTable: [MTApplicationInstance mainInstance].openDocument.mainDataTable];
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
    CGFloat itemsMargin = 8.0000f;
    NSUInteger counter = 0;
    for (UIBarButtonItem *barButtonItem in [[self.navigationController toolbar] items]) {
        if (barButtonItem != [self barButtonItemSliderView]) {
            NSString *viewSelector = NSStringFromSelector(@selector(view));
            UIView *view = [barButtonItem valueForKey:viewSelector];
            if (view != nil) {
                CGFloat width = view? [view frame].size.width : (CGFloat)0.0;
                nonSliderButtonsWidth += width + itemsMargin;
            } else {
                nonSliderButtonsWidth += [barButtonItem width];
            }
        }
        counter++;
    }
    self.barButtonItemSliderView.width = self.navigationController.toolbar.frame.size.width - nonSliderButtonsWidth - (itemsMargin * counter + 1);
    [self.sliderView setFrame:CGRectMake(self.sliderView.frame.origin.x, self.sliderView.frame.origin.y, self.barButtonItemSliderView.width, self.sliderView.frame.size.height)];
    [self.navigationController.toolbar setNeedsLayout];
    [self.view bringSubviewToFront:self.toolbarSideRight];
    [self layoutSubviewSliderPagination];
    self.labelStatus.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 44.0000f);
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    if ([self.tabBarController.selectedViewController isEqual: self.navigationController] && self.activityExporting == NO) {
        MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
        MTReportViewerReportPageView *displayView = (MTReportViewerReportPageView *)pageViewController.view;
        
        [self setFrameBeforeRotation: [displayView frame]];
        
        [self setSnapshotBeforeRotation: captureSnapshotOfView(displayView)];
        [displayView insertSubview:[self snapshotBeforeRotation] aboveSubview:displayView];
        
        [displayView setNeedsDisplay];
        
        CGRect oldBounds = displayView.bounds;
        [self redrawWithFrame:oldBounds];
        
        pageViewController = [self currentPageviewController];
        displayView = (MTReportViewerReportPageView *)pageViewController.view;
        
        [self setFrameAfterRotation: oldBounds];
        [UIView setAnimationsEnabled:NO];
        [self setSnapshotAfterRotation: captureSnapshotOfView(displayView)];
        
        
        CGRect framePreservingHeight = CGRectMake(self.frameBeforeRotation.origin.x,
                                                  self.frameBeforeRotation.origin.y,
                                                  self.frameBeforeRotation.size.width,
                                                  self.snapshotAfterRotation.frame.size.height);
        
        self.snapshotAfterRotation.frame = framePreservingHeight;
        
        UIImage *imageBeforeRotation = self.snapshotBeforeRotation.image;
        imageBeforeRotation = [imageBeforeRotation resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
        
        UIImage *imageAfterRotation = [self.snapshotAfterRotation image];
        imageAfterRotation = [imageAfterRotation resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
        
        [UIView setAnimationsEnabled:YES];
        
        if ([imageAfterRotation size].height < [imageBeforeRotation size].height) {
            [self.snapshotAfterRotation setAlpha:0.0000f];
            [displayView insertSubview:self.snapshotAfterRotation aboveSubview:[self snapshotBeforeRotation]];
            [self.snapshotAfterRotation setAlpha:1.0000f];
        } else {
            [displayView insertSubview:self.snapshotAfterRotation aboveSubview:[self snapshotBeforeRotation]];
            [[self snapshotBeforeRotation] setAlpha:0.0000f];
        }
        
        [[self snapshotAfterRotation] setFrame:self.frameAfterRotation];
        framePreservingHeight = CGRectMake(self.frameAfterRotation.origin.x, self.frameAfterRotation.origin.y, self.frameAfterRotation.size.width, self.snapshotAfterRotation.frame.size.height);
        [[self snapshotBeforeRotation] setFrame:framePreservingHeight];
        
        if ([displayView respondsToSelector:@selector(setDrawBlankPage:)]) {
            ((MTReportViewerReportPageView *)displayView).drawBlankPage = YES;
        }
        
        [displayView setNeedsDisplay];
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.navigationItem.titleView sizeToFit];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.navigationItem.titleView sizeToFit];
        [self localDidRotate];
    }];
    
}

#pragma mark - add controls

- (void)addProgressViewToView {
    [self.view addSubview:self.progressView];
    [self.view bringSubviewToFront:self.progressView];
}

- (void)removeProgressViewFromView {
    [self.progressView removeFromSuperview];
}

- (void)addPageSliderToView {
    [self.view addSubview:self.toolbarSideRight];
    [self.view bringSubviewToFront:self.toolbarSideRight];
}

#pragma mark - properties

- (NSDictionary *)attributesStatusLabelBold {
    UIColor *textColor = [UIColor whiteColor];
    UIFont *fontBold = [UIFont boldSystemFontOfSize:8.0000f];
    return @{
             NSForegroundColorAttributeName : textColor,
             NSFontAttributeName : fontBold,
             };
}
- (NSDictionary *)attributesStatusLabelLight {
    UIColor *textColor = [UIColor whiteColor];
    UIFont *font = [UIFont systemFontOfSize:8.0000f];
    return @{
             NSForegroundColorAttributeName : textColor,
             NSFontAttributeName : font,
             };
}

- (NSDictionary *)attributesStatusLabelCentered {
    NSMutableParagraphStyle *paragraphStyleCentered = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyleCentered setAlignment:NSTextAlignmentLeft];
    return @{
             NSParagraphStyleAttributeName : paragraphStyleCentered
             };
}

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


- (void)sliderTapped:(UIGestureRecognizer *)tap {
    UISlider *slider = (UISlider *)tap.view;
    if (slider.highlighted == NO) {
        CGPoint pt = [tap locationInView: slider];
        CGFloat percentage = pt.x / slider.bounds.size.width;
        CGFloat delta = percentage * (slider.maximumValue - slider.minimumValue);
        CGFloat value = slider.minimumValue + delta;
        [slider setValue:value animated:YES];
        [self sliderPageDidFinishDrag:slider];
        [self sliderChangedPage:slider];
    }
}

#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage {
    return [UIImage imageNamed:MADImageBarButtonItemMadViewer8];
}

- (void)setTintColorForToolbar:(UIToolbar *)toolbar {
    //toolbar.barTintColor = [UIColor tintColorBlue];
    toolbar.tintColor = [UIColor tintColorWhite];
}

- (void)setTintColorForSidebar:(UIToolbar *)toolbar {
    UIImage *blank = [UIImage new];
    [toolbar setBackgroundImage:blank forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [toolbar setShadowImage:blank forToolbarPosition:UIToolbarPositionAny];
    toolbar.backgroundColor = [UIColor tintColorWhiteAlpha];
}

const CGFloat MADSliderPaginationWidth = 40.0000f;

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

- (void)sliderChangedPage:(id)sender {

    UISlider *slider = (UISlider *)sender;
    float sliderIndex = lroundf([slider value]);
    if ((int)sliderIndex != self.currentPageIndex) {
        self.currentPageIndex = sliderIndex;
        [self updatePageStatus];
        MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithDocument: [MTApplicationInstance mainInstance].openDocument
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
                [reportViewer.labelDateLastRefreshed setHidden:NO];
                reportViewer.updatingOfTimerIsPaused = NO;
                reportViewer.isRefreshing = NO;
                reportViewer = nil;
            }
        }];
    }
}

- (IBAction)sliderPageDidFinishDrag:(id)sender {
    ((UISlider *)sender).value = lroundf(((UISlider *)sender).value);               // Sets your slider to this value
}

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    [[MTApplicationInstance mainInstance].openDocument.managedObjectContext save:&error];
    if (error != nil) {
        [[MTApplicationInstance mainInstance].openDocument.managedObjectContext save:&error];
    }
    [self.viewControllerDelegate viewControllerDidFinish: self];
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

- (void)localDidRotate {

    if (self.activityExporting == NO) {
        
        MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
        UIView *displayView = [pageViewController view];

        if (displayView) {
            if ([displayView respondsToSelector:@selector(setDrawBlankPage:)]) {
                [(MTReportViewerReportPageView *)displayView setDrawBlankPage:NO];
            }
        }
        [displayView setNeedsDisplay];
        
        [self.snapshotBeforeRotation removeFromSuperview];
        [self.snapshotAfterRotation removeFromSuperview];
    }
}

- (MTReportViewerReportPageViewController *)currentPageviewController {
    return [self pageViewControllerAtIndex: self.currentPageIndex];
}

- (MTReportViewerReportPageViewController *)pageViewControllerAtIndex:(NSUInteger)index {
    NSArray *viewControllers = self.viewControllers;
    NSInteger numberOfViewControllers = [viewControllers count];
    MTReportViewerReportPageViewController *result = nil;
    if (index < numberOfViewControllers) {
        result = viewControllers[index];
    } else {
        result = viewControllers.lastObject;
    }
    return result;
}

- (BOOL)shouldReprocess {
    return self.isRefreshing == NO && self.startedRefresh == NO && self.activityExporting == NO;
}

- (void)redrawWithFrame:(CGRect)frame {
    if ([self shouldReprocess]) {
        [self setDisplayActive];
        [self reloadWithSize:frame.size];
    }
}

- (void)drawPage:(NSUInteger)pageIndex inRect:(CGRect)printableRect {
    [self.printPageRendererReport drawPageAtIndex: pageIndex
                                           inRect: printableRect];
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
    
    [self.pageSlider setEnabled:YES];
    [self.pageSlider setTintColor:[UIColor tintColorRed]];

    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    UITabBarItem *item;
    for (item in tabBarItems) {
        item.enabled = YES;
    }
    
    self.barButtonItemRefresh.enabled = YES;
    self.barButtonItemDone.enabled = YES;
    self.barButtonItemPrint.enabled = YES;
    self.barButtonItemSendToPdf.enabled = YES;
    self.barButtonItemActivity.enabled = YES;
    
    [self setIsRefreshing:NO];
    [self setUpdatingOfTimerIsPaused:NO];
    self.barButtonItemRefresh.enabled = YES;
    self.labelDateLastRefreshed.hidden = NO;
    self.labelDateLastRefreshed.text = @"";
    [self.labelDateLastRefreshed setNeedsDisplay];

    [self.navigationItem setRightBarButtonItem:self.barButtonItemRefresh animated:YES];

}

- (void)setDisplayInactive {
    
    [self setPageingEnabled:NO];
    
    [self.pageSlider setEnabled:NO];
    [self.pageSlider setTintColor:[UIColor lightGrayColor]];
    
    NSArray *tabBarItems = self.tabBarController.tabBar.items;
    for (UITabBarItem *item in tabBarItems) {
        item.enabled = NO;
    }

    self.isRefreshing = YES;
    self.barButtonItemRefresh.enabled = NO;
    self.barButtonItemDone.enabled = NO;
    self.barButtonItemPrint.enabled = NO;
    self.barButtonItemSendToPdf.enabled = NO;
    self.barButtonItemActivity.enabled = NO;
    [self setUpdatingOfTimerIsPaused:YES];
    NSString *refreshing = NSLocalizedString(@"Refreshing data.", @"Refreshing data.");
    self.labelDateLastRefreshed.text = refreshing;
    [self.labelDateLastRefreshed setNeedsDisplay];
    self.barButtonItemDone.enabled = NO;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = NO;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self.navigationItem setRightBarButtonItem: barButtonItem
                                      animated: YES];
    
}

- (IBAction)refresh:(id)sender {

    self.didRefreshBeforeReaload = YES;
    self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    
    self.barButtonItemDone.enabled = NO;

    if (self.isRefreshing == NO) {
        self.startedRefresh = YES;
        self.isRefreshing = YES;
        [self setDisplayInactive];
        
        MTDatabase *database = [MTApplicationInstance mainInstance].openDocument.mainDatabase;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver: self
                               selector: @selector(reportDocumentDidReadRows:)
                                   name: MTNotificationDidReadRowsName
                                 object: database];
        

        __weak __block MADViewerController *weakself = self;
        [[MTApplicationInstance mainInstance].openDocument refresh:^(BOOL success, NSError *error) {
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
                               [[MTKeyChain sharedObject] deleteKey: [MTApplicationInstance mainInstance].openDocument.mainDatabase.databaseConnection.connectionString
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
    activityItemProviderPdf.document = [MTApplicationInstance mainInstance].openDocument;
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
                            [[MTApplicationInstance mainInstance].openDocument setActivityDelegate:weakself];
                            UIPrintPageRenderer *printPageRender = [[MTApplicationInstance mainInstance].openDocument printerPrintPageRender];
                            sharedController.printPageRenderer = printPageRender;
                            sharedController.delegate = [MTApplicationInstance mainInstance].openDocument;
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
    self.activityExporting = YES;
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
            weakself.activityExporting = NO;
            [weakself enableTabBarItems];
        } else {
            if (activityType.length > 0) {  // Long running activity
                if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
                    if (sharedController) {
                        sharedController.delegate = weakself;
                        UIPrintPageRenderer *printPageRender = [[MTApplicationInstance mainInstance].openDocument printerPrintPageRender];
                        sharedController.printPageRenderer = printPageRender;
                        sharedController.delegate = [MTApplicationInstance mainInstance].openDocument;
                        __weak MADViewerController *weakself = self;
                        if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
                            [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = [UIColor tintColorAnalogous4];
                            [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [UIColor tintColorRed];
                            [sharedController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                                [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].barTintColor           = nil;
                                [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor              = [UIColor tintColorWhite];
                                weakself.pageSlider.enabled = YES;
                                weakself.activityExporting = NO;
                                [weakself enableTabBarItems];
                            }];
                        }
                    }
                }
                weakself.pageSlider.enabled = YES;
                weakself.activityExporting = NO;
            } else {    // Cancel button
                weakself.pageSlider.enabled = YES;
                weakself.activityExporting = NO;
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

- (void)doneButton {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
    [[MTApplicationInstance mainInstance].openDocument prepareForQuery];
    
    __weak MADocument *weakdoc = [MTApplicationInstance mainInstance].openDocument;

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        
        [blockViewer watchFormatter: weakdoc.reportFormatter];
        BOOL startedRefresh = blockViewer.startedRefresh;
        
        weakdoc.reportFormatter.didRefresh = startedRefresh;
        [weakdoc.reportFormatter formatForSize:viewBounds contentChanged:startedRefresh];
        
        MTReportViewerPrintPageRenderer *printPageRender =  [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: weakdoc.reportFormatter
                                                                                                                   dataTable: weakdoc.mainDataTable];
        blockViewer.printPageRendererReport = printPageRender;
        [blockViewer ignoreFormatter: weakdoc.reportFormatter];

        __weak MADocument *doc2 = weakdoc;
        __weak MADViewerController *blockViewer2 = blockViewer;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            NSUInteger numberOfPages = [[MTApplicationInstance mainInstance].openDocument.reportFormatter numberOfPages];
            blockViewer2.numberOfPages = numberOfPages;
            blockViewer2.maxNumberOfPages = numberOfPages > 0 ? (numberOfPages - 1) : 0;
            [blockViewer2 setDisplayActive];
            
            MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithDocument: [MTApplicationInstance mainInstance].openDocument
                                                                                                                    pageNumber: (blockViewer2.currentPageIndex + 1)
                                                                                                                       ofPages: numberOfPages];
            pageOne.view.frame = blockViewer2.view.bounds;
            pageOne.delegate = blockViewer2;
            NSArray *viewControllers = @[pageOne];
            
            [blockViewer2 setViewControllers: viewControllers
                                   direction: UIPageViewControllerNavigationDirectionForward
                                    animated: NO
                                  completion: nil];

            blockViewer2.isRefreshing = NO;
            blockViewer2.startedRefresh = NO;
            blockViewer2.barButtonItemDone.enabled = YES;
            [blockViewer2 updateRecordsReadStatus];
            
            doc2.reportFormatter.didRefresh = NO;
            
            if (blockViewer2.backgroundTaskIdRefresh != UIBackgroundTaskInvalid) {
                
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                if (blockViewer2.didRefreshBeforeReaload) {
                    notification.alertBody = NSLocalizedString(@"Refresh completed.", @"Refresh completed.");
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                    blockViewer2.didRefreshBeforeReaload = NO;
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
    if (viewerViewController.pageIsAnimating == NO) {
        NSUInteger visiblePageNumber = 0;
        pageViewControllerLast.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        pageViewControllerLast.view.translatesAutoresizingMaskIntoConstraints = YES;
        if (pageViewControllerLast != nil && [pageViewControllerLast respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerLast.pageNumber;
        }
        if (visiblePageNumber + 1 <= self.numberOfPages) {
            result = [[MTReportViewerReportPageViewController alloc] initWithDocument: [MTApplicationInstance mainInstance].openDocument
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
    if (viewerViewController.pageIsAnimating == NO) {
        NSUInteger visiblePageNumber = 0;
        if (pageViewControllerPrevious != nil && [pageViewControllerPrevious respondsToSelector:@selector(pageNumber)]) {
            visiblePageNumber = pageViewControllerPrevious.pageNumber;
        }
        if (visiblePageNumber - 1 > 0) {
            result = [[MTReportViewerReportPageViewController alloc] initWithDocument: [MTApplicationInstance mainInstance].openDocument
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

- (void)pageViewController:(MADViewerController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    
    if (completed || finished) {
        [pageViewController setPageIsAnimating:NO];
        if (pageViewController.viewControllers.count > 0) {
            MTReportViewerReportPageViewController *viewController = pageViewController.viewControllers[0];
            [pageViewController setCurrentPageIndex: viewController.pageNumber - 1];
            [pageViewController updatePageStatus];
            [pageViewController.pageSlider setValue: pageViewController.currentPageIndex
                                           animated: YES];
        }
    }
    
}

- (UIPageViewControllerSpineLocation)pageViewController:(MADViewerController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    pageViewController.pageIsAnimating = NO;
    return UIPageViewControllerSpineLocationMin;
}

- (void)pageViewController:(MADViewerController *)pageViewController
    willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    pageViewController.pageIsAnimating = YES;
    
}

#pragma mark - Status Label

- (void)updateStatusWithTime:(NSString *)timeMessage {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateStatusWithTime:timeMessage];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:timeMessage attributes:self.attributesStatusLabelBold];
        self.statusMessage1 = attributedString;
        [self updateStatusLabel: self.statusMessage1
             recordsReadMessage: self.statusMessage2
        andNumberOfPagesMessage: self.statusMessage3];
    }
}


- (void)updateStatusWithRecordsRead:(NSString *)message {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateStatusWithRecordsRead:message];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message
                                                                               attributes:self.attributesStatusLabelLight];
        self.statusMessage2 = attributedString;
        [self updateStatusLabel: self.statusMessage1
             recordsReadMessage: self.statusMessage2
        andNumberOfPagesMessage: self.statusMessage3];
    }
}

- (void)updateStatusWithPageNumber:(NSString *)message {
    if ([NSThread isMainThread] == NO) {
        __weak MADViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateStatusWithPageNumber:message];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:[self attributesStatusLabelLight]];
        self.statusMessage3 = attributedString;
        [self updateStatusLabel: self.statusMessage1
             recordsReadMessage: self.statusMessage2
        andNumberOfPagesMessage: self.statusMessage3];
    }
}

- (void)updateStatusLabel:(NSAttributedString *)timeMessage
       recordsReadMessage:(NSAttributedString *)recordsReadMessage
  andNumberOfPagesMessage:(NSAttributedString *)numberOfPagesMessage {
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithAttributedString:timeMessage];

    if ([[recordsReadMessage string] length] > 0) {
        [status appendAttributedString:self.lineReturnString];
        [status appendAttributedString:recordsReadMessage];
    }

    if ([[numberOfPagesMessage string] length] > 0) {
        [status appendAttributedString:self.lineReturnString];
        [status appendAttributedString:numberOfPagesMessage];
    }
    
    NSRange range = NSMakeRange(0, [status length]);
    NSDictionary *attributes = [NSDictionary dictionaryWithDictionary:[self attributesStatusLabelCentered]];
    [status addAttributes:attributes range:range];
    
    [self.labelStatus setAttributedText:status];
}

- (void)updateLateRefreshedLabel:(id)sender {
    if (self.lastCacheDate == nil) {
        
        NSURL *cachedDataUrl = [[MTApplicationInstance mainInstance].openDocument cachedDataUrl];
        NSString *cachedDataPath = [cachedDataUrl path];
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedDataPath error:&error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            [self setLastCacheDate: lastD];
        }
    }
    
    if (self.lastCacheDate == nil) {
        [self updateStatusWithTime:@"No Cache"];
    } else {
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:self.lastCacheDate];
        NSString *display = [dateStringAndInterval former];
        [self updateStatusWithTime:display];
        
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
        
        if ([self timerLabelTimeSinceRefreh] != nil) {
            if ([[self timerLabelTimeSinceRefreh] respondsToSelector:@selector(isValid)]) {
                if ([[self timerLabelTimeSinceRefreh] isValid]) {
                    [[self timerLabelTimeSinceRefreh] invalidate];
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
        NSNumber *numberOfResults = @([[MTApplicationInstance mainInstance].openDocument.mainDataTable numberOfRows]);
        [self updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];
    }
}

- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs {
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Read %@ records.", @"Read %@ records.");
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [self updateStatusWithRecordsRead:readRecords];
}

- (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs {
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatting page %@.", @"Formatting page %@.");
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [self updateStatusWithRecordsRead:readRecords];
}

- (void)updatePageStatus {
    NSString *localizedPageOfPagesFormat = NSLocalizedString(@"Page %1@ of %2@ pages.", @"Page %1@ of %2@ pages.");
    NSNumber *startPageN = @([self currentPageIndex] + 1);
    NSNumber *endPageN = @([self numberOfPages]);
    NSString *startPage = [NSNumberFormatter localizedStringFromNumber:startPageN numberStyle:NSNumberFormatterDecimalStyle];
    NSString *endPage = [NSNumberFormatter localizedStringFromNumber:endPageN numberStyle:NSNumberFormatterDecimalStyle];

    NSString *localizedPageOfPages = [NSString stringWithFormat:localizedPageOfPagesFormat, startPage, endPage];
    [self updateStatusWithPageNumber:localizedPageOfPages];
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

@end
