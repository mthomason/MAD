//
//  MTViewPrintPageRenderReport.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportViewerReportPageView.h"
#import <MADDataStructures/MTPair.h>
#import "NSDate+Extras.h"

static NSString * const PageNumber = @"Page %@";

static const CGFloat PageCounterWidth = 99.0000f;
static const CGFloat PageCounterHeight = 33.0000f;
static const CGFloat PageCounterBuffer = 10.0000f;

@interface MTReportViewerReportPageView ()

    @property (nonatomic, weak) UILabel *timeSinceRefrehLabel;
    @property (nonatomic, strong) UIView *timeSinceRefreshView;
    @property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;
    @property (nonatomic, assign) bool firstTime;
    @property (nonatomic, assign) bool displaysPageCounter;
    @property (nonatomic, assign) bool displaysCacheTimer;

@end

@implementation MTReportViewerReportPageView

- (void)dealloc {
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
    }
    _delegate = nil;
    _delegatePage = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.firstTime) {
        self.firstTime = false;
        if (self.displaysCacheTimer) {
            [self addTimerView];
            [self updateLateRefreshedLabel:self];
        }
        if (self.displaysPageCounter) {
            [self displayPageCounterIndicator];
        }
    }
}

- (void)drawRect:(CGRect)rect {
    if (!self.drawBlankPage) {
        [self.delegate drawView:self inRect:rect];
    }
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    NSString *pageNumber = [NSNumberFormatter localizedStringFromNumber: @([self.delegatePage pageNumber])
                                                               numberStyle: NSNumberFormatterSpellOutStyle];
    NSString *formatString = NSLocalizedString(PageNumber, PageNumber);
    return [NSString stringWithFormat:formatString, pageNumber.capitalizedString];
}

#pragma mark

- (void)initalize {
    self.displaysCacheTimer = false;
    self.displaysPageCounter = false;
    self.drawBlankPage = false;
    self.firstTime = true;
}

#pragma mark

- (UIView *)displayPageCounterIndicator {

    UIView *numberView = [[UIView alloc] initWithFrame:CGRectMake(CGPointZero.x + self.bounds.size.width - PageCounterWidth - PageCounterBuffer,
                                                                  CGPointZero.y + PageCounterBuffer,
                                                                  PageCounterWidth,
                                                                  PageCounterHeight)];
    UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.5000f];
    numberView.backgroundColor = bgColor;
    numberView.userInteractionEnabled = NO;
    numberView.alpha = 0.0000f;
    numberView.layer.cornerRadius =  6.0000f;
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y,
                                                                   PageCounterWidth, PageCounterHeight)];
    labelView.text = [NSString stringWithFormat: @"%lu of %lu",
                                                    (unsigned long)[self.delegatePage pageNumber],
                                                    (unsigned long)[self.delegatePage numberOfPages]];
    labelView.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 1.0000f];
    labelView.textColor = [UIColor whiteColor];
    labelView.textAlignment = NSTextAlignmentCenter;
    labelView.userInteractionEnabled = NO;
    labelView.backgroundColor = [UIColor clearColor];
    [numberView addSubview:labelView];
    
    [self addSubview:numberView];

    [UIView animateWithDuration:0.3000f delay:0.0000f
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            
                            numberView.alpha = 1.0000f;
                            
                        } completion:^(BOOL finished) {
                            
                            if (finished) {
                                [UIView animateWithDuration:0.30000f delay:1.0000f
                                                    options:UIViewAnimationOptionCurveEaseOut animations:^{
                                                        numberView.alpha = 0.0000f;
                                                    } completion:nil];
                            }
                        }];
    return nil;
}

- (void)addTimerView {
    if (self.timeSinceRefreshView == nil) {
        CGRect viewFrame = CGRectMake(self.frame.size.width - 220.0000f, self.frame.size.height - 23.0000f,
                                      220.0000f, 23.0000f);
        UIView *view = [[UIView alloc] initWithFrame:viewFrame];
        UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.5000f];
        view.backgroundColor = bgColor;
        view.userInteractionEnabled = NO;
        view.alpha = 0.0000f;
        view.layer.cornerRadius =  6.0000f;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, viewFrame.size.width, viewFrame.size.height)];
        label.font = [UIFont systemFontOfSize:[UIFont systemFontSize] - 2.0000f];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = NO;
        UIColor *textColor = [UIColor whiteColor];
        label.textColor = textColor;
        UIColor *backgroundColor = [UIColor clearColor];
        label.backgroundColor = backgroundColor;
        
        [view addSubview:label];
        [self addSubview:view];
        
        __weak UIView *blockView = view;
        [UIView animateWithDuration:0.3000f delay:0.0900f options:UIViewAnimationOptionCurveEaseIn animations:^{
            blockView.alpha = 1.0000f;
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.30000f delay:2.0000f
                                    options:UIViewAnimationOptionCurveEaseOut animations:^{
                                        blockView.alpha = 0.0000f;
                                    } completion:nil];
            }
        }];
        
        self.timeSinceRefrehLabel = label;
        self.timeSinceRefreshView = view;
    }
}

- (void)updateLateRefreshedLabel:(id)sender {

    NSDate * _Nullable lastCacheDate = [self.delegatePage lastCacheDate];
    if (lastCacheDate == nil) {
        self.timeSinceRefrehLabel.text = @"No Cache";
        
    } else {
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:lastCacheDate];
        self.timeSinceRefrehLabel.text = dateStringAndInterval.former;
        MTDateResolution resolution = ((NSNumber *)dateStringAndInterval.latter).integerValue;
        
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
        
        if (self.timerLabelTimeSinceRefreh != nil) {
            if ([self.timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
                if ([self.timerLabelTimeSinceRefreh isValid]) {
                    [self.timerLabelTimeSinceRefreh invalidate];
                }
            }
            self.timerLabelTimeSinceRefreh = nil;
        }
        
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: updateLabelInSeconds target:self
                                                    selector: @selector(updateLateRefreshedLabel:) userInfo:nil
                                                     repeats: NO];
        self.timerLabelTimeSinceRefreh = t;
    }
}


@end
