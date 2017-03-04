//
//  MTQueryCacheVacuum.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheVacuum.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

@implementation MTQueryCacheVacuum

- (instancetype)initWithObject:(id)object {

    if (self = [super init]) {
        NSAssert([object isKindOfClass:[NSDictionary class]],
                        @"MTQueryCacheVacuum expects NSDictionary.");
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    return @"VACUUM";
}

- (BOOL)returnsResults {
    return NO;
}

@end
