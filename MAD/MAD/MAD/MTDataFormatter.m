//
//  MTDataFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataFormatter.h"

@interface MTDataFormatter ()

@end

@implementation MTDataFormatter

- (instancetype)initWithQuery:(MTQuery *)query {
    self = [super init];
    if (self) {
        [self setQuery:query];
        [self setDidRefresh:NO];
    }
    return self;
}


+ (instancetype)reportFormatterWithQuery:(MTQuery *)query {
    MTDataFormatter *result = [[MTDataFormatter alloc] initWithQuery:query];
    return result;
}

#pragma mark - Reading cached data

- (BOOL)format {
    return YES;
}

@end
