//
//  MUIViewControllerReportViewer.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerReportViewer.h"

@interface MTViewControllerReportViewer ()

@property (retain, nonatomic) IBOutlet UIView *viewBackground;
@property (retain, nonatomic) IBOutlet UIView *viewContainer;

@property (nonatomic, retain) MTPageViewControllerReport *pageController;
@property (nonatomic, copy) MTPrintPageRendererReport *printPageRendererReport;
@property (assign) NSUInteger numberOfPages;
@property (assign) NSUInteger currentPageIndex;

@property (nonatomic, copy) NSArray *initalViewControllers;

@end

@implementation MTViewControllerReportViewer

- (void)dealloc {
    [_initalViewControllers release];
    [_printPageRendererReport release];
    [_documentReport release];
    [_pageController release];
    [_viewContainer release];
    [_viewBackground release];
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
    
    NSManagedObjectContext *managedObjectContext = [[self documentReport] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    
    MTPrintPageRendererReport *prtingPageRendererReport = [[MTPrintPageRendererReport alloc] initWithDocument:document];
    NSUInteger numberOfPages = [prtingPageRendererReport numberOfPages];    //Returning zero when there are pages!!!!
    [self setNumberOfPages:numberOfPages];
    [self setPrintPageRendererReport: prtingPageRendererReport];
    
    MTPageViewControllerReport *pageController = [[MTPageViewControllerReport alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{}];


    NSUInteger initalNumberOfPagesRequired = 1;
    NSMutableArray *initalPages = [[NSMutableArray alloc] initWithCapacity:initalNumberOfPagesRequired];
    MTViewControllerReportPage *pageOne = [[MTViewControllerReportPage alloc] initWithPageData:[self printPageRendererReport] andPageNumber:1];
    [initalPages addObject:pageOne];
    [pageOne release];
    if (initalNumberOfPagesRequired == 2) {
        MTViewControllerReportPage *pageTwo = [[MTViewControllerReportPage alloc] initWithPageData:[self printPageRendererReport] andPageNumber:2];
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
    [prtingPageRendererReport release];

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

#pragma mark - UIPageViewControllerDataSrouce

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger visablePageNumber = [(MTViewControllerReportPage *)viewController pageNumber];
    MTViewControllerReportPage *result = nil;
    if (visablePageNumber + 1 <= [self numberOfPages]) {
        result = [[MTViewControllerReportPage alloc] initWithPageData:[self printPageRendererReport] andPageNumber:visablePageNumber + 1];
    }
    return [result autorelease];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger visablePageNumber = [(MTViewControllerReportPage *)viewController pageNumber];
    MTViewControllerReportPage *result = nil;
    if (visablePageNumber - 1 > 0) {
        result = [[MTViewControllerReportPage alloc] initWithPageData:[self printPageRendererReport] andPageNumber:visablePageNumber - 1];
    }
    return [result autorelease];
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