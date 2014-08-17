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

#import "MTReportViewerController.h"
#import "UIDevice+Hack.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "UIApplication+Extras.h"
#import "MAReportDocument.h"
#import "MTActivityItemProviderPdf.h"
#import "UAAppReviewManager.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryCache.h"
#import "NSError+UserInterface.h"
#import "MTReportFormatter.h"
#import "MTQuery.h"
#import "MTPaper.h"
#import "MTPair.h"
#import "MTActivityReportPrintPreview.h"
#import "MTReportViewerReportPageViewController.h"

#import "MTSliderPageVertical.h"

#import "UIPageViewController+Extras.h"
#import "UIViewController+ui.h"
#import "UIViewController+tabBarItem.h"
#import "MTDataTable.h"

#import "MTNotificationDidFormatPage.h"
#import "MTNotificationDidReadRows.h"

@interface MTReportViewerController ()
    <UIPopoverControllerDelegate,
        MTPrintingProtocol,
        MTActivityReportPrintPreviewDelegate,
        MTTabBarImageProtocol,
        UIPrintInteractionControllerDelegate,
        MTActivityItemProviderDelegate>

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
@property (nonatomic, strong) IBOutlet UISlider *sliderPagination; // FIXME: Remvoe this slider, sometime EVER!!!WTFFF

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

@implementation MTReportViewerController

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
    
    self.activityExporting = NO;
    self.didRefreshBeforeReaload = NO;
    NSAttributedString *lineReturnString = [[NSAttributedString alloc] initWithString:@"\n"];
    self.lineReturnString = lineReturnString;
    [self initializeVerticalSlider];
    [self initalizeLabelStatus];
    [self initalizeStatusMessages];
    [self initalizeProgressBars];
}

- (void)initalizeProgressBars {
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [progressView setTrackTintColor:[UIColor tintColorRed]];
    [progressView setTintColor:[UIColor tintColorBlue]];
    [progressView setProgress:0.0000f animated:NO];
    [self setProgressView:progressView];
    [[self toolbarSideRight] addSubview:[self pageSlider]];
}

