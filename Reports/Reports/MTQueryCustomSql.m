//
//  MTQueryCustomSql.m
//  MAD
//
//  Created by Michael Thomason on 4/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCustomSql.h"

@implementation MTQueryCustomSql

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSString class]], @"MTQueryCustomSql expects NSString.");
        NSString *queryString = [[NSString alloc] initWithString:object];
        [self setQueryObject:queryString];
        [self setExpectsResults:YES];
        
    }
    return self;
}

@end
