//
//  NSDate+Extras.h
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSDate_Extras_h
#define Reports_NSDate_Extras_h

#import <Foundation/Foundation.h>
#import <MADDataStructures/MADDataStructures.h>

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

@class MTPair;

@interface NSDate (Extras)

+ (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate;

@end

#endif
