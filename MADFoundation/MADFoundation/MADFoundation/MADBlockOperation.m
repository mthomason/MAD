//
//  MADBlockOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADBlockOperation.h"
#import "madlog.h"

@interface MADBlockOperation ()

	@property (nonatomic, copy, nullable) OperationBlock block;

@end

@implementation MADBlockOperation

- (void)dealloc {
	os_log_info(GetFoundationLog(), "-[%s %s]", NSStringFromClass(self.class).UTF8String, __FUNCTION__);
}

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

- (instancetype)initWithMainQueueBlock:(nullable dispatch_block_t)block {
	return [self initWithBlock:^(OperationCompletionBlock operationCompletionBlock) {
		if (block) {
			dispatch_async(dispatch_get_main_queue(), ^{
				block();
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
	OperationCompletionBlock completion = ^{
		[self finish];
	};

	if (self.block) {
		self.block(completion);
	} else {
		completion();
	}
}

@end
