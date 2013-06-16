//
//  NSDate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "NSDate+Extras.h"

@implementation NSDate (Extras)

+ (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate {
                       //     resolution: (MTDateResolution) resolution {
	//NSTimeInterval interval = [lastDate timeIntervalSinceNow];
	//NSString *pattern;
    
    unsigned int theUnits;
    
    MTDateResolution resultResolution;
    /*
	if (resolution == MTDateResolutionYear) {

        theUnits = NSYearCalendarUnit;

	} else if (resolution == MTDateResolutionMonth) {

        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit;
        
    } else if (resolution == MTDateResolutionWeek) {

        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit;
	
    } else if (resolution == MTDateResolutionDay) {

        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit;

	} else if (resolution == MTDateResolutionHour) {
		
        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit;
	
    } else if (resolution == MTDateResolutionMinute) {
		
        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
	
    } else if (resolution == MTDateResolutionSecond) {
		
        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	
    } else if (resolution == MTDateResolutionMillisecond) {
        
        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	
    } else {

        theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	
    }
    */
    theUnits = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	
    NSMutableString *result = [[NSMutableString alloc] initWithString:@"Updated "];
    NSDate *now = [NSDate date];
    NSCalendar *aCalender = [NSCalendar currentCalendar];
    NSDateComponents *aDateComponents = [aCalender components:theUnits fromDate:now toDate:lastDate options:0];

    BOOL forceInclude = YES;
    NSInteger includedComponetsCounter = 0;
    static NSInteger permittedComponents = 1;
    BOOL printedOne = NO;
    if (forceInclude && [aDateComponents year] != 0) {
        if (ABS([aDateComponents year]) == 1) {
            [result appendFormat:@"%d year", ABS([aDateComponents year])];
        } else {
            [result appendFormat:@"%d years", ABS([aDateComponents year])];
        }
        printedOne = YES;
        forceInclude = YES;
        [result appendString:@" "];
        includedComponetsCounter++;
        resultResolution = MTDateResolutionYear;
    }
    
    if ((forceInclude && [aDateComponents month] != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            if (ABS([aDateComponents month]) == 1) {
                [result appendFormat:@"%d month", ABS([aDateComponents month])];
            } else {
                [result appendFormat:@"%d months", ABS([aDateComponents month])];
            }
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionMonth;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && [aDateComponents week] != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            if (ABS([aDateComponents week]) == 1) {
                [result appendFormat:@"%d week", ABS([aDateComponents week])];
            } else {
                [result appendFormat:@"%d weeks", ABS([aDateComponents week])];
            }
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionWeek;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && [aDateComponents day] != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            if (ABS([aDateComponents day]) == 1) {
                [result appendFormat:@"%d day", ABS([aDateComponents day])];
            } else {
                [result appendFormat:@"%d days", ABS([aDateComponents day])];
            }
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionDay;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && [aDateComponents hour] != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            if (ABS([aDateComponents hour]) == 1) {
                [result appendFormat:@"%d hour", ABS([aDateComponents hour])];
            } else {
                [result appendFormat:@"%d hours", ABS([aDateComponents hour])];
            }
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionHour;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && [aDateComponents minute] != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            if (ABS([aDateComponents minute]) == 1) {
                [result appendFormat:@"%d minute", ABS([aDateComponents minute])];
            } else {
                [result appendFormat:@"%d minutes", ABS([aDateComponents minute])];
            }
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionMinute;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && [aDateComponents second] != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            if (ABS([aDateComponents second]) == 1) {
                [result appendFormat:@"%d second", ABS([aDateComponents second])];
            } else {
                [result appendFormat:@"%d seconds", ABS([aDateComponents second])];
            }
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionSecond;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }

    if ((forceInclude && printedOne) || includedComponetsCounter == 0) {

        if (includedComponetsCounter < permittedComponents) {
            NSTimeInterval ti = [lastDate timeIntervalSinceDate:now];
            NSInteger secPart = (NSInteger)ti;
            NSTimeInterval goodPart = ti - secPart;
            NSInteger milliseconds = ABS((goodPart * 1000));

            if (milliseconds == 1) {
                [result appendFormat:@"%d millisecond", milliseconds];
            } else {
                [result appendFormat:@"%d milliseconds", milliseconds];
            }
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionMillisecond;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }

    
    
    
    [result appendString: NSLocalizedString(@"ago", @"ago")];
    if ([result isEqualToString:@"ago"]) {
        BOOL bre = YES;
    }
    NSNumber *resultType = [@(resultResolution) retain];
    MTPair *results = [[MTPair pairWithFormer:result andLatter:@(resultResolution)] retain];
    [resultType release];
    [result release];
	return [results autorelease];
}

@end
