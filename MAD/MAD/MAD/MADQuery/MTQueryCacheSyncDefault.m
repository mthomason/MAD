//
//  MTQueryCacheSyncOn.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheSyncDefault.h"

@implementation MTQueryCacheSyncDefault

- (instancetype)initWithObject:(id)object {
    return self = [super initWithObject:object];
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    return @"PRAGMA synchronous=NORMAL;";
}

- (BOOL)returnsResults {
    return NO;
}

@end
