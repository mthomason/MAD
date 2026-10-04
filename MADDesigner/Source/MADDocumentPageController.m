//
//  MADDocumentPageController.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDocumentPageController.h"
#import "MADPrintingProtocol.h"
#import "MADReportPageViewProtocol.h"
#import "MADReportPageView.h"
#import "MADTabBarController.h"
#import "MADDocumentScroller.h"
#import "MADPageViewAttributes.h"
#import "madlog.h"

#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <MAD/MTPaper.h>
#import <MAD/MADocument.h>

#import <UIKit/UIAccessibility.h>
#import <UIKit/UINavigationController.h>

static const CGFloat PageEdgeInsetMargin = 3.0;

static inline UIEdgeInsets boundsInsets(CGFloat, CGFloat);
static inline CGFloat zoomScale(CGFloat, CGFloat, CGFloat);
static inline CGFloat EdgeInsetForScrollIndicator(CGFloat, CGFloat, CGFloat, CGFloat);
static inline CGFloat MaximumZoomScaleForPaper(CGSize, CGSize, CGFloat);
static inline CGFloat MinimumZoomScaleForPaper(CGSize, CGSize, CGFloat);
static inline CGPoint documentCenterPoint(CGSize, CGSize, CGFloat);

static inline CGFloat zoomScale(CGFloat l1, CGFloat l2, CGFloat m) {
	return 1.0 +  ( l2 - l1 - (m * 2.0) )  / l1;
}

static inline CGFloat EdgeInsetForScrollIndicator(CGFloat parentViewLength, CGFloat subViewLength,
												  CGFloat layoutGuideLength, CGFloat margin) {
	return parentViewLength > subViewLength ?
	((parentViewLength - subViewLength) / 2.0) + margin : layoutGuideLength + margin;
}

static inline CGFloat MaximumZoomScaleForPaper(CGSize paper, CGSize container, CGFloat margin) {
	return MAX(zoomScale(paper.width, container.width, margin),
			   zoomScale(paper.height, container.height, margin));
}

static inline CGFloat MinimumZoomScaleForPaper(CGSize paper, CGSize container, CGFloat margin) {
	return MIN(zoomScale(paper.width, container.width, margin),
			   zoomScale(paper.height, container.height, margin));
}

static inline CGPoint documentCenterPoint(CGSize scrollerBoundsSize, CGSize contentSize, CGFloat margin) {
	return CGPointMake(contentSize.width * 0.5 + MAX(((scrollerBoundsSize.width - (margin * 2.0)) - contentSize.width) * 0.5, 0.0),
					   contentSize.height * 0.5 + MAX(((scrollerBoundsSize.height - (margin * 2.0)) - contentSize.height) * 0.5, 0.0));
}

static inline UIEdgeInsets boundsInsets(CGFloat topLayoutGuide, CGFloat bottomLayoutGuide) {
	return UIEdgeInsetsMake(topLayoutGuide, CGSizeZero.width, bottomLayoutGuide, CGSizeZero.width);
}

@interface MADDocumentPageController () <UIAccessibilityReadingContent, UIScrollViewDelegate, MADReportPageViewProtocol>

	@property (readwrite, nonatomic, weak) MADocument *document;
	@property (readwrite, nonatomic, weak) MADReportPageView *documentView;
	@property (readwrite, nonatomic, copy) MADPageViewAttributes *pageViewAttributes;
	@property (readwrite, nonatomic, weak) MADDocumentScroller *documentScroller;

@end

@implementation MADDocumentPageController {
	BOOL _initalLayout;
}

#pragma mark -
#pragma mark Static Helpers

+ (void)centerDocumentView:(UIView *)documentView insideScrollView:(UIScrollView *)scrollView
													topLayoutGuide:(CGFloat)topLayoutGuide
												 bottomLayoutGuide:(CGFloat)bottomLayoutGuide
															margin:(const CGFloat)margin {
	
	documentView.center = documentCenterPoint(scrollView.bounds.size, scrollView.contentSize, margin);
	scrollView.scrollIndicatorInsets = [MADDocumentPageController ScrollIndicatorInset: scrollView
																				bounds: boundsInsets(topLayoutGuide, bottomLayoutGuide)];
	
}

