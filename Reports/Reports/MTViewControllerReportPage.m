//
//  MTViewControllerReportPage.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerReportPage.h"

@interface MTViewControllerReportPage ()

@property (nonatomic, assign, readwrite) NSUInteger pageNumber;
@property (atomic, retain) MTPrintPageRendererReport *printRenderData;
@property (atomic, retain) MTViewPrintPageRenderReport *renderedReportView;

@end

@implementation MTViewControllerReportPage

- (void)dealloc {
    [_document release];
    [_renderedReportView release];
    [_printRenderData release];
    [super dealloc];
}

- (id)initWithPageData:(MTPrintPageRendererReport *)pageData andPageNumber:(NSUInteger)pageNumber {
    self = [super init];
    if (self) {
        MTPrintPageRendererReport *printRenderData = [pageData copy];
        [self setPrintRenderData:printRenderData];
        [printRenderData release];
        
        [self setPageNumber:pageNumber];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    MTViewPrintPageRenderReport *renderedReportView = [[MTViewPrintPageRenderReport alloc] initWithFrame:[[self view] frame]
                                                                                              pageNumber:[self pageNumber]
                                                                                      andPrintRenderData:[self printRenderData]];
    [self setRenderedReportView:renderedReportView];
    [renderedReportView release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![[self renderedReportView] isDescendantOfView:[self view]]) {
        [[self view] addSubview:[self renderedReportView]];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[self renderedReportView] isDescendantOfView:[self view]]) {
        [[self renderedReportView] removeFromSuperview];
    }
}

@end