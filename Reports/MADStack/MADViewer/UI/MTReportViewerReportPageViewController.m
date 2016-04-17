//
//  MTViewControllerReportPage.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportViewerReportPageViewController.h"
#import "MTReportViewerReportPageView.h"
#import "NSDate+Extras.h"
#import "MADDocumentScroller.h"
#import "MADPageViewAttributes.h"

static const CGFloat PageEdgeInsetMargin = 3.0000f;


@interface MADReportPageViewController ()
    <UIAccessibilityReadingContent, UIScrollViewDelegate, MADReportPageViewProtocol>

    @property (nonatomic, weak, readwrite) UIView *documentView;

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, copy, readwrite) MADPageViewAttributes *pageViewAttributes;
    @property (nonatomic, assign) bool initalLayout;

@end

@implementation MADReportPageViewController

#pragma mark - Static Helpers

+ (void)centerDocumentView:(UIView *)documentView insideScrollView:(UIScrollView *)scrollView
            topLayoutGuide:(id <UILayoutSupport>)topLayoutGuide bottomLayoutGuide:(id <UILayoutSupport>)bottomLayoutGuide margin:(const CGFloat)margin {
    documentView.center = documentCenterPoint(scrollView.bounds.size, scrollView.contentSize, margin);
    scrollView.scrollIndicatorInsets = [MADReportPageViewController ScrollIndicatorInsetForScrollView: scrollView insets: boundsInsets(topLayoutGuide, bottomLayoutGuide)];
}

static inline UIEdgeInsets MADEdgeInsetsForLayoutGuides(id<UILayoutSupport> topLayoutGuide, id<UILayoutSupport> bottomLayoutGuide);
static inline UIEdgeInsets MADEdgeInsetsForLayoutGuides(id<UILayoutSupport> topLayoutGuide, id<UILayoutSupport> bottomLayoutGuide) {
    return UIEdgeInsetsMake(topLayoutGuide.length, CGSizeZero.width, bottomLayoutGuide.length, CGSizeZero.width);
}

static inline CGFloat zoomScale(CGFloat l1, CGFloat l2, CGFloat m);
static inline CGFloat zoomScale(CGFloat l1, CGFloat l2, CGFloat m) {
    return 1 +  ( l2 - l1 - (m * 2) )  / l1;
}

static inline CGFloat edgeInsetForScrollIndicator(CGFloat parentViewLength, CGFloat subViewLength, CGFloat layoutGuideLength, CGFloat margin);
static inline CGFloat edgeInsetForScrollIndicator(CGFloat parentViewLength, CGFloat subViewLength, CGFloat layoutGuideLength, CGFloat margin) {
    return parentViewLength > subViewLength ? ((parentViewLength - subViewLength) / 2.0000f) + margin : layoutGuideLength + margin;
}

static inline CGFloat maximumZoomScaleForPaperInContainer(CGSize paper, CGSize container, CGFloat margin);
static inline CGFloat maximumZoomScaleForPaperInContainer(CGSize paper, CGSize container, CGFloat margin) {
    return MAX(zoomScale(paper.width, container.width, margin),
               zoomScale(paper.height, container.height, margin));
}

static inline CGFloat minimumZoomScaleForPaperInContainer(CGSize paper, CGSize container, CGFloat margin);
static inline CGFloat minimumZoomScaleForPaperInContainer(CGSize paper, CGSize container, CGFloat margin) {
    return MIN(zoomScale(paper.width, container.width, margin),
               zoomScale(paper.height, container.height, margin));
}

static inline CGPoint documentCenterPoint(CGSize scrollerBoundsSize, CGSize contentSize, CGFloat margin);
static inline CGPoint documentCenterPoint(CGSize scrollerBoundsSize, CGSize contentSize, CGFloat margin) {
    return CGPointMake(contentSize.width * 0.5000f + MAX(((scrollerBoundsSize.width - (margin * 2)) - contentSize.width) * 0.5000f, 0.0000f),
                       contentSize.height * 0.5000f + MAX(((scrollerBoundsSize.height - (margin * 2)) - contentSize.height) * 0.5000f, 0.0000f));
}

+ (UIEdgeInsets)ScrollIndicatorInsetForScrollView:(UIScrollView *)scrollView insets:(UIEdgeInsets)insets {
    return UIEdgeInsetsMake(edgeInsetForScrollIndicator(scrollView.bounds.size.height, scrollView.contentSize.height, insets.top, PageEdgeInsetMargin),
                            edgeInsetForScrollIndicator(scrollView.bounds.size.width, scrollView.contentSize.width, insets.left, PageEdgeInsetMargin),
                            edgeInsetForScrollIndicator(scrollView.bounds.size.height, scrollView.contentSize.height, insets.bottom, PageEdgeInsetMargin),
                            edgeInsetForScrollIndicator(scrollView.bounds.size.width, scrollView.contentSize.width, insets.right, PageEdgeInsetMargin));
}

static inline UIEdgeInsets boundsInsets(id<UILayoutSupport> topLayoutGuide, id<UILayoutSupport> bottomLayoutGuide);
static inline UIEdgeInsets boundsInsets(id<UILayoutSupport> topLayoutGuide, id<UILayoutSupport> bottomLayoutGuide) {
    return UIEdgeInsetsMake(topLayoutGuide.length, CGSizeZero.width, bottomLayoutGuide.length, CGSizeZero.width);
}

#pragma mark - Static Constructors

+ (instancetype)newReportPageViewControllerWithDocument:(MADocument *)document pageAttributes:(MADPageViewAttributes *)pageAttributes frame:(CGRect)frame andDelegate:(id <MTPrintingProtocol>)delegate {
    
    MADReportPageViewController *pageViewController = [[self alloc] initWithDocument: document andPageAttributtes: pageAttributes];
    pageViewController.view.frame = frame;
    pageViewController.delegate = delegate;
    return pageViewController;

}

