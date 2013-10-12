//
//  NSNumber+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/17/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSNumber+Extras.h"

@implementation NSNumber (Extras)

+ (NSNumber *)zero {
    return [[[self alloc] initWithInteger:0] autorelease];
}

@end