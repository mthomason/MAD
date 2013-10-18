//
//  MTViewControllerReportPage.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerReportPageViewController.h"
#import "NSDate+Extras.h"

@interface MTReportViewerReportPageViewController ()

@property (nonatomic, assign) NSUInteger pageNumber;
@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) BOOL showPageNumberDisplay;

@property (nonatomic, retain) UIView *pageNumberDisplay;
@property (nonatomic, retain) NSTimer *timerLabelTimeSinceRefreh;

@property (nonatomic, retain) UIView *timeSinceRefreshView;
@property (nonatomic, retain) UIView *pageNumberView;
@property (nonatomic, retain) UILabel *timeSinceRefrehLabel;

@end

@implementation MTReportViewerReportPageViewController

- (void)dealloc {
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        [_timerLabelTimeSinceRefreh release];
        _timerLabelTimeSinceRefreh = nil;
    }
    [_lastCacheDate release];
    [_timeSinceRefreshView release];
    [_timeSinceRefrehLabel release];
    [_pageNumberView release];
    [_pageNumberDisplay release];
    _delegate = nil;
    [super dealloc];
}

- (void)updateLateRefreshedLabel:(id)sender {
    if ([self lastCacheDate] == nil) {
        MAReportDocument *reportDocument = [[MTActiveDocument sharedDocument] activeDocument];
        RptqDocument *document = [reportDocument activeDocument];
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        RptqQueryCache *queryCache = [query hasQueryCache];
        NSDate *lastD = [[queryCache cacheDate] retain];
        [self setLastCacheDate: lastD];
        [lastD release];
        if ([self lastCacheDate] == nil) {  //I give up
            [self setLastCacheDate:[NSDate date]];
        }
    }
    MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:[self lastCacheDate]];
    [[self timeSinceRefrehLabel] setText:[dateStringAndInterval former]];
    
    MTDateResolution resolution = [[dateStringAndInterval latter] integerValue];
    
    NSTimeInterval updateLabelInSeconds;
    
    switch (resolution) {
        case MTDateResolutionDay:
            updateLabelInSeconds = 86400.0;
            break;
        case MTDateResolutionHour:
            updateLabelInSeconds = 3600.0;
            break;
        case MTDateResolutionMinute:
            updateLabelInSeconds = 60.0;
            break;
        case MTDateResolutionSecond:
            updateLabelInSeconds = 1.0;
            break;
        case MTDateResolutionMillisecond:
            updateLabelInSeconds = 0.1;
            break;
        default:
            updateLabelInSeconds = 86400;
            break;
    }

    if ([self timerLabelTimeSinceRefreh] != nil) {
        if ([[self timerLabelTimeSinceRefreh] respondsToSelector:@selector(isValid)]) {
            if ([[self timerLabelTimeSinceRefreh] isValid]) {
                [[self timerLabelTimeSinceRefreh] invalidate];
            }
        }
        [self setTimerLabelTimeSinceRefreh:nil];
    }
    
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: updateLabelInSeconds target:self
                                                selector: @selector(updateLateRefreshedLabel:) userInfo:nil
                                                 repeats: NO];
    [self setTimerLabelTimeSinceRefreh:t];
}

- (id)initWithPageNumber:(NSUInteger)pageNumber ofPages:(NSUInteger)numberOfPages {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setShowPageNumberDisplay:YES];
        [self setPageNumber:pageNumber];
        [self setNumberOfPages:numberOfPages];
    }
    return self;
}

