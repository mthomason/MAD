//
//  MADBlockObserverTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADBlockObserverTests.m: coverage for
//  MADBlockObserver, the block-based MADOperationObserver the app uses to
//  hang start/produce/finish handlers on an operation without a delegate.
//
//  Two layers are pinned, as on Apple: the protocol methods called directly
//  (each handler sees the exact operation / produced operation / error list,
//  and a nil handler is a safe no-op), and one real run where MADOperation
//  drives the observer through -start and -finish.
//
//  The real -beginBackgroundTask needs a UIApplication, which a test process
//  does not have; the test subclass stubs it out and -execute finishes
//  immediately so the run is synchronous -- the same shape as MADOperationTests.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADBlockObserver.h>
#import <MADFoundation/MADOperation.h>

@interface MADObserverOperation : MADOperation
@end

@implementation MADObserverOperation
- (void)beginBackgroundTask {}
- (void)endBackgroundTask {}
- (void)execute { [self finish]; }
@end

#pragma mark - Handlers, called directly

static void testStartHandlerReceivesTheOperation(void) {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	__block MADOperation *captured = nil;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:^(MADOperation *op) {
		captured = [op retain];	// MRC __block variables do not retain
	} produceHandler:nil finishHandler:nil];

	[observer operationDidStart:operation];

	MAD_PASS(captured == operation, "the start handler received the operation");
}

static void testProduceHandlerReceivesBothOperations(void) {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	NSOperation *produced = [[NSOperation alloc] init];
	__block MADOperation *capturedOperation = nil;
	__block NSOperation *capturedProduced = nil;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:nil
																 produceHandler:^(MADOperation *op, NSOperation *newOp) {
		capturedOperation = [op retain];
		capturedProduced = [newOp retain];
	} finishHandler:nil];

	[observer operation:operation didProduceOperation:produced];

	MAD_PASS(capturedOperation == operation, "the produce handler received the operation");
	MAD_PASS(capturedProduced == produced, "the produce handler received the produced operation");
}

static void testFinishHandlerReceivesOperationAndErrors(void) {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	NSError *error = [NSError errorWithDomain:@"com.example.tests" code:7 userInfo:nil];
	NSArray<NSError *> *errors = @[error];
	__block MADOperation *capturedOperation = nil;
	__block NSArray<NSError *> *capturedErrors = nil;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:nil
																 produceHandler:nil
																  finishHandler:^(MADOperation *op, NSArray<NSError *> *errs) {
		capturedOperation = [op retain];
		capturedErrors = [errs retain];
	}];

	[observer operationDidFinish:operation errors:errors];

	MAD_PASS(capturedOperation == operation, "the finish handler received the operation");
	MAD_PASS_EQUAL(capturedErrors, errors, "the finish handler received the errors");
}

static void testFinishOnlyInitializerLeavesTheOtherHandlersUnset(void) {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	__block NSUInteger finishCount = 0;
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithFinishHandler:^(MADOperation *op, NSArray<NSError *> *errs) {
		finishCount++;
	}];

	// No start or produce handler was supplied; those notifications must be no-ops.
	MAD_NO_THROW([observer operationDidStart:operation], "a nil start handler is a no-op");
	MAD_NO_THROW([observer operation:operation didProduceOperation:[[NSOperation alloc] init]],
				 "a nil produce handler is a no-op");
	[observer operationDidFinish:operation errors:nil];

	MAD_PASS(finishCount == (NSUInteger)1, "the finish handler ran once");
}

static void testAllNilHandlersAreSafe(void) {
	MADObserverOperation *operation = [[MADObserverOperation alloc] init];
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithStartHandler:nil
																 produceHandler:nil
																  finishHandler:nil];

	MAD_NO_THROW([observer operationDidStart:operation], "all-nil start is a no-op");
	MAD_NO_THROW([observer operation:operation didProduceOperation:[[NSOperation alloc] init]],
				 "all-nil produce is a no-op");
	MAD_NO_THROW([observer operationDidFinish:operation errors:nil], "all-nil finish is a no-op");
}

#pragma mark - Driven by a real operation

static void testObserverReceivesTheOperationLifecycle(void) {
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
		finishedErrors = [errors retain];	// MRC __block variables do not retain
	}];
	[operation addObserver:observer];

	// -willEnqueue evaluates the (empty) conditions and reaches Ready, which is
	// the state -main requires; -start then runs the whole lifecycle synchronously.
	[operation willEnqueue];
	[operation start];
	[operation produceOperation:produced];

	MAD_PASS(operation.isFinished, "the operation finished");
	MAD_PASS(startCount == (NSUInteger)1, "one start callback");
	MAD_PASS(finishCount == (NSUInteger)1, "one finish callback");
	MAD_PASS(finishedErrors.count == (NSUInteger)0, "no errors");
	// -produceOperation: was called after the run, and still notifies.
	MAD_PASS(produceCount == (NSUInteger)1, "one produce callback");
}

MAD_TEST_MAIN("MADBlockObserverTests",
	MAD_TEST(testStartHandlerReceivesTheOperation),
	MAD_TEST(testProduceHandlerReceivesBothOperations),
	MAD_TEST(testFinishHandlerReceivesOperationAndErrors),
	MAD_TEST(testFinishOnlyInitializerLeavesTheOtherHandlersUnset),
	MAD_TEST(testAllNilHandlersAreSafe),
	MAD_TEST(testObserverReceivesTheOperationLifecycle));
