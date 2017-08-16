//
//  MADBlockOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADBlockOperation.h"
#import <os/log.h>

@interface MADBlockOperation ()

    @property (nonatomic, copy) OperationBlock block;

@end

@implementation MADBlockOperation

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "-[%s %s]", NSStringFromClass(self.class).UTF8String, __FUNCTION__);
}

/**
    The designated initializer.
 
    - parameter block: The closure to run when the operation executes. This
        closure will be run on an arbitrary queue. The parameter passed to the
        block **MUST** be invoked by your code, or else the `BlockOperation`
        will never finish executing. If this parameter is `nil`, the operation
        will immediately finish.
 */

- (instancetype)initWithBlock:(OperationBlock)block {
    if (self = [super init]) {
        _block = block;
    }
    return self;
}

- (instancetype)initWithMainQueueBlock:(dispatch_block_t)block {
    self = [self initWithBlock:^(void(^operationCompletionBlock)(void)) {
        block();
        if (operationCompletionBlock) {
            operationCompletionBlock();
        }
    }];
    return self;
}

- (void)execute {

    OperationCompletionBlock completion = ^{
        [self finish];
    };
    
    if (self.block){
        self.block(completion);
    } else {
        completion();
        return;
    }
}

@end
