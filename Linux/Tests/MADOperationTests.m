//
//  MADOperationTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADOperationTests.m: coverage for
//  MADOperation, the base class of the app's async operation framework.
//  Exercises the state-machine naming, lazy collections, the condition/
//  observer wiring, the finishing path, and one end-to-end run.
//
//  The original's note still holds off Apple: the real -main starts a
//  background task, so the end-to-end test runs a subclass that stubs the
//  (now no-op) methods out.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationQueue.h>

@interface MADRunOperation : MADOperation
@end
@implementation MADRunOperation
- (void)beginBackgroundTask {}
- (void)endBackgroundTask {}
- (void)execute { [self finish]; }
@end

#pragma mark - State naming

static void testStateNameMapping(void) {
	MAD_PASS_EQUAL(NSStringFromMADOperationState(MADOperationStateInitialized), @"Initialized", "Initialized");
	MAD_PASS_EQUAL(NSStringFromMADOperationState(MADOperationStatePending), @"Pending", "Pending");
	MAD_PASS_EQUAL(NSStringFromMADOperationState(MADOperationStateEvaluatingConditions), @"EvaluatingConditions", "EvaluatingConditions");
	MAD_PASS_EQUAL(NSStringFromMADOperationState(MADOperationStateReady), @"Ready", "Ready");
	MAD_PASS_EQUAL(NSStringFromMADOperationState(MADOperationStateExecuting), @"Executing", "Executing");
	MAD_PASS_EQUAL(NSStringFromMADOperationState(MADOperationStateFinishing), @"Finishing", "Finishing");
	MAD_PASS_EQUAL(NSStringFromMADOperationState(MADOperationStateFinished), @"Finished", "Finished");
}

static void testStateNameUnknown(void) {
	MAD_PASS_EQUAL(NSStringFromMADOperationState((MADOperationState)999), @"Unknown", "unknown state");
}

#pragma mark - Initial state

static void testInitDefaults(void) {
	MADOperation *op = [[MADOperation alloc] init];
	MAD_PASS(op.state == MADOperationStateInitialized, "state is Initialized");
	MAD_PASS(op.identifier == (NSUInteger)0, "identifier is zero");
	MAD_PASS(!op.isReady, "not ready");
	MAD_PASS(!op.isExecuting, "not executing");
	MAD_PASS(!op.isFinished, "not finished");
}

static void testIdentifierIsSettable(void) {
	MADOperation *op = [[MADOperation alloc] init];
	op.identifier = 42;
	MAD_PASS(op.identifier == (NSUInteger)42, "identifier round trips");
}

static void testLazyCollectionsAreEmpty(void) {
	MADOperation *op = [[MADOperation alloc] init];
	MAD_PASS(op.errors != nil, "errors exists");
	MAD_PASS(op.errors.count == (NSUInteger)0, "errors is empty");
	MAD_PASS(op.conditions != nil, "conditions exists");
	MAD_PASS(op.conditions.count == (NSUInteger)0, "conditions is empty");
	MAD_PASS(op.observers != nil, "observers exists");
	MAD_PASS(op.observers.count == (NSUInteger)0, "observers is empty");
}

#pragma mark - Conditions and observers

static void testAddCondition(void) {
	MADOperation *op = [[MADOperation alloc] init];
	// Any object answering the condition protocol works for wiring coverage.
	NSObject *condition = [[NSObject alloc] init];
	[op addCondition:(id)condition];
	MAD_PASS(op.conditions.count == (NSUInteger)1, "one condition");
}

static void testAddObserver(void) {
	MADOperation *op = [[MADOperation alloc] init];
	NSObject *observer = [[NSObject alloc] init];
	[op addObserver:(id)observer];
	MAD_PASS(op.observers.count == (NSUInteger)1, "one observer");
}

#pragma mark - Finishing

static void testFinishTransitionsToFinished(void) {
	MADOperation *op = [[MADOperation alloc] init];
	[op finish];
	MAD_PASS(op.state == MADOperationStateFinished, "state is Finished");
	MAD_PASS(op.isFinished, "isFinished");
	MAD_PASS(!op.isReady, "not ready");
	MAD_PASS(!op.isExecuting, "not executing");
	MAD_PASS(op.errors.count == (NSUInteger)0, "no errors");
}

static void testFinishWithErrorPopulatesErrors(void) {
	MADOperation *op = [[MADOperation alloc] init];
	NSError *error = [NSError errorWithDomain:@"com.example" code:7 userInfo:nil];
	[op finishWithError:error];
	MAD_PASS(op.isFinished, "isFinished");
	MAD_PASS(op.errors.count == (NSUInteger)1, "one error");
	MAD_PASS(op.errors.firstObject.code == 7, "error code");
	MAD_PASS_EQUAL(op.errors.firstObject.domain, @"com.example", "error domain");
}

static void testFinishWithErrorsArray(void) {
	MADOperation *op = [[MADOperation alloc] init];
	NSError *a = [NSError errorWithDomain:@"d" code:1 userInfo:nil];
	NSError *b = [NSError errorWithDomain:@"d" code:2 userInfo:nil];
	[op finish:@[a, b]];
	MAD_PASS(op.isFinished, "isFinished");
	MAD_PASS(op.errors.count == (NSUInteger)2, "two errors");
}

static void testFinishIsIdempotent(void) {
	MADOperation *op = [[MADOperation alloc] init];
	NSError *error = [NSError errorWithDomain:@"d" code:1 userInfo:nil];
	[op finishWithError:error];
	[op finishWithError:error];
	MAD_PASS(op.errors.count == (NSUInteger)1, "still one error");
}

static void testWillEnqueueAdvancesPastPendingToReady(void) {
	// -willEnqueue drives the advance explicitly: Pending, then condition
	// evaluation for a dependency-free operation, so it is Ready before the
	// queue starts observing -- the point of the fix for GNUstep's queue.
	MADOperation *op = [[MADOperation alloc] init];
	[op willEnqueue];
	MAD_PASS(op.state == MADOperationStateReady, "state is Ready");
	MAD_PASS(op.isReady, "isReady");
}

#pragma mark - End-to-end run

static void testRunToCompletion(void) {
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	MADRunOperation *op = [[MADRunOperation alloc] init];

	[queue addOperation:op];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
	while (!op.isFinished && [deadline timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}

	MAD_PASS(op.isFinished, "operation finished");
	MAD_PASS(op.state == MADOperationStateFinished, "state is Finished");
}

MAD_TEST_MAIN("MADOperationTests",
	MAD_TEST(testStateNameMapping),
	MAD_TEST(testStateNameUnknown),
	MAD_TEST(testInitDefaults),
	MAD_TEST(testIdentifierIsSettable),
	MAD_TEST(testLazyCollectionsAreEmpty),
	MAD_TEST(testAddCondition),
	MAD_TEST(testAddObserver),
	MAD_TEST(testFinishTransitionsToFinished),
	MAD_TEST(testFinishWithErrorPopulatesErrors),
	MAD_TEST(testFinishWithErrorsArray),
	MAD_TEST(testFinishIsIdempotent),
	MAD_TEST(testWillEnqueueAdvancesPastPendingToReady),
	MAD_TEST(testRunToCompletion));
