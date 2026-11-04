//
//  MADStandard.m
//  MADExplorer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADStandard.h"
#import <Foundation/NSBundle.h>
#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSString.h>
#include <string>
#include <cmath>

@implementation MADStandard

+ (NSString *)standardStringForDouble:(double)d {
	std::string d_str = std::to_string(d);
	const char *c_str = d_str.c_str();
	id result = [[NSString alloc] initWithUTF8String: c_str];
	return result;
}

+ (NSString *)standardStringForUnsignedLong:(unsigned long)ul {
	std::string d_str = std::to_string(ul);
	const char *c_str = d_str.c_str();
	id result = [[NSString alloc] initWithUTF8String: c_str];
	return result;
}

+ (NSString *)standardStringForFileSize:(unsigned long long)filesize {
	// The user's locale supplies the decimal and grouping separators; the unit
	// is part of the localized format so it can be translated or reordered.
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.minimumFractionDigits = 3;
	formatter.maximumFractionDigits = 3;
	double megabytes = round((filesize / 1000000.0) * 1000.0) / 1000.0;
	NSString *number = [formatter stringFromNumber:@(megabytes)];
	return [[NSString alloc] initWithFormat:
		NSLocalizedString(@"%@ MB", @"File size in megabytes; %@ is the formatted number."),
		number];
}

@end
