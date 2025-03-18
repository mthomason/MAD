//
//  MADStringUtilities.m
//  MADFoundation
//
//  Created by Michael on 6/3/17.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADStringUtilities.h"

@implementation MADStringUtilities

+ (NSString *)stringByAppendingPeriodToString:(NSString *)string {
	static NSString *period = @".";
	return [string stringByAppendingString:period];
}

+ (NSString *)stringByAppendingKeyPath:(NSString *)keyPath toString:(NSString *)string {
	NSString *stringWithPeriod = [self stringByAppendingPeriodToString:string];
	return [stringWithPeriod stringByAppendingString:keyPath];
}

@end
