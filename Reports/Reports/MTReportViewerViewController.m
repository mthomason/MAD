//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerViewController.h"

@interface MTReportViewerController ()

@property (nonatomic, retain) MTReportViewerPrintPageRenderer *printPageRenderForPrinting;

@property (nonatomic, retain) IBOutlet UIView *sliderView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSliderView;
@property (nonatomic, retain) IBOutlet UISlider *sliderPagination;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemPrint;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSendToPdf;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemDone;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, assign) CGRect lastLayoutBounds;

@property (nonatomic, assign) BOOL startedRefresh;

@property (nonatomic, assign) BOOL pageIsAnimating;

@property (nonatomic, retain) IBOutlet UILabel *labelDateLastRefreshed;

@property (nonatomic, retain) NSDate *lastCacheDate;
@property (nonatomic, retain) NSTimer *timerLabelTimeSinceRefreh;

@property (atomic, assign) BOOL isRefreshing;
@property (nonatomic, retain) IBOutlet DocumentStatusView *documentStatusView;

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *statusLabelWidthConstraint;

@property (nonatomic, assign) BOOL updatingOfTimerIsPaused;


@end

@implementation MTReportViewerController

- (void)dealloc {
    [_sliderPagination release];
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        [_timerLabelTimeSinceRefreh release];
        _timerLabelTimeSinceRefreh = nil;
    }
    [_documentStatusView release];
    [_printPageRenderForPrinting release];
    [_printPageRendererReport release];
    [_documentReport release];
    //[_pageController release];
    [_barButtonItemRefresh release];
    [_barButtonItemPrint release];
    [_barButtonItemSendToPdf release];
    [_labelDateLastRefreshed release];
    [_statusLabelWidthConstraint release];
    [_barButtonItemDone release];
    [_sliderView release];
    [_barButtonItemSliderView release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setTitle:@"MAD Viewer"];
    }
    return self;
}

- (void)loadReport:(MAReportDocument *)report {
    [report retain];
    [self setDocumentReport:report];
    [report release];
    NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:document];
    [self setPrintPageRendererReport: prtingPageRendererReport];
    //[[self printPageRendererReport] setDidRefresh:YES];
    //[[self printPageRendererReport] cachePrintPageRenderDataForSize:[[self view] bounds].size];
    [prtingPageRendererReport release];
    
    [self viewDidAppearLogic];

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    [self reloadReportView];
    dispatch_async(queuePriorityBackground, ^{
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            //[self setIsRefreshing:NO];
            [self reload];
        });
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setIsRefreshing:NO];
    [self setUpdatingOfTimerIsPaused:NO];
    _timerLabelTimeSinceRefreh = nil;
    _lastCacheDate = nil;
    [[self labelDateLastRefreshed] setText:@""];
    [self setPageIsAnimating:NO];
    
    [self setStartedRefresh:NO];
    
    NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];

    MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:document];
    [self setPrintPageRendererReport: prtingPageRendererReport];
    [prtingPageRendererReport release];
    
    [[self view] setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    [self setDataSource:self];
    [self setDelegate:self];
    
    [self setCurrentPageIndex:0];
    
    UIViewController *blankPage = [[UIViewController alloc] init];
    [self setViewControllers:@[blankPage] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) { }];
    [blankPage release];
    
    [[self sliderPagination] setValue:0.0000f];
    [[self sliderPagination] addTarget:self action:@selector(sliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [[self sliderPagination] setMinimumValue:0];

}

- (void)sliderChangedPage:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float sliderIndex = lroundf([slider value]); // Rounds float to an integer
    [slider setValue:sliderIndex];               // Sets your slider to this value
    [self setCurrentPageIndex:sliderIndex];
    NSInteger initIndex;
    if ([self currentPageIndex] < [self numberOfPages]) {
        initIndex = [self currentPageIndex] + 1;
    } else {
        initIndex = [self numberOfPages] > 0 ? [self numberOfPages] : 0;
    }
    MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:[self currentPageIndex] + 1 ofPages:[self numberOfPages]];
    [[pageOne view] setFrame:[[self view] bounds]];
    
    [pageOne setDelegate:self];
    
    [self setViewControllers:@[pageOne] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        if (finished) {
            [[pageOne view] setNeedsDisplay];
            [self resetScreen];
        }
        
    }];
    [pageOne release];
    
    //[self setViewControllers:<#(NSArray *)#> direction:<#(UIPageViewControllerNavigationDirection)#> animated:YES completion:^(BOOL finished) { }]
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
    
    //[self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[[self navigationController] toolbar] setNeedsLayout];
    if ([self asyncDelegate]) {
        [[self asyncDelegate] displayContentController:self];
    } else {
        [self reload];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self asyncDelegate] == nil) {
        [self viewDidAppearLogic];
    }
}

