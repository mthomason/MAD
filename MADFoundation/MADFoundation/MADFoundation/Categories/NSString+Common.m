//
//  NSString+Common.m
//  MADFoundation
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "NSString+Common.h"

@implementation NSString (Common)

- (NSString *)stringByAppendingPeriod {
    static NSString *period = @".";
    return [self stringByAppendingString:period];
}

- (NSString *)stringByAppendingKeyPath:(NSString *)keyPath {
    return [[self stringByAppendingPeriod] stringByAppendingString:keyPath];
}

@end
