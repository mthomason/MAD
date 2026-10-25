//
//  NSDate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDateFromTimeFormatter_h
#define Reports_MADDateFromTimeFormatter_h

#import <Foundation/NSObject.h>

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
+ (double)timeIntervalForResolution:(MTDateResolution)resolution;

@end

#endif