- (void)viewDidAppearLogic {
    NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
    BOOL hasCachedData = ([query hasQueryCache] != nil);
    if ([self startedRefresh] == NO && hasCachedData == NO) {
        if ([self documentReport] != nil) {
            dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(queuePriorityBackground, ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refresh:self];
                });
            });
        }
        
    } else {
        NSDate *lastRefresh = [[query hasQueryCache] cacheDate];
        if (lastRefresh != nil) {
            
            NSDate *lastD = [[[query hasQueryCache] cacheDate] retain];
            [self setLastCacheDate: lastD];
            [lastD release];
            [self updateLateRefreshedLabel:self];
            
        }
    }
}

- (void)updateLateRefreshedLabel:(id)sender {
    if ([self updatingOfTimerIsPaused] == NO) {
        if ([self lastCacheDate] == nil) {
            NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
            RptqQuery *query = [[database hasQueries] anyObject];
            NSDate *lastD = [[[query hasQueryCache] cacheDate] retain];
            [self setLastCacheDate: lastD];
            [lastD release];
            if ([self lastCacheDate] == nil) {  //I give up
                [self setLastCacheDate:[NSDate date]];
            }
        }
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:[self lastCacheDate]];
        [[self documentStatusView] setDocumentMessage:[dateStringAndInterval former]];
        [[self labelDateLastRefreshed] setText:[dateStringAndInterval former]];

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
        NSTimer *t = [[NSTimer scheduledTimerWithTimeInterval:updateLabelInSeconds target:self
                                                    selector:@selector(updateLateRefreshedLabel:) userInfo:nil
                                                     repeats:NO] retain];
        [self setTimerLabelTimeSinceRefreh:t];
        [t release];
        
    }
}



- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
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
        [UIView animateWithDuration:duration animations:^{
            [[self statusLabelWidthConstraint] setConstant:labelWidth];
        }];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self setIsRefreshing:NO];
            [self reload];
        });
    });
}

- (IBAction)done:(id)sender {
    [[self viewControllerDelegate] viewControllerDidFinish: self];
}

- (void)drawPageAtIndex:(NSUInteger)pageIndex inRect:(CGRect)printableRect {
    [[self printPageRendererReport] drawPageAtIndex:pageIndex inRect:printableRect];
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error];
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender {
    if ([self isRefreshing] == NO) {
        //if ([self documentReport] != nil) {
            [self setIsRefreshing:YES];
            [[self barButtonItemRefresh] setEnabled:NO];
            [[self barButtonItemDone] setEnabled:NO];
            [[self barButtonItemPrint] setEnabled:NO];
            [[self barButtonItemSendToPdf] setEnabled:NO];
            
            //[[self labelDateLastRefreshed] setHidden:YES];
            [self setUpdatingOfTimerIsPaused:YES];
            [[self labelDateLastRefreshed] setText:NSLocalizedString(@"Refreshing data.", @"Refreshing data.")];
            [[self labelDateLastRefreshed] setNeedsDisplay];
            [[self documentStatusView] setActivityState:YES];
            [[self barButtonItemDone] setEnabled:NO];
            dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            
            dispatch_async(queuePriorityBackground, ^{
                
                [[self documentReport] refresh:^(BOOL success) {
                    
                    if (success) {
                        [[self printPageRendererReport] setDidRefresh:YES];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSDate *lastD = [[NSDate date] retain];
                            [self setLastCacheDate: lastD];
                            [lastD release];
                            [self reload];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self resetScreen];
                        });
                    }
                }];
            });
       //}
    }
}

- (void)reload {
    if ([self documentReport] != nil) {
        CGSize viewBounds = [[self view] bounds].size;
        
        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queuePriorityBackground, ^{
            
            [[self printPageRendererReport] cachePrintPageRenderDataForSize:viewBounds];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUInteger numberOfPages = [[self printPageRendererReport] numberOfPages];
                [self setNumberOfPages:numberOfPages];
                [[self sliderPagination] setMaximumValue:numberOfPages > 0 ? (numberOfPages - 1) : 0];

                MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:[self currentPageIndex] + 1 ofPages:[self numberOfPages]];
                [[pageOne view] setFrame:[[self view] bounds]];
                
                [pageOne setDelegate:self];
                
                [self setViewControllers:@[pageOne] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
                    if (finished) {
                        [[pageOne view] setNeedsDisplay];
                        [self resetScreen];
                    }
                    
                }];
                [pageOne release];
            });
        });
    } else {
        [self resetScreen];
    }
}

