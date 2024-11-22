//
//  MADQueryCacheBeginTransaction.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheBeginTransaction.h"
#import <MADAPI/MADQueryType.h>

@implementation MADQueryCacheBeginTransaction

- (instancetype)initWithObject:(id)object {
	return self = [super init];
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	return @"BEGIN TRANSACTION;";
}

- (BOOL)returnsResults {
	return NO;
}

- (MADQueryType)type {
	return MADQueryTypeCacheBeginTransaction;
}

@end
