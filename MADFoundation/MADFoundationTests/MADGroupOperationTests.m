//
//  MADGroupOperationTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADGroupOperation's structural API: the lazily-created suspended
//  internal queue and the finishing-operation/dependency wiring.  (A full run of
//  a group is intentionally not exercised here; see BUGS.md for the error
//  aggregation quirk in -operationDidFinish:withErrors:.)
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

@end
