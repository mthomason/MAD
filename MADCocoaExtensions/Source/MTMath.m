//
//  MTMath.m
//  MAD
//
//  Created by Michael Thomason on 7/1/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTMath.h"

@implementation MTMath

+ (NSNumber *)newSystemFileSizeToMB:(unsigned long long)sfs {
	return [[NSNumber alloc] initWithDouble:(double)sfs / 1000000.0];
}

@end
