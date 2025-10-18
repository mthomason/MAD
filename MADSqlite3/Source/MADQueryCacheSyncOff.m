//
//  MADQueryCacheSyncOff.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheSyncOff.h"
#import <MADAPI/MADQueryType.h>

@implementation MADQueryCacheSyncOff

- (instancetype)initWithObject:(id)object {
	self = [super init];
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	return @"PRAGMA synchronous=OFF;";
}

- (BOOL)returnsResults {
	return NO;
}

- (MADQueryType)type {
	return MADQueryTypeCacheSyncModeOff;
}

@end
