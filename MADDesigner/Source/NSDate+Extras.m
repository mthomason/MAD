//
//  NSDate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 6/5/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSDate+Extras.h"
#import <MADDataStructures/MTPair.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSNumberFormatter.h>
#import <math.h>

static inline NSCalendarUnit calUnitsAll(void);
static inline NSCalendarUnit calUnitsAll(void) {
	return NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfMonth |
			NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
}

@interface MADDateFromTimeFormatter()
@property (nonatomic, strong) NSNumberFormatter *formatter;
@end

@implementation MADDateFromTimeFormatter

- (void)dealloc { }

- (instancetype)init {
	if (self = [super init]) {
		NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
		formatter.numberStyle = NSNumberFormatterSpellOutStyle;
		self.formatter = formatter;
	}
	return self;
}

- (NSString *)localizedUnitWithMagnitude:(NSInteger)magnitude format:(NSString *)format {
	NSString *spelled = [self.formatter stringFromNumber:@(magnitude)];
	return [NSString localizedStringWithFormat:format, (long long)magnitude, spelled];
}

- (MTPair *)stringWithTimeIntervalSinceDate:(NSDate *)lastDate {
	MTDateResolution resultResolution = MTDateResolutionDay;

	NSMutableString *unit = [[NSMutableString alloc] init];
	NSDate *now = [NSDate date];
	NSDateComponents *aDateComponents = [[NSCalendar currentCalendar] components: calUnitsAll()
																		fromDate: now
																		  toDate: lastDate
																		 options: 0];

	BOOL forceInclude = YES;
	BOOL printedOne = NO;
	int_fast8_t includedComponetsCounter = 0;
	static const int_fast8_t permittedComponents = 1;

	if (forceInclude && aDateComponents.year != 0) {
		[unit appendString:[self localizedUnitWithMagnitude:ABS(aDateComponents.year)
			format:NSLocalizedString(@"%lld years", @"Relative time unit: years.")]];
		printedOne = YES;
		forceInclude = YES;
		includedComponetsCounter++;
		resultResolution = MTDateResolutionYear;
	}

	if ((forceInclude && aDateComponents.month != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			[unit appendString:[self localizedUnitWithMagnitude:ABS(aDateComponents.month)
				format:NSLocalizedString(@"%lld months", @"Relative time unit: months.")]];
			printedOne = YES;
			forceInclude = YES;
			resultResolution = MTDateResolutionMonth;
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}

	if ((forceInclude && aDateComponents.weekOfMonth != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			[unit appendString:[self localizedUnitWithMagnitude:ABS(aDateComponents.weekOfMonth)
				format:NSLocalizedString(@"%lld weeks", @"Relative time unit: weeks.")]];
			printedOne = YES;
			forceInclude = YES;
			resultResolution = MTDateResolutionWeek;
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}

	if ((forceInclude && aDateComponents.day != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			[unit appendString:[self localizedUnitWithMagnitude:ABS(aDateComponents.day)
				format:NSLocalizedString(@"%lld days", @"Relative time unit: days.")]];
			printedOne = YES;
			forceInclude = YES;
			resultResolution = MTDateResolutionDay;
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}

	if ((forceInclude && aDateComponents.hour != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			[unit appendString:[self localizedUnitWithMagnitude:ABS(aDateComponents.hour)
				format:NSLocalizedString(@"%lld hours", @"Relative time unit: hours.")]];
			printedOne = YES;
			forceInclude = YES;
			resultResolution = MTDateResolutionHour;
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}

	if ((forceInclude && aDateComponents.minute != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			[unit appendString:[self localizedUnitWithMagnitude:ABS(aDateComponents.minute)
				format:NSLocalizedString(@"%lld minutes", @"Relative time unit: minutes.")]];
			printedOne = YES;
			forceInclude = YES;
			resultResolution = MTDateResolutionMinute;
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}

	if ((forceInclude && aDateComponents.second != 0) || (forceInclude && printedOne)) {
		if (includedComponetsCounter < permittedComponents) {
			[unit appendString:[self localizedUnitWithMagnitude:ABS(aDateComponents.second)
				format:NSLocalizedString(@"%lld seconds", @"Relative time unit: seconds.")]];
			printedOne = YES;
			forceInclude = YES;
			resultResolution = MTDateResolutionSecond;
		} else {
			forceInclude = NO;
		}
		includedComponetsCounter++;
	}

	if ((forceInclude && printedOne) || includedComponetsCounter == 0) {
		if (includedComponetsCounter < permittedComponents) {
			NSTimeInterval ti = [lastDate timeIntervalSinceDate:now];
			NSInteger magnitude = (NSInteger)fabs(((ti - (NSTimeInterval)(NSInteger)ti) * 1000.0));
			[unit appendString:[self localizedUnitWithMagnitude:magnitude
				format:NSLocalizedString(@"%lld milliseconds", @"Relative time unit: milliseconds.")]];
			resultResolution = MTDateResolutionMillisecond;
		}
		includedComponetsCounter++;
	}

	NSString *resultText = [NSString localizedStringWithFormat:
		NSLocalizedString(@"Updated %@ ago.", @"Relative update time; %@ is the duration, e.g. two hours."),
		unit];
	NSNumber *resultType = [[NSNumber alloc] initWithShort: resultResolution];
	return [[MTPair alloc] initWithFormer:resultText andLatter:resultType];
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