+ (UIEdgeInsets)ScrollIndicatorInset:(UIScrollView *)scrollView
							  bounds:(UIEdgeInsets)insets {
	return UIEdgeInsetsMake(EdgeInsetForScrollIndicator(scrollView.bounds.size.height,
														scrollView.contentSize.height,
														insets.top,
														PageEdgeInsetMargin),
							EdgeInsetForScrollIndicator(scrollView.bounds.size.width,
														scrollView.contentSize.width,
														insets.left,
														PageEdgeInsetMargin),
							EdgeInsetForScrollIndicator(scrollView.bounds.size.height,
														scrollView.contentSize.height,
														insets.bottom,
														PageEdgeInsetMargin),
							EdgeInsetForScrollIndicator(scrollView.bounds.size.width,
														scrollView.contentSize.width,
														insets.right,
														PageEdgeInsetMargin));
}

#pragma mark -
#pragma mark Static Constructors

+ (instancetype)newDocumentPageController:(MADocument *)document
						   pageAttributes:(MADPageViewAttributes *)pageAttributes {
	id pageViewController = [[self alloc] initWithDocument: document
										andPageAttributtes: pageAttributes];
	return pageViewController;
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	[_documentView removeFromSuperview];
	[_documentScroller removeFromSuperview];
}

- (instancetype)initWithDocument:(MADocument *)document
			  andPageAttributtes:(MADPageViewAttributes *)pageAttributes {
	if (self = [super init]) {
		_document = document;
		_initalLayout = YES;
		_pageViewAttributes = [pageAttributes copyWithZone:nil];
	}
	return self;
}

#pragma mark -
#pragma mark UIViewController Protocol


- (void)viewDidLoad {
	[super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;

	MTPaper *paper = self.document.paper;
	
	MADDocumentScroller *documentScroller = [[MADDocumentScroller alloc] initWithFrame:self.view.frame];
	documentScroller.contentSize = paper.paperSize;
	documentScroller.contentInset = UIEdgeInsetsMake(PageEdgeInsetMargin, PageEdgeInsetMargin,
											   PageEdgeInsetMargin, PageEdgeInsetMargin);
	documentScroller.autoresizingMask = MADViewAutoresizingFlexable();
	documentScroller.translatesAutoresizingMaskIntoConstraints = YES;
	documentScroller.delegate = self;
	
	MADReportPageView *documentView = [[MADReportPageView alloc] initWithFrame:paper.bounds];
	documentView.backgroundColor = [UIColor whiteColor];
	documentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	documentView.translatesAutoresizingMaskIntoConstraints = YES;
	documentView.delegatePage = self;
	[documentScroller addSubview:documentView];

	self.documentView = documentView;

	documentScroller.delegate = self;
	[self.view addSubview: documentScroller];
	self.documentScroller = documentScroller;

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

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	UIView *documentView = self.documentView;
	MADDocumentScroller *documentScroller = self.documentScroller;
	
	UIEdgeInsets safeAreaInsets;
	MADViewSafeAreaInserts(self.view, &safeAreaInsets);
	
	[MADDocumentPageController centerDocumentView: documentView
								 insideScrollView: documentScroller
								   topLayoutGuide: safeAreaInsets.top
								bottomLayoutGuide: safeAreaInsets.bottom
										   margin: PageEdgeInsetMargin];
	if (_initalLayout) {
		_initalLayout = NO;
		
		UIEdgeInsets scrollIndicatorInsets = boundsInsets(safeAreaInsets.top, safeAreaInsets.bottom);
		documentScroller.scrollIndicatorInsets = [MADDocumentPageController ScrollIndicatorInset: documentScroller
																						  bounds: scrollIndicatorInsets];
		
		MADocument *document = self.document;
		documentScroller.maximumZoomScale = MaximumZoomScaleForPaper(document.paper.paperSize, documentScroller.bounds.size, PageEdgeInsetMargin);
		documentScroller.minimumZoomScale = MinimumZoomScaleForPaper(document.paper.paperSize, documentScroller.bounds.size, PageEdgeInsetMargin);
		
		[documentScroller setZoomScale: self.pageViewAttributes.zoomScaleInital animated:NO];
		documentView.contentScaleFactor = self.pageViewAttributes.contentScaleFactor;
	}
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	MADDocumentScroller *documentScroller = self.documentScroller;
	CGPoint currentContentOffset = documentScroller.contentOffset;
	CGPoint nextContentOffset = CGPointMake((size.width != documentScroller.contentSize.width)?(size.width - documentScroller.contentSize.width) / 2.0 : 0.0,
											currentContentOffset.y);
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		
		UIEdgeInsets safeAreaInsets;
		MADViewSafeAreaInserts(self.view, &safeAreaInsets);
		
		UIEdgeInsets safeBoundsInsets = boundsInsets(safeAreaInsets.top, safeAreaInsets.bottom);
		
		documentScroller.scrollIndicatorInsets = [MADDocumentPageController ScrollIndicatorInset: self.documentScroller bounds: safeBoundsInsets];
		documentScroller.contentOffset = nextContentOffset;
		documentScroller.bounds = MADRectOfSize(size);
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		
		MADocument *document = self.document;
		documentScroller.maximumZoomScale = MaximumZoomScaleForPaper(document.paper.paperSize, documentScroller.bounds.size, PageEdgeInsetMargin);
		documentScroller.minimumZoomScale = MinimumZoomScaleForPaper(document.paper.paperSize, documentScroller.bounds.size, PageEdgeInsetMargin);
		
	}];
}

- (CGFloat)zoomScale {
	return self.documentScroller.zoomScale;
}

- (NSUInteger)pageNumber {
	return self.pageViewAttributes.pageNumber;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.documentView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	UIEdgeInsets safeAreaInsets;
	MADViewSafeAreaInserts(self.view, &safeAreaInsets);

	[MADDocumentPageController centerDocumentView: self.documentView
								 insideScrollView: scrollView
								   topLayoutGuide: safeAreaInsets.top
								bottomLayoutGuide: safeAreaInsets.bottom
										   margin: PageEdgeInsetMargin];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view
						atScale:(CGFloat)scale {
	
	UIEdgeInsets safeAreaInsets;
	MADViewSafeAreaInserts(self.view, &safeAreaInsets);

	[MADDocumentPageController centerDocumentView: view
								 insideScrollView: scrollView
								   topLayoutGuide: safeAreaInsets.top
								bottomLayoutGuide: safeAreaInsets.bottom
										   margin: PageEdgeInsetMargin];
	view.contentScaleFactor = scrollView.traitCollection.displayScale * scale;
	[view setNeedsDisplay];
}

#pragma mark -
#pragma mark UIAccessibility

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

#pragma mark -
#pragma mark MADReportPageViewProtocol

- (NSURL *)thumbnailURL {
	return _document.thumbnailURL;
}

- (NSURL *)documentURL {
	return _document.fileURL;
}

- (NSDate * _Nullable)lastCacheDate {
	if (self.pageViewAttributes.reportLastCacheDate == nil) {
		NSError *error = nil;
		NSString *path = self.document.urlDataTableCache.path;
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path error: &error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "Error: %@", error);
		} else {
			self.pageViewAttributes.reportLastCacheDate = [attributes fileModificationDate];
		}
	}
	return self.pageViewAttributes.reportLastCacheDate;
}

#pragma mark -
#pragma mark MADPrintingProtocol

- (MADPrintPageRenderer *)printPageRenderer {
	return [self.delegate printPageRenderer];
}

@end
