//
//  MADStringUtilities.m
//  MADFoundation
//
//  Created by Michael on 6/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADStringUtilities.h"

static NSString * const kMADPeriodString = @".";

@implementation MADStringUtilities

+ (NSString *)stringByAppendingPeriod:(NSString *)string {
	if (string.length == 0) { return kMADPeriodString; }
	return [string hasSuffix:kMADPeriodString] ? string : [string stringByAppendingString:kMADPeriodString];
}

+ (NSString *)stringByAppendingKeyPath:(NSString *)keyPath toString:(NSString *)string {
	if (keyPath.length == 0) { return string; }
	return [[self stringByAppendingPeriod:string] stringByAppendingString:keyPath];
}

@end
