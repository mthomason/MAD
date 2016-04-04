//
//  NSDate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSDate_Extras_h
#define Reports_NSDate_Extras_h

#import <UIKit/UIKit.h>

typedef NS_ENUM(short, MTDateResolution) {
	MTDateResolutionYear = 1,
	MTDateResolutionMonth,
    MTDateResolutionWeek,
	MTDateResolutionDay,
    MTDateResolutionHour,
    MTDateResolutionMinute,
    MTDateResolutionSecond,
    MTDateResolutionMillisecond
};

@class MTPair;

@interface MADDateFromTimeFormatter : NSObject

    - (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate;
    + (NSTimeInterval)timeIntervalForResolution:(MTDateResolution)resolution;

@end

#endif
