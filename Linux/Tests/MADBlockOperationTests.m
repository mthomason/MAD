//
//  MADBlockOperationTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADBlockOperationTests.m: coverage for
//  MADBlockOperation, the block-to-operation adapter.  The block is invoked by
//  `-execute`, which is exercised directly here (it does not touch
//  UIApplication the way `-main` does).
//

#import "MADTestSupport.h"
#import <MADFoundation/MADBlockOperation.h>

static void testBlockRunsAndFinishes(void) {
	__block BOOL ran = NO;
	MADBlockOperation *op = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock completion) {
		ran = YES;
		completion();
	}];
	[op execute];
	MAD_PASS(ran, "the block ran");
	MAD_PASS(op.isFinished, "the operation finished");
}

static void testNilBlockFinishesImmediately(void) {
	MADBlockOperation *op = [[MADBlockOperation alloc] initWithBlock:nil];
	[op execute];
	MAD_PASS(op.isFinished, "an operation with no block finishes immediately");
}

static void testBlockWithoutCompletionDoesNotFinish(void) {
	MADBlockOperation *op = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock completion) {
		// Deliberately never calls the completion continuation.
	}];
	[op execute];
	MAD_PASS(!op.isFinished, "the operation stays unfinished until completion is called");
}

static void testMainQueueBlockRunsOnMainThread(void) {
	__block BOOL ran = NO;
	__block BOOL ranOnMain = NO;
	MADBlockOperation *op = [[MADBlockOperation alloc] initWithMainQueueBlock:^{
		ran = YES;
		ranOnMain = [NSThread isMainThread];
	}];
	[op execute];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
	while (!op.isFinished && [deadline timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}

	MAD_PASS(ran, "the main-queue block ran");
	MAD_PASS(ranOnMain, "it ran on the main thread");
	MAD_PASS(op.isFinished, "the operation finished");
}

MAD_TEST_MAIN("MADBlockOperationTests",
	MAD_TEST(testBlockRunsAndFinishes),
	MAD_TEST(testNilBlockFinishesImmediately),
	MAD_TEST(testBlockWithoutCompletionDoesNotFinish),
	MAD_TEST(testMainQueueBlockRunsOnMainThread));
