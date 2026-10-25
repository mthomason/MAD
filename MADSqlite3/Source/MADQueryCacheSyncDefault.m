//
//  MADQueryCacheSyncOn.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheSyncDefault.h"
#import <MADAPI/MADQueryType.h>

@implementation MADQueryCacheSyncDefault

- (instancetype)initWithObject:(id)object {
	self = [super initWithObject:object];
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	return @"PRAGMA synchronous=NORMAL;";
}

- (BOOL)returnsResults {
	return NO;
}

- (MADQueryType)type {
	return MADQueryTypeCacheSyncModeDefault;
}

@end
