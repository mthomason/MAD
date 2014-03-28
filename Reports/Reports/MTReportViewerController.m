//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

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
#import "MTCache.h"
#import "MTQuery.h"
#import "MTPaper.h"
#import "MTActivityReportPrintPreview.h"
#import "MTReportViewerReportPageViewController.h"

@interface MTReportViewerController ()
    <UIPopoverControllerDelegate, MTPrintingProtocol, MTActivityReportPrintPreviewDelegate>

@property (nonatomic, retain) MTReportViewerPrintPageRenderer *printPageRendererReport;

@property (nonatomic, retain) IBOutlet UIView *sliderView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSliderView;
@property (nonatomic, retain) IBOutlet UISlider *sliderPagination;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemPrint;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSendToPdf;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemDone;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemActivity;

@property (nonatomic, retain) IBOutlet UILabel *labelDateLastRefreshed;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *statusLabelWidthConstraint;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, assign) CGRect lastLayoutBounds;

@property (nonatomic, retain) NSDate *lastCacheDate;
@property (nonatomic, retain) NSTimer *timerLabelTimeSinceRefreh;

@property (nonatomic, assign) BOOL startedRefresh;
@property (nonatomic, assign) BOOL pageIsAnimating;
@property (atomic,    assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL updatingOfTimerIsPaused;

@property (nonatomic, retain) UIPopoverController *popoverControllerActivity;

@property (nonatomic, retain) UIImageView *snapshotBeforeRotation;
@property (nonatomic, retain) UIImageView *snapshotAfterRotation;

@property (nonatomic, assign) CGRect frameBeforeRotation;
@property (nonatomic, assign) CGRect frameAfterRotation;

@end

@implementation MTReportViewerController {

}

static UIImageView *captureSnapshotOfView (UIView *targetView) {
    UIGraphicsBeginImageContextWithOptions([targetView bounds].size, YES, 0);
    [[targetView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *snapshotView = [[UIImageView alloc] initWithImage:image];
    [snapshotView setFrame:[targetView frame]];
    return [snapshotView autorelease];
}

- (void)dealloc {
    [_snapshotAfterRotation release];
    [_snapshotBeforeRotation release];
    [_popoverControllerActivity release];
    [_printPageRendererReport release];
    [_sliderPagination release];
    _asyncDelegate = nil;
    
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        [_timerLabelTimeSinceRefreh release];
        _timerLabelTimeSinceRefreh = nil;
    }
    
    [_barButtonItemRefresh release];
    [_barButtonItemPrint release];
    [_barButtonItemSendToPdf release];
    [_barButtonItemActivity release];
    [_labelDateLastRefreshed release];
    [_statusLabelWidthConstraint release];
    [_barButtonItemDone release];
    [_sliderView release];
    [_barButtonItemSliderView release];
    [_lastCacheDate release];
    [super dealloc];
}

- (UITabBarItem *)tabBarItem {
    UIImage *tabBarImage = [UIImage imageNamed:@"UIBarButtonItemDatabase"];
    UIImage *tabBarImageOg = [tabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    NSString *title = NSLocalizedString(@"Viewer", @"Viewer");
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:title
                                                             image:tabBarImageOg
                                                               tag:0];
    //self.tabBarItem = tabBarItem;
    return [tabBarItem autorelease];
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
    
    [labelMadDesigner release];
    
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
    
    UIViewController *blankPage = [[UIViewController alloc] init];
    NSArray *blankPageArray = @[blankPage];
    [self setViewControllers:blankPageArray direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) { }];
    [blankPage release];
    
    [[self sliderPagination] setValue:0.0000f];
    [[self sliderPagination] addTarget:self action:@selector(sliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [[self sliderPagination] addTarget:self action:@selector(sliderPageDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
    [[self sliderPagination] setMinimumValue:0];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MTApplicationInstance *app = [AppDelegate app];
    MAReportDocument *reportDocument = [app activeDocument];

    MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[reportDocument reportFormatter]];
    [self setPrintPageRendererReport: prtingPageRendererReport];
    [prtingPageRendererReport release];
    
    [[[self navigationController] toolbar] setNeedsLayout];
    if ([self asyncDelegate]) {
        __block __weak MTReportViewerController *viewController = self;
        [[self asyncDelegate] displayContentController:viewController];
    } else {
        if ([MTApplicationInstance isMadDesigner]) {
            [self reload:self];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIColor *barTintColor = [UIColor tintColor];
    UIColor *tintColor = [UIColor tintColor2];
    UIToolbar *toolbar = [[self navigationController] toolbar];
    [toolbar setBarTintColor:barTintColor];
    [toolbar setTintColor:tintColor];
   // if ([self asyncDelegate] == nil) {
      //  MTApplicationInstance *applicationInstance = [AppDelegate app];
    //    MAReportDocument *reportDocument = [applicationInstance activeDocument];
  //      RptqDocument *document = [reportDocument activeDocument];
//        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
       // RptqQuery *query = [[database hasQueries] anyObject];
        
    //    BOOL hasCachedData = ([query hasQueryCache] != nil);
  //      if ([self startedRefresh] == NO && hasCachedData == NO) {
            //[self refresh:self];
//        } else {
            //NSDate *lastRefresh = [[query hasQueryCache] cacheDate];
            //if (lastRefresh != nil) {
                
               // NSDate *lastD = [[[query hasQueryCache] cacheDate] retain];
               // [self setLastCacheDate: lastD];
              //  [lastD release];
            //    [self updateLateRefreshedLabel:self];
          
          //  }
        //}
   // }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // FIXME: This has to be cleared, or the cache grows, and grows.
    [self setPrintPageRendererReport:nil];
    
    if ([self timerLabelTimeSinceRefreh] != nil) {
        if ([[self timerLabelTimeSinceRefreh] respondsToSelector:@selector(isValid)]) {
            if ([[self timerLabelTimeSinceRefreh] isValid]) {
                [[self timerLabelTimeSinceRefreh] invalidate];
            }
        }
        [self setTimerLabelTimeSinceRefreh:nil];
    }

}

- (void)sliderChangedPage:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float sliderIndex = lroundf([slider value]); // Rounds float to an integer
    if ((int)sliderIndex != [self currentPageIndex]) {
        [self setCurrentPageIndex:sliderIndex];
        MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:[self currentPageIndex] + 1 ofPages:[self numberOfPages]];
        [[pageOne view] setFrame:[[self view] bounds]];
        
        [pageOne setDelegate:self];
        
        __block MTReportViewerController *reportViewer = self;
        [self setViewControllers:@[pageOne] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
            if (finished) {
                [[pageOne view] setNeedsDisplay];
                [[reportViewer labelDateLastRefreshed] setHidden:NO];
                [reportViewer setUpdatingOfTimerIsPaused:NO];
                //[sender updateLateRefreshedLabel:sender];
                [reportViewer setIsRefreshing:NO];

            }
            
        }];
        [pageOne release];
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

- (void)updateLateRefreshedLabel:(id)sender {
    MTReportViewerController *reportViewer;
    Class reportViewerClass = [MTReportViewerController class];
    if ([sender isKindOfClass:reportViewerClass]) {
        reportViewer = sender;
    } else {
        reportViewer = self;
    }
    
    if ([reportViewer updatingOfTimerIsPaused] == NO) {
        if ([reportViewer lastCacheDate] == nil) {

            RptqQuery *query = [AppDelegate activeRptqQuery];
            NSDate *lastD = [[[query hasQueryCache] cacheDate] retain];
            [reportViewer setLastCacheDate: lastD];
            [lastD release];
            if ([reportViewer lastCacheDate] == nil) {  //I give up
                [reportViewer setLastCacheDate:[NSDate date]];
            }
        }
        NSDate *lastCacheDate = [reportViewer lastCacheDate];
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:lastCacheDate];
        NSString *former = [dateStringAndInterval former];
        [[reportViewer labelDateLastRefreshed] setText:former];

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
        
        if ([reportViewer timerLabelTimeSinceRefreh] != nil) {
            if ([[reportViewer timerLabelTimeSinceRefreh] respondsToSelector:@selector(isValid)]) {
                if ([[reportViewer timerLabelTimeSinceRefreh] isValid]) {
                    [[reportViewer timerLabelTimeSinceRefreh] invalidate];
                }
            }
            [reportViewer setTimerLabelTimeSinceRefreh:nil];
        }
        
        NSTimer *t = [[NSTimer scheduledTimerWithTimeInterval:updateLabelInSeconds target:reportViewer
                                                     selector:@selector(updateLateRefreshedLabel:) userInfo:nil
                                                      repeats:NO] retain];
        [reportViewer setTimerLabelTimeSinceRefreh:t];
        [t release];
        
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    MTReportViewerReportPageViewController *pageViewController = [self currentPageviewController];
    UIView *displayView = [pageViewController view];

    [self setFrameBeforeRotation: [displayView frame]];

    [self setSnapshotBeforeRotation: captureSnapshotOfView(displayView)];
    [displayView insertSubview:[self snapshotBeforeRotation] aboveSubview:displayView];

    BOOL isPad = [UIDevice isPad];
    if (isPad == NO) {
        CGFloat labelWidth = 180.0000f;
        switch (toInterfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                labelWidth = 370.000;
                break;
            case UIInterfaceOrientationLandscapeRight:
                labelWidth = 370.000;
                break;
            case UIInterfaceOrientationPortrait:
                labelWidth = 170.000;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                labelWidth = 170.000;
                break;
            default:
                labelWidth = 170.000;
                break;
        }
        
        //__block MTReportViewerController *reportViewer = self;
        //[UIView animateWithDuration:duration animations:^{
            //[[reportViewer statusLabelWidthConstraint] setConstant:labelWidth];
        //}];
    }
}

- (MTReportViewerReportPageViewController *)currentPageviewController {
    NSInteger pageIndex = [self currentPageIndex];
    MTReportViewerReportPageViewController *pageViewController = [self pageViewControllerAtIndex:pageIndex];
    return [[pageViewController retain] autorelease];
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
    
    [self.snapshotAfterRotation setFrame:self.frameAfterRotation];
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
    return [[result retain] autorelease];
}

- (void)redrawReportViewer:(MTReportViewerController *)reportViewerController withFrame:(CGRect)frame {
    [MTReportViewerController setDisplayActive:reportViewerController];
    MTApplicationInstance *app = [AppDelegate app];
    MAReportDocument *doc = [app activeDocument];
    [[doc reportFormatter] formatForSize:frame.size];
    
    NSUInteger numberOfPages = [[doc reportFormatter] numberOfPages];
    [reportViewerController setNumberOfPages:numberOfPages];
    [[reportViewerController sliderPagination] setMaximumValue:numberOfPages > 0 ? (numberOfPages - 1) : 0];
    
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
    [pageOne release];
    
    [[reportViewerController barButtonItemDone] setEnabled:YES];
    
}

- (void)drawPageAtIndex:(NSUInteger)pageIndex inRect:(CGRect)printableRect {
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

+ (void)setDisplayActive:(MTReportViewerController *)controller {

    NSArray *tabBarItems = [[[controller tabBarController] tabBar] items];
    for (UITabBarItem *item in tabBarItems) {
//        [item.image renderingMode]
        [item setEnabled:YES];
    }
    
    [[controller barButtonItemRefresh] setEnabled:YES];
    [[controller barButtonItemDone] setEnabled:YES];
    [[controller barButtonItemPrint] setEnabled:YES];
    [[controller barButtonItemSendToPdf] setEnabled:YES];
    [[controller barButtonItemActivity] setEnabled:YES];
    
    [controller setIsRefreshing:NO];
    [controller setUpdatingOfTimerIsPaused:NO];
    [[controller barButtonItemRefresh] setEnabled:YES];
    [[controller labelDateLastRefreshed] setHidden:NO];
    [[controller labelDateLastRefreshed] setText:@""];
    [[controller labelDateLastRefreshed] setNeedsDisplay];

    [[controller navigationItem] setRightBarButtonItem:[controller barButtonItemRefresh] animated:YES];

}

+ (void)setDisplayInactive:(MTReportViewerController *)controller {

    NSArray *tabBarItems = [[[controller tabBarController] tabBar] items];
    for (UITabBarItem *item in tabBarItems) {
        [item setEnabled:NO];
    }

    [controller setIsRefreshing:YES];
    [[controller barButtonItemRefresh] setEnabled:NO];
    [[controller barButtonItemDone] setEnabled:NO];
    [[controller barButtonItemPrint] setEnabled:NO];
    [[controller barButtonItemSendToPdf] setEnabled:NO];
    [[controller barButtonItemActivity] setEnabled:NO];
    [controller setUpdatingOfTimerIsPaused:YES];
    NSString *refreshing = NSLocalizedString(@"Refreshing data.", @"Refreshing data.");
    [[controller labelDateLastRefreshed] setText:refreshing];
    [[controller labelDateLastRefreshed] setNeedsDisplay];
    [[controller barButtonItemDone] setEnabled:NO];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];
    [activityIndicator setHidesWhenStopped:NO];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [[controller navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
    [barButtonItem release];
    [activityIndicator release];
    
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
        [MTReportViewerController setDisplayInactive:reportViewer];
        
        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queuePriorityBackground, ^{
            
            __block MTReportViewerController *reportViewer2 = reportViewer;
            
            MTApplicationInstance *applicationInstance = [[AppDelegate app] retain];
            MAReportDocument *reportDocument = [[applicationInstance activeDocument] retain];

            [reportDocument refresh:^(BOOL success, NSError *error) {
            
                dispatch_queue_t highpriorityqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
                if (success) {
                    

                    __block MTReportViewerController *reportViewer3 = reportViewer2;
                    dispatch_async(highpriorityqueue, ^{
                        __block MTReportViewerController *reportViewer4 = reportViewer3;
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [MTReportViewerController setDisplayActive:reportViewer4];
                            NSDate *lastD = [[NSDate date] retain];
                            [reportViewer4 setLastCacheDate: lastD];
                            [lastD release];
                            [reportViewer4 reload:reportViewer4];
                        });
                    });
                } else {
                    [error performSelectorOnMainThread:@selector(presentErrorToUser) withObject:nil waitUntilDone:NO];
                    __block MTReportViewerController *reportViewer3 = reportViewer2;
                    dispatch_async(highpriorityqueue, ^{
                        __block MTReportViewerController *reportViewer4 = reportViewer3;
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [MTReportViewerController setDisplayActive:reportViewer4];
                            [reportViewer4 reload:reportViewer4];
                        });
                    });
                }
            }];
            [reportDocument release];
            [applicationInstance release];
        });
    }
}

- (IBAction)activity:(id)sender {

    NSString *temporaryDirectoryPath = NSTemporaryDirectory();
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: temporaryDirectoryPath];
    NSURL *urlEmpty = [[temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"] retain];
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
            [popoverController release];
        }
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{ }];
    }
    
    [activityViewController release];
    [urlEmpty release];
    [activityItemProviderPdf release];
}

