//
//  MADQueryCacheEndTransaction.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheEndTransaction.h"
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheEndTransaction ()

@end

@implementation MADQueryCacheEndTransaction

- (instancetype)initWithObject:(id)object {
	self = [super init];
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	return @"END TRANSACTION;";
}

- (BOOL)returnsResults {
	return NO;
}

- (MADQueryType)type {
	return MADQueryTypeCacheEndTransaction;
}

@end
