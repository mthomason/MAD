//
//  NSDate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSDate+Extras.h"

#import <Foundation/NSBundle.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSNumberFormatter.h>

#import <MADDataStructures/MTPair.h>

#import <math.h>

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

static inline NSCalendarUnit calUnitsAll(void);
static inline NSString *newStringLocalizedFormatYears(NSInteger);
static inline NSString *newStringLocalizedFormatMonths(NSInteger);
static inline NSString *newStringLocalizedFormatSeconds(NSInteger) __attribute__((unused));
static inline NSString *newStringLocalizedFormatMilliseconds(NSInteger);
static inline NSString *newStringLocalizedFormatFormatMinutes(NSInteger) __attribute__((unused));

static inline NSCalendarUnit calUnitsAll(void) {
	return NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth |
			NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
}

static inline NSString *newStringLocalizedFormatYears(NSInteger i) {
	return i == 1 ? NSLocalizedString(FormatYear, FormatYear) :
					NSLocalizedString(FormatYears, FormatYears);
}

static inline NSString *newStringLocalizedFormatMonths(NSInteger i) {
	return i == 1 ? NSLocalizedString(FormatMonth, FormatMonth) :
					NSLocalizedString(FormatMonths, FormatMonths);
}

static inline NSString *newStringLocalizedFormatSeconds(NSInteger i) {
	return i == 1 ? NSLocalizedString(FormatSecond, FormatSecond) :
					NSLocalizedString(FormatSeconds, FormatSeconds);
}

static inline NSString *newStringLocalizedFormatMilliseconds(NSInteger i) {
	return i == 1 ? NSLocalizedString(FormatMillisecond, FormatMillisecond) :
					NSLocalizedString(FormatMilliseconds, FormatMilliseconds);
}

static inline NSString *newStringLocalizedFormatFormatMinutes(NSInteger i) {
	return i == 1 ? NSLocalizedString(FormatMinute, FormatMinute) :
					NSLocalizedString(FormatMinutes, FormatMinutes);
}

@interface MADDateFromTimeFormatter()
	@property (nonatomic, strong) NSNumberFormatter *formatter;
@end

@implementation MADDateFromTimeFormatter

- (void)dealloc {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype)init {
	if (self = [super init]) {
		NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
		formatter.numberStyle = NSNumberFormatterSpellOutStyle;
		self.formatter = formatter;
	}
	return self;
}

