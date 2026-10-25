//
//  MADOperationQueue.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationQueue.h"
#import "NSOperation+CompletionBlock.h"
#import "MADBlockObserver.h"
#import "MADOperationCondition.h"
#import "MADExclusivityController.h"
#import "madlog.h"

#import <MADFoundation/MADOperation.h>

@implementation MADOperationQueue

- (void)dealloc { }

#pragma mark - Adding Operations

- (void)addOperation:(nonnull NSOperation *)operation {
	if ([operation isKindOfClass:[MADOperation class]]) {
		[self addMADOperation:(MADOperation *)operation];
	} else {
		[self addStandardOperation:operation];
	}

	// Notify the delegate that an operation will be added
	id<MADOperationQueueDelegate> delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(operationQueue:willAddOperation:)]) {
		[delegate operationQueue:self willAddOperation:operation];
	}

	[super addOperation:operation];
}

- (void)addMADOperation:(nonnull MADOperation *)operation {
	__weak MADOperationQueue *weakSelf = self;

	// Set up a block delegate to handle operation lifecycle events
	MADBlockObserver *delegate = [[MADBlockObserver alloc] initWithStartHandler:^(MADOperation *__unused oper) {
		//os_log_info(GetFoundationLog(), "Starting operation %@", oper.name);
	} produceHandler:^(MADOperation *__unused oper, NSOperation *newOp) {
		__strong MADOperationQueue *sself = weakSelf;
		if (sself) {
			[sself addOperation:newOp];
		}
	} finishHandler:^(MADOperation *oper, NSArray<NSError *> *errors) {
		__strong MADOperationQueue *sself = weakSelf;
		if (sself) {
			[sself.delegate operationQueue:sself operationDidFinish:oper withErrors:errors];
			//os_log_info(GetFoundationLog(), "Finished operation %@", oper.name);
		}
	}];

	[operation addObserver:delegate];

	// Add dependencies from conditions
	[self addConditionDependenciesForOperation:operation];

	// Handle mutual exclusivity
	[self enforceMutualExclusivityForOperation:operation];

	// Notify the operation that it's ready to be enqueued
	[operation willEnqueue];
}

- (void)addStandardOperation:(nonnull NSOperation *)operation {
	__weak MADOperationQueue *weakSelf = self;
	__weak NSOperation *weakOperation = operation;

	[operation addCompletionBlock:^{
		__strong MADOperationQueue *queue = weakSelf;
		NSOperation *op = weakOperation;
		if (queue && op) {
			id<MADOperationQueueDelegate> delegate = queue.delegate;
			if ([delegate respondsToSelector:@selector(operationQueue:operationDidFinish:withErrors:)]) {
				[delegate operationQueue:queue operationDidFinish:op withErrors:nil];
			}
		}
	}];
}

#pragma mark - Dependency Management

- (void)addConditionDependenciesForOperation:(nonnull MADOperation *)operation {
	NSMutableArray<NSOperation *> *dependencies = [NSMutableArray arrayWithCapacity:operation.conditions.count];
	for (id<MADOperationCondition> condition in operation.conditions) {
		NSOperation *dependency = [condition dependencyForOperation:operation];
		if (dependency) {
			[dependencies addObject:dependency];
		}
	}

	for (NSOperation *dependency in dependencies) {
		[operation addDependency:dependency];
		[self addOperation:dependency];
	}
}

#pragma mark - Mutual Exclusivity

- (void)enforceMutualExclusivityForOperation:(nonnull MADOperation *)operation {
	NSMutableArray<NSString *> *concurrencyCategories = [NSMutableArray array];
	for (id<MADOperationCondition> condition in operation.conditions) {
		if ([condition isMutuallyExclusive]) {
			[concurrencyCategories addObject:condition.name];
		}
	}

	if (concurrencyCategories.count > 0) {
		MADExclusivityController *exclusivityController = [MADExclusivityController sharedExclusivityController];
		[exclusivityController addOperation:operation categories:concurrencyCategories];

		MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:nil
																	produceHandler:nil
																	 finishHandler:^(MADOperation *oper, NSArray<NSError *> *__unused errors) {
			[exclusivityController removeOperation:oper categories:concurrencyCategories];
		}];

		[operation addObserver:observer];
	}
}

#pragma mark - Batch Operations

- (void)addOperations:(nonnull NSArray<NSOperation *> *)ops waitUntilFinished:(BOOL)wait {
	for (NSOperation * op in ops) {
		[self addOperation:op];
	}
	
	if (wait) {
		for (NSOperation * op in ops) {
			[op waitUntilFinished];
		}
	}
}

@end
