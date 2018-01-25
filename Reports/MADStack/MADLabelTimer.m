//
//  MADLabelTimer.m
//  MAD Designer
//
//  Created by Michael on 3/2/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelTimer.h"
#import <UIKit/UILabel.h>
#import <MADDataStructures/MTPair.h>
#import "NSDate+Extras.h"

static NSString * const MADTextNoCache = @"No Cache";

@interface MADLabelTimer ()

    @property (nonatomic, weak) UILabel *label;
    @property (nonatomic, strong) MADDateFromTimeFormatter *dateTimeFormatter;
    @property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;
    @property (nonatomic, strong) NSDate *lastCacheDate;


@end

@implementation MADLabelTimer

void invalidateTimer(NSTimer *);
void invalidateTimer(NSTimer *t) {
    if (t != nil) {
        if ([t respondsToSelector:@selector(isValid)]) {
            if (t.valid) {
                [t invalidate];
            }
        }
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIView *view = [[UIView alloc] initWithFrame:frame];
        UIColor *bgColor = [[UIColor alloc] initWithWhite:0.0000f alpha:0.5000f];
        view.backgroundColor = bgColor;
        view.userInteractionEnabled = NO;
        view.layer.cornerRadius =  6.0000f;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x,
                                                                   CGPointZero.y,
                                                                   frame.size.width,
                                                                   frame.size.height)];
        label.font = [UIFont systemFontOfSize:[UIFont systemFontSize] - 2.0000f];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = NO;
        UIColor *textColor = [UIColor whiteColor];
        label.textColor = textColor;
        UIColor *backgroundColor = [UIColor clearColor];
        label.backgroundColor = backgroundColor;
        
        [view addSubview:label];
        self.label = label;
    }
    return self;
}

- (void)didMoveToWindow {
    if (self.window == nil) {
        invalidateTimer(_timerLabelTimeSinceRefreh);
        _dateTimeFormatter = nil;
    }
}

- (MADDateFromTimeFormatter *)dateTimeFormatter {
    if (_dateTimeFormatter == nil) {
        MADDateFromTimeFormatter *dateTimeFormatter = [[MADDateFromTimeFormatter alloc] init];
        _dateTimeFormatter = dateTimeFormatter;
    }
    return _dateTimeFormatter;
}

- (void)updateWithDate:(NSDate *)lastCacheDate {

    if (lastCacheDate == nil) {
        [self displayNoCache];
    } else {
        
        _lastCacheDate = lastCacheDate.copy;
        NSTimeInterval updateLabelInSeconds = [self displayWithLastCacheDate:lastCacheDate];
        
        invalidateTimer(_timerLabelTimeSinceRefreh);

        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: updateLabelInSeconds
                                                      target: self
                                                    selector: @selector(updateWithTimer:)
                                                    userInfo: _lastCacheDate
                                                     repeats: NO];
        self.timerLabelTimeSinceRefreh = t;
    }

}

- (void)updateWithTimer:(NSTimer *)timer {
    
    if (_lastCacheDate == nil) {
        [self displayNoCache];
    } else {
        
        NSTimeInterval updateLabelInSeconds = [self displayWithLastCacheDate:_lastCacheDate];
        invalidateTimer(_timerLabelTimeSinceRefreh);

        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: updateLabelInSeconds
                                                      target: self
                                                    selector: @selector(updateWithTimer:)
                                                    userInfo: _lastCacheDate
                                                     repeats: NO];
        self.timerLabelTimeSinceRefreh = t;
    }
}

- (void)displayNoCache {
    self.label.text = NSLocalizedString(MADTextNoCache, MADTextNoCache);
}

- (MTDateResolution)displayWithLastCacheDate:(NSDate *)lastCacheDate {
    MTPair *dateStringAndInterval;
    dateStringAndInterval = [self.dateTimeFormatter stringWithTimeIntervalSinceDate:_lastCacheDate];
    self.label.text = [dateStringAndInterval.former copyWithZone:nil];
    return ((NSNumber *)dateStringAndInterval.latter).shortValue;
}

@end
