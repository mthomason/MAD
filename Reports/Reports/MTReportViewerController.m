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

@interface MTReportViewerController ()
    <UIPopoverControllerDelegate, MTPrintingProtocol, MTActivityReportPrintPreviewDelegate>

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

@property (nonatomic, strong) NSDictionary *attributesLabelDateUpdated;
@property (nonatomic, strong) NSDictionary *attributesLabelNumberOfPages;
@property (nonatomic, strong) NSDictionary *attributesRecordsRead;
@property (nonatomic, strong) NSDictionary *attributesStatusLabel;

@property (nonatomic, strong) NSAttributedString *statusMessage1;
@property (nonatomic, strong) NSAttributedString *statusMessage2;
@property (nonatomic, strong) NSAttributedString *statusMessage3;

@end

@implementation MTReportViewerController

- (void)dealloc {
    _asyncDelegate = nil;
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

- (id)init {
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options {
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    
    UIToolbar *vertToolbar = [[UIToolbar alloc] init];
    MTSliderPageVertical *vertSlider = [[MTSliderPageVertical alloc] init];
    [vertSlider setMaximumValue:0];
    [vertSlider setMinimumValue:0];
    [vertSlider setContinuous:YES];
    [vertSlider setTintColor:[UIColor tintColorRed]];

    UILabel *labelStatus = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 30.0000f, 44.0000f)];
    [labelStatus setNumberOfLines:3];
    [labelStatus setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    UIBarButtonItem *barButtonLabelStatus = [[UIBarButtonItem alloc] initWithCustomView:labelStatus];
    [self setBarButtonLabelStatus:barButtonLabelStatus];
    [self setLabelStatus:labelStatus];
    
    UITapGestureRecognizer *sliderTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [vertSlider addGestureRecognizer:sliderTapped];
    
    vertSlider.transform = CGAffineTransformRotate(vertSlider.transform, 1.0000f / 2.0000f * M_PI);
    vertToolbar.transform = CGAffineTransformRotate(vertSlider.transform, 3.0000f / 2.0000f * M_PI);
    
    [self setPageSlider:vertSlider];
    [self setToolbarSideRight:vertToolbar];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[UIColor colorWithRed:0.0000f green:0.00000f blue:0.0000f alpha:0.8000f]];
    [shadow setShadowOffset:CGSizeMake(0.0000f, 1.0000f)];
    [shadow setShadowBlurRadius:5.0000f];
    UIColor *textColor = [UIColor lightTextColor];
    UIFont *font = [UIFont systemFontOfSize:8.0000f];
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : textColor,
                                 NSFontAttributeName : font,
                                 NSShadowAttributeName : shadow,
                                 };
    
    NSAttributedString *statusMessage1 = [NSAttributedString new];
    NSAttributedString *statusMessage2 = [NSAttributedString new];
    NSAttributedString *statusMessage3 = [NSAttributedString new];
    [self setStatusMessage1:statusMessage1];
    [self setStatusMessage2:statusMessage2];
    [self setStatusMessage3:statusMessage3];
    
    [self setAttributesLabelDateUpdated:attributes];
    [self setAttributesLabelNumberOfPages:attributes];
    [self setAttributesRecordsRead:attributes];
    NSMutableParagraphStyle *paragraphStyleCentered = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyleCentered setAlignment:NSTextAlignmentCenter];
    NSDictionary *attributesCenter = @{
                                       NSParagraphStyleAttributeName : paragraphStyleCentered
                                       };
    [self setAttributesStatusLabel:attributesCenter];

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

