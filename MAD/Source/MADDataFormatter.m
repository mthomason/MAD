//
//  MTDataFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataFormatter.h"

@interface MADDataFormatter ()

@end

@implementation MADDataFormatter

+ (instancetype)newDataFormatter:(MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *)query {
	id result = [[self alloc] initWithQuery:query];
	return result;
}

- (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *)query {
	if (self = [super init]) {
		self.query = query;
		self.didRefresh = NO;
	}
	return self;
}

#pragma mark - Reading cached data

- (BOOL)needsFormat { return YES; }

- (void)setDidRefresh:(BOOL)didRefresh {
	_didRefresh = didRefresh;
}

@end
