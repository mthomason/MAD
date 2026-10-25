//
//  MADGroupOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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

- (void)dealloc { }

#pragma mark - Initialization

- (instancetype)init {
	if (self = [super init]) {
		_aggregatedErrors = [NSMutableArray array];
		MADLogDebug("MADGroupOperation <%p:%@> initialized.", self, self.name);
	}
	return self;
}

#pragma mark - Adding Operations

- (void)addOperations:(NSArray<__kindof NSOperation *> *)operations {
	MADLogDebug("MADGroupOperation <%p:%@> addOperations (simple): adding %lu operations.",
				self, self.name, (unsigned long)operations.count);
	[self addOperations:operations finishingOperation:nil];
}

- (void)addOperations:(NSArray<__kindof NSOperation *> *)operations finishingOperation:(nullable NSBlockOperation *)finishingOperation {
	MADLogDebug("MADGroupOperation <%p:%@> addOperations: adding %lu operations with finishingOperation <%p>",
				self, self.name, (unsigned long)operations.count, finishingOperation);

	(void)self.internalQueue;
	self.finishingOperation = finishingOperation ?: [NSBlockOperation blockOperationWithBlock:^{
		MADLogDebug("MADGroupOperation <%p:%@> default (empty) finishingOperation block executed.", self, self.name);
	}];
	for (NSOperation *op in operations) {
		[self.finishingOperation addDependency:op];
		MADLogDebug("MADGroupOperation <%p:%@>   - Adding op <%p:%@> to internalQueue.",
					self, self.name, op, op.name);
		[self.internalQueue addOperation:op];
	}
}

- (void)addOperation:(NSOperation *)operation {
	MADLogDebug("MADGroupOperation <%p:%@> addOperation (single): adding op <%p:%@> to internalQueue.",
				self, self.name, operation, operation.name);
	[self.internalQueue addOperation:operation];
}

#pragma mark - Execution

- (void)execute {
	MADLogDebug("MADGroupOperation <%p:%@> execute called. Cancelled: %s",
				self, self.name, self.isCancelled ? "YES" : "NO");
	if (self.isCancelled) {
		[self finish];
		return;
	}

	self.internalQueue.suspended = NO;

	// Ensure finishingOperation is not nil before adding it to the queue
	if (self.finishingOperation) {
		MADLogDebug("MADGroupOperation <%p:%@> adding finishingOperation <%p:%@> to internalQueue.",
					self, self.name, self.finishingOperation, self.finishingOperation.name);
		[self.internalQueue addOperation:(NSOperation * _Nonnull)self.finishingOperation];
	} else {
		// If finishingOperation is nil, create a default empty block operation
		MADLogInfo("MADGroupOperation <%p:%@> execute: finishingOperation was nil. Creating and adding a default empty one.",
				   self, self.name);
		NSBlockOperation *defaultFinishingOperation = [NSBlockOperation blockOperationWithBlock:^{
			MADLogDebug("MADGroupOperation <%p:%@> execute: default (late) finishingOperation block executed.", self, self.name);
		}];
		defaultFinishingOperation.name = [NSString stringWithFormat:@"%@_DefaultLateFinishingBlock", self.name ?: @"UnnamedGroup"];
		[self.internalQueue addOperation:defaultFinishingOperation];
	}
}

#pragma mark - Error Handling

- (void)aggregateError:(NSError *)error {
	if (!error) return;
	@synchronized (self) {
		[self.aggregatedErrors addObject:error];
	}
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray<NSError *> *)errors {
	// For use by subclassers.
	MADLogDebug("MADGroupOperation <%p:%@> operationDidFinish (subclass hook): Op <%p:%@> finished. Error count: %lu. Aggregated errors now: %lu.",
				self, self.name, operation, operation.name, (unsigned long)errors.count, (unsigned long)self.aggregatedErrors.count);
}

#pragma mark - MADOperationQueueDelegate

- (void)operationQueue:(MADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation {
	MADLogDebug("MADGroupOperation <%p:%@> (as delegate) operationQueue:<%p:%@> willAddOperation:<%p:%@>. FinishingOpIsFinished: %s",
				self, self.name, operationQueue, operationQueue.name, operation, operation.name,
				self.finishingOperation.isFinished ? "YES" : "NO");
	
	NSAssert(!self.finishingOperation.isFinished, @"Cannot add new operations to a group after the group has completed.");

	if (operation != self.finishingOperation) {
		[self.finishingOperation addDependency:operation];
	}
}

- (void)operationQueue:(MADOperationQueue *)opQueue operationDidFinish:(NSOperation *)op withErrors:(NSArray<NSError *> *)errs {
	MADLogDebug("MADGroupOperation <%p:%@> (as delegate) operationQueue:<%p:%@> operationDidFinish:<%p:%@>. Error count: %lu",
				self, self.name, opQueue, opQueue.name, op, op.name, (unsigned long)errs.count);
	@synchronized (self) {
		[self.aggregatedErrors addObjectsFromArray:errs];
	}

	if (op == self.finishingOperation) {
		MADLogDebug("MADGroupOperation <%p:%@> The group's main finishingOperation <%p:%@> has itself finished. Total aggregated errors: %lu.",
					self, self.name, self.finishingOperation, self.finishingOperation.name, (unsigned long)self.aggregatedErrors.count);
		self.internalQueue.suspended = YES;
		MADLogDebug("MADGroupOperation <%p:%@> internalQueue <%p:%@> suspended.",
					self, self.name, self.internalQueue, self.internalQueue.name);
		// The group collects one error per failed sub-operation; -finish: takes
		// the array. -finishWithError: would box the array as a single "error".
		[self finish:self.aggregatedErrors.copy];
	} else {
		[self operationDidFinish:op withErrors:errs];
	}
}

#pragma mark - Cleanup

- (void)cleanup {
	MADLogDebug("MADGroupOperation <%p:%@> cleanup called.", self, self.name);
	self.internalQueue.delegate = nil;
	[self.internalQueue cancelAllOperations];
	MADLogDebug("MADGroupOperation <%p:%@> internalQueue all operations cancelled.", self, self.name);
	self.internalQueue = nil; // Release the queue
	self.finishingOperation = nil; // Release the finishing op
	[self.aggregatedErrors removeAllObjects];
	[super cleanup];
	MADLogDebug("MADGroupOperation <%p:%@> cleanup complete.", self, self.name);
}

#pragma mark - Lazy Load

- (MADOperationQueue *)internalQueue {
	if (!_internalQueue) {
		MADLogDebug("MADGroupOperation <%p:%@> Lazy loading internalQueue.", self, self.name);
		_internalQueue = [MADOperationQueue new];
		_internalQueue.suspended = YES;
		_internalQueue.delegate = self;
		MADLogDebug("MADGroupOperation <%p:%@> internalQueue <%p:%@> created and configured.",
					self, self.name, _internalQueue, _internalQueue.name);
	}
	return _internalQueue;
}

@end
