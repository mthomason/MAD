//
//  NSData+Comparson.m
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "NSData+Comparson.h"

@implementation NSData (Comparson)

- (NSComparisonResult)compareData:(NSData *)data {
    NSComparisonResult result;
    if ([self isEqualToData:data]) {
        result = NSOrderedSame;
    } else {
        result = self.length > data.length ? NSOrderedAscending : NSOrderedDescending;
    }
    return result;
}

@end
