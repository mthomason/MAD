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
@property (atomic, retain) MTViewPrintPageRenderReport *renderedReportView;

@end

@implementation MTViewControllerReportPage

- (void)dealloc {
    [_document release];
    [_renderedReportView release];
    [super dealloc];
}

- (id)initWithPageNumber:(NSUInteger)pageNumber {
    self = [super init];
    if (self) {
        [self setPageNumber:pageNumber];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self view] setBackgroundColor:[UIColor purpleColor]];
    [[self view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self view] setClipsToBounds:YES];
    MTViewPrintPageRenderReport *renderedReportView = [[MTViewPrintPageRenderReport alloc] initWithFrame:[[self view] bounds]];
    //[renderedReportView setCenter:[[self view] center]];
    [renderedReportView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [renderedReportView setBackgroundColor:[UIColor brownColor]];
    [renderedReportView setDelegate:self];
    [self setRenderedReportView:renderedReportView];
    [renderedReportView release];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![[self renderedReportView] isDescendantOfView:[self view]]) {
        [[self view] addSubview:[self renderedReportView]];
        [[self renderedReportView] setBounds:[[self view] bounds]];
        [[self renderedReportView] setCenter:[[self view] center]];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[self renderedReportView] isDescendantOfView:[self view]]) {
        [[self renderedReportView] removeFromSuperview];
    }
}

- (void)drawView:(id)sender inRect:(CGRect)rect {
    [[self delegate] drawPageAtIndex:[self pageNumber] - 1 inRect:rect];
}

@end