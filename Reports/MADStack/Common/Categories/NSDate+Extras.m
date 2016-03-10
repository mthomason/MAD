//
//  NSDate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSDate+Extras.h"
#import <MADDataStructures/MTPair.h>

static NSString * const FormatYear          = @"%@ year ";
static NSString * const FormatYears         = @"%@ years ";
static NSString * const FormatMonth         = @"%@ month ";
static NSString * const FormatMonths        = @"%@ months ";
static NSString * const FormatWeek          = @"%@ week ";
static NSString * const FormatWeeks         = @"%@ weeks ";
static NSString * const FormatDay           = @"%@ day ";
static NSString * const FormatDays          = @"%@ days ";
static NSString * const FormatHour          = @"%@ hour ";
static NSString * const FormatHours         = @"%@ hours ";
static NSString * const FormatMinute        = @"%@ minute ";
static NSString * const FormatMinutes       = @"%@ minutes ";
static NSString * const FormatSecond        = @"%@ second ";
static NSString * const FormatSeconds       = @"%@ seconds ";
static NSString * const FormatMillisecond   = @"%@ millisecond ";
static NSString * const FormatMilliseconds  = @"%@ milliseconds ";

static NSString * const TextAgo = @"ago.";

@interface MADDateFromTimeFormatter()

@property (nonatomic, strong) NSNumberFormatter *formatter;

@end

@implementation MADDateFromTimeFormatter

static inline NSCalendarUnit calUnitsAll();
static inline NSCalendarUnit calUnitsAll() {
    return NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
}

static inline NSString *LocalizedFormatYears(NSInteger i);
static inline NSString *LocalizedFormatYears(NSInteger i) {
    return i == 1 ? NSLocalizedString(FormatYear, FormatYear) : NSLocalizedString(FormatYears, FormatYears);
}

static inline NSString *LocalizedFormatMonths(NSInteger i);
static inline NSString *LocalizedFormatMonths(NSInteger i) {
    return i == 1 ? NSLocalizedString(FormatMonth, FormatMonth) : NSLocalizedString(FormatMonths, FormatMonths);
}

+ (NSString *)LocalizedFormatFormatMinutes:(NSInteger)i {
    return i == 1 ? NSLocalizedString(FormatMinute, FormatMinute) : NSLocalizedString(FormatMinutes, FormatMinutes);
}

static inline NSString *LocalizedFormatSeconds(NSInteger i);
static inline NSString *LocalizedFormatSeconds(NSInteger i) {
    return i == 1 ? NSLocalizedString(FormatSecond, FormatSecond) : NSLocalizedString(FormatSeconds, FormatSeconds);
}

static inline NSString *LocalizedFormatMilliseconds(NSInteger i);
static inline NSString *LocalizedFormatMilliseconds(NSInteger i) {
    return i == 1 ? NSLocalizedString(FormatMillisecond, FormatMillisecond) : NSLocalizedString(FormatMilliseconds, FormatMilliseconds);
}

- (instancetype)init {
    if (self = [super init]) {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterSpellOutStyle;
        self.formatter = formatter;
    }
    return self;
}

- (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate {
    MTDateResolution resultResolution;
    
    NSMutableString *text = [[NSMutableString alloc] initWithString:@"Updated "];
    NSDate *now = [NSDate date];
    NSCalendar *aCalender = [NSCalendar currentCalendar];
    NSDateComponents *aDateComponents = [aCalender components: calUnitsAll()
                                                     fromDate: now
                                                       toDate: lastDate
                                                      options: 0];
    
    NSString *format;
    bool forceInclude = true;
    bool printedOne = false;
    int_fast8_t includedComponetsCounter = 0;
    static const int_fast8_t permittedComponents = 1;
    
    if (forceInclude && aDateComponents.year != 0) {
        
        NSNumber *year = @(ABS(aDateComponents.year));
        NSString *spelledOut = [self.formatter stringFromNumber: year];
        [text appendFormat:LocalizedFormatYears(aDateComponents.year), spelledOut];
        printedOne = true;
        forceInclude = true;
        includedComponetsCounter++;
        resultResolution = MTDateResolutionYear;
    }
    
    if ((forceInclude && aDateComponents.month != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            NSNumber *month = @(ABS(aDateComponents.month));
            NSString *spelledOut = [self.formatter stringFromNumber: month];
            NSString *format = LocalizedFormatMonths(aDateComponents.month);
            [text appendFormat:format, spelledOut];
            printedOne = true;
            forceInclude = true;
            resultResolution = MTDateResolutionMonth;
        } else {
            forceInclude = false;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && aDateComponents.weekOfMonth != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            
            NSNumber *week = @(ABS(aDateComponents.weekOfMonth));
            NSString *spelledOut = [self.formatter stringFromNumber: week];
            NSString *format = aDateComponents.weekOfMonth == 1 ? NSLocalizedString(FormatWeek, FormatWeek) : NSLocalizedString(FormatWeeks, FormatWeeks);
            [text appendFormat:format, spelledOut];
            printedOne = true;
            forceInclude = true;
            resultResolution = MTDateResolutionWeek;
        } else {
            forceInclude = false;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && aDateComponents.day != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            
            NSNumber *day = @(ABS(aDateComponents.day));
            NSString *spelledOut = [self.formatter stringFromNumber: day];
            format = aDateComponents.day == 1 ? NSLocalizedString(FormatDay, FormatDay) : NSLocalizedString(FormatDays, FormatDays);
            [text appendFormat:format, spelledOut];
            printedOne = true;
            forceInclude = true;
            resultResolution = MTDateResolutionDay;
        } else {
            forceInclude = false;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && aDateComponents.hour != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            @autoreleasepool {
                NSNumber *hour = @(ABS(aDateComponents.hour));
                NSString *spelledOut = [self.formatter stringFromNumber: hour];
                format = aDateComponents.hour == 1 ? NSLocalizedString(FormatHour, FormatHour) : NSLocalizedString(FormatHours, FormatHours);
                [text appendFormat:format, spelledOut];
                printedOne = true;
                forceInclude = true;
                resultResolution = MTDateResolutionHour;
            }
        } else {
            forceInclude = false;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && aDateComponents.minute != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            @autoreleasepool {
                NSNumber *minute = @(ABS(aDateComponents.minute));
                NSString *spelledOut = [self.formatter stringFromNumber: minute];
                NSString *format = [MADDateFromTimeFormatter LocalizedFormatFormatMinutes:aDateComponents.minute];
                [text appendFormat:format, spelledOut];
                printedOne = true;
                forceInclude = true;
                resultResolution = MTDateResolutionMinute;
            }
        } else {
            forceInclude = false;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && aDateComponents.second != 0) || (forceInclude && printedOne)) {
        if (includedComponetsCounter < permittedComponents) {
            @autoreleasepool {
                NSNumber *second = @(ABS(aDateComponents.second));
                NSString *spelledOut = [self.formatter stringFromNumber: second];
                NSString *format = LocalizedFormatSeconds(aDateComponents.second);
                [text appendFormat:format, spelledOut];
                printedOne = true;
                forceInclude = true;
                resultResolution = MTDateResolutionSecond;
            }
        } else {
            forceInclude = false;
        }
        includedComponetsCounter++;
    }
    
    if ((forceInclude && printedOne) || includedComponetsCounter == 0) {
        
        if (includedComponetsCounter < permittedComponents) {
            NSTimeInterval ti = [lastDate timeIntervalSinceDate:now];
            NSNumber *milliseconds = @((NSInteger)fabs(((ti - (NSInteger)ti) * 1000)));
            NSString *spelledOut = [self.formatter stringFromNumber: milliseconds];
            format = LocalizedFormatMilliseconds(milliseconds.integerValue);
            [text appendFormat:format, spelledOut];
            resultResolution = MTDateResolutionMillisecond;
        }
        includedComponetsCounter++;
    }
    
    [text appendString: NSLocalizedString(TextAgo, TextAgo)];
    
    NSNumber *resultType = @(resultResolution);
    return [MTPair pairWithFormer:text andLatter:resultType];
}

+ (NSTimeInterval)timeIntervalForResolution:(MTDateResolution)resolution {
    switch (resolution) {
        case MTDateResolutionDay:
            return 86400.0;
            break;
        case MTDateResolutionHour:
            return 3600.0;
            break;
        case MTDateResolutionMinute:
            return 60.0;
            break;
        case MTDateResolutionSecond:
            return 1.0;
            break;
        case MTDateResolutionMillisecond:
            return 0.1;
            break;
        default:
            return 86400.0;
            break;
    }
}

@end
