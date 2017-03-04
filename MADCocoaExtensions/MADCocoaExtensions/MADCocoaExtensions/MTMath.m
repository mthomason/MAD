//
//  MTMath.m
//  MAD
//
//  Created by Michael Thomason on 7/1/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTMath.h"

@implementation MTMath

+ (NSNumber *)newSystemFileSizeToMB:(unsigned long long)sfs {
    return [[NSNumber alloc] initWithDouble:sfs / 1000000];
}

@end
