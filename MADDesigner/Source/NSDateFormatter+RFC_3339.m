//
//  NSDateFormatter+RFC_3339.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSDateFormatter+RFC_3339.h"
#import <Foundation/NSLocale.h>
#import <Foundation/NSTimeZone.h>

@implementation NSDateFormatter (RFC_3339)

+ (instancetype)RFC_3339 {
	NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
	NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	rfc3339DateFormatter.locale = enUSPOSIXLocale;
	// The trailing token used to be a literal 'Z', which made the formatter accept only
	// that one spelling of UTC. RFC 3339 also allows a numeric offset ("+02:00"), and a
	// server timestamp using it was silently dropped. XXXXX emits "Z" for a zero offset
	// and parses either spelling.
	rfc3339DateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssXXXXX";
	rfc3339DateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	return rfc3339DateFormatter;
}

@end
