//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerViewController.h"

@interface MTReportViewerController ()

@property (nonatomic, retain) MTReportViewerPrintPageRenderer *printPageRendererReport;

@property (nonatomic, retain) IBOutlet UIView *sliderView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSliderView;
@property (nonatomic, retain) IBOutlet UISlider *sliderPagination;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemPrint;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSendToPdf;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemDone;

@property (nonatomic, retain) IBOutlet UILabel *labelDateLastRefreshed;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *statusLabelWidthConstraint;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, assign) CGRect lastLayoutBounds;

@property (nonatomic, retain) NSDate *lastCacheDate;
@property (nonatomic, retain) NSTimer *timerLabelTimeSinceRefreh;

@property (nonatomic, assign) BOOL startedRefresh;
@property (nonatomic, assign) BOOL pageIsAnimating;
@property (atomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL updatingOfTimerIsPaused;

@end

@implementation MTReportViewerController

- (void)dealloc {
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
    [_labelDateLastRefreshed release];
    [_statusLabelWidthConstraint release];
    [_barButtonItemDone release];
    [_sliderView release];
    [_barButtonItemSliderView release];
    [_lastCacheDate release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setEdgesForExtendedLayout: UIRectEdgeNone];
    [self setTitle:@"MAD Viewer"];
    
    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    NSAttributedString *attributedString = [AppDelegate attributedStringMadViewer];
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
    
    //id activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    //NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    //[activeDocument release];

    //RptqDocument *document = [[RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext] retain];

    //MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:document];
    //[self setPrintPageRendererReport: prtingPageRendererReport];
    //[prtingPageRendererReport release];
    
    [[self view] setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [self setDataSource:self];
    [self setDelegate:self];
    
    [self setCurrentPageIndex:0];
    //[document release];
    
    UIViewController *blankPage = [[UIViewController alloc] init];
    NSArray *blankPageArray = @[blankPage];
    [self setViewControllers:blankPageArray direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) { }];
    [blankPage release];
    
    [[self sliderPagination] setValue:0.0000f];
    [[self sliderPagination] addTarget:self action:@selector(sliderChangedPage:) forControlEvents:UIControlEventValueChanged];
    [[self sliderPagination] addTarget:self action:@selector(sliderPageDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
    [[self sliderPagination] setMinimumValue:0];

}

- (void)sliderChangedPage:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float sliderIndex = lroundf([slider value]); // Rounds float to an integer
    if ((int)sliderIndex != [self currentPageIndex]) {
        //[slider setValue:sliderIndex];               // Sets your slider to this value
        [self setCurrentPageIndex:sliderIndex];
        //NSInteger initIndex;
        //if ([self currentPageIndex] < [self numberOfPages]) {
        //    initIndex = [self currentPageIndex] + 1;
        //} else {
        //    initIndex = [self numberOfPages] > 0 ? [self numberOfPages] : 0;
        //}
        MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:[self currentPageIndex] + 1 ofPages:[self numberOfPages]];
        [[pageOne view] setFrame:[[self view] bounds]];
        
        [pageOne setDelegate:self];
        
        __block MTReportViewerController *reportViewer = self;
        [self setViewControllers:@[pageOne] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
            if (finished) {
                [[pageOne view] setNeedsDisplay];
                [MTReportViewerController resetScreen:reportViewer];
            }
            
        }];
        [pageOne release];
    }
    
    //[self setViewControllers:<#(NSArray *)#> direction:<#(UIPageViewControllerNavigationDirection)#> animated:YES completion:^(BOOL finished) { }]
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    id activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:document];
    [self setPrintPageRendererReport: prtingPageRendererReport];
    [prtingPageRendererReport release];
    [activeDocument release];
    
    [[[self navigationController] toolbar] setNeedsLayout];
    if ([self asyncDelegate]) {
        __block __weak MTReportViewerController *viewController = self;
        [[self asyncDelegate] displayContentController:viewController];
    } else {
        //__block MTReportViewerController *reportViewer = self;
        [self reload:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //if ([self printPageRendererReport] != nil) {
    //    [[self printPageRendererReport] release];
        //[self setPrintPageRendererReport:nil];
    //}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self asyncDelegate] == nil) {
        [self viewDidAppearLogic];
    }
}

