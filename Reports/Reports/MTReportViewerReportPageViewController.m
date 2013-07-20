//
//  MTViewControllerReportPage.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerReportPageViewController.h"

@interface MTReportViewerReportPageViewController ()

@property (nonatomic, assign) NSUInteger pageNumber;
@property (nonatomic, assign) NSUInteger numberOfPages;

@property (nonatomic, retain) MTReportViewerReportPageView *renderedReportView;

@property (nonatomic, retain) UIView *pageNumberDisplay;

@end

@implementation MTReportViewerReportPageViewController

- (void)dealloc {
    [_document release];
    [_renderedReportView release];
    [_pageNumberDisplay release];
    [super dealloc];
}

- (id)initWithPageNumber:(NSUInteger)pageNumber ofPages:(NSUInteger)numberOfPages {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setPageNumber:pageNumber];
        [self setNumberOfPages:numberOfPages];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self view] setBackgroundColor:[UIColor whiteColor]];
    [[self view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self view] setClipsToBounds:YES];
    MTReportViewerReportPageView *renderedReportView = [[MTReportViewerReportPageView alloc] initWithFrame:[[self view] bounds]];
    [renderedReportView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [renderedReportView setBackgroundColor:[UIColor whiteColor]];
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
    [self pageNumberViewForPageNumber:[self pageNumber] of:[self numberOfPages]];
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

- (UIView *)pageNumberViewForPageNumber:(NSUInteger)pageNumber of:(NSUInteger)numberOfPages {
    CGFloat w = 66.0000f;
    CGFloat h = 33.0000f;
    CGFloat y = CGPointZero.y + 10.0000f;
    CGFloat x = CGPointZero.x + self.view.bounds.size.width - w - y;
    __block UIView *numberView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, w, h)];
    [labelView setText:[NSString stringWithFormat:@"%d of %d", pageNumber, numberOfPages]];
    [labelView setFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]+1.0000f]];
    [labelView setTextColor:[UIColor whiteColor]];
    [labelView setTextAlignment:NSTextAlignmentCenter];
    [numberView setBackgroundColor:[UIColor darkGrayColor]];
    [numberView setUserInteractionEnabled:NO];
    [labelView setUserInteractionEnabled:NO];
    [labelView setBackgroundColor:[UIColor clearColor]];
    [[numberView layer] setCornerRadius: 6.0000f];
    [numberView addSubview:labelView];
    [labelView autorelease];
    [numberView setAlpha:0.0000f];
    [[self renderedReportView] addSubview:numberView];
    
    [UIView animateWithDuration:0.7000f animations:^{
        [numberView setAlpha:1.0000f];
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.70000f delay:1.7000f
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                [numberView setAlpha:0.0000f];
            } completion:nil ];
        }
    }];
    return [numberView autorelease];
}

@end