static UIImageView *captureSnapshotOfView (UIView *targetView) {
    UIGraphicsBeginImageContextWithOptions([targetView bounds].size, YES, 0);
    [[targetView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *snapshotView = [[UIImageView alloc] initWithImage:image];
    [snapshotView setFrame:[targetView frame]];
    return snapshotView;
}

- (UIImage *)tabBarImage {
    return [UIImage imageNamed:@"UIBarButtonItemMadViewer"];
}

- (NSString *)title {
    return NSLocalizedString(@"MAD Viewer", "MAD Viewer");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    [self setViewControllers:blankPageArray direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) { }];

    [[self pageSlider] setValue:0.0000f];
    [[self pageSlider] addTarget:self action:@selector(sliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [[self pageSlider] addTarget:self action:@selector(sliderPageDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
    [[self pageSlider] setMinimumValue:0];

    [[self sliderPagination] setValue:0.0000f];
    [[self sliderPagination] addTarget:self action:@selector(sliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [[self sliderPagination] addTarget:self action:@selector(sliderPageDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
    [[self sliderPagination] setMinimumValue:0];

    [[self toolbarSideRight] addSubview:[self pageSlider]];
    [[self view] addSubview:[self toolbarSideRight]];
    [[self view] bringSubviewToFront:[self toolbarSideRight]];
    
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithArray:[self toolbarItems]];
    [toolbarItems insertObject:[self barButtonLabelStatus] atIndex:1];
    [self setToolbarItems:toolbarItems animated:NO];
    
    [self setTintColorForToolbar:[[self navigationController] toolbar]];
    [self setTintColorForSidebar:[self toolbarSideRight]];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[[self navigationController] toolbar] setNeedsLayout];
    
    if ([self asyncDelegate]) {
        __block __weak MTReportViewerController *viewController = self;
        [[self asyncDelegate] displayContentController:viewController];
    } else {
        if ([MTApplicationInstance isMadDesigner]) {
            [self reload:self];
        }
    }
    [self addSliderPagination];
    [self updateLateRefreshedLabel:self];
}

- (void)setTintColorForToolbar:(UIToolbar *)toolbar {
    UIColor *barTintColor = [UIColor tintColor];
    UIColor *tintColor = [UIColor tintColor2];
    [toolbar setBarTintColor:barTintColor];
    [toolbar setTintColor:tintColor];
}

- (void)setTintColorForSidebar:(UIToolbar *)toolbar {
    
    UIImage *blank = [UIImage new];
    [toolbar setBackgroundImage:blank forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [toolbar setShadowImage:blank forToolbarPosition:UIToolbarPositionAny];
    [toolbar setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self printPageRendererReport] == nil) {
        MTApplicationInstance *app = [AppDelegate app];
        __block MAReportDocument *doc = [app activeDocument];
        [doc activeDocument];    // Initalizes the report formatter, if not already done... Important!
        MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[doc reportFormatter]];
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
        MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber: [self currentPageIndex] + 1
                                                                                                                     ofPages: [self numberOfPages]];
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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[[self navigationItem] titleView] sizeToFit];
}

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    [[reportDocument managedObjectContext] save:&error];
    if (error != nil) {
        [[reportDocument managedObjectContext] save:&error];
    }
    [[self viewControllerDelegate] viewControllerDidFinish: self];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
    UIView *displayView = [pageViewController view];

    [self setFrameBeforeRotation: [displayView frame]];

    [self setSnapshotBeforeRotation: captureSnapshotOfView(displayView)];
    [displayView insertSubview:[self snapshotBeforeRotation] aboveSubview:displayView];
}

- (MTReportViewerReportPageViewController *)currentPageviewController {
    NSInteger pageIndex = [self currentPageIndex];
    return [self pageViewControllerAtIndex:pageIndex];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
    UIView *displayView = [pageViewController view];
    [displayView setNeedsDisplay];

    CGRect oldBounds = displayView.bounds;
    [self redrawReportViewer:self withFrame:oldBounds];

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


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [[[self navigationItem] titleView] sizeToFit];

    MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
    UIView *displayView = [pageViewController view];
    
    [(MTReportViewerReportPageView *)displayView setDrawBlankPage:NO];
    [displayView setNeedsDisplay];

    [[self snapshotBeforeRotation] removeFromSuperview];
    [[self snapshotAfterRotation] removeFromSuperview];

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

- (void)redrawReportViewer:(MTReportViewerController *)reportViewerController withFrame:(CGRect)frame {
    [reportViewerController setDisplayActive];
    MTApplicationInstance *app = [AppDelegate app];
    MAReportDocument *doc = [app activeDocument];
    [[doc reportFormatter] formatForSize:frame.size];
    
    NSUInteger numberOfPages = [[doc reportFormatter] numberOfPages];
    [reportViewerController setNumberOfPages:numberOfPages];
    [self setMaxNumberOfPages:numberOfPages > 0 ? (numberOfPages - 1) : 0];
    
    NSInteger pageNumber = [reportViewerController currentPageIndex] + 1;
    MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:pageNumber
                                                                                                                 ofPages:numberOfPages];
    [[pageOne view] setFrame:frame];
    
    [pageOne setDelegate:reportViewerController];
    
    NSArray *viewControllers = @[pageOne];
    [reportViewerController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        if (finished) {
            [[pageOne view] setNeedsDisplay];
        }
    }];
    
    [[reportViewerController barButtonItemDone] setEnabled:YES];
    
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
}

#pragma mark - Actions

- (void)setDisplayActive {

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
    
    __block MTReportViewerController *reportViewer;
    if ([sender isKindOfClass:[MTReportViewerController class]]) {
        reportViewer = sender;
    } else {
        reportViewer = self;
    }
    
    [[reportViewer barButtonItemDone] setEnabled:NO];

    if ([reportViewer isRefreshing] == NO) {
        [self setStartedRefresh:YES];
        [self setIsRefreshing:YES];
        [reportViewer setDisplayInactive];
        
        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queuePriorityBackground, ^{
            
            __block MTReportViewerController *reportViewer2 = reportViewer;
            
            MTApplicationInstance *applicationInstance = [AppDelegate app];
            MAReportDocument *reportDocument = [applicationInstance activeDocument];
            
            NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
            [defaultCenter addObserver: self
                              selector: @selector(reportDocumentDidReadRows:)
                                  name: @"MTNotificationDidReadRows"
                                object: [[reportDocument defaultQuery] database]];
            

            [reportDocument refresh:^(BOOL success, NSError *error) {
            
                dispatch_queue_t highpriorityqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
                if (success) {
                    
                    __block MTReportViewerController *reportViewer3 = reportViewer2;
                    dispatch_async(highpriorityqueue, ^{
                        __block MTReportViewerController *reportViewer4 = reportViewer3;
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [reportViewer4 setDisplayActive];
                            NSDate *lastD = [NSDate date];
                            [reportViewer4 setLastCacheDate: lastD];
                            [reportViewer4 reload:reportViewer4];
                            [reportViewer4 timerDealloc];
                            [reportViewer4 updateLateRefreshedLabel:reportViewer4];
                            
                            NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
                            [defaultCenter removeObserver:self name:@"MTNotificationDidReadRows" object:[[reportDocument defaultQuery] database]];
                            
                        });
                    });
                } else {
                    [error performSelectorOnMainThread:@selector(presentErrorToUser) withObject:nil waitUntilDone:NO];
                    __block MTReportViewerController *reportViewer3 = reportViewer2;
                    dispatch_async(highpriorityqueue, ^{
                        __block MTReportViewerController *reportViewer4 = reportViewer3;
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [reportViewer4 setDisplayActive];
                            [reportViewer4 reload:reportViewer4];
                            [reportViewer4 timerDealloc];
                            [reportViewer4 updateLateRefreshedLabel:reportViewer4];
                            
                            NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
                            [defaultCenter removeObserver:self name:@"MTNotificationDidReadRows" object:[[reportDocument defaultQuery] database]];
                            
                        });
                    });
                }
            }];
        });
    }
}

