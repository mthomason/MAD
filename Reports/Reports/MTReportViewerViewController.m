//
//  MUIViewControllerReportViewer.m
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerViewController.h"

@interface MTReportViewerViewController ()

@property (nonatomic, retain) MTPrintPageRendererReport *printPageRendererReport;

@property (retain, nonatomic) IBOutlet UIView *viewBackground;
@property (retain, nonatomic) IBOutlet UIView *viewContainer;

@property (nonatomic, retain) MTReportViewerReportViewController *pageController;

@property (assign) NSUInteger numberOfPages;
@property (assign) NSUInteger currentPageIndex;

@property (nonatomic, retain) NSArray *initalViewControllers;

@property (retain, nonatomic) IBOutlet UIToolbar *toolbarTop;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarBottom;

@property (retain, nonatomic) IBOutletCollection(UIToolbar) NSArray *toolbars;


@end

@implementation MTReportViewerViewController

- (void)dealloc {
    [_initalViewControllers release];
    [_printPageRendererReport release];
    [_documentReport release];
    [_pageController release];
    [_viewContainer release];
    [_viewBackground release];
    [_toolbarTop release];
    [_toolbarBottom release];
    [_toolbars release];
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
    
    [[self viewContainer] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    
    [self setPageController:pageController];
    [pageController release];

    NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    MTPrintPageRendererReport *prtingPageRendererReport = [[MTPrintPageRendererReport alloc] initWithDocument:document];
    [self setPrintPageRendererReport: prtingPageRendererReport];
    [prtingPageRendererReport release];

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[[self pageController] view] setFrame:[[self viewContainer] bounds]];
    [[self viewContainer] addSubview:[[self pageController] view]];

    [[self printPageRendererReport] setPrintableSize:[[self viewContainer] bounds].size];
    [[self printPageRendererReport] cachePrintPageRenderData];
    NSUInteger numberOfPages = [[self printPageRendererReport] numberOfPages];
    [self setNumberOfPages:numberOfPages];
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

#pragma mark - UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger visablePageNumber = [(MTReportViewerReportPageViewController *)viewController pageNumber];
    MTReportViewerReportPageViewController *result = nil;
    if (visablePageNumber + 1 <= [self numberOfPages]) {
        result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber + 1];
        [result setDelegate: self];
        [[result view] setFrame:[[self viewContainer] bounds]];
    }
    return result;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger visablePageNumber = [(MTReportViewerReportPageViewController *)viewController pageNumber];
    MTReportViewerReportPageViewController *result = nil;
    if (visablePageNumber - 1 > 0) {
        result = [[MTReportViewerReportPageViewController alloc] initWithPageNumber:visablePageNumber - 1];
        [result setDelegate: self];
        [[result view] setFrame:[[self viewContainer] bounds]];
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
    
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return UIPageViewControllerSpineLocationMin;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    
}

@end
