//
//  MADGroupOperationTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADGroupOperationTests.m: coverage for
//  MADGroupOperation's structural API, the lazily-created suspended internal
//  queue, the finishing-operation/dependency wiring, and the aggregated errors
//  the group finishes with.  (A full run of a group is not exercised here, but
//  the error path it uses is.)
//

#import "MADTestSupport.h"
#import <MADFoundation/MADGroupOperation.h>
#import <MADFoundation/MADOperationQueue.h>

static void testInternalQueueIsLazyAndSuspended(void) {
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	MAD_PASS(group.internalQueue != nil, "internal queue is created lazily");
	// GNUstep declares -isSuspended, not a `suspended` property, so dot syntax
	// needs the explicit getter here.
	MAD_PASS([group.internalQueue isSuspended], "internal queue starts suspended");
}

static void testAddOperationsAddsToInternalQueue(void) {
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	NSBlockOperation *a = [NSBlockOperation blockOperationWithBlock:^{}];
	NSBlockOperation *b = [NSBlockOperation blockOperationWithBlock:^{}];
	[group addOperations:@[a, b] finishingOperation:nil];
	MAD_PASS(group.internalQueue.operationCount == (NSUInteger)2, "both operations were added to the internal queue");
}

static void testAddOperationsSetsFinishingOperationAndDependencies(void) {
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	NSBlockOperation *a = [NSBlockOperation blockOperationWithBlock:^{}];
	NSBlockOperation *b = [NSBlockOperation blockOperationWithBlock:^{}];
	[group addOperations:@[a, b] finishingOperation:nil];

	MAD_PASS(group.finishingOperation != nil, "a finishing operation was created");
	MAD_PASS(group.finishingOperation.dependencies.count == (NSUInteger)2, "the finishing operation has two dependencies");
	MAD_PASS([group.finishingOperation.dependencies containsObject:a], "the finishing operation depends on the first");
	MAD_PASS([group.finishingOperation.dependencies containsObject:b], "the finishing operation depends on the second");
}

static void testFinishingWithSeveralErrorsKeepsThemSeparate(void) {
	// The group finishes through -finish: (which takes an array), not
	// -finishWithError: (which would box the array as one bogus error).
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	NSError *first = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
	NSError *second = [NSError errorWithDomain:@"test" code:2 userInfo:nil];

	[group finish:@[first, second]];

	MAD_PASS(group.isFinished, "the group finished");
	MAD_PASS(group.errors.count == (NSUInteger)2, "both errors were kept separate");
	for (id error in group.errors) {
		MAD_PASS([error isKindOfClass:[NSError class]], "each entry is an NSError");
	}
}

MAD_TEST_MAIN("MADGroupOperationTests",
	MAD_TEST(testInternalQueueIsLazyAndSuspended),
	MAD_TEST(testAddOperationsAddsToInternalQueue),
	MAD_TEST(testAddOperationsSetsFinishingOperationAndDependencies),
	MAD_TEST(testFinishingWithSeveralErrorsKeepsThemSeparate));