- (void)reportDocumentDidReadRows:(NSNotification *)sender {
    NSDictionary *parameters = [sender userInfo];
    NSNumber *rowNumber = [parameters objectForKey:@"MTDatabaseNumberOfRowsReadKey"];
    [self updateRecordsReadStatusWithNumberOfRecordsRead:rowNumber];
}

- (IBAction)activity:(id)sender {

    NSString *temporaryDirectoryPath = NSTemporaryDirectory();
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
    NSURL *urlEmpty = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    MTActivityItemProviderPdf *activityItemProviderPdf = [[MTActivityItemProviderPdf alloc] initWithPlaceholderItem:urlEmpty];
    NSArray *activityItems = @[activityItemProviderPdf];
    
    // FIXME: Delete preview
    UIActivityViewControllerCompletionHandler activityViewControllerCompletionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed) {
            [UAAppReviewManager userDidSignificantEvent:YES];
        }
    };
    
    MTActivityReportPrintPreview *printPreview = [[MTActivityReportPrintPreview alloc] init];
    [printPreview setDelegate:self];
    NSArray *applicationActivities = @[printPreview];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
    [activityViewController setCompletionHandler:activityViewControllerCompletionHandler];

    if ([UIDevice isPad]) {
        if ([self popoverControllerActivity] == nil || [[self popoverControllerActivity] isPopoverVisible] == NO) {
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            [popoverController setDelegate:self];
            [popoverController presentPopoverFromBarButtonItem:[self barButtonItemActivity] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            [self setPopoverControllerActivity:popoverController];
        }
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{ }];
    }
}

- (UIViewController *)previewViewControllerForInteractionController: (UIDocumentInteractionController *) controller {
    return self;
}

- (void)prepareForInteractionController:(UIDocumentInteractionController *)controller withCompletionHandler:(void (^)(BOOL))completionHandler {

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
    __block __weak MTReportViewerController *blockself = self;
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queuePriorityBackground, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [blockself reload:blockself];
        });
    });
}

