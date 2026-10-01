//
//  MADGroupOperationTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADGroupOperation's structural API: the lazily-created suspended
//  internal queue, the finishing-operation/dependency wiring, and the aggregated
//  errors the group finishes with.  (A full run of a group is not exercised
//  here, but the error path it uses is.)
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADGroupOperation.h>
#import <MADFoundation/MADOperationQueue.h>

@interface MADGroupOperationTests : XCTestCase
@end

@implementation MADGroupOperationTests

- (void)testInternalQueueIsLazyAndSuspended {
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	XCTAssertNotNil(group.internalQueue);
	XCTAssertTrue(group.internalQueue.suspended);
}

- (void)testAddOperationsAddsToInternalQueue {
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	NSBlockOperation *a = [NSBlockOperation blockOperationWithBlock:^{}];
	NSBlockOperation *b = [NSBlockOperation blockOperationWithBlock:^{}];
	[group addOperations:@[a, b] finishingOperation:nil];
	XCTAssertEqual(group.internalQueue.operationCount, (NSUInteger)2);
}

- (void)testAddOperationsSetsFinishingOperationAndDependencies {
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	NSBlockOperation *a = [NSBlockOperation blockOperationWithBlock:^{}];
	NSBlockOperation *b = [NSBlockOperation blockOperationWithBlock:^{}];
	[group addOperations:@[a, b] finishingOperation:nil];

	XCTAssertNotNil(group.finishingOperation);
	XCTAssertEqual(group.finishingOperation.dependencies.count, (NSUInteger)2);
	XCTAssertTrue([group.finishingOperation.dependencies containsObject:a]);
	XCTAssertTrue([group.finishingOperation.dependencies containsObject:b]);
}

- (void)testFinishingWithSeveralErrorsKeepsThemSeparate {
	// The group finishes through -finish: (which takes an array), not
	// -finishWithError: (which would box the array as one bogus error).
	MADGroupOperation *group = [[MADGroupOperation alloc] init];
	NSError *first = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
	NSError *second = [NSError errorWithDomain:@"test" code:2 userInfo:nil];

	[group finish:@[first, second]];

	XCTAssertTrue(group.isFinished);
	XCTAssertEqual(group.errors.count, (NSUInteger)2);
	for (id error in group.errors) {
		XCTAssertTrue([error isKindOfClass:[NSError class]]);
	}
}

@end
