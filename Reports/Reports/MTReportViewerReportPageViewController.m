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

@property (nonatomic, retain) MTReportViewerReportPageView *renderedReportView;

@property (nonatomic, retain) UIView *pageNumberDisplay;

@property (nonatomic, assign) BOOL showPageNumberDisplay;
@property (nonatomic, retain) NSTimer *timerLabelTimeSinceRefreh;
@property (nonatomic, retain) UIView *timeSinceRefreshView;
@property (nonatomic, retain) UILabel *timeSinceRefrehLabel;

@end

@implementation MTReportViewerReportPageViewController

- (void)updateLateRefreshedLabel:(id)sender {
    if ([self lastCacheDate] == nil) {
        NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        NSDate *lastD = [[[query hasQueryCache] cacheDate] retain];
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
    NSTimer *t = [[NSTimer scheduledTimerWithTimeInterval:updateLabelInSeconds target:self
                                                 selector:@selector(updateLateRefreshedLabel:) userInfo:nil
                                                  repeats:NO] retain];
    [self setTimerLabelTimeSinceRefreh:t];
    [t release];
    
}


- (void)dealloc {
    [_lastCacheDate release];
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        [_timerLabelTimeSinceRefreh release];
        _timerLabelTimeSinceRefreh = nil;
    }

    [_document release];
    [_renderedReportView release];
    [_pageNumberDisplay release];
    [super dealloc];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self view] setBackgroundColor:[UIColor purpleColor]];
    [[self view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self view] setClipsToBounds:YES];
    MTReportViewerReportPageView *renderedReportView = [[MTReportViewerReportPageView alloc] initWithFrame:[[self view] bounds]];
    [renderedReportView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [renderedReportView setBackgroundColor:[UIColor greenColor]];
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
    if ([self showPageNumberDisplay]) {
        [self addTimerView];
        [self updateLateRefreshedLabel:self];

        [self pageNumberViewForPageNumber:[self pageNumber] of:[self numberOfPages]];
        
    } else {
        [self setShowPageNumberDisplay:YES];
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

- (void)addTimerView {
    if ([self timeSinceRefreshView] == nil) {
        CGFloat width = 220.0000f;
        CGFloat height = 23.0000f;
        CGFloat originX = self.renderedReportView.frame.size.width - width;
        CGFloat originY = self.renderedReportView.frame.size.height - height;
        CGRect viewFrame = CGRectMake(originX, originY, width, height);
        __block UIView *view = [[UIView alloc] initWithFrame:viewFrame];
        CGRect labelFrame = CGRectMake(CGPointZero.x, CGPointZero.y, viewFrame.size.width, viewFrame.size.height);
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        [label setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]-2.0000f]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setUserInteractionEnabled:NO];
        [view setUserInteractionEnabled:NO];
        UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.7000f];
        [view setBackgroundColor:bgColor];
        [label setBackgroundColor:[UIColor clearColor]];
        
        [view addSubview:label];
        [view setAlpha:0.0000f];
        [[view layer] setCornerRadius: 6.0000f];
        
        [[self renderedReportView] addSubview:view];
        [UIView animateWithDuration:0.3000f animations:^{
            [view setAlpha:1.0000f];
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.30000f delay:5.0000f
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
    __block UIView *numberView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, w, h)];
    [labelView setText:[NSString stringWithFormat:@"%d of %d", pageNumber, numberOfPages]];
    [labelView setFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]+1.0000f]];
    [labelView setTextColor:[UIColor whiteColor]];
    [labelView setTextAlignment:NSTextAlignmentCenter];
    UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.7000f];
    [numberView setBackgroundColor:bgColor];
    [numberView setUserInteractionEnabled:NO];
    [labelView setUserInteractionEnabled:NO];
    [labelView setBackgroundColor:[UIColor clearColor]];
    [[numberView layer] setCornerRadius: 6.0000f];
    [numberView addSubview:labelView];
    [labelView autorelease];
    [numberView setAlpha:0.0000f];
    [[self renderedReportView] addSubview:numberView];
    
    
    [UIView animateWithDuration:0.3000f animations:^{
        [numberView setAlpha:1.0000f];
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.30000f delay:1.0000f
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                [numberView setAlpha:0.0000f];
            } completion:nil ];
        }
    }];
    
    return [numberView autorelease];
}

@end