- (void)reload:(MTReportViewerController *)reportViewer {
    
    [reportViewer setDisplayInactive];
    
    __block __weak MTReportViewerController *blockViewer = reportViewer;
    CGSize viewBounds = [[reportViewer view] bounds].size;
    
    MTApplicationInstance *app = [AppDelegate app];
    __block __weak MAReportDocument *doc = [app activeDocument];
    [doc activeDocument];    // Initalizes the report formatter, if not already done... Important!
    if ([self printPageRendererReport] == nil) {
        MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[doc reportFormatter]];
        [self setPrintPageRendererReport: prtingPageRendererReport];
    }

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queuePriorityBackground, ^{
        [[doc reportFormatter] setDidRefresh:[self startedRefresh]];
        [[doc reportFormatter] formatForSize:viewBounds];
        
        __block __weak MAReportDocument *doc2 = doc;
        __block __weak MTReportViewerController *blockViewer2 = blockViewer;
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [blockViewer2 setDisplayActive];
            
            NSUInteger numberOfPages = [[doc reportFormatter] numberOfPages];
            [blockViewer2 setNumberOfPages:numberOfPages];
            NSInteger maxValue = numberOfPages > 0 ? (numberOfPages - 1) : 0;
            [blockViewer2 setMaxNumberOfPages:maxValue];

            NSInteger pageNumber = [blockViewer2 currentPageIndex] + 1;
            MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:pageNumber
                                                                                                                         ofPages:numberOfPages];
            [[pageOne view] setFrame:[[blockViewer2 view] bounds]];
            
            [pageOne setDelegate:reportViewer];
            
            NSArray *viewControllers = @[pageOne];
            [blockViewer2 setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {}];
            [blockViewer2 setIsRefreshing:NO];
            [blockViewer2 setStartedRefresh:NO];
            [[doc2 reportFormatter] setDidRefresh:NO];
            [[blockViewer2 barButtonItemDone] setEnabled:YES];
           
            [blockViewer2 updateRecordsReadStatus];
            
        });
    });
}

- (void)sendToPdfWithCompletionHandler:(void (^)(BOOL))completionHandler {

    [[self barButtonItemDone] setEnabled:NO];
    [[self barButtonItemSendToPdf] setEnabled:NO];
    [[self barButtonItemActivity] setEnabled:NO];
    [[self barButtonItemRefresh] setEnabled:NO];
    [[self barButtonItemPrint] setEnabled:NO];
    [self setUpdatingOfTimerIsPaused:YES];
    [[self labelDateLastRefreshed] setText:NSLocalizedString(@"Exporting data.", @"Exporting data.")];
    [[self labelDateLastRefreshed] setNeedsDisplay];
    
    for (UITabBarItem *i in [[[self tabBarController] tabBar] items]) {
        [i setEnabled:NO];
    }
    __block MTReportViewerController *blockself = self;
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queuePriorityBackground, ^{
        
        NSString *temporaryDirectoryPath = NSTemporaryDirectory();
        NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
        NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];

        MTApplicationInstance *app = [AppDelegate app];
        MAReportDocument *doc = [app activeDocument];
        MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery:[doc defaultQuery]
                                                                               andLayout:[doc activeDocument]];
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:reportFormatter];

        [printPageRender writeToPdf:temporaryFile];
        
        __block MTReportViewerController *blockself2 = blockself;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [blockself2 setUpdatingOfTimerIsPaused:NO];
            [blockself2 updateLateRefreshedLabel:blockself2];
            [[blockself2 barButtonItemRefresh] setEnabled:YES];
            [[blockself2 barButtonItemDone] setEnabled:YES];
            [[blockself2 barButtonItemPrint] setEnabled:YES];
            [[blockself2 barButtonItemSendToPdf] setEnabled:YES];
            [[blockself2 barButtonItemActivity] setEnabled:YES];
            
            for (UITabBarItem *i in [[[blockself2 tabBarController] tabBar] items]) {
                [i setEnabled:YES];
            }
            UIDocumentInteractionController *c = [UIDocumentInteractionController  interactionControllerWithURL:temporaryFile];
            [c setDelegate:blockself2];
            [c presentPreviewAnimated:YES];
        });
        
    });

}

- (IBAction)sendToPdf:(id)sender {
    [self sendToPdfWithCompletionHandler:^(BOOL success){ }];
}