- (UIViewController *)previewViewControllerForInteractionController: (UIDocumentInteractionController *) controller {
    return [[self retain] autorelease];
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
    __block MTReportViewerController *blockself = self;
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [blockself reload:blockself];
        });
    });
}

- (void)reload:(MTReportViewerController *)reportViewer {
    
    [MTReportViewerController setDisplayInactive:reportViewer];
    
    __block MTReportViewerController *blockViewer = reportViewer;
    CGSize viewBounds = [[reportViewer view] bounds].size;
    
    MTApplicationInstance *app = [AppDelegate app];
    __block MAReportDocument *doc = [app activeDocument];

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        [[doc reportFormatter] setDidRefresh:[self startedRefresh]];
        [[doc reportFormatter] formatForSize:viewBounds];
        
        __block MAReportDocument *doc2 = doc;
        __block MTReportViewerController *blockViewer2 = blockViewer;
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [MTReportViewerController setDisplayActive:blockViewer2];
            
            NSUInteger numberOfPages = [[doc reportFormatter] numberOfPages];
            [blockViewer2 setNumberOfPages:numberOfPages];
            [[blockViewer2 sliderPagination] setMaximumValue:numberOfPages > 0 ? (numberOfPages - 1) : 0];
            
            NSInteger pageNumber = [blockViewer2 currentPageIndex] + 1;
            MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:pageNumber
                                                                                                                         ofPages:numberOfPages];
            [[pageOne view] setFrame:[[blockViewer2 view] bounds]];
            
            [pageOne setDelegate:reportViewer];
            
            NSArray *viewControllers = @[pageOne];
            [blockViewer2 setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {}];
            [pageOne release];
            [blockViewer2 setIsRefreshing:NO];
            [blockViewer2 setStartedRefresh:NO];
            [[doc2 reportFormatter] setDidRefresh:NO];
            [[blockViewer2 barButtonItemDone] setEnabled:YES];
            
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
        MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery:[doc defaultQuery] andLayout:[doc activeDocument]];
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:reportFormatter];

        [printPageRender writeToPdf:temporaryFile];
        [printPageRender release];
        
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
    
    [self sendToPdfWithCompletionHandler:^(BOOL success){
     
    }];
    
    
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
        [printPageRender release];
        
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
            //[[result view] setBackgroundColor:[UIColor redColor]];
            //[[self view] setBackgroundColor:[UIColor blueColor]];

            [result autorelease];
            
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
            [result autorelease];
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
            [[(MTReportViewerController *)pageViewController sliderPagination] setValue:[(MTReportViewerController *)pageViewController currentPageIndex] animated:YES];
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

@end
