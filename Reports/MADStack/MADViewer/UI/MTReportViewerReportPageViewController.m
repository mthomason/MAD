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
#import <MAD/MTPaper.h>

@interface MTReportViewerReportPageViewController ()
    <UIAccessibilityReadingContent, UIScrollViewDelegate, MADReportViewerReportPageViewProtocol>

    @property (readonly) UIScrollView *scrollView;
    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, weak) UIView *documentView;
    @property (nonatomic, assign) NSUInteger reportPageNumber;
    @property (nonatomic, assign) NSUInteger reportNumberOfPages;
    @property (nonatomic, strong) NSDate *reportLastCacheDate;
    @property (nonatomic, assign) bool initalLayout;

@end

@implementation MTReportViewerReportPageViewController

+ (instancetype)PageViewControllerWithDocument:(MADocument *)document pageNumber:(NSUInteger)pageNumber ofPages:(NSUInteger)numberOfPages
                                         frame:(CGRect)frame andDelegate:(id <MTPrintingProtocol>)delegate {
    
    MTReportViewerReportPageViewController *pageViewController = [[self alloc] initWithDocument: document
                                                                                     pageNumber: pageNumber
                                                                                        ofPages: numberOfPages];
    pageViewController.view.frame = frame;
    pageViewController.delegate = delegate;
    return pageViewController;

}

- (void)dealloc {
    _delegate = nil;
}

- (instancetype)initWithDocument:(MADocument *)document pageNumber:(NSUInteger)pageNumber ofPages:(NSUInteger)numberOfPages {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.document = document;
        self.reportPageNumber = pageNumber;
        self.reportNumberOfPages = numberOfPages;
        self.initalLayout = true;
    }
    return self;
}

#pragma mark - UIViewController Protocol

const CGFloat PageEdgeInsetMargin = 3.0000f;

- (void)loadView {

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.backgroundColor = [UIColor lightGrayColor];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.translatesAutoresizingMaskIntoConstraints = YES;
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    scrollView.contentSize = self.document.paper.paperSize;
    scrollView.contentInset = UIEdgeInsetsMake(PageEdgeInsetMargin, PageEdgeInsetMargin, PageEdgeInsetMargin, PageEdgeInsetMargin);
    scrollView.bounces = YES;
    scrollView.alwaysBounceVertical = YES;
    scrollView.delegate = self;
    
    MTReportViewerReportPageView *renderedReportView = [[MTReportViewerReportPageView alloc] initWithFrame:self.document.paper.bounds];
    UIColor *whiteColor = [UIColor whiteColor];
    renderedReportView.backgroundColor = whiteColor;
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tabBarController.navigationController.view setNeedsLayout];   //Forces the top layout guide to set.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [((UIScrollView *)self.view) flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

static inline CGFloat edgeInsetForScrollIndicator(CGFloat parentViewLength, CGFloat subViewLength, CGFloat layoutGuideLength);
static inline CGFloat edgeInsetForScrollIndicator(CGFloat parentViewLength, CGFloat subViewLength, CGFloat layoutGuideLength) {
    return parentViewLength > subViewLength ? ((parentViewLength - subViewLength) / 2.0000f) + PageEdgeInsetMargin : layoutGuideLength + PageEdgeInsetMargin;
}

static inline CGFloat maximumZoomScaleForPaperInContainer(CGSize paper, CGSize container);
static inline CGFloat maximumZoomScaleForPaperInContainer(CGSize paper, CGSize container) {
    return MAX((1 + ((((container.width - paper.width)  - (PageEdgeInsetMargin * 2))  / paper.width))),
               (1 + ((((container.height - paper.height)  - (PageEdgeInsetMargin * 2) ) / paper.height))));
}

static inline CGFloat minimumZoomScaleForPaperInContainer(CGSize paper, CGSize container);
static inline CGFloat minimumZoomScaleForPaperInContainer(CGSize paper, CGSize container) {
    return MIN((1 + ((((container.width - paper.width)  - (PageEdgeInsetMargin * 2))  / paper.width))),
               (1 + ((((container.height - paper.height)  - (PageEdgeInsetMargin * 2) ) / paper.height))));
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.initalLayout) {
        self.initalLayout = false;
        self.scrollView.scrollIndicatorInsets = [MTReportViewerReportPageViewController ScrollIndicatorInsetForScrollView:self.scrollView
                                                                                                                   insets: UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width)];
        
        self.scrollView.maximumZoomScale = maximumZoomScaleForPaperInContainer(self.document.paper.paperSize, self.view.bounds.size);
        self.scrollView.minimumZoomScale = minimumZoomScaleForPaperInContainer(self.document.paper.paperSize, self.view.bounds.size);
    }
}

- (UIScrollView *)scrollView {
    return ((UIScrollView *)self.view);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
}



#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.documentView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    CGFloat offsetX = MAX(((scrollView.bounds.size.width - (PageEdgeInsetMargin * 2)) - scrollView.contentSize.width) * 0.5000f, 0.0000f);
    CGFloat offsetY = MAX(((scrollView.bounds.size.height - (PageEdgeInsetMargin * 2)) - scrollView.contentSize.height) * 0.5000f, 0.0000f);
    self.documentView.center = CGPointMake(scrollView.contentSize.width * 0.5000f + offsetX,
                                           scrollView.contentSize.height * 0.5000f + offsetY);
    
    scrollView.scrollIndicatorInsets = [MTReportViewerReportPageViewController ScrollIndicatorInsetForScrollView:scrollView
                                                                                                          insets: UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width)];
    
}

+ (UIEdgeInsets)ScrollIndicatorInsetForScrollView:(UIScrollView *)scrollView insets:(UIEdgeInsets)insets {
    return UIEdgeInsetsMake(edgeInsetForScrollIndicator(scrollView.bounds.size.height, scrollView.contentSize.height, insets.top),
                                                                         edgeInsetForScrollIndicator(scrollView.bounds.size.width, scrollView.contentSize.width, insets.left),
                                                                         edgeInsetForScrollIndicator(scrollView.bounds.size.height, scrollView.contentSize.height, insets.bottom),
                                                                         edgeInsetForScrollIndicator(scrollView.bounds.size.width, scrollView.contentSize.width, insets.right));
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

#pragma mark - MADReportViewerReportPageViewProtocol

- (NSUInteger)pageNumber {
    return self.reportPageNumber;
}

- (NSUInteger)numberOfPages {
    return self.reportNumberOfPages;
}

- (NSDate * _Nullable)lastCacheDate {
    if (self.reportLastCacheDate == nil) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: self.document.cachedDataUrl.path
                                                                                    error: &error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            self.reportLastCacheDate = lastD;
        }
    }
    return self.reportLastCacheDate;
}

#pragma mark - MTPrintingProtocol

- (MTReportViewerPrintPageRenderer *)printPageRender {
    return [self.delegate printPageRender];
}

@end
