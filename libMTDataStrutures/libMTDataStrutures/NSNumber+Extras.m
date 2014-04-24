//
//  NSNumber+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/17/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "NSNumber+Extras.h"

@implementation NSNumber (Extras)

+ (NSNumber *)zero {
    return [[self alloc] initWithInteger:0];
}

@end