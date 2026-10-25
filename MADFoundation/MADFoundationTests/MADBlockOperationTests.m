//
//  MADBlockOperationTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADBlockOperation: the block-to-operation adapter.  The block
//  is invoked by `-execute`, which is exercised directly here (it does not touch
//  UIApplication the way `-main` does).
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADBlockOperation.h>

@interface MADBlockOperationTests : XCTestCase
@end

@implementation MADBlockOperationTests

- (void)testBlockRunsAndFinishes {
	__block BOOL ran = NO;
	MADBlockOperation *op = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock completion) {
		ran = YES;
		completion();
	}];
	[op execute];
	XCTAssertTrue(ran);
	XCTAssertTrue(op.isFinished);
}

- (void)testNilBlockFinishesImmediately {
	MADBlockOperation *op = [[MADBlockOperation alloc] initWithBlock:nil];
	[op execute];
	XCTAssertTrue(op.isFinished);
}

- (void)testBlockWithoutCompletionDoesNotFinish {
	MADBlockOperation *op = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock completion) {
		// Deliberately never calls the completion continuation.
	}];
	[op execute];
	XCTAssertFalse(op.isFinished);
}

- (void)testMainQueueBlockRunsOnMainThread {
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

	XCTAssertTrue(ran);
	XCTAssertTrue(ranOnMain);
	XCTAssertTrue(op.isFinished);
}

@end