- (void)resetScreen {
    
    [[self barButtonItemRefresh] setEnabled:YES];
    [[self barButtonItemDone] setEnabled:YES];
    [[self barButtonItemPrint] setEnabled:YES];
    [[self barButtonItemSendToPdf] setEnabled:YES];
    
    [[self labelDateLastRefreshed] setHidden:NO];
    [self setUpdatingOfTimerIsPaused:NO];
    [[self documentStatusView] setActivityState:NO];
    [self updateLateRefreshedLabel:self];
    [self setIsRefreshing:NO];
    [[self barButtonItemRefresh] setEnabled:YES];

}

- (void)reloadReportView {
    [[self printPageRendererReport] setDidRefresh:YES];
    [[self printPageRendererReport] cachePrintPageRenderDataForSize:[[self view] bounds].size];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger numberOfPages = [[self printPageRendererReport] numberOfPages];
        [self setNumberOfPages:numberOfPages];
        [[self sliderPagination] setMaximumValue:numberOfPages];
    });
}

- (IBAction)sendToPdf:(id)sender {

    [[self barButtonItemDone] setEnabled:NO];
    [[self barButtonItemSendToPdf] setEnabled:NO];
    [[self barButtonItemRefresh] setEnabled:NO];
    [[self barButtonItemPrint] setEnabled:NO];
    [self setUpdatingOfTimerIsPaused:YES];
    [[self labelDateLastRefreshed] setText:NSLocalizedString(@"Exporting data.", @"Exporting data.")];
    [[self labelDateLastRefreshed] setNeedsDisplay];

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        
        NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
        NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] init];
        [printPageRender writeToPdf:temporaryFile];
        [printPageRender release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUpdatingOfTimerIsPaused:NO];
            [self updateLateRefreshedLabel:self];
            [[self barButtonItemRefresh] setEnabled:YES];
            [[self barButtonItemDone] setEnabled:YES];
            [[self barButtonItemPrint] setEnabled:YES];
            [[self barButtonItemSendToPdf] setEnabled:YES];
            UIDocumentInteractionController *c = [UIDocumentInteractionController interactionControllerWithURL:temporaryFile];\
            [c setDelegate:self];
            [c presentPreviewAnimated:YES];
        });

    });
}

- (IBAction)print:(id)sender {
    
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
    if (controller) {
        
        [[self barButtonItemPrint] setEnabled:NO];
        [[self barButtonItemRefresh] setEnabled:NO];
        [[self barButtonItemSendToPdf] setEnabled:NO];
        
        UIPrintInteractionCompletionHandler completionHandler =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            [[self barButtonItemPrint] setEnabled:YES];
            [[self barButtonItemRefresh] setEnabled:YES];
            [[self barButtonItemSendToPdf] setEnabled:YES];
            if(!completed && error){
                MTLog(@"FAILED! due to error in domain %@ with error code %u", error.domain, error.code);
            }
        };
        
        // Obtain a printInfo so that we can set our printing defaults.
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = [[RptqDocument activeDocument] name];
        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        controller.printInfo = printInfo;
        
        controller.showsPageRange = YES;
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] init];
        [controller setPrintPageRenderer:printPageRender];
        //[self setPrintPageRenderForPrinting:printPageRender];
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

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    
    MTReportViewerReportPageViewController *result = nil;
    if ([self pageIsAnimating] == NO) {
        NSUInteger visablePageNumber = [(MTReportViewerReportPageViewController *)viewController pageNumber];
        if (visablePageNumber + 1 <= [self numberOfPages]) {
            result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber + 1  ofPages:[self numberOfPages]];
            [result setDelegate: self];
            [[result view] setFrame:[[self view] bounds]];
            [result autorelease];
        }
    }
    return result;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    
    MTReportViewerReportPageViewController *result = nil;
    if ([self pageIsAnimating] == NO) {
        NSUInteger visablePageNumber = [(MTReportViewerReportPageViewController *)viewController pageNumber];
        if (visablePageNumber - 1 > 0) {
            result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber - 1 ofPages:[self numberOfPages]];
            [result setDelegate: self];
            [[result view] setFrame:[[self view] bounds]];
            [result autorelease];
        }
    }
    return result;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [self numberOfPages];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return [self currentPageIndex];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    if (completed || finished) {
        [self setPageIsAnimating:NO];
        if ([[self viewControllers] count] > 0) {
            MTReportViewerReportPageViewController *pageViewController = [[self viewControllers] objectAtIndex:0];
            [self setCurrentPageIndex:[pageViewController pageNumber] - 1];
            [[self sliderPagination] setValue:[self currentPageIndex] animated:YES];
        }
    }
    
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    [self setPageIsAnimating:NO];
    return UIPageViewControllerSpineLocationMin;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    
    [self setPageIsAnimating:YES];
    
}

@end
