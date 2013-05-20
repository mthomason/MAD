//
//  MTViewControllerReportPage.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerReportPageViewController.h"

@interface MTReportViewerReportPageViewController ()

@property (nonatomic, assign, readwrite) NSUInteger pageNumber;
@property (atomic, retain) MTReportViewerReportPageView *renderedReportView;

@end

@implementation MTReportViewerReportPageViewController

- (void)dealloc {
    [_document release];
    [_renderedReportView release];
    [super dealloc];
}

- (id)initWithPageNumber:(NSUInteger)pageNumber {
    self = [super initWithNibName:nil bundle:nil];
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
    MTReportViewerReportPageView *renderedReportView = [[MTReportViewerReportPageView alloc] initWithFrame:[[self view] bounds]];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
