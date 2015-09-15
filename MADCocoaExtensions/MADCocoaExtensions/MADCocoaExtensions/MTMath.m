//
//  MTMath.m
//  MAD
//
//  Created by Michael Thomason on 7/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTMath.h"

@implementation MTMath

+ (NSInteger)getRandomNumberBetween:(NSInteger)from to:(NSInteger)to {
    return (NSInteger)from + arc4random() % (to - from + 1);
}

+ (NSNumber *)systemFileSizeToMB:(unsigned long long)sfs {
    return @((double)sfs / 1000000);
}

@end
