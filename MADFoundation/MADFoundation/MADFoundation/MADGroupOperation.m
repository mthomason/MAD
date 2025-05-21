//
//  MADGroupOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADGroupOperation.h"
#import "MADOperationQueue.h"
#import "madlog.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

/**
 A subclass of `Operation` that executes zero or more operations as part of its
 own execution. This class of operation is very useful for abstracting several
 smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
 is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.
 
 Additionally, `GroupOperation`s are useful if you establish a chain of dependencies,
 but part of the chain may "loop". For example, if you have an operation that
 requires the user to be authenticated, you may consider putting the "login"
 operation inside a group operation. That way, the "login" operation may produce
 subsequent operations (still within the outer `GroupOperation`) that will all
 be executed before the rest of the operations in the initial chain of operations.
 */

@interface MADGroupOperation () <MADOperationQueueDelegate>
	@property (nonatomic, strong, readwrite) MADOperationQueue *internalQueue;
	@property (nonatomic, strong) NSMutableArray <__kindof NSError *> *aggregatedErrors;

@end

@implementation MADGroupOperation

#pragma mark - Lifecycle

- (void)dealloc {
	os_log_info(GetFoundationLog(), "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

#pragma mark - Initialization

- (instancetype)init {
	if (self = [super init]) {
		_aggregatedErrors = [NSMutableArray array];
	}
	return self;
}

#pragma mark - Adding Operations

- (void)addOperations:(NSArray<__kindof NSOperation *> *)operations {
	[self addOperations:operations finishingOperation:nil];
}

- (void)addOperations:(NSArray<__kindof NSOperation *> *)operations
   finishingOperation:(nullable NSBlockOperation *)finishingOperation {
	self.finishingOperation = finishingOperation ?: [NSBlockOperation blockOperationWithBlock:^{}];

	for (NSOperation *op in operations) {
		[self.finishingOperation addDependency:op];
		[self.internalQueue addOperation:op];
	}
}

- (void)addOperation:(NSOperation *)operation {
	[self.internalQueue addOperation:operation];
}

#pragma mark - Execution

- (void)execute {
	if (self.isCancelled) {
		[self finish];
		return;
	}

	self.internalQueue.suspended = NO;

	// Ensure finishingOperation is not nil before adding it to the queue
	if (self.finishingOperation) {
		[self.internalQueue addOperation:(NSOperation * _Nonnull)self.finishingOperation];
	} else {
		// If finishingOperation is nil, create a default empty block operation
		NSBlockOperation *defaultFinishingOperation = [NSBlockOperation blockOperationWithBlock:^{}];
		[self.internalQueue addOperation:defaultFinishingOperation];
	}
}

#pragma mark - Error Handling

- (void)aggregateError:(NSError *)error {
	@synchronized (self) {
		[self.aggregatedErrors addObject:error];
	}
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray<NSError *> *)errors {
	// For use by subclassers.
}

#pragma mark - MADOperationQueueDelegate

- (void)operationQueue:(MADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation {
	NSAssert(!self.finishingOperation.isFinished, @"Cannot add new operations to a group after the group has completed.");

	if (operation != self.finishingOperation) {
		[self.finishingOperation addDependency:operation];
	}
}

- (void)operationQueue:(MADOperationQueue *)operationQueue
	 operationDidFinish:(NSOperation *)operation
			 withErrors:(NSArray<NSError *> *)errors {
	@synchronized (self) {
		[self.aggregatedErrors addObjectsFromArray:errors];
	}

	if (operation == self.finishingOperation) {
		self.internalQueue.suspended = YES;
		[self finishWithError:self.aggregatedErrors.copy];
	} else {
		[self operationDidFinish:operation withErrors:errors];
	}
}

#pragma mark - Cleanup

- (void)cleanup {
	self.internalQueue.delegate = nil;
	[self.internalQueue cancelAllOperations];
	[super cleanup];
}

#pragma mark - Lazy Load

- (MADOperationQueue *)internalQueue {
	if (!_internalQueue) {
		_internalQueue = [MADOperationQueue new];
		_internalQueue.suspended = YES;
		_internalQueue.delegate = self;
	}
	return _internalQueue;
}

@end
