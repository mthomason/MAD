//
//  MADBlockOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADBlockOperation.h"
#import "madlog.h"

@interface MADBlockOperation ()

	@property (nonatomic, copy, nullable) OperationBlock block;

@end

@implementation MADBlockOperation

- (void)dealloc { }

/**
	The designated initializer.
 
	- parameter block: The closure to run when the operation executes. This
		closure will be run on an arbitrary queue. The parameter passed to the
		block **MUST** be invoked by your code, or else the `BlockOperation`
		will never finish executing. If this parameter is `nil`, the operation
		will immediately finish.
 */

- (instancetype)initWithBlock:(nullable OperationBlock)block {
	if (self = [super init]) {
		_block = [block copy];
	}
	return self;
}

- (instancetype)initWithMainQueueBlock:(nullable dispatch_block_t)mainThreadBlock {
	MADLogDebug("MADBlockOperation <%p:%@> initWithMainQueueBlock: block is %s",
				self, self.name, mainThreadBlock ? "provided" : "nil");
	return [self initWithBlock:^(OperationCompletionBlock operationCompletionBlock) {
		if (mainThreadBlock) {
			dispatch_async(dispatch_get_main_queue(), ^{
				mainThreadBlock();
				if (operationCompletionBlock) {
					operationCompletionBlock();
				}
			});
		} else if (operationCompletionBlock) {
			operationCompletionBlock();
		}
	}];
}

- (void)execute {
	MADLogDebug("MADBlockOperation <%p:%@> execute. Operation block is %s",
				self, self.name, self.block ? "present" : "nil");
	
	OperationCompletionBlock completion = ^{
		// [self finish] will be logged by MADOperation's finish method.
		MADLogDebug("MADBlockOperation <%p:%@> internal completion block called, finishing operation.",
					self, self.name);
		[self finish];
	};
	
	if (self.block) {
		MADLogDebug("MADBlockOperation <%p:%@> invoking operation block.", self, self.name);
		self.block(completion);
	} else {
		MADLogDebug("MADBlockOperation <%p:%@> no operation block, finishing immediately.", self, self.name);
		completion();
	}
}

@end
