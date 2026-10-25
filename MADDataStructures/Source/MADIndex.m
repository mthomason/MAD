//
//  MADIndex.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADIndex.h"

#import <Foundation/NSString.h>

@implementation MADIndex

- (instancetype)initWithIndex:(NSUInteger)index andObject:(nullable id)object {
	if (self = [super init]) {
		_index = index;
		_object = object;
	}
	return self;
}

#pragma mark - Description

- (NSString *)description {
	NSString *objectDescription = self.object ? [self.object description] : @"nil";
	return [NSString stringWithFormat:@"<MADIndex: index=%lu, object=%@>", (unsigned long)self.index, objectDescription];
}

@end
