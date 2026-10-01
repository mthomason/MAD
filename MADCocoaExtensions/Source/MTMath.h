//
//  MTMath.h
//  MAD
//
//  Created by Michael Thomason on 7/1/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTMath_h
#define Reports_MTMath_h

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSRange.h>
#import <stdlib.h>

static inline NSUInteger madRandomNumberBetween(NSUInteger from, NSUInteger to);
static inline NSUInteger madRandomNumberInRange(NSRange range);
static inline double madSystemFileSizeToMB(unsigned long long sfs);

static inline NSUInteger madRandomNumberBetween(NSUInteger from, NSUInteger to) {
	return from + arc4random() % (to - from + 1);
}

static inline NSUInteger madRandomNumberInRange(NSRange range) {
	return range.location + arc4random() % ((range.location + range.length - 1) - range.location + 1);
}

static inline double madSystemFileSizeToMB(unsigned long long sfs) {
	return (double)sfs / 1000000.0;
}

@interface MTMath : NSObject

+ (NSNumber *)newSystemFileSizeToMB:(unsigned long long)sfs;

@end

#endif