#pragma mark - NSObject

- (void)dealloc { }

- (instancetype)initWithDocument:(MADocument *)document andPageAttributtes:(MADPageViewAttributes *)pageAttributes {
    if (self = [super init]) {
        _document = document;
        _initalLayout = true;
        _pageViewAttributes = pageAttributes.copy;
    }
    return self;
}

#pragma mark - UIViewController Protocol

- (void)loadView {

    MADocument *document = self.document;
    
    MADDocumentScroller *scrollView = [[MADDocumentScroller alloc] initWithFrame:CGRectZero];
    scrollView.contentSize = document.paper.paperSize;
    scrollView.contentInset = UIEdgeInsetsMake(PageEdgeInsetMargin, PageEdgeInsetMargin, PageEdgeInsetMargin, PageEdgeInsetMargin);
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.translatesAutoresizingMaskIntoConstraints = YES;
    scrollView.delegate = self;
    
    MADReportPageView *renderedReportView = [[MADReportPageView alloc] initWithFrame:document.paper.bounds];
    renderedReportView.backgroundColor = [UIColor whiteColor];
    renderedReportView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    renderedReportView.translatesAutoresizingMaskIntoConstraints = YES;
    renderedReportView.delegatePage = self;
    [scrollView addSubview:renderedReportView];
    
    self.documentView = renderedReportView;
    self.view = scrollView;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.documentScroller.delegate = self;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tabBarController.navigationController.view setNeedsLayout];   //Forces the top layout guide to set.

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.documentScroller flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.initalLayout) {
        self.initalLayout = false;
        
        self.documentScroller.scrollIndicatorInsets = [MADReportPageViewController ScrollIndicatorInsetForScrollView:self.documentScroller insets: MADEdgeInsetsForLayoutGuides(self.topLayoutGuide, self.bottomLayoutGuide)];
        
        MADocument *document = self.document;
        self.documentScroller.maximumZoomScale = maximumZoomScaleForPaperInContainer(document.paper.paperSize, self.documentScroller.bounds.size, PageEdgeInsetMargin);
        self.documentScroller.minimumZoomScale = minimumZoomScaleForPaperInContainer(document.paper.paperSize, self.documentScroller.bounds.size, PageEdgeInsetMargin);
        

        [self.documentScroller setZoomScale: self.pageViewAttributes.zoomScaleInital animated:NO];
        self.documentView.contentScaleFactor = self.pageViewAttributes.contentScaleFactor;
    }
    
}

- (UIScrollView *)documentScroller {
    return ((UIScrollView *)self.view);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    CGPoint currentContentOffset = self.documentScroller.contentOffset;
    CGPoint nextContentOffset = CGPointMake( (size.width != self.documentScroller.contentSize.width)?(size.width - self.documentScroller.contentSize.width) / 2 : 0.0f, currentContentOffset.y);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.documentScroller.scrollIndicatorInsets = [MADReportPageViewController ScrollIndicatorInsetForScrollView: self.documentScroller
                                                                                                              insets: MADEdgeInsetsForLayoutGuides(self.topLayoutGuide, self.bottomLayoutGuide)];
        self.documentScroller.contentOffset = nextContentOffset;
        self.documentScroller.bounds = CGRectMake(CGPointZero.x, CGPointZero.y, size.width, size.height);
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        MADocument *document = self.document;
        self.documentScroller.maximumZoomScale = maximumZoomScaleForPaperInContainer(document.paper.paperSize, self.documentScroller.bounds.size, PageEdgeInsetMargin);
        self.documentScroller.minimumZoomScale = minimumZoomScaleForPaperInContainer(document.paper.paperSize, self.documentScroller.bounds.size, PageEdgeInsetMargin);
        
    }];
}

- (CGFloat)zoomScale {
    return self.documentScroller.zoomScale;
}

- (NSUInteger)pageNumber {
    return self.pageViewAttributes.pageNumber;
}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.documentView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [MADReportPageViewController centerDocumentView:self.documentView insideScrollView:scrollView topLayoutGuide:self.topLayoutGuide bottomLayoutGuide:self.bottomLayoutGuide margin:PageEdgeInsetMargin];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [MADReportPageViewController centerDocumentView:view insideScrollView:scrollView topLayoutGuide:self.topLayoutGuide bottomLayoutGuide:self.bottomLayoutGuide margin:PageEdgeInsetMargin];
    view.contentScaleFactor = scrollView.traitCollection.displayScale * scale;
    [view setNeedsDisplay];
}

#pragma mark - UIAccessibility

- (NSInteger)accessibilityLineNumberForPoint:(CGPoint)point { return 1; }

- (NSString * _Nullable)accessibilityContentForLineNumber:(NSInteger)lineNumber {
    return @"Content for line number";
}

- (CGRect)accessibilityFrameForLineNumber:(NSInteger)lineNumber {
    return self.view.frame;
}

- (NSString * _Nullable)accessibilityPageContent {
    return @"Content for line number";
}

#pragma mark - MADReportPageViewProtocol

- (NSDate * _Nullable)lastCacheDate {
    if (self.pageViewAttributes.reportLastCacheDate == nil) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: self.document.urlDataTableCache.path error: &error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            self.pageViewAttributes.reportLastCacheDate = lastD.copy;
        }
    }
    return self.pageViewAttributes.reportLastCacheDate;
}

#pragma mark - MTPrintingProtocol

- (MTReportViewerPrintPageRenderer *)printPageRender {
    return [self.delegate printPageRender];
}

@end
