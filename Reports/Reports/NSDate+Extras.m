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

    MTDateResolution resultResolution;
    NSMutableString *result = [[NSMutableString alloc] initWithString:@"Updated "];
    NSDate *now = [NSDate date];
    NSCalendar *aCalender = [NSCalendar currentCalendar];
    NSDateComponents *aDateComponents = [aCalender components: (NSYearCalendarUnit | NSMonthCalendarUnit |
                                                                NSWeekCalendarUnit | NSDayCalendarUnit |
                                                                NSHourCalendarUnit | NSMinuteCalendarUnit |
                                                                NSSecondCalendarUnit)
                                                     fromDate: now
                                                       toDate: lastDate
                                                      options: 0];

    NSString *format;
    BOOL forceInclude = YES;
    NSInteger includedComponetsCounter = 0;
    static NSInteger permittedComponents = 1;
    BOOL printedOne = NO;
    if (forceInclude && [aDateComponents year] != 0) {
        
        NSInteger year = ABS([aDateComponents year]);
        NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(year)
                                                                numberStyle: NSNumberFormatterSpellOutStyle];
        if (year == 1) {
            format = NSLocalizedString(@"%@ year", @"%@ year");
        } else {
            format = NSLocalizedString(@"%@ years", @"%@ years");
        }
        [result appendFormat:format, spelledOut];
        printedOne = YES;
        forceInclude = YES;
        [result appendString:@" "];
        includedComponetsCounter++;
        resultResolution = MTDateResolutionYear;
    }
    
    if ((forceInclude && [aDateComponents month] != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            NSInteger month = ABS([aDateComponents month]);
            NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(month)
                                                                    numberStyle: NSNumberFormatterSpellOutStyle];
            if (month == 1) {
                format = NSLocalizedString(@"%@ month", @"%@ month");
            } else {
                format = NSLocalizedString(@"%@ months", @"%@ months");
            }
            [result appendFormat:format, spelledOut];
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
            
            NSInteger week = ABS([aDateComponents week]);
            NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(week)
                                                                    numberStyle: NSNumberFormatterSpellOutStyle];
            if (week == 1) {
                format = NSLocalizedString(@"%@ week", @"%@ week");
            } else {
                format = NSLocalizedString(@"%@ weeks", @"%@ weeks");
            }
            [result appendFormat:format, spelledOut];
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
            
            NSInteger day = ABS([aDateComponents day]);
            NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(day)
                                                                    numberStyle: NSNumberFormatterSpellOutStyle];
            if (day == 1) {
                format = NSLocalizedString(@"%@ day", @"%@ day");
            } else {
                format = NSLocalizedString(@"%@ days", @"%@ days");
            }
            [result appendFormat:format, spelledOut];
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
            
            NSInteger hour = ABS([aDateComponents hour]);
            NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(hour)
                                                                    numberStyle: NSNumberFormatterSpellOutStyle];
            if (hour == 1) {
                format = NSLocalizedString(@"%@ hour", @"%@ hour");
            } else {
                format = NSLocalizedString(@"%@ hours", @"%@ hours");
            }
            [result appendFormat:format, spelledOut];
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

            NSInteger minute = ABS([aDateComponents minute]);
            NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(minute)
                                                                    numberStyle: NSNumberFormatterSpellOutStyle];
            if (minute == 1) {
                format = NSLocalizedString(@"%@ minute", @"%@ minute");
            } else {
                format = NSLocalizedString(@"%@ minutes", @"%@ minutes");
            }
            [result appendFormat:format, spelledOut];
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
            
            NSInteger second = ABS([aDateComponents second]);
            NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(second)
                                                                    numberStyle: NSNumberFormatterSpellOutStyle];
            if (second == 1) {
                format = NSLocalizedString(@"%@ second", @"%@ second");
            } else {
                format = NSLocalizedString(@"%@ seconds", @"%@ seconds");
            }
            [result appendFormat:format, spelledOut];
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
            NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber: @(milliseconds)
                                                                    numberStyle: NSNumberFormatterSpellOutStyle];
            if (milliseconds == 1) {
                format = NSLocalizedString(@"%@ millisecond", @"%@ millisecond");
            } else {
                format = NSLocalizedString(@"%@ milliseconds", @"%@ milliseconds");
            }
            [result appendFormat:format, spelledOut];
            printedOne = YES;
            forceInclude = YES;
            [result appendString:@" "];
            resultResolution = MTDateResolutionMillisecond;
        } else {
            forceInclude = NO;
        }
        includedComponetsCounter++;
    }

    
    
    
    [result appendString: NSLocalizedString(@"ago.", @"ago.")];
    //if ([result isEqualToString:NSLocalizedString(@"ago.", @"ago.")]) {
    //    BOOL bre = YES;
    //}
    NSNumber *resultType = [@(resultResolution) retain];
    MTPair *results = [[MTPair pairWithFormer:result andLatter:@(resultResolution)] retain];
    [resultType release];
    [result release];
	return [results autorelease];
}

@end
