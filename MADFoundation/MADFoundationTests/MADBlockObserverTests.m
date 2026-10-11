//
//  MADBlockObserverTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADBlockObserver: the block-based MADOperationObserver the app uses
//  to hang start/produce/finish handlers on an operation without a delegate object.
//
//  Two layers are pinned: the protocol methods called directly (each handler sees
//  the exact operation / produced operation / error list, and a nil handler is a
//  safe no-op), and one real run where MADOperation drives the observer through
//  -start and -finish.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADBlockObserver.h>
#import <MADFoundation/MADOperation.h>

// The real -beginBackgroundTask needs a UIApplication, which a logic test does not
// have; -execute finishes immediately so the run is synchronous.
@interface MADObserverOperation : MADOperation
@end

@implementation MADObserverOperation
- (void)beginBackgroundTask {}
- (void)endBackgroundTask {}
- (void)execute { [self finish]; }
@end

@interface MADBlockObserverTests : XCTestCase
@end

@implementation MADBlockObserverTests

#pragma mark - Handlers, called directly

- (void)testStartHandlerReceivesTheOperation {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	__block MADOperation *captured = nil;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:^(MADOperation *op) {
		captured = op;
	} produceHandler:nil finishHandler:nil];

	[observer operationDidStart:operation];

	XCTAssertEqual(captured, operation);
}

- (void)testProduceHandlerReceivesBothOperations {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	NSOperation *produced = [[NSOperation alloc] init];
	__block MADOperation *capturedOperation = nil;
	__block NSOperation *capturedProduced = nil;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:nil
																 produceHandler:^(MADOperation *op, NSOperation *newOp) {
		capturedOperation = op;
		capturedProduced = newOp;
	} finishHandler:nil];

	[observer operation:operation didProduceOperation:produced];

	XCTAssertEqual(capturedOperation, operation);
	XCTAssertEqual(capturedProduced, produced);
}

- (void)testFinishHandlerReceivesOperationAndErrors {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	NSError *error = [NSError errorWithDomain:@"com.example.tests" code:7 userInfo:nil];
	NSArray<NSError *> *errors = @[error];
	__block MADOperation *capturedOperation = nil;
	__block NSArray<NSError *> *capturedErrors = nil;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:nil
																 produceHandler:nil
																  finishHandler:^(MADOperation *op, NSArray<NSError *> *errs) {
		capturedOperation = op;
		capturedErrors = errs;
	}];

	[observer operationDidFinish:operation errors:errors];

	XCTAssertEqual(capturedOperation, operation);
	XCTAssertEqualObjects(capturedErrors, errors);
}

- (void)testFinishOnlyInitializerLeavesTheOtherHandlersUnset {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	__block NSUInteger finishCount = 0;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithFinishHandler:^(MADOperation *op, NSArray<NSError *> *errs) {
		finishCount++;
	}];

	// No start or produce handler was supplied; those notifications must be no-ops.
	XCTAssertNoThrow([observer operationDidStart:operation]);
	XCTAssertNoThrow([observer operation:operation didProduceOperation:[[NSOperation alloc] init]]);
	[observer operationDidFinish:operation errors:nil];

	XCTAssertEqual(finishCount, (NSUInteger)1);
}

- (void)testAllNilHandlersAreSafe {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:nil
																 produceHandler:nil
																  finishHandler:nil];

	XCTAssertNoThrow([observer operationDidStart:operation]);
	XCTAssertNoThrow([observer operation:operation didProduceOperation:[[NSOperation alloc] init]]);
	XCTAssertNoThrow([observer operationDidFinish:operation errors:nil]);
}

#pragma mark - Driven by a real operation

- (void)testObserverReceivesTheOperationLifecycle {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	NSOperation *produced = [[NSOperation alloc] init];

	__block NSUInteger startCount = 0;
	__block NSUInteger produceCount = 0;
	__block NSUInteger finishCount = 0;
	__block NSArray<NSError *> *finishedErrors = nil;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:^(MADOperation *op) {
		startCount++;
	} produceHandler:^(MADOperation *op, NSOperation *newOp) {
		produceCount++;
	} finishHandler:^(MADOperation *op, NSArray<NSError *> *errors) {
		finishCount++;
		finishedErrors = errors;
	}];
	[operation addObserver:observer];

	// -willEnqueue evaluates the (empty) conditions and reaches Ready, which is the
	// state -main requires; -start then runs the whole lifecycle synchronously.
	[operation willEnqueue];
	[operation start];
	[operation produceOperation:produced];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(startCount, (NSUInteger)1);
	XCTAssertEqual(finishCount, (NSUInteger)1);
	XCTAssertEqual(finishedErrors.count, (NSUInteger)0);
	// -produceOperation: was called after the run, and still notifies.
	XCTAssertEqual(produceCount, (NSUInteger)1);
}

@end
