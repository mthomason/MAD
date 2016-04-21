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

#import "MADDataFormatter.h"

@interface MADDataFormatter ()

@end

@implementation MADDataFormatter

+ (instancetype)newReportFormatterWithQuery:(MTQuery *)query {
    MADDataFormatter *result = [[MADDataFormatter alloc] initWithQuery:query];
    return result;
}

- (instancetype)initWithQuery:(MTQuery *)query {
    if (self = [super init]) {
        self.query = query;
        self.didRefresh = false;
    }
    return self;
}

#pragma mark - Reading cached data

- (BOOL)needsFormat { return YES; }

@end