- (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate {
	MTDateResolution resultResolution;
	
	NSMutableString *text = [[NSMutableString alloc] initWithString:@"Updated "];
	NSDate *now = [NSDate date];
	NSDateComponents *aDateComponents = [[NSCalendar currentCalendar] components: calUnitsAll()
																		fromDate: [NSDate date]
																		  toDate: lastDate
																		 options: 0];
	
	BOOL forceInclude = YES;
	BOOL printedOne = NO;
	int_fast8_t includedComponetsCounter = 0;
	static const int_fast8_t permittedComponents = 1;
	NSString *format;
	
	if (forceInclude && aDateComponents.year != 0) {
		
		@autoreleasepool {
			NSNumber *year = @(ABS(aDateComponents.year));
			NSString *spelledOut = [self.formatter stringFromNumber: year];
			[text appendFormat:newStringLocalizedFormatYears(aDateComponents.year), spelledOut];
			printedOne = YES;
			forceInclude = YES;
			includedComponetsCounter++;
			resultResolution = MTDateResolutionYear;
			spelledOut = nil;
			year = nil;
		}
	}
	
	if ((forceInclude && aDateComponents.month != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			@autoreleasepool {
				NSNumber *month = @(ABS(aDateComponents.month));
				NSString *spelledOut = [self.formatter stringFromNumber: month];
				format = newStringLocalizedFormatMonths(aDateComponents.month);
				[text appendFormat:format, spelledOut];
				printedOne = YES;
				forceInclude = YES;
				resultResolution = MTDateResolutionMonth;
				spelledOut = nil;
				format = nil;
				month = nil;
			}
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}
	
	if ((forceInclude && aDateComponents.weekOfMonth != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			@autoreleasepool {
				NSNumber *week = @(ABS(aDateComponents.weekOfMonth));
				NSString *spelledOut = [self.formatter stringFromNumber: week];
				format = aDateComponents.weekOfMonth == 1 ? NSLocalizedString(FormatWeek, FormatWeek) :
															NSLocalizedString(FormatWeeks, FormatWeeks);
				[text appendFormat:format, spelledOut];
				printedOne = YES;
				forceInclude = YES;
				resultResolution = MTDateResolutionWeek;
				spelledOut = nil;
				format = nil;
				week = week;
			}
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}
	
	if ((forceInclude && aDateComponents.day != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			@autoreleasepool {
				NSNumber *day = @(ABS(aDateComponents.day));
				NSString *spelledOut = [self.formatter stringFromNumber: day];
				format = aDateComponents.day == 1 ? NSLocalizedString(FormatDay, FormatDay) :
													NSLocalizedString(FormatDays, FormatDays);
				[text appendFormat:format, spelledOut];
				printedOne = YES;
				forceInclude = YES;
				resultResolution = MTDateResolutionDay;
				spelledOut = nil;
				format = nil;
				day = nil;
			}
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}
	
	if ((forceInclude && aDateComponents.hour != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			@autoreleasepool {
				NSNumber *hour = @(ABS(aDateComponents.hour));
				NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber:hour
																		numberStyle:NSNumberFormatterSpellOutStyle];
				format = aDateComponents.hour == 1 ? NSLocalizedString(FormatHour, FormatHour) :
													 NSLocalizedString(FormatHours, FormatHours);
				[text appendFormat:format, spelledOut];
				printedOne = YES;
				forceInclude = YES;
				resultResolution = MTDateResolutionHour;
				spelledOut = nil;
				format = nil;
				hour = nil;
			}
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}
	
	if ((forceInclude && aDateComponents.minute != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			@autoreleasepool {
				format = aDateComponents.minute == 1 ? NSLocalizedString(FormatMinute, FormatMinute) :
													   NSLocalizedString(FormatMinutes, FormatMinutes);
				NSNumber *minute = @(ABS(aDateComponents.minute));
				NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber:minute
																		numberStyle:NSNumberFormatterSpellOutStyle];
				[text appendFormat:format, spelledOut];
				printedOne = YES;
				forceInclude = YES;
				resultResolution = MTDateResolutionMinute;
				spelledOut = nil;
				format = nil;
				minute = nil;
			}
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}
	
	if ((forceInclude && aDateComponents.second != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			@autoreleasepool {
				format = aDateComponents.second == 1 ? NSLocalizedString(FormatSecond, FormatSecond) :
													   NSLocalizedString(FormatSeconds, FormatSeconds);
				NSNumber *second = @(ABS(aDateComponents.second));
				NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber:second
																		numberStyle:NSNumberFormatterSpellOutStyle];
				//NSString *spelledOut = [self.formatter stringFromNumber: second];
				[text appendFormat:format, spelledOut];
				printedOne = YES;
				forceInclude = YES;
				resultResolution = MTDateResolutionSecond;
				spelledOut = nil;
				format = nil;
				second = nil;
			}
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}
	
	if ((forceInclude && printedOne) || includedComponetsCounter == 0) {
		
		if (includedComponetsCounter < permittedComponents) {
			NSTimeInterval ti = [lastDate timeIntervalSinceDate:now];
			NSNumber *milliseconds = @((NSInteger)fabs(((ti - (NSInteger)ti) * 1000)));
			NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber:milliseconds
																	numberStyle:NSNumberFormatterSpellOutStyle];

			format = newStringLocalizedFormatMilliseconds(milliseconds.integerValue);
			[text appendFormat:format, spelledOut];
			spelledOut = nil;
			format = nil;
			milliseconds = nil;
			resultResolution = MTDateResolutionMillisecond;
		}
		includedComponetsCounter++;
	}
	
	[text appendString: NSLocalizedString(TextAgo, TextAgo)];
	
	NSNumber *resultType = [[NSNumber alloc] initWithShort: resultResolution];
	NSString *resultText = text.copy;
	
	return [MTPair newPairWithFormer: resultText
						   andLatter: resultType];
}

+ (double)timeIntervalForResolution:(MTDateResolution)resolution {
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
