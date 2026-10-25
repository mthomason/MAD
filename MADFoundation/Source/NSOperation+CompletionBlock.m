//
//  NSOperation+CompletionBlock.m
//  MADFoundation
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSOperation+CompletionBlock.h"
#import <Foundation/NSArray.h>

@implementation NSOperation (CompletionBlock)

/*
	Appends block to the operation's completion work. If a completion block is
	already set, the two are chained so the existing one runs first and the new
	one second, each exactly once. A nil block changes nothing.
 */
- (void)addCompletionBlock:(void(^)(void))block {
	if (!block) {
		return;
	}
	void (^existing)(void) = self.completionBlock;
	if (!existing) {
		self.completionBlock = block;
		return;
	}
	self.completionBlock = ^{
		existing();
		block();
	};
}

/*
	Adds each operation in dependencies as a dependency of the receiver, so the
	receiver does not start until all of them have finished.
 */
- (void)addDependencies:(NSArray <__kindof NSOperation *> *)dependencies {
	for (NSOperation *dependency in dependencies) {
		[self addDependency:dependency];
	}
}

@end
