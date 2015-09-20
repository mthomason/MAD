//
//  NSDateFormatter+RFC_3339.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSDateFormatter+RFC_3339.h"

@implementation NSDateFormatter (RFC_3339)

+ (instancetype) RFC_3339 {
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    rfc3339DateFormatter.locale = enUSPOSIXLocale;
    rfc3339DateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    rfc3339DateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return rfc3339DateFormatter;
}

@end
