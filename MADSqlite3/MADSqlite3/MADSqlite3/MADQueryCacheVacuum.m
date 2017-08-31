//
//  MADQueryCacheVacuum.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheVacuum.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <MADAPI/MADQueryType.h>

@implementation MADQueryCacheVacuum

- (instancetype)initWithObject:(id)object {

    if (self = [super init]) {
        NSAssert([object isKindOfClass:[NSDictionary class]],
                        @"MADQueryCacheVacuum expects NSDictionary.");
    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    return @"VACUUM";
}

- (BOOL)returnsResults {
    return NO;
}

- (MADQueryType)type {
    return MADQueryTypeCacheVacuum;
}

@end
