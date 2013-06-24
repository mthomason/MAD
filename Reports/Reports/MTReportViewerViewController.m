//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerViewController.h"

@interface MTReportViewerViewController ()

@property (nonatomic, retain) MTReportViewerPrintPageRenderer *printPageRenderForPrinting;

@property (nonatomic, retain) IBOutlet UIView *viewBackground;
@property (nonatomic, retain) IBOutlet UIView *viewContainer;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemPrint;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemRefresh;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSendToPdf;

@property (nonatomic, retain) MTReportViewerReportViewController *pageController;

@property (nonatomic, retain) NSArray *initalViewControllers;

@property (nonatomic, retain) IBOutlet UIToolbar *toolbarTop;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbarBottom;

@property (nonatomic, retain) IBOutletCollection(UIToolbar) NSArray *toolbars;

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, assign) CGRect lastLayoutBounds;

@property (nonatomic, assign) BOOL startedRefresh;

@property (nonatomic, assign) BOOL pageIsAnimating;

@property (nonatomic, retain) IBOutlet UILabel *labelDateLastRefreshed;

@property (nonatomic, retain) NSDate *lastCacheDate;
@property (nonatomic, assign) NSTimer *timerLabelTimeSinceRefreh;

@property (atomic, assign) BOOL isRefreshing;
@property (retain, nonatomic) IBOutlet DocumentStatusView *documentStatusView;

@end

@implementation MTReportViewerViewController

- (void)dealloc {
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh isValid]) {
            [_timerLabelTimeSinceRefreh invalidate];
        }
        _timerLabelTimeSinceRefreh = nil;
    }
    [_documentStatusView release];
    [_printPageRenderForPrinting release];
    [_initalViewControllers release];
    [_printPageRendererReport release];
    [_documentReport release];
    [_pageController release];
    [_viewContainer release];
    [_viewBackground release];
    [_toolbarTop release];
    [_toolbarBottom release];
    [_toolbars release];
    [_barButtonItemRefresh release];
    [_barButtonItemPrint release];
    [_barButtonItemSendToPdf release];
    [_labelDateLastRefreshed release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setTitle:@"MAD Viewer"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setIsRefreshing:NO];
    _timerLabelTimeSinceRefreh = nil;
    _lastCacheDate = nil;
    [[self labelDateLastRefreshed] setText:@""];
    [self setPageIsAnimating:NO];
    
    [self setStartedRefresh:NO];
    
    [[self view] setBackgroundColor:[UIColor greenColor]];
    
    MTReportViewerReportViewController *pageController = [[MTReportViewerReportViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl
                                                                                       navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                                     options:@{}];
    [[pageController view] setBackgroundColor:[UIColor blueColor]];
    [pageController setDataSource:self];
    [pageController setDelegate:self];

    NSUInteger initalNumberOfPagesRequired = 1;
    NSMutableArray *initalPages = [[NSMutableArray alloc] initWithCapacity:initalNumberOfPagesRequired];

    [self setCurrentPageIndex:0];
    
    MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:1 ofPages:initalNumberOfPagesRequired];
    [[pageOne view] setBounds:[[self viewContainer] bounds]];
    [[pageOne view] setCenter:[[self viewContainer] center]];
    [pageOne setDelegate:self];
    [initalPages addObject:pageOne];

    [pageOne release];
    if (initalNumberOfPagesRequired == 2) {
        MTReportViewerReportPageViewController *pageTwo = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:2 ofPages:initalNumberOfPagesRequired];
        [[pageTwo view] setBounds:[[self viewContainer] bounds]];
        [[pageTwo view] setCenter:[[self viewContainer] center]];
        [pageTwo setDelegate:self];
        [initalPages addObject:pageTwo];
        [pageTwo release];
    }
    
    [pageController setViewControllers:initalPages direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
    
    }];

    [initalPages release];
    
    [[self viewContainer] addSubview:[pageController view]];

    [self setPageController:pageController];
    [pageController release];
    
    NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    
    MTReportViewerPrintPageRenderer *prtingPageRendererReport = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:document];
    [self setPrintPageRendererReport: prtingPageRendererReport];
    [prtingPageRendererReport release];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[[self pageController] view] setFrame:[[self viewContainer] bounds]];
    [self reloadReportView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
 
    BOOL hasCachedData = ([query hasQueryCache] != nil);
    if ([self startedRefresh] == NO && hasCachedData == NO) {

        [[self barButtonItemRefresh] setEnabled:NO];
        [[self documentReport] refresh:^(BOOL success) {
            
            if (success) {
                [self reloadReportView];
                
                NSDate *lastD = [[NSDate date] retain];
                [self setLastCacheDate: lastD];
                [lastD release];
                
                [self updateLateRefreshedLabel:self];

            }
            [[self barButtonItemRefresh] setEnabled:YES];

        }];

    } else {
        NSDate *lastRefresh = [[query hasQueryCache] cacheDate];
        NSString *timeInterval;
        if (lastRefresh != nil) {
            
            NSDate *lastD = [[[query hasQueryCache] cacheDate] retain];
            [self setLastCacheDate: lastD];
            [lastD release];

            [self updateLateRefreshedLabel:self];

        } else {
            timeInterval = NSLocalizedString(@"No cached data.", @"No cached data.");
        }
    }
}

