//
//  MADBlockOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADBlockOperation_h
#define MAD_Designer_MADBlockOperation_h

#import <MADFoundation/MADOperation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^OperationCompletionBlock)(void);
typedef void(^OperationBlock)(OperationCompletionBlock completionBlock);

/// A sublcass of `Operation` to execute a block.
@interface MADBlockOperation : MADOperation

	/**
	 The designated initializer.
 
	 - parameter block: The closure to run when the operation executes. This
		closure will be run on an arbitrary queue. The parameter passed to the
		block **MUST** be invoked by your code, or else the `BlockOperation`
		will never finish executing. If this parameter is `nil`, the operation
		will immediately finish.
	 */
	- (instancetype)initWithBlock:(nullable OperationBlock)block;

	/**
	 A convenience initializer to execute a block on the main queue.
 
	 - parameter mainQueueBlock: The block to execute on the main queue. Note
		that this block does not have a "continuation" block to execute (unlike
		the designated initializer). The operation will be automatically ended
		after the `mainQueueBlock` is executed.
	 */
	- (instancetype)initWithMainQueueBlock:(nullable dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END

#endif