- (void)viewDidAppearLogic {
    
    id activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
    BOOL hasCachedData = ([query hasQueryCache] != nil);
    if ([self startedRefresh] == NO && hasCachedData == NO) {
        if (activeDocument != nil) {
//            dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
//            dispatch_async(queuePriorityBackground, ^{
//                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refresh:self];
//                });
//            });
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
    [activeDocument release];
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
            id activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
            NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
            RptqQuery *query = [[database hasQueries] anyObject];
            NSDate *lastD = [[[query hasQueryCache] cacheDate] retain];
            [reportViewer setLastCacheDate: lastD];
            [lastD release];
            if ([reportViewer lastCacheDate] == nil) {  //I give up
                [reportViewer setLastCacheDate:[NSDate date]];
            }
            [activeDocument release];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([self timerLabelTimeSinceRefreh] != nil) {
        if ([[self timerLabelTimeSinceRefreh] respondsToSelector:@selector(isValid)]) {
            if ([[self timerLabelTimeSinceRefreh] isValid]) {
                [[self timerLabelTimeSinceRefreh] invalidate];
            }
        }
        [self setTimerLabelTimeSinceRefreh:nil];
    }
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
        __block MTReportViewerController *reportViewer = self;
        [UIView animateWithDuration:duration animations:^{
            [[reportViewer statusLabelWidthConstraint] setConstant:labelWidth];
        }];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self reload:self];
}

- (IBAction)done:(id)sender {
    [[self viewControllerDelegate] viewControllerDidFinish: self];
}

- (void)drawPageAtIndex:(NSUInteger)pageIndex inRect:(CGRect)printableRect {
    [[self printPageRendererReport] drawPageAtIndex:pageIndex inRect:printableRect];
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return [UIDevice isPad] ? [self navigationController] : self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    
    
        NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
        NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error];
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender {
    
    __block MTReportViewerController *reportViewer;
    if ([sender isKindOfClass:[MTReportViewerController class]]) {
        reportViewer = sender;
    } else {
        reportViewer = self;
    }

    NSLog(@"retainCount %lu", (unsigned long)reportViewer.retainCount);

    if ([reportViewer isRefreshing] == NO) {

        [reportViewer setIsRefreshing:YES];
        [[reportViewer barButtonItemRefresh] setEnabled:NO];
        [[reportViewer barButtonItemDone] setEnabled:NO];
        [[reportViewer barButtonItemPrint] setEnabled:NO];
        [[reportViewer barButtonItemSendToPdf] setEnabled:NO];
        
        [reportViewer setUpdatingOfTimerIsPaused:YES];
        [[reportViewer labelDateLastRefreshed] setText:NSLocalizedString(@"Refreshing data.", @"Refreshing data.")];
        [[reportViewer labelDateLastRefreshed] setNeedsDisplay];
        [[reportViewer barButtonItemDone] setEnabled:NO];
        
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicator setColor:[UIColor blackColor]];
        [activityIndicator startAnimating];
        [activityIndicator setHidden:NO];
        [activityIndicator setHidesWhenStopped:NO];
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [[self navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
        [barButtonItem release];
        [activityIndicator release];
        
        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queuePriorityBackground, ^{
            
            id activeDocument = [[MTActiveDocument sharedDocument] activeDocument];

            [activeDocument refresh:^(BOOL success) {
            
                NSLog(@"retainCount %lu", (unsigned long)reportViewer.retainCount);

                if (success) {
                    
                    //__block MTReportViewerController *reportViewerBackground = reportViewer;
                    
                    [[reportViewer printPageRendererReport] setDidRefresh:YES];

                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        [[reportViewer navigationItem] setRightBarButtonItem:[reportViewer barButtonItemRefresh] animated:YES];
                        NSDate *lastD = [[NSDate date] retain];
                        [reportViewer setLastCacheDate: lastD];
                        [lastD release];
                        [reportViewer reload:reportViewer];
                        [reportViewer resetScreen];
                    });
                } else {

                    dispatch_sync(dispatch_get_main_queue(), ^{

                        [[reportViewer navigationItem] setRightBarButtonItem:[reportViewer barButtonItemRefresh] animated:YES];
                        [reportViewer reload:reportViewer];
                        [reportViewer resetScreen];
                    });
                }
            }];
        });
    }
}