- (void)loadView {
    //[super loadView];
    MTReportViewerReportPageView *renderedReportView = [[MTReportViewerReportPageView alloc] initWithFrame:CGRectZero];
    [renderedReportView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [renderedReportView setTranslatesAutoresizingMaskIntoConstraints:YES];
    UIColor *whiteColor = [UIColor whiteColor];
    [renderedReportView setBackgroundColor:whiteColor];
    [renderedReportView setDelegate:self];
    [self setView:renderedReportView];
    [renderedReportView release];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self showPageNumberDisplay]) {
        [self addTimerView];
        [self updateLateRefreshedLabel:self];

        [self pageNumberViewForPageNumber:[self pageNumber] of:[self numberOfPages]];
        
    } else {
        [self setShowPageNumberDisplay:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([self timerLabelTimeSinceRefreh] != nil) {
        if ([[self timerLabelTimeSinceRefreh] respondsToSelector:@selector(isValid)]) {
            if ([[self timerLabelTimeSinceRefreh] isValid]) {
                [[self timerLabelTimeSinceRefreh] invalidate];
            }
        }
        [self setTimerLabelTimeSinceRefreh:nil];
    }
}

- (void)drawView:(id)sender inRect:(CGRect)rect {
    [[self delegate] drawPageAtIndex:[self pageNumber] - 1 inRect:rect];
}

- (void)addTimerView {
    if ([self timeSinceRefreshView] == nil) {
        CGFloat width = 220.0000f;
        CGFloat height = 23.0000f;
        NSLog(@"%@", @(self.topLayoutGuide.length));
        CGFloat originX = self.view.frame.size.width - width;
        CGFloat originY = self.view.frame.size.height - height;
        CGRect viewFrame = CGRectMake(originX, originY, width, height);
        __block UIView *view = [[UIView alloc] initWithFrame:viewFrame];
        CGRect labelFrame = CGRectMake(CGPointZero.x, CGPointZero.y, viewFrame.size.width, viewFrame.size.height);
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        [label setFont:[UIFont systemFontOfSize:[UIFont systemFontSize] - 2.0000f]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setUserInteractionEnabled:NO];
        [view setUserInteractionEnabled:NO];
        UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.5000f];
        [view setBackgroundColor:bgColor];
        [label setBackgroundColor:[UIColor clearColor]];
        
        [view addSubview:label];
        [view setAlpha:0.0000f];
        //[[view layer] setCornerRadius: 6.0000f];
        
        [[self view] addSubview:view];
        [UIView animateWithDuration:0.3000f animations:^{
            [view setAlpha:1.0000f];
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.30000f delay:2.0000f
                                    options:UIViewAnimationOptionCurveEaseIn animations:^{
                                        [view setAlpha:0.0000f];
                                    } completion:nil];
            }
        }];

        [self setTimeSinceRefrehLabel:label];
        [self setTimeSinceRefreshView: view];
        [label release];
        [view release];
    }

}


- (UIView *)pageNumberViewForPageNumber:(NSUInteger)pageNumber of:(NSUInteger)numberOfPages {
    CGFloat w = 99.0000f;
    CGFloat h = 33.0000f;
    CGFloat y = CGPointZero.y + 10.0000f;
    CGFloat x = CGPointZero.x + self.view.bounds.size.width - w - y;
    
    UIView *numberView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, w, h)];
    [labelView setText:[NSString stringWithFormat:@"%d of %d", pageNumber, numberOfPages]];
    [labelView setFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 1.0000f]];
    [labelView setTextColor:[UIColor whiteColor]];
    [labelView setTextAlignment:NSTextAlignmentCenter];
    UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.5000f];
    [numberView setBackgroundColor:bgColor];
    [numberView setUserInteractionEnabled:NO];
    [labelView setUserInteractionEnabled:NO];
    [labelView setBackgroundColor:[UIColor clearColor]];
    //[[numberView layer] setCornerRadius: 6.0000f];
    [numberView addSubview:labelView];
    [numberView setAlpha:0.0000f];
    [[self view] addSubview:numberView];
    [self setPageNumberView:numberView];
    
    MTReportViewerReportPageViewController *weakSelf = self;
    [UIView animateWithDuration:0.3000f animations:^{
        
        [[self pageNumberView] setAlpha:1.0000f];

    } completion:^(BOOL finished) {
        
        if (finished) {

            [UIView animateWithDuration:0.30000f delay:1.0000f
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                                    
                                    [[self pageNumberView] setAlpha:0.0000f];

                                } completion:^(BOOL finished) {
                                    
                                    
                                }];
        }
    }];
    [labelView release];
    [numberView release];
    return nil;
}

@end
