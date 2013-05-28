//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerViewController.h"

@interface MTReportViewerViewController ()

@property (retain, nonatomic) IBOutlet UIView *viewBackground;
@property (retain, nonatomic) IBOutlet UIView *viewContainer;

@property (nonatomic, retain) MTReportViewerReportViewController *pageController;

@property (assign) NSUInteger numberOfPages;
@property (assign) NSUInteger currentPageIndex;

@property (nonatomic, retain) NSArray *initalViewControllers;

@property (retain, nonatomic) IBOutlet UIToolbar *toolbarTop;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarBottom;

@property (retain, nonatomic) IBOutletCollection(UIToolbar) NSArray *toolbars;

@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemRefresh;

@property (nonatomic, assign) CGRect lastLayoutBounds;

@property (nonatomic, assign) BOOL startedRefresh;

@property (nonatomic, assign) BOOL pageIsAnimating;

@property (nonatomic, retain) MTReportViewerPrintPageRenderer *printPageRenderForPrinting;

@end

@implementation MTReportViewerViewController

- (void)dealloc {
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
    [_printButton release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setPageIsAnimating:NO];
    
    [self setStartedRefresh:NO];
    
    [[self view] setBackgroundColor:[UIColor greenColor]];
    
    MTReportViewerReportViewController *pageController = [[MTReportViewerReportViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl
                                                                                       navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                                     options:@{}];
    [[pageController view] setBackgroundColor:[UIColor blueColor]];

    NSUInteger initalNumberOfPagesRequired = 1;
    NSMutableArray *initalPages = [[NSMutableArray alloc] initWithCapacity:initalNumberOfPagesRequired];

    MTReportViewerReportPageViewController *pageOne = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:1];
    [[pageOne view] setBounds:[[self viewContainer] bounds]];
    [[pageOne view] setCenter:[[self viewContainer] center]];
    [pageOne setDelegate:self];
    [initalPages addObject:pageOne];
    [pageOne release];
    if (initalNumberOfPagesRequired == 2) {
        MTReportViewerReportPageViewController *pageTwo = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:2];
        [[pageTwo view] setBounds:[[self viewContainer] bounds]];
        [[pageTwo view] setCenter:[[self viewContainer] center]];
        [pageTwo setDelegate:self];
        [initalPages addObject:pageTwo];
        [pageTwo release];
    }
    
    [pageController setViewControllers:initalPages direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
    
    }];

    [initalPages release];
    
    [pageController setDataSource:self];
    [pageController setDelegate:self];

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
    

    if ([self startedRefresh] == NO && [[self documentReport] hasCachedData] == NO) {

        [[self barButtonItemRefresh] setEnabled:NO];
        [[self documentReport] refresh:^(BOOL success) {

            if (success) {
                [self reloadReportView];
                [[self barButtonItemRefresh] setEnabled:YES];
            }

        }];

    }

    //[self reloadReportView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[[self pageController] view] removeFromSuperview];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (void)drawPageAtIndex:(NSUInteger)pageIndex inRect:(CGRect)printableRect {
    [[self printPageRendererReport] drawPageAtIndex:pageIndex inRect:printableRect];
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender {
    [[self barButtonItemRefresh] setEnabled:NO];
    [[self documentReport] refresh:^(BOOL success) {
        
        if (success) {
            [self reloadReportView];
            [[self barButtonItemRefresh] setEnabled:YES];
        }
        
    }];
}

- (void)reloadReportView {
    [[self printPageRendererReport] cachePrintPageRenderDataForSize:[[self viewContainer] bounds].size];
    NSUInteger numberOfPages = [[self printPageRendererReport] numberOfPages];
    [self setNumberOfPages:numberOfPages];
}
- (IBAction)sendTo:(id)sender {
}

- (IBAction)sendToPdf:(id)sender {
    MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] init];
    [printPageRender writeToPdf:@"/Users/mthomason/Desktop/edareports.pdf"];
    [printPageRender release];
}

- (IBAction)print:(id)sender {

    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
    if(controller){
        
        UIPrintInteractionCompletionHandler completionHandler =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
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
            [controller presentFromBarButtonItem:[self printButton] animated:YES completionHandler:completionHandler];  // iPad
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
            result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber + 1];
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
            result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber - 1];
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

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
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
    [self setPrintButton:nil];
    [super viewDidUnload];
}
@end
