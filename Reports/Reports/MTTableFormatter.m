//
//  MTTableFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableFormatter.h"
#import "MTQuery.h"

@implementation MTTableFormatter

- (instancetype)initWithQuery:(MTQuery *)query {
    self = [super initWithQuery:query];
    if (self) {

        self.query = query;
        self.didRefresh = NO;
    }
    return self;
}

+ (instancetype)reportFormatterWithQuery:(MTQuery *)query {
    MTTableFormatter *result = [[MTTableFormatter alloc] initWithQuery:query];
    return result;
}

#pragma mark - Reading cached data

- (BOOL)format {
    return [super format];
}

@end
