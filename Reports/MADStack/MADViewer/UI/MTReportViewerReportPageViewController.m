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

@interface MTReportViewerReportPageViewController ()
    <UIAccessibilityReadingContent, MADReportViewerReportPageViewProtocol>

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, assign) NSUInteger reportPageNumber;
    @property (nonatomic, assign) NSUInteger reportNumberOfPages;
    @property (nonatomic, strong) NSDate *reportLastCacheDate;

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

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.document = document;
        self.reportPageNumber = pageNumber;
        self.reportNumberOfPages = numberOfPages;
    }
    return self;

}

- (void)loadView {

    MTReportViewerReportPageView *renderedReportView = [[MTReportViewerReportPageView alloc] initWithFrame:CGRectZero];
    UIColor *whiteColor = [UIColor whiteColor];
    renderedReportView.backgroundColor = whiteColor;
    renderedReportView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    renderedReportView.translatesAutoresizingMaskIntoConstraints = YES;
    renderedReportView.delegatePage = self;
    self.view = renderedReportView;

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
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)drawViewInRect:(CGRect)rect {
    [self.delegate drawPage:self.reportPageNumber - 1 inRect:rect];
}

- (NSInteger)accessibilityLineNumberForPoint:(CGPoint)point {
    return 1;
}


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
        NSURL *cachedDataUrl = [self.document cachedDataUrl];
        NSString *cachedDataPath = [cachedDataUrl path];
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedDataPath error:&error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            self.reportLastCacheDate = lastD;
        }
    }
    return self.reportLastCacheDate;
}

@end
