//
//  MADDocumentPageController.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDocumentPageController.h"

#import <UIKit/UIAccessibility.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UINavigationController.h>

#import <MADCocoaExtensions/UIView+Animations.h>
#import <MAD/MTPaper.h>
#import <MAD/MADocument.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADPrintingProtocol.h"

#import "MADTabBarController.h"

#import "MADReportPageView.h"
#import "NSDate+Extras.h"
#import "MADDocumentScroller.h"
#import "MADPageViewAttributes.h"

static const CGFloat PageEdgeInsetMargin = 3.0000f;

static inline UIEdgeInsets MADEdgeInsetsForLayoutGuides(id <UILayoutSupport> topLayoutGuide,
                                                        id <UILayoutSupport> bottomLayoutGuide);
static inline UIEdgeInsets MADEdgeInsetsForLayoutGuides(id <UILayoutSupport> topLayoutGuide,
                                                        id <UILayoutSupport> bottomLayoutGuide) {
    return UIEdgeInsetsMake(topLayoutGuide.length, CGSizeZero.width, bottomLayoutGuide.length, CGSizeZero.width);
}

static inline CGFloat zoomScale(CGFloat l1, CGFloat l2, CGFloat m);
static inline CGFloat zoomScale(CGFloat l1, CGFloat l2, CGFloat m) {
    return 1 +  ( l2 - l1 - (m * 2) )  / l1;
}

static inline CGFloat edgeInsetForScrollIndicator(CGFloat parentViewLength, CGFloat subViewLength,
                                                  CGFloat layoutGuideLength, CGFloat margin);
static inline CGFloat edgeInsetForScrollIndicator(CGFloat parentViewLength, CGFloat subViewLength,
                                                  CGFloat layoutGuideLength, CGFloat margin) {
    return parentViewLength > subViewLength ?
            ((parentViewLength - subViewLength) / 2.0000f) + margin : layoutGuideLength + margin;
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

static inline UIEdgeInsets boundsInsets(id<UILayoutSupport> topLayoutGuide, id<UILayoutSupport> bottomLayoutGuide);
static inline UIEdgeInsets boundsInsets(id<UILayoutSupport> topLayoutGuide, id<UILayoutSupport> bottomLayoutGuide) {
    return UIEdgeInsetsMake(topLayoutGuide.length, CGSizeZero.width, bottomLayoutGuide.length, CGSizeZero.width);
}

@interface MADDocumentPageController ()
    <UIAccessibilityReadingContent,
        UIScrollViewDelegate,
        MADReportPageViewProtocol>

    @property (readwrite, nonatomic, weak) MADocument *document;

    @property (readwrite, nonatomic, weak) MADReportPageView *documentView;

    @property (readwrite, nonatomic, copy) MADPageViewAttributes *pageViewAttributes;
    @property (readwrite, nonatomic, weak) MADDocumentScroller *documentScroller;

@end

@implementation MADDocumentPageController {
    BOOL _initalLayout;
}

#pragma mark - Static Helpers

+ (void)centerDocumentView:(UIView *)documentView insideScrollView:(UIScrollView *)scrollView
                                                    topLayoutGuide:(id <UILayoutSupport>)topLayoutGuide
                                                 bottomLayoutGuide:(id <UILayoutSupport>)bottomLayoutGuide
                                                            margin:(const CGFloat)margin {
    
    documentView.center = documentCenterPoint(scrollView.bounds.size, scrollView.contentSize, margin);
    scrollView.scrollIndicatorInsets = [MADDocumentPageController ScrollIndicatorInsetForScrollView: scrollView
                                                                                               insets: boundsInsets(topLayoutGuide, bottomLayoutGuide)];
    
}

+ (UIEdgeInsets)ScrollIndicatorInsetForScrollView:(UIScrollView *)scrollView
                                           insets:(UIEdgeInsets)insets {
    return UIEdgeInsetsMake(edgeInsetForScrollIndicator(scrollView.bounds.size.height,
                                                        scrollView.contentSize.height,
                                                        insets.top,
                                                        PageEdgeInsetMargin),
                            edgeInsetForScrollIndicator(scrollView.bounds.size.width,
                                                        scrollView.contentSize.width,
                                                        insets.left,
                                                        PageEdgeInsetMargin),
                            edgeInsetForScrollIndicator(scrollView.bounds.size.height,
                                                        scrollView.contentSize.height,
                                                        insets.bottom,
                                                        PageEdgeInsetMargin),
                            edgeInsetForScrollIndicator(scrollView.bounds.size.width,
                                                        scrollView.contentSize.width,
                                                        insets.right,
                                                        PageEdgeInsetMargin));
}

#pragma mark - Static Constructors

+ (instancetype)newReportPageViewControllerWithDocument:(MADocument *)document
                                         pageAttributes:(MADPageViewAttributes *)pageAttributes {
    
    id pageViewController;
    pageViewController = [[self alloc] initWithDocument: document
                                     andPageAttributtes: pageAttributes];
    return pageViewController;

}

#pragma mark - NSObject

- (void)dealloc {
    [_documentView removeFromSuperview];
}

- (instancetype)initWithDocument:(MADocument *)document
              andPageAttributtes:(MADPageViewAttributes *)pageAttributes {
    if (self = [super init]) {
        _document = document;
        _initalLayout = YES;
        MADPageViewAttributes *attributes = pageAttributes.copy;
        self.pageViewAttributes = attributes;
    }
    return self;
}

#pragma mark - UIViewController Protocol


- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    MTPaper *paper = self.document.paper;
    
    MADDocumentScroller *scrollView = [[MADDocumentScroller alloc] initWithFrame:self.view.frame];
    scrollView.contentSize = paper.paperSize;
    scrollView.contentInset = UIEdgeInsetsMake(PageEdgeInsetMargin, PageEdgeInsetMargin,
                                               PageEdgeInsetMargin, PageEdgeInsetMargin);
    scrollView.autoresizingMask = MADViewAutoresizingFlexable();
    scrollView.translatesAutoresizingMaskIntoConstraints = YES;
    scrollView.delegate = self;
    
    MADReportPageView *renderedReportView = [[MADReportPageView alloc] initWithFrame:paper.bounds];
    renderedReportView.backgroundColor = [UIColor whiteColor];
    renderedReportView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin;
    renderedReportView.translatesAutoresizingMaskIntoConstraints = YES;
    renderedReportView.delegatePage = self;
    [scrollView addSubview:renderedReportView];

    self.documentView = renderedReportView;

    scrollView.delegate = self;
    [self.view addSubview: scrollView];
    self.documentScroller = scrollView;

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
    if (_initalLayout) {
        _initalLayout = NO;
        
        MADDocumentScroller *documentScroller = self.documentScroller;
        documentScroller.scrollIndicatorInsets = [MADDocumentPageController ScrollIndicatorInsetForScrollView: documentScroller
                                                                                                       insets: MADEdgeInsetsForLayoutGuides(self.topLayoutGuide, self.bottomLayoutGuide)];
        
        MADocument *document = self.document;
        documentScroller.maximumZoomScale = maximumZoomScaleForPaperInContainer(document.paper.paperSize,
                                                                                     documentScroller.bounds.size,
                                                                                    PageEdgeInsetMargin);
        documentScroller.minimumZoomScale = minimumZoomScaleForPaperInContainer(document.paper.paperSize,
                                                                                     documentScroller.bounds.size,
                                                                                     PageEdgeInsetMargin);
        
        [documentScroller setZoomScale: self.pageViewAttributes.zoomScaleInital animated:NO];
        self.documentView.contentScaleFactor = self.pageViewAttributes.contentScaleFactor;
    }
    
}