- (void)initializeVerticalSlider {
    MTSliderPageVertical *vertSlider = [[MTSliderPageVertical alloc] init];
    [vertSlider setMaximumValue:0.0000f];
    [vertSlider setMinimumValue:0.0000f];
    [vertSlider setContinuous:YES];
    [vertSlider setTintColor:[UIColor tintColorRed]];
    [vertSlider setValue:0.0000f];
    [vertSlider addTarget:self action:@selector(sliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [vertSlider addTarget:self action:@selector(sliderPageDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *sliderTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [vertSlider addGestureRecognizer:sliderTapped];
    
    vertSlider.transform = CGAffineTransformRotate(vertSlider.transform, 1.0000f / 2.0000f * M_PI);
    [self setPageSlider:vertSlider];
    
    UIToolbar *vertToolbar = [[UIToolbar alloc] init];
    vertToolbar.transform = CGAffineTransformRotate(vertSlider.transform, 3.0000f / 2.0000f * M_PI);
    [self setToolbarSideRight:vertToolbar];

}

- (void)initalizeLabelStatus {
    UILabel *labelStatus = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 30.0000f, 44.0000f)];
    [labelStatus setNumberOfLines:3];
    [labelStatus setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    UIBarButtonItem *barButtonLabelStatus = [[UIBarButtonItem alloc] initWithCustomView:labelStatus];
    [self setBarButtonLabelStatus:barButtonLabelStatus];
    [self setLabelStatus:labelStatus];
}

- (void)initalizeStatusMessages {
    NSAttributedString *statusMessage1 = [NSAttributedString new];
    NSAttributedString *statusMessage2 = [NSAttributedString new];
    NSAttributedString *statusMessage3 = [NSAttributedString new];
    [self setStatusMessage1:statusMessage1];
    [self setStatusMessage2:statusMessage2];
    [self setStatusMessage3:statusMessage3];
}

#pragma mark - UIViewController Standard Callbacks

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backgroundTaskIdRefresh = UIBackgroundTaskInvalid;
    
    [self setEdgesForExtendedLayout: UIRectEdgeNone];
    [self setTitle:@"MAD Viewer"];
    
    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    NSAttributedString *attributedString = [MTApplicationInstance localizedAttributedApplicationNameMadViewer];
    [labelMadDesigner setAttributedText:attributedString];
    [[self navigationItem] setTitleView:labelMadDesigner];
    [[[self navigationItem] titleView] sizeToFit];
    
    _timerLabelTimeSinceRefreh = nil;
    
    [self setIsRefreshing:NO];
    [self setUpdatingOfTimerIsPaused:NO];
    
    _lastCacheDate = nil;
    
    [[self labelDateLastRefreshed] setText:@""];

    [self setPageIsAnimating:NO];
    [self setStartedRefresh:NO];
    
    [[self view] setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    
    [self setDataSource:self];
    [self setDelegate:self];
    
    [self setCurrentPageIndex:0];
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
    
    [self setTintColorForToolbar:[[self navigationController] toolbar]];
    [self setTintColorForSidebar:[self toolbarSideRight]];
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[[self navigationController] toolbar] setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.document initalizeMainQuery];
    [self reload];
    [self addSliderPagination];
    [self updateLateRefreshedLabel:self];
    
    if ([self printPageRendererReport] == nil) {
        [self.document activeDocumentModel];    // Initalizes the report formatter, if not already done... Important!
        MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: [self.document reportFormatter]
                                                                                                                           dataTable: [self.document mainDataTable]];
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

#pragma mark - add controls

- (void)addProgressViewToView {
    [[self view] addSubview:[self progressView]];
    [[self view] bringSubviewToFront:[self progressView]];
}

- (void)removeProgressViewFromView {
    [[self progressView] removeFromSuperview];
}

- (void)addPageSliderToView {
    [[self view] addSubview:[self toolbarSideRight]];
    [[self view] bringSubviewToFront:[self toolbarSideRight]];
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
    [shadow setShadowColor:[UIColor colorWithRed:0.0000f green:0.00000f blue:0.0000f alpha:0.8000f]];
    [shadow setShadowOffset:CGSizeMake(0.0000f, 1.0000f)];
    [shadow setShadowBlurRadius:5.0000f];
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
    return [UIImage imageNamed:@"UIBarButtonItemMadViewer"];
}

- (NSString *)title {
    return NSLocalizedString(@"MAD Viewer", "MAD Viewer");
}

- (void)setTintColorForToolbar:(UIToolbar *)toolbar {
    UIColor *barTintColor = [UIColor tintColorBlue];
    UIColor *tintColor = [UIColor tintColorWhite];
    [toolbar setBarTintColor:barTintColor];
    [toolbar setTintColor:tintColor];
}

- (void)setTintColorForSidebar:(UIToolbar *)toolbar {
    UIImage *blank = [UIImage new];
    [toolbar setBackgroundImage:blank forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [toolbar setShadowImage:blank forToolbarPosition:UIToolbarPositionAny];
    [toolbar setBackgroundColor:[UIColor tintColorWhiteAlpha]];
}

- (void)addSliderPagination {
    CGFloat w = 40.0000f;
    CGFloat x = self.view.frame.size.width - w;
    CGFloat y = 0.0000f;
    CGFloat h = self.view.frame.size.height;
    CGRect frame = CGRectMake(x, y, w, h);
    CGRect framePageSlider = CGRectMake(CGPointZero.x, CGPointZero.y, w, h);
    [[self toolbarSideRight] setFrame:frame];
    [[self pageSlider] setFrame:framePageSlider];
}

- (void)sliderChangedPage:(id)sender {

    UISlider *slider = (UISlider *)sender;
    float sliderIndex = lroundf([slider value]);
    if ((int)sliderIndex != [self currentPageIndex]) {
        [self setCurrentPageIndex:sliderIndex];
        [self updatePageStatus];
        MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                                                                PageNumber: self.currentPageIndex + 1
                                                                                                                   ofPages: self.numberOfPages];
        [[pageOne view] setFrame:[[self view] bounds]];
        [pageOne setDelegate:self];
        
        __block MTReportViewerController *reportViewer = self;
        [[self view] bringSubviewToFront:[self toolbarSideRight]];
        [self setViewControllers:@[pageOne] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
            if (finished) {
                [[reportViewer view] bringSubviewToFront:[reportViewer toolbarSideRight]];
                [[pageOne view] setNeedsDisplay];
                [[reportViewer labelDateLastRefreshed] setHidden:NO];
                [reportViewer setUpdatingOfTimerIsPaused:NO];
                [reportViewer setIsRefreshing:NO];
                reportViewer = nil;
            }
        }];
    }
}


- (IBAction)sliderPageDidFinishDrag:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float sliderIndex = lroundf([slider value]); // Rounds float to an integer
    [slider setValue:sliderIndex];               // Sets your slider to this value
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat nonSliderButtonsWidth = CGSizeZero.width;
    CGFloat itemsMargin = 8.0000f;
    NSUInteger counter = 0;
    for (UIBarButtonItem *barButtonItem in [[[self navigationController] toolbar] items]) {
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
    CGFloat width = [[[self navigationController] toolbar] frame].size.width - nonSliderButtonsWidth - (itemsMargin * counter + 1);
    [[self barButtonItemSliderView] setWidth:width];
    [[self sliderView] setFrame:CGRectMake(self.sliderView.frame.origin.x, self.sliderView.frame.origin.y, width, self.sliderView.frame.size.height)];
    [[[self navigationController] toolbar] setNeedsLayout];
    [[self view] bringSubviewToFront:[self toolbarSideRight]];
    [self addSliderPagination];
    
    CGRect bounds = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 44.0000f);
    [[self labelStatus] setBounds:bounds];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[[self navigationItem] titleView] sizeToFit];
}

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    [[self.document managedObjectContext] save:&error];
    if (error != nil) {
        [[self.document managedObjectContext] save:&error];
    }
    [[self viewControllerDelegate] viewControllerDidFinish: self];
}