- (IBAction)print:(id)sender {
    
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
    if (controller) {
        
        [[self barButtonItemPrint] setEnabled:NO];
        [[self barButtonItemRefresh] setEnabled:NO];
        [[self barButtonItemSendToPdf] setEnabled:NO];
        [[self barButtonItemActivity] setEnabled:NO];
        
        __block MTReportViewerController *reportViewer = self;
        UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            [[reportViewer barButtonItemPrint] setEnabled:YES];
            [[reportViewer barButtonItemRefresh] setEnabled:YES];
            [[reportViewer barButtonItemSendToPdf] setEnabled:YES];
            [[reportViewer barButtonItemActivity] setEnabled:YES];
            if(!completed && error){
                //MTLog(@"FAILED! due to error in domain %@ with error code %u", error.domain, error.code);
            }
        };
        
        // Obtain a printInfo so that we can set our printing defaults.
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        
        
        MTApplicationInstance *applicationInstance = [AppDelegate app];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        printInfo.jobName = [reportDocument name];
        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        controller.printInfo = printInfo;
        
        controller.showsPageRange = YES;
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] init];
        [controller setPrintPageRenderer:printPageRender];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [controller presentFromBarButtonItem:[self barButtonItemPrint]
                                        animated:YES
                               completionHandler:completionHandler];  // iPad
        } else {
            [controller presentAnimated:YES completionHandler:completionHandler];  // iPhone
        }
    }
    
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
            result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber + 1  ofPages:[self numberOfPages]];
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
            result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber - 1 ofPages:[self numberOfPages]];
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
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateStatusWithTime:timeMessage];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:timeMessage attributes:[self attributesLabelDateUpdated]];
        [self setStatusMessage1:attributedString];
        [self updateStatusLabel:[self statusMessage1] recordsReadMessage:[self statusMessage2] andNumberOfPagesMessage:[self statusMessage3]];
    }
}


- (void)updateStatusWithRecordsRead:(NSString *)message {
    if ([NSThread isMainThread] == NO) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateStatusWithRecordsRead:message];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:[self attributesLabelDateUpdated]];
        [self setStatusMessage2:attributedString];
        [self updateStatusLabel:[self statusMessage1] recordsReadMessage:[self statusMessage2] andNumberOfPagesMessage:[self statusMessage3]];
    }
}

- (void)updateStatusWithPageNumber:(NSString *)message {
    if ([NSThread isMainThread] == NO) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateStatusWithPageNumber:message];
        });
    } else {
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:[self attributesLabelDateUpdated]];
        [self setStatusMessage3:attributedString];
        [self updateStatusLabel:[self statusMessage1] recordsReadMessage:[self statusMessage2] andNumberOfPagesMessage:[self statusMessage3]];
    }
}

- (void)updateStatusLabel:(NSAttributedString *)timeMessage recordsReadMessage:(NSAttributedString *)recordsReadMessage andNumberOfPagesMessage:(NSAttributedString *)numberOfPagesMessage {
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithAttributedString:timeMessage];
    
    NSAttributedString *newlineString = [[NSAttributedString alloc] initWithString:@"\n"];

    
    if ([[recordsReadMessage string] length] > 0) {
        [status appendAttributedString:newlineString];
        [status appendAttributedString:recordsReadMessage];
    }

    if ([[numberOfPagesMessage string] length] > 0) {
        [status appendAttributedString:newlineString];
        [status appendAttributedString:numberOfPagesMessage];
    }
    
    NSRange range = NSMakeRange(0, [status length]);
    [status addAttributes:[self attributesStatusLabel] range:range];
                NSStringDrawingOptions drawingOptions = (NSStringDrawingUsesLineFragmentOrigin);

    CGSize labelSize = [status boundingRectWithSize:CGSizeMake(300.0000f, 88.0000f) options:drawingOptions context:nil].size;
    CGRect bounds = CGRectMake(CGPointZero.x, CGPointZero.y, labelSize.width, 44.0000f);
    [[self labelStatus] setBounds:bounds];
    [[self labelStatus] setAttributedText:status];
}

- (void)updateLateRefreshedLabel:(id)sender {
    if ([self lastCacheDate] == nil) {
        
        MTApplicationInstance *applicationInstance = [AppDelegate app];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSURL *cachedDataUrl = [reportDocument cachedDataUrl];
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
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateRecordsReadStatus];
        });
    } else {
        MTApplicationInstance *app = [AppDelegate app];
        MAReportDocument *doc = [app activeDocument];
        NSNumber *numberOfResults = @([[doc reportFormatter] numberOfResults]);
        [self updateRecordsReadStatusWithNumberOfRecordsRead:numberOfResults];
    }
}

- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs {
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Read %@ records.", @"Read %@ records.");
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
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setMaxNumberOfPages:numberOfPages];
        });
    } else {
        if (round([[self pageSlider] maximumValue]) != round(numberOfPages)) {
            [[self sliderPagination] setMaximumValue:numberOfPages];
            [[self pageSlider] setMaximumValue:numberOfPages];
        }
    }
    [self updatePageStatus];
}

@end