- (void)updateLateRefreshedLabel:(id)sender {

        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:[self lastCacheDate]];
        
        
        CGFloat offsetX = CGPointZero.x + [[self labelDateLastRefreshed] frame].origin.x;
        CGFloat width = [[self view] bounds].size.width - offsetX - 105.0000f;
    [[self documentStatusView] setDocumentMessage:[dateStringAndInterval former]];
        [[self labelDateLastRefreshed] setText:[dateStringAndInterval former]];
        CGSize printSize = [[dateStringAndInterval former] sizeWithFont:[[self labelDateLastRefreshed] font]];
        CGSize targetSize = CGSizeMake(printSize.width, [[self labelDateLastRefreshed] frame].size.height);
        CGSize labelSize = [[self labelDateLastRefreshed] systemLayoutSizeFittingSize:targetSize];
        [[self labelDateLastRefreshed] setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, width, labelSize.height)];
        [[[self labelDateLastRefreshed] superview] setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, width - offsetX, labelSize.height)];
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
            if ([[self timerLabelTimeSinceRefreh] isValid]) {
                [[self timerLabelTimeSinceRefreh] invalidate];
            }
            [self setTimerLabelTimeSinceRefreh:nil];
        }
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:updateLabelInSeconds target:self
                                                    selector:@selector(updateLateRefreshedLabel:) userInfo:nil
                                                     repeats:NO];
        [self setTimerLabelTimeSinceRefreh:t];
    
}



- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (void)drawPageAtIndex:(NSUInteger)pageIndex inRect:(CGRect)printableRect {
    [[self printPageRendererReport] drawPageAtIndex:pageIndex inRect:printableRect];
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller {
    return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {

    NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error];
    
    MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:[self currentPageIndex] + 1 ofPages:[self numberOfPages]];
    [[pageOne view] setFrame:[[self viewContainer] bounds]];
    [pageOne setDelegate:self];
    [[self pageController] setViewControllers:@[pageOne] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        
    }];
    [pageOne release];
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender {
    if ([self isRefreshing] == NO) {
        [[self barButtonItemRefresh] setEnabled:NO];
        [self setIsRefreshing:YES];
        [[self barButtonItemRefresh] setEnabled:NO];
        [[self labelDateLastRefreshed] setHidden:YES];
        [[self labelDateLastRefreshed] setText:@""];
        [[self labelDateLastRefreshed] setNeedsDisplay];
        [[self documentStatusView] setActivityState:YES];
        
        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        
        dispatch_async(queuePriorityBackground, ^{
            
            [[self documentReport] refresh:^(BOOL success) {
                
                if (success) {
                    [self reloadReportView];
                    if ([self currentPageIndex] + 1 >= [self numberOfPages]) {
                        [self setCurrentPageIndex:[self numberOfPages] - 1];
                    }
                    
                    MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:[self currentPageIndex] + 1 ofPages:[self numberOfPages]];
                    [[pageOne view] setFrame:[[self viewContainer] bounds]];
                    [pageOne setDelegate:self];
                    [[self pageController] setViewControllers:@[pageOne] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
                        
                    }];
                    [pageOne release];
                    
                    NSDate *lastD = [[NSDate date] retain];
                    [self setLastCacheDate: lastD];
                    [lastD release];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [[self labelDateLastRefreshed] setHidden:NO];
                        [[self documentStatusView] setActivityState:NO];
                        [self updateLateRefreshedLabel:self];
                        [self setIsRefreshing:NO];
                        [[self barButtonItemRefresh] setEnabled:YES];
                        
                    });
                    //[[self barButtonItemRefresh] setEnabled:YES];
                    
                }
            }];
        });
    }
}

- (void)reloadReportView {
    [[self printPageRendererReport] setDidRefresh:YES];
    [[self printPageRendererReport] cachePrintPageRenderDataForSize:[[self viewContainer] bounds].size];
    NSUInteger numberOfPages = [[self printPageRendererReport] numberOfPages];
    [self setNumberOfPages:numberOfPages];
}

- (IBAction)sendToPdf:(id)sender {
    NSURL *temporaryDirectory = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"preview.pdf"];
    MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] init];
    [printPageRender writeToPdf:temporaryFile];
    [printPageRender release];
    UIDocumentInteractionController *c = [UIDocumentInteractionController interactionControllerWithURL:temporaryFile];
    [c setDelegate:self];
    [c presentPreviewAnimated:YES];
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
                NSLog(@"FAILED! due to error in domain %@ with error code %u", error.domain, error.code);
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
        [self setPrintPageRenderForPrinting:printPageRender];
        controller.printPageRenderer = [self printPageRenderForPrinting];
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
            [[result view] setFrame:[[self viewContainer] bounds]];
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
            [[result view] setFrame:[[self viewContainer] bounds]];
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

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {

    if (completed || finished) {
        [self setPageIsAnimating:NO];
    }

}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    [self setPageIsAnimating:NO];
    return UIPageViewControllerSpineLocationMin;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    
    [self setPageIsAnimating:YES];
    
}

- (void)viewDidUnload {
    [self setDocumentStatusView:nil];
    [super viewDidUnload];
}
@end
