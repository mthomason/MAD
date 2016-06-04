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

@dynamic didRefresh;

- (instancetype)initWithQuery:(MTQuery *)query {
    if (self = [super initWithQuery:query]) {

        self.query = query;
        self.didRefresh = NO;
        
    }
    return self;
}

#pragma mark - Reading cached data

- (BOOL)needsFormat { return super.needsFormat; }

@end