//- (UIScrollView *)documentScroller {
//    return ((UIScrollView *)self.view);
//}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    MADDocumentScroller *documentScroller = self.documentScroller;
    CGPoint currentContentOffset = documentScroller.contentOffset;
    CGPoint nextContentOffset = CGPointMake( (size.width != documentScroller.contentSize.width)?(size.width - documentScroller.contentSize.width) / 2 : 0.0f, currentContentOffset.y);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        documentScroller.scrollIndicatorInsets =
        [MADDocumentPageController ScrollIndicatorInsetForScrollView: self.documentScroller
                                                              insets: MADEdgeInsetsForLayoutGuides(self.topLayoutGuide, self.bottomLayoutGuide)];
        documentScroller.contentOffset = nextContentOffset;
        documentScroller.bounds = MADRectOfSize(size);
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        MADocument *document = self.document;
        documentScroller.maximumZoomScale = maximumZoomScaleForPaperInContainer(document.paper.paperSize,
                                                                                documentScroller.bounds.size,
                                                                                PageEdgeInsetMargin);
        documentScroller.minimumZoomScale = minimumZoomScaleForPaperInContainer(document.paper.paperSize,
                                                                                documentScroller.bounds.size,
                                                                                PageEdgeInsetMargin);
        
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
    [MADDocumentPageController centerDocumentView: self.documentView
                                   insideScrollView: scrollView
                                     topLayoutGuide: self.topLayoutGuide
                                  bottomLayoutGuide: self.bottomLayoutGuide
                                             margin: PageEdgeInsetMargin];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view
                        atScale:(CGFloat)scale {
    [MADDocumentPageController centerDocumentView: view
                                   insideScrollView: scrollView
                                     topLayoutGuide: self.topLayoutGuide
                                  bottomLayoutGuide: self.bottomLayoutGuide
                                             margin: PageEdgeInsetMargin];
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
        NSString *path = self.document.urlDataTableCache.path;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path
                                                                                    error: &error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            self.pageViewAttributes.reportLastCacheDate = lastD.copy;
        }
    }
    return self.pageViewAttributes.reportLastCacheDate;
}

#pragma mark - MADPrintingProtocol

- (MADPrintPageRenderer *)printPageRenderer {
    return [self.delegate printPageRenderer];
}

@end