static UIImageView *captureSnapshotOfView (UIView *targetView) {
    UIGraphicsBeginImageContextWithOptions([targetView bounds].size, YES, 0);
    [[targetView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *snapshotView = [[UIImageView alloc] initWithImage:image];
    [snapshotView setFrame:[targetView frame]];
    return snapshotView;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (self.activityExporting == NO) {
        MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
        UIView *displayView = [pageViewController view];
        
        [self setFrameBeforeRotation: [displayView frame]];
        
        [self setSnapshotBeforeRotation: captureSnapshotOfView(displayView)];
        [displayView insertSubview:[self snapshotBeforeRotation] aboveSubview:displayView];
    }
}

- (MTReportViewerReportPageViewController *)currentPageviewController {
    return [self pageViewControllerAtIndex:[self currentPageIndex]];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (self.activityExporting == NO) {
        
        MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
        UIView *displayView = [pageViewController view];
        [displayView setNeedsDisplay];
        
        CGRect oldBounds = displayView.bounds;
        [self redrawWithFrame:oldBounds];
        
        pageViewController = [self currentPageviewController];
        displayView = [pageViewController view];
        
        [self setFrameAfterRotation: oldBounds];
        [UIView setAnimationsEnabled:NO];
        [self setSnapshotAfterRotation: captureSnapshotOfView(displayView)];
        
        
        CGRect framePreservingHeight = CGRectMake(self.frameBeforeRotation.origin.x, self.frameBeforeRotation.origin.y, self.frameBeforeRotation.size.width, self.snapshotAfterRotation.frame.size.height);
        [self.snapshotAfterRotation setFrame:framePreservingHeight];
        
        UIImage *imageBeforeRotation = [[self snapshotBeforeRotation] image];
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
        
        [(MTReportViewerReportPageView *)displayView setDrawBlankPage:YES];
        [displayView setNeedsDisplay];
    }
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [[[self navigationItem] titleView] sizeToFit];
    if (self.activityExporting == NO) {
        
        MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
        UIView *displayView = [pageViewController view];
        
        [(MTReportViewerReportPageView *)displayView setDrawBlankPage:NO];
        [displayView setNeedsDisplay];
        
        [[self snapshotBeforeRotation] removeFromSuperview];
        [[self snapshotAfterRotation] removeFromSuperview];
    }
}

- (MTReportViewerReportPageViewController *)pageViewControllerAtIndex:(NSUInteger)index {
    NSArray *viewControllers = [self viewControllers];
    NSInteger numberOfViewControllers = [viewControllers count];
    MTReportViewerReportPageViewController *result = nil;
    if (index < numberOfViewControllers) {
        result = [viewControllers objectAtIndex:index];
    } else {
        result = [viewControllers lastObject];
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
    [[self printPageRendererReport] drawPageAtIndex:pageIndex inRect:printableRect];
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return [UIDevice isPad] ? [self navigationController] : self;
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
    
    [[self pageSlider] setEnabled:YES];
    [[self pageSlider] setTintColor:[UIColor tintColorRed]];

    NSArray *tabBarItems = [[[self tabBarController] tabBar] items];
    for (UITabBarItem *item in tabBarItems) {
        [item setEnabled:YES];
    }
    
    [[self barButtonItemRefresh] setEnabled:YES];
    [[self barButtonItemDone] setEnabled:YES];
    [[self barButtonItemPrint] setEnabled:YES];
    [[self barButtonItemSendToPdf] setEnabled:YES];
    [[self barButtonItemActivity] setEnabled:YES];
    
    [self setIsRefreshing:NO];
    [self setUpdatingOfTimerIsPaused:NO];
    [[self barButtonItemRefresh] setEnabled:YES];
    [[self labelDateLastRefreshed] setHidden:NO];
    [[self labelDateLastRefreshed] setText:@""];
    [[self labelDateLastRefreshed] setNeedsDisplay];

    [[self navigationItem] setRightBarButtonItem:[self barButtonItemRefresh] animated:YES];

}

- (void)setDisplayInactive {
    
    [self setPageingEnabled:NO];
    
    [[self pageSlider] setEnabled:NO];
    [[self pageSlider] setTintColor:[UIColor lightGrayColor]];
    
    NSArray *tabBarItems = [[[self tabBarController] tabBar] items];
    for (UITabBarItem *item in tabBarItems) {
        [item setEnabled:NO];
    }

    [self setIsRefreshing:YES];
    [[self barButtonItemRefresh] setEnabled:NO];
    [[self barButtonItemDone] setEnabled:NO];
    [[self barButtonItemPrint] setEnabled:NO];
    [[self barButtonItemSendToPdf] setEnabled:NO];
    [[self barButtonItemActivity] setEnabled:NO];
    [self setUpdatingOfTimerIsPaused:YES];
    NSString *refreshing = NSLocalizedString(@"Refreshing data.", @"Refreshing data.");
    [[self labelDateLastRefreshed] setText:refreshing];
    [[self labelDateLastRefreshed] setNeedsDisplay];
    [[self barButtonItemDone] setEnabled:NO];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];
    [activityIndicator setHidesWhenStopped:NO];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [[self navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
    
}

- (IBAction)refresh:(id)sender {
    self.didRefreshBeforeReaload = YES;
    self.backgroundTaskIdRefresh = [[UIApplication sharedApplication] requestBackgroundTask];
    __weak __block MTReportViewerController *weakself = self;
    
    [[weakself barButtonItemDone] setEnabled:NO];

    if ([weakself isRefreshing] == NO) {
        [weakself setStartedRefresh:YES];
        [weakself setIsRefreshing:YES];
        [weakself setDisplayInactive];
        
        MTDatabase *database = [[self.document defaultQuery] database];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: weakself
                               selector: @selector(reportDocumentDidReadRows:)
                                   name: MTNotificationDidReadRowsName
                                 object: database];
        
        
        [weakself.document refresh:^(BOOL success, NSError *error) {

            if (!success) {
                [error performSelectorOnMainThread:@selector(presentErrorToUser) withObject:nil waitUntilDone:NO];
            } else {
                NSDate *lastD = [NSDate date];
                [weakself setLastCacheDate:lastD];
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
    NSDictionary *parameters = [sender userInfo];
    NSNumber *pageNumber = [parameters objectForKey:MTDatabaseNumberOfPagesFormattedKey];
    [self updateRecordsReadStatusWithNumberOfPagesFormatted:pageNumber];
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    NSDictionary *parameters = [sender userInfo];
    NSNumber *rowNumber = [parameters objectForKey:MTDatabaseNumberOfRowsReadKey];
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
        __weak MTReportViewerController *weakself = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[weakself popoverControllerActivity] dismissPopoverAnimated:YES];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
                        if (sharedController) {
                            [self.document setActivityDelegate:weakself];
                            UIPrintPageRenderer *printPageRender = [self.document printerPrintPageRender];
                            [sharedController setPrintPageRenderer:printPageRender];
                            [sharedController setDelegate:self.document] ;
                            __weak MTReportViewerController *weakself2 = weakself;
                            void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
                            ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
                                [weakself2.pageSlider setEnabled:YES];
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
    [activityItemProviderPdf setDelegate:self];
    NSArray *activityItems = @[activityItemProviderPdf];
    [self setActivityItemProviderPdf:activityItemProviderPdf];
    
    MTActivityReportPrintPreview *printPreview = [[MTActivityReportPrintPreview alloc] init];
    printPreview.delegate = self;

    NSArray *applicationActivities = @[printPreview];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:applicationActivities];
    
    __weak __block MTReportViewerController *weakself = self;
    
    UIActivityViewControllerCompletionHandler activityViewControllerCompletionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed) {
            [weakself.pageSlider setEnabled:YES];
            weakself.activityExporting = NO;
            [UAAppReviewManager userDidSignificantEvent:YES];
        } else {
            if ([activityType length] > 0) {
                if ([activityType caseInsensitiveCompare:UIActivityTypePrint] == NSOrderedSame) {
                    UIPrintInteractionController *sharedController = [UIPrintInteractionController sharedPrintController];
                    if (sharedController) {
                        [sharedController setDelegate:self];
                        UIPrintPageRenderer *printPageRender = [self.document printerPrintPageRender];
                        [sharedController setPrintPageRenderer:printPageRender];
                        [sharedController setDelegate:self.document];
                        __weak MTReportViewerController *weakself = self;
                        if ([UIDevice isPad] == NO) {
                            [sharedController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                                weakself.pageSlider.enabled = YES;
                                weakself.activityExporting = NO;
                            }];
                        }
                    }
                }
                weakself.pageSlider.enabled = YES;
                weakself.activityExporting = NO;
            } else {
                weakself.pageSlider.enabled = YES;
                weakself.activityExporting = NO;
            }
        }
    };
    
    [activityViewController setCompletionHandler:activityViewControllerCompletionHandler];
    
    if ([UIDevice isPad]) {
        if ([self popoverControllerActivity] == nil || [[self popoverControllerActivity] isPopoverVisible] == NO) {
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            popoverController.delegate = self;
            [popoverController presentPopoverFromBarButtonItem: self.barButtonItemActivity
                                      permittedArrowDirections: UIPopoverArrowDirectionAny
                                                      animated: YES];
            [self setPopoverControllerActivity:popoverController];
            [self disableTabBarItems];
        }
    } else {

        __weak MTReportViewerController *weakSelf = self;
        [self presentViewController:activityViewController animated:YES completion:^{
            [[[[weakSelf presentedViewController] navigationController] navigationBar] setBarTintColor:[UIColor tintColorAnalogous4]];
        }];
    }
}

- (UIViewController *)previewViewControllerForInteractionController: (UIDocumentInteractionController *) controller {
    return [self navigationController];
}

- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller
                  withCompletionHandler:(void (^)(BOOL))completionHandler {
    
    if ([UIDevice isPad] == NO) {
        [self dismissViewControllerAnimated:YES completion:^{
            completionHandler(YES);
        }];
    } else {
        [[self popoverControllerActivity] dismissPopoverAnimated:YES];
        completionHandler(YES);
    }

}

- (void)reload {
    __weak MTReportViewerController *blockself = self;
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
    
    __weak MTReportViewerController *blockViewer = self;
    
    [self.document prepareForQuery];
    
    __weak MAReportDocument *weakdoc = self.document;

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        
        [blockViewer watchFormatter: weakdoc.reportFormatter];
        BOOL startedRefresh = blockViewer.startedRefresh;
        
        [[weakdoc reportFormatter] setDidRefresh:startedRefresh];
        [[weakdoc reportFormatter] formatForSize:viewBounds contentChanged:startedRefresh];
        
        MTReportViewerPrintPageRenderer *printPageRender =  [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter: [weakdoc reportFormatter]
                                                                                                                  dataTable: [weakdoc mainDataTable]];
        [blockViewer setPrintPageRendererReport:printPageRender];

        [self ignoreFormatter: weakdoc.reportFormatter];

        __weak MAReportDocument *doc2 = weakdoc;
        __weak MTReportViewerController *blockViewer2 = blockViewer;
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            NSUInteger numberOfPages = [[self.document reportFormatter] numberOfPages];
            [blockViewer2 setNumberOfPages:numberOfPages];
            [blockViewer2 setMaxNumberOfPages:numberOfPages > 0 ? (numberOfPages - 1) : 0];
            [blockViewer2 setDisplayActive];
            
            MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                                                                    PageNumber: ([blockViewer2 currentPageIndex] + 1)
                                                                                                                       ofPages: numberOfPages];
            [[pageOne view] setFrame:[[blockViewer2 view] bounds]];
            [pageOne setDelegate:blockViewer2];
            NSArray *viewControllers = @[pageOne];
            
            [blockViewer2 setViewControllers: viewControllers direction:UIPageViewControllerNavigationDirectionForward
                                    animated: NO completion: nil];
            [blockViewer2 setIsRefreshing:NO];
            [blockViewer2 setStartedRefresh:NO];
            [[blockViewer2 barButtonItemDone] setEnabled:YES];
            [blockViewer2 updateRecordsReadStatus];
            
            [[doc2 reportFormatter] setDidRefresh:NO];
            
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

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    MTReportViewerReportPageViewController *result = nil;
    if ([(MTReportViewerController *)pageViewController pageIsAnimating] == NO) {
        NSUInteger visablePageNumber = 0;
        MTReportViewerReportPageViewController *lastPage = (MTReportViewerReportPageViewController *)viewController;
        [[lastPage view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [[lastPage view] setTranslatesAutoresizingMaskIntoConstraints:YES];
        if (lastPage != nil && [lastPage respondsToSelector:@selector(pageNumber)]) {
            visablePageNumber = [lastPage pageNumber];
        }
        if (visablePageNumber + 1 <= [self numberOfPages]) {
            result = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                           PageNumber: visablePageNumber + 1
                                                                              ofPages: [self numberOfPages]];
            [result setDelegate: self];
            [[result view] setFrame:[[self view] bounds]];
            [[result view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
            [[result view] setTranslatesAutoresizingMaskIntoConstraints:YES];
        }
    }
    return result;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    MTReportViewerReportPageViewController *result = nil;
    if ([(MTReportViewerController *)pageViewController pageIsAnimating] == NO) {
        NSUInteger visablePageNumber = 0;
        MTReportViewerReportPageViewController *lastPage = (MTReportViewerReportPageViewController *)viewController;
        if (lastPage != nil && [lastPage respondsToSelector:@selector(pageNumber)]) {
            visablePageNumber = [lastPage pageNumber];
        }
        if (visablePageNumber - 1 > 0) {
            result = [[MTReportViewerReportPageViewController alloc] initWithDocument: self.document
                                                                           PageNumber: visablePageNumber - 1
                                                                              ofPages: [self numberOfPages]];
            [result setDelegate: self];
            [[result view] setFrame:[[self view] bounds]];
            [[result view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
            [[result view] setTranslatesAutoresizingMaskIntoConstraints:YES];
        }
    }
    return result;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [(MTReportViewerController *)pageViewController numberOfPages];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return [(MTReportViewerController *)pageViewController currentPageIndex];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    if (completed || finished) {
        [(MTReportViewerController *)pageViewController setPageIsAnimating:NO];
        if ([[(MTReportViewerController *)pageViewController viewControllers] count] > 0) {
            MTReportViewerReportPageViewController *viewController = [[pageViewController viewControllers] objectAtIndex:0];
            [(MTReportViewerController *)pageViewController setCurrentPageIndex:[viewController pageNumber] - 1];
            [(MTReportViewerController *)pageViewController updatePageStatus];
            [[(MTReportViewerController *)pageViewController sliderPagination] setValue:[(MTReportViewerController *)pageViewController currentPageIndex] animated:YES];
            [[(MTReportViewerController *)pageViewController pageSlider] setValue:[(MTReportViewerController *)pageViewController currentPageIndex] animated:YES];
        }
    }
    
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    [(MTReportViewerController *)pageViewController setPageIsAnimating:NO];
    return UIPageViewControllerSpineLocationMin;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    [(MTReportViewerController *)pageViewController setPageIsAnimating:YES];
    
}

#pragma mark - Status Label

- (void)updateStatusWithTime:(NSString *)timeMessage {
    if ([NSThread isMainThread] == NO) {
        __weak MTReportViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateStatusWithTime:timeMessage];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:timeMessage attributes:[self attributesStatusLabelBold]];
        [self setStatusMessage1:attributedString];
        [self updateStatusLabel:[self statusMessage1] recordsReadMessage:[self statusMessage2] andNumberOfPagesMessage:[self statusMessage3]];
    }
}


- (void)updateStatusWithRecordsRead:(NSString *)message {
    if ([NSThread isMainThread] == NO) {
        __weak MTReportViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateStatusWithRecordsRead:message];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:[self attributesStatusLabelLight]];
        [self setStatusMessage2:attributedString];
        [self updateStatusLabel:[self statusMessage1] recordsReadMessage:[self statusMessage2] andNumberOfPagesMessage:[self statusMessage3]];
    }
}

- (void)updateStatusWithPageNumber:(NSString *)message {
    if ([NSThread isMainThread] == NO) {
        __weak MTReportViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateStatusWithPageNumber:message];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:[self attributesStatusLabelLight]];
        [self setStatusMessage3:attributedString];
        [self updateStatusLabel:[self statusMessage1] recordsReadMessage:[self statusMessage2] andNumberOfPagesMessage:[self statusMessage3]];
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
    [status addAttributes:[self attributesStatusLabelCentered] range:range];
    
    [[self labelStatus] setAttributedText:status];
}

- (void)updateLateRefreshedLabel:(id)sender {
    if ([self lastCacheDate] == nil) {
        
        NSURL *cachedDataUrl = [self.document cachedDataUrl];
        NSString *cachedDataPath = [cachedDataUrl path];
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedDataPath error:&error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            [self setLastCacheDate: lastD];
        }
    }
    
    if ([self lastCacheDate] == nil) {
        [self updateStatusWithTime:@"No Cache"];
    } else {
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:[self lastCacheDate]];
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
        __weak MTReportViewerController *weakSelf = self;
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
        __weak MTReportViewerController *weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf setMaxNumberOfPages:numberOfPages];
        });
    } else {
        if (round([[self pageSlider] maximumValue]) != round(numberOfPages)) {
            [[self sliderPagination] setMaximumValue:numberOfPages];
            [[self pageSlider] setMaximumValue:numberOfPages];
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
