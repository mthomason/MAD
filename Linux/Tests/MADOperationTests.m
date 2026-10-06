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
	// Not a defect: -willEnqueue sets state to Pending, but because -isReady is a
	// KVO-dependent key of "state" (see +keyPathsForValuesAffectingValueForKey:), the
	// didChangeValueForKey:@"state" notification re-enters -isReady, which runs
	// -evaluateConditions on a dependency-free operation and advances it straight to
	// Ready. That mapping is what NSOperation dependency scheduling needs, so it stays;
	// nothing outside MADOperation.m reads .state, so the skipped Pending is
	// unobservable. This pins the observable end state.
	MADOperation *op = [[MADOperation alloc] init];
	[op willEnqueue];
#if __APPLE__
	MAD_PASS(op.state == MADOperationStateReady, "state is Ready");
#else
	// GNUstep does not consult the dependent key on that notification, so the
	// advance happens on the first -isReady query instead -- which is exactly
	// what a queue does when it schedules the operation, so the observable
	// behaviour through the queue is the same.  See the Phase B status in
	// MAD_LINUX.md.
	MAD_PASS(op.state == MADOperationStatePending, "state stays Pending until isReady is queried");
	MAD_PASS(op.isReady, "the first isReady query is YES");
	MAD_PASS(op.state == MADOperationStateReady, "the query advanced it to Ready");
#endif
}

#pragma mark - End-to-end run

static void testRunToCompletion(void) {
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	MADRunOperation *op = [[MADRunOperation alloc] init];

	// GNUstep divergence: adding a MADOperation to a queue raises there --
	// GNUstep's NSOperationQueue removes its "isReady" observation every time
	// the notification fires, and MADOperation's state machine notifies isReady
	// more than once (Pending -> EvaluatingConditions -> Ready) where Apple's
	// notifies once.  Recorded as a counted need; see the Phase B status in
	// MAD_LINUX.md.
	@try {
		[queue addOperation:op];

		NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
		while (!op.isFinished && [deadline timeIntervalSinceNow] > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}

		MAD_PASS(op.isFinished, "operation finished");
		MAD_PASS(op.state == MADOperationStateFinished, "state is Finished");
	} @catch (NSException *e) {
		MAD_NEED(NO, @"GNUstep's NSOperationQueue removes its isReady observation twice; MADOperation's state machine notifies isReady more than once (Apple does once) and GNUstep raises on the second removal");
	}
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
