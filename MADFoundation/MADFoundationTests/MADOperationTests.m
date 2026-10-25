//
//  MADOperationTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperation, the base class of the app's async operation
//  framework.  Exercises the state-machine naming, lazy collections, the
//  condition/observer wiring, the finishing path, and one end-to-end run.
//
//  NOTE: the real `-main` starts a UIApplication background task, which a logic
//  test has no UIApplication for.  The end-to-end test therefore runs a subclass
//  that stubs those two methods out.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationQueue.h>

@interface MADRunOperation : MADOperation
@end
@implementation MADRunOperation
- (void)beginBackgroundTask {}
- (void)endBackgroundTask {}
- (void)execute { [self finish]; }
@end

@interface MADOperationTests : XCTestCase
@end

@implementation MADOperationTests

#pragma mark - State naming

- (void)testStateNameMapping {
	XCTAssertEqualObjects(NSStringFromMADOperationState(MADOperationStateInitialized), @"Initialized");
	XCTAssertEqualObjects(NSStringFromMADOperationState(MADOperationStatePending), @"Pending");
	XCTAssertEqualObjects(NSStringFromMADOperationState(MADOperationStateEvaluatingConditions), @"EvaluatingConditions");
	XCTAssertEqualObjects(NSStringFromMADOperationState(MADOperationStateReady), @"Ready");
	XCTAssertEqualObjects(NSStringFromMADOperationState(MADOperationStateExecuting), @"Executing");
	XCTAssertEqualObjects(NSStringFromMADOperationState(MADOperationStateFinishing), @"Finishing");
	XCTAssertEqualObjects(NSStringFromMADOperationState(MADOperationStateFinished), @"Finished");
}

- (void)testStateNameUnknown {
	XCTAssertEqualObjects(NSStringFromMADOperationState((MADOperationState)999), @"Unknown");
}

#pragma mark - Initial state

- (void)testInitDefaults {
	MADOperation *op = [[MADOperation alloc] init];
	XCTAssertEqual(op.state, MADOperationStateInitialized);
	XCTAssertEqual(op.identifier, (NSUInteger)0);
	XCTAssertFalse(op.isReady);
	XCTAssertFalse(op.isExecuting);
	XCTAssertFalse(op.isFinished);
}

- (void)testIdentifierIsSettable {
	MADOperation *op = [[MADOperation alloc] init];
	op.identifier = 42;
	XCTAssertEqual(op.identifier, (NSUInteger)42);
}

- (void)testLazyCollectionsAreEmpty {
	MADOperation *op = [[MADOperation alloc] init];
	XCTAssertNotNil(op.errors);
	XCTAssertEqual(op.errors.count, (NSUInteger)0);
	XCTAssertNotNil(op.conditions);
	XCTAssertEqual(op.conditions.count, (NSUInteger)0);
	XCTAssertNotNil(op.observers);
	XCTAssertEqual(op.observers.count, (NSUInteger)0);
}

#pragma mark - Conditions and observers

- (void)testAddCondition {
	MADOperation *op = [[MADOperation alloc] init];
	// Any object answering the condition protocol works for wiring coverage.
	NSObject *condition = [[NSObject alloc] init];
	[op addCondition:(id)condition];
	XCTAssertEqual(op.conditions.count, (NSUInteger)1);
}

- (void)testAddObserver {
	MADOperation *op = [[MADOperation alloc] init];
	NSObject *observer = [[NSObject alloc] init];
	[op addObserver:(id)observer];
	XCTAssertEqual(op.observers.count, (NSUInteger)1);
}

#pragma mark - Finishing

- (void)testFinishTransitionsToFinished {
	MADOperation *op = [[MADOperation alloc] init];
	[op finish];
	XCTAssertEqual(op.state, MADOperationStateFinished);
	XCTAssertTrue(op.isFinished);
	XCTAssertFalse(op.isReady);
	XCTAssertFalse(op.isExecuting);
	XCTAssertEqual(op.errors.count, (NSUInteger)0);
}

- (void)testFinishWithErrorPopulatesErrors {
	MADOperation *op = [[MADOperation alloc] init];
	NSError *error = [NSError errorWithDomain:@"com.example" code:7 userInfo:nil];
	[op finishWithError:error];
	XCTAssertTrue(op.isFinished);
	XCTAssertEqual(op.errors.count, (NSUInteger)1);
	XCTAssertEqual(op.errors.firstObject.code, 7);
	XCTAssertEqualObjects(op.errors.firstObject.domain, @"com.example");
}

- (void)testFinishWithErrorsArray {
	MADOperation *op = [[MADOperation alloc] init];
	NSError *a = [NSError errorWithDomain:@"d" code:1 userInfo:nil];
	NSError *b = [NSError errorWithDomain:@"d" code:2 userInfo:nil];
	[op finish:@[a, b]];
	XCTAssertTrue(op.isFinished);
	XCTAssertEqual(op.errors.count, (NSUInteger)2);
}

- (void)testFinishIsIdempotent {
	MADOperation *op = [[MADOperation alloc] init];
	NSError *error = [NSError errorWithDomain:@"d" code:1 userInfo:nil];
	[op finishWithError:error];
	[op finishWithError:error];
	XCTAssertEqual(op.errors.count, (NSUInteger)1);
}

- (void)testWillEnqueueAdvancesPastPendingToReady {
	// -willEnqueue drives the advance explicitly (Pending, then condition
	// evaluation for a dependency-free operation) rather than leaning on the
	// KVO dependent-key side effect, which cost GNUstep's NSOperationQueue its
	// "isReady" observation.  This pins the observable end state.
	MADOperation *op = [[MADOperation alloc] init];
	[op willEnqueue];
	XCTAssertEqual(op.state, MADOperationStateReady);
}

#pragma mark - End-to-end run

- (void)testRunToCompletion {
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	MADRunOperation *op = [[MADRunOperation alloc] init];

	[queue addOperation:op];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
	while (!op.isFinished && [deadline timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}

	XCTAssertTrue(op.isFinished);
	XCTAssertEqual(op.state, MADOperationStateFinished);
}

@end
