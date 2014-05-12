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
#import "AppDelegate.h"
#import "NSDate+Extras.h"
#import "MTApplicationInstance.h"
#import "MTPair.h"
@interface MTReportViewerReportPageViewController ()

@property (nonatomic, assign) NSUInteger pageNumber;
@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) BOOL showPageNumberDisplay;

@property (nonatomic, strong) UIView *pageNumberDisplay;
@property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;

@property (nonatomic, strong) UIView *timeSinceRefreshView;
@property (nonatomic, strong) UIView *pageNumberView;
@property (nonatomic, strong) UILabel *timeSinceRefrehLabel;

//@property (nonatomic, strong) UISlider *pageSlider;

@end

@implementation MTReportViewerReportPageViewController

- (void)dealloc {
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
        _timerLabelTimeSinceRefreh = nil;
    }
    _delegate = nil;
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
    MTReportViewerReportPageView *renderedReportView = [[MTReportViewerReportPageView alloc] initWithFrame:CGRectZero];
    [renderedReportView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [renderedReportView setTranslatesAutoresizingMaskIntoConstraints:YES];
    UIColor *whiteColor = [UIColor whiteColor];
    [renderedReportView setBackgroundColor:whiteColor];
    [renderedReportView setDelegate:self];
    [self setView:renderedReportView];
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
    NSInteger index = [self pageNumber] - 1;
    [[self delegate] drawPage:index
                              inRect:rect];
}

- (void)addTimerView {
    if ([self timeSinceRefreshView] == nil) {
        CGFloat width = 220.0000f;
        CGFloat height = 23.0000f;
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
        [[view layer] setCornerRadius: 6.0000f];
        
        [[self view] addSubview:view];
        [UIView animateWithDuration:0.3000f delay:0.0900f options:UIViewAnimationOptionCurveEaseIn animations:^{
            [view setAlpha:1.0000f];
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.30000f delay:2.0000f
                                    options:UIViewAnimationOptionCurveEaseOut animations:^{
                                        [view setAlpha:0.0000f];
                                    } completion:nil];
            }
        }];

        [self setTimeSinceRefrehLabel:label];
        [self setTimeSinceRefreshView: view];
    }

}

- (void)updateLateRefreshedLabel:(id)sender {
    if ([self lastCacheDate] == nil) {
        
        MTApplicationInstance *applicationInstance = [AppDelegate app];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        NSURL *cachedDataUrl = [reportDocument cachedDataUrl];
        NSString *cachedDataPath = [cachedDataUrl path];
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachedDataPath error:&error];
        if (error == nil) {
            NSDate *lastD = [attributes fileModificationDate];
            [self setLastCacheDate: lastD];
        }
    }
    
    if ([self lastCacheDate] == nil) {
        [[self timeSinceRefrehLabel] setText:@"No Cache"];
        
    } else {
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:[self lastCacheDate]];
        NSString *display = [dateStringAndInterval former];
        [[self timeSinceRefrehLabel] setText:display];
        
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
}

- (UIView *)pageNumberViewForPageNumber:(NSUInteger)pageNumber of:(NSUInteger)numberOfPages {
    CGFloat w = 99.0000f;
    CGFloat h = 33.0000f;
    CGFloat y = CGPointZero.y + 10.0000f;
    CGFloat x = CGPointZero.x + self.view.bounds.size.width - w - y;
    
    UIView *numberView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, w, h)];
    [labelView setText:[NSString stringWithFormat:@"%lu of %lu", (unsigned long)pageNumber, (unsigned long)numberOfPages]];
    [labelView setFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 1.0000f]];
    [labelView setTextColor:[UIColor whiteColor]];
    [labelView setTextAlignment:NSTextAlignmentCenter];
    UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.5000f];
    [numberView setBackgroundColor:bgColor];
    [numberView setUserInteractionEnabled:NO];
    [labelView setUserInteractionEnabled:NO];
    [labelView setBackgroundColor:[UIColor clearColor]];
    [[numberView layer] setCornerRadius: 6.0000f];
    [numberView addSubview:labelView];
    [numberView setAlpha:0.0000f];
    [[self view] addSubview:numberView];
    [self setPageNumberView:numberView];
    
    [UIView animateWithDuration:0.3000f delay:0.0000f options:UIViewAnimationOptionCurveEaseIn animations:^{
        [[self pageNumberView] setAlpha:1.0000f];
    } completion:^(BOOL finished) {
        
        if (finished) {
            [UIView animateWithDuration:0.30000f delay:1.0000f
                                options:UIViewAnimationOptionCurveEaseOut animations:^{
                                    [[self pageNumberView] setAlpha:0.0000f];
                                } completion:nil];
        }
    }];
    return nil;
}

@end