- (void)reload:(MTReportViewerController *)reportViewer {
    
    //__block __weak MTReportViewerController *reportViewer = self;
    //id activeDocument = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    //if (activeDocument != nil) {
        CGSize viewBounds = [[reportViewer view] bounds].size;
        
        //NSLog(@"retainCount %lu", (unsigned long)reportViewer.retainCount);
        
        //dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        //dispatch_async(queuePriorityBackground, ^{
            
            //NSLog(@"retainCount %lu", (unsigned long)reportViewer.retainCount);
    NSLog(@"retainCount %lu", (unsigned long)reportViewer.retainCount);

            [[reportViewer printPageRendererReport] cachePrintPageRenderDataForSize:viewBounds];
    NSLog(@"retainCount %lu", (unsigned long)reportViewer.retainCount);

            //dispatch_sync(dispatch_get_main_queue(), ^{

                //NSLog(@"retainCount %lu", (unsigned long)reportViewer.retainCount);
                
                NSUInteger numberOfPages = [[self printPageRendererReport] numberOfPages];
                [reportViewer setNumberOfPages:numberOfPages];
                [[reportViewer sliderPagination] setMaximumValue:numberOfPages > 0 ? (numberOfPages - 1) : 0];

                NSInteger pageNumber = [reportViewer currentPageIndex] + 1;
                MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:pageNumber
                                                                                                                             ofPages:numberOfPages];
                [[pageOne view] setFrame:[[reportViewer view] bounds]];
                
                [pageOne setDelegate:reportViewer];
        
                NSArray *viewControllers = @[pageOne];
                [reportViewer setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
                    if (finished) {
                        //[[pageOne view] setNeedsDisplay];
//                        [MTReportViewerController resetScreen:reportViewer];
                    }
                }];
                [pageOne release];
            //});
        //});
    //} else {
    //    [self resetScreen];
    //}
    //[activeDocument release];
}

- (void)resetScreen {
    [MTReportViewerController resetScreen:self];
}

+ (void)resetScreen:(MTReportViewerController *)sender {
    
    [[sender barButtonItemRefresh] setEnabled:YES];
    [[sender barButtonItemDone] setEnabled:YES];
    [[sender barButtonItemPrint] setEnabled:YES];
    [[sender barButtonItemSendToPdf] setEnabled:YES];
    
    [[sender labelDateLastRefreshed] setHidden:NO];
    [sender setUpdatingOfTimerIsPaused:NO];
    //[sender updateLateRefreshedLabel:sender];
    [sender setIsRefreshing:NO];
    [[sender barButtonItemRefresh] setEnabled:YES];
    
}

- (IBAction)sendToPdf:(id)sender {
    

    [[self barButtonItemDone] setEnabled:NO];
    [[self barButtonItemSendToPdf] setEnabled:NO];
    [[self barButtonItemRefresh] setEnabled:NO];
    [[self barButtonItemPrint] setEnabled:NO];
    [self setUpdatingOfTimerIsPaused:YES];
    [[self labelDateLastRefreshed] setText:NSLocalizedString(@"Exporting data.", @"Exporting data.")];
    [[self labelDateLastRefreshed] setNeedsDisplay];
    
    __block MTReportViewerController *reportViewer = self;

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        
        NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
        NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] init];
        [printPageRender writeToPdf:temporaryFile];
        [printPageRender release];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [reportViewer setUpdatingOfTimerIsPaused:NO];
            [reportViewer updateLateRefreshedLabel:reportViewer];
            [[reportViewer barButtonItemRefresh] setEnabled:YES];
            [[reportViewer barButtonItemDone] setEnabled:YES];
            [[reportViewer barButtonItemPrint] setEnabled:YES];
            [[reportViewer barButtonItemSendToPdf] setEnabled:YES];
            
            UIDocumentInteractionController *c = [UIDocumentInteractionController  interactionControllerWithURL:temporaryFile];
            [c setDelegate:reportViewer];
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
        
        __block MTReportViewerController *reportViewer = self;
        UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            [[reportViewer barButtonItemPrint] setEnabled:YES];
            [[reportViewer barButtonItemRefresh] setEnabled:YES];
            [[reportViewer barButtonItemSendToPdf] setEnabled:YES];
            if(!completed && error){
                //MTLog(@"FAILED! due to error in domain %@ with error code %u", error.domain, error.code);
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
            //[[result view] setBackgroundColor:[UIColor redColor]];
            //[[self view] setBackgroundColor:[UIColor blueColor]];

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
