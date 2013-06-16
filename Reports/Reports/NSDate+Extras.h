//
//  NSDate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTPair.h"

typedef NS_ENUM(NSUInteger, MTDateResolution) {
	MTDateResolutionYear = 1,
	MTDateResolutionMonth,
    MTDateResolutionWeek,
	MTDateResolutionDay,
    MTDateResolutionHour,
    MTDateResolutionMinute,
    MTDateResolutionSecond,
    MTDateResolutionMillisecond
};

@interface NSDate (Extras)

+ (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate;

@end
