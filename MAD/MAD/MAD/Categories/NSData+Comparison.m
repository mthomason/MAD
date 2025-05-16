//
//  NSData+Comparison.m
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "NSData+Comparison.h"
#import <Foundation/Foundation.h>

@implementation NSData (Comparison)

- (NSComparisonResult)compareData:(NSData *)data {
	if (!data) {
		return NSOrderedDescending; // Assume nil data is "less than" valid data
	}

	if ([self isEqualToData:data]) {
		return NSOrderedSame;
	}

	NSUInteger minLength = MIN(self.length, data.length);
	int result = memcmp(self.bytes, data.bytes, minLength);

	if (result == 0) {
		// If contents are the same up to minLength, the longer data is "greater"
		return (self.length > data.length) ? NSOrderedDescending : NSOrderedAscending;
	}

	return (result > 0) ? NSOrderedDescending : NSOrderedAscending;
}

@end
