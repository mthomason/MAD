//
//  MADOperationConditionResultTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADOperationConditionResultTests.m: coverage
//  for MADOperationConditionResult: the public factories, the -error accessor,
//  and +evaluateConditions:operation:completion:.
//
//  XCTestExpectation is not available on GNUstep; the asynchronous cases poll
//  the run loop with a deadline (MADWaitForFlag) instead.  The stub condition
//  also swaps Apple's QOS_CLASS_DEFAULT for the classic queue priority, which
//  is what GNUstep's libdispatch headers define.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>

// A condition that reports whatever the test tells it to, either synchronously or
// from a background queue, so both halves of the protocol can be exercised.
@interface MADStubCondition : NSObject <MADOperationCondition>
@property (nonatomic, copy) NSString *conditionName;
@property (nonatomic, assign) BOOL satisfied;
@property (nonatomic, assign) BOOL completesAsynchronously;
@end

@implementation MADStubCondition

- (instancetype)init {
	if (self = [super init]) {
		_conditionName = @"MADStubCondition";
		_satisfied = YES;
	}
	return self;
}

- (NSString *)name { return self.conditionName; }
- (BOOL)isMutuallyExclusive { return NO; }
- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	return [MADOperationConditionResult newOperationConditionResult:self.satisfied
															   name:self.conditionName];
}

- (void)evaluateForOperation:(MADOperation *)operation
				  completion:(void (^)(MADOperationConditionResult *))completion {
	if (self.completesAsynchronously) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			completion([self evaluateForOperation:operation]);
		});
	} else {
		completion([self evaluateForOperation:operation]);
	}
}

@end

#pragma mark - Factories

static void testSatisfiedResult(void) {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultSatisfied];
	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS(result.error == nil, "no error");
}

static void testSatisfiedResultVendsNoError(void) {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResult:YES
																								name:@"SomeCondition"];
	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS(result.error == nil, "no error");
}

static void testFailedResultCarriesTheConditionName(void) {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResult:NO
																								name:@"SomeCondition"];
	MAD_PASS(!result.isSucceed, "fails");
	MAD_PASS(result.error != nil, "has an error");
	MAD_PASS_EQUAL(result.error.userInfo[MADOperationConditionKey], @"SomeCondition", "error carries the condition name");
}

// MADOperationConditionKey is the documented lookup key for "which condition failed".
static void testConditionKeyConstant(void) {
	MAD_PASS_EQUAL(MADOperationConditionKey, @"OperationCondition", "key constant");
}

static void testFailedNotSatisfiedResultShape(void) {
	MADOperationConditionResult *result =
		[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:@"SomeCondition"];

	MAD_PASS(!result.isSucceed, "fails");
	MAD_PASS(result.error.code == (NSInteger)-82795, "error code");
	// The domain is a fixed constant; the condition name travels in userInfo.
	MAD_PASS_EQUAL(result.error.domain, @"MADOperationCondition", "error domain");
	MAD_PASS_EQUAL(result.error.userInfo[NSLocalizedFailureReasonErrorKey], @"Not Satisfied", "failure reason");
	MAD_PASS_EQUAL(result.error.userInfo[NSLocalizedDescriptionKey],
				   @"Condition 'SomeCondition' not Satisfied", "description");
}

static void testFailedResultKeepsTheSuppliedError(void) {
	NSError *error = [NSError errorWithDomain:@"com.example" code:99 userInfo:nil];
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultFailed:error];

	MAD_PASS(!result.isSucceed, "fails");
	MAD_PASS_EQUAL(result.error, error, "keeps the supplied error");
}

// A "failed" result with no error is a programming error, so the factory substitutes
// a generic one rather than handing back a failure with nothing to report.
static void testFailedResultWithNilErrorSubstitutesAGenericError(void) {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultFailed:nil];

	MAD_PASS(!result.isSucceed, "fails");
	MAD_PASS(result.error != nil, "has an error");
	MAD_PASS(result.error.code == (NSInteger)32874, "generic error code");
	MAD_PASS_EQUAL(result.error.userInfo[NSLocalizedFailureReasonErrorKey], @"Internal Error", "failure reason");
}

// A plain -init is possible because the class does not close it off. It lands in a
// state no factory produces: not satisfied, but with no error to explain why.
static void testInitDefaultsToNotSatisfiedWithNoError(void) {
	MADOperationConditionResult *result = [[MADOperationConditionResult alloc] init];
	MAD_PASS(!result.isSucceed, "not satisfied");
	MAD_PASS(result.error == nil, "no error");
}

#pragma mark - +evaluateConditions:operation:completion:

// The no-conditions case short-circuits and calls back on the calling thread, unlike
// the general case below. Callers that assume an asynchronous callback would be wrong
// here, which is worth pinning.
static void testNoConditionsCompletesSynchronouslyWithNoErrors(void) {
	MADOperation *operation = [[MADOperation alloc] init];
	__block BOOL calledBack = NO;
	__block NSArray *errors = nil;

	[MADOperationConditionResult evaluateConditions:@[]
										  operation:operation
										 completion:^(NSArray<NSError *> *failures) {
		calledBack = YES;
		errors = [failures retain];
	}];

	MAD_PASS(calledBack, "the empty-conditions path is synchronous");
	MAD_PASS(errors != nil, "errors is not nil");
	MAD_PASS(errors.count == (NSUInteger)0, "no errors");
}

static void testAllSatisfiedConditionsReportNoErrors(void) {
	MADStubCondition *a = [[MADStubCondition alloc] init];
	MADStubCondition *b = [[MADStubCondition alloc] init];
	MADOperation *operation = [[MADOperation alloc] init];

	__block BOOL calledBack = NO;
	__block NSArray<NSError *> *errors = nil;
	void (^completion)(NSArray<NSError *> *) = [^(NSArray<NSError *> *failures) {
		errors = [failures retain];
		calledBack = YES;
	} copy];

	[MADOperationConditionResult evaluateConditions:@[a, b]
										  operation:operation
										 completion:completion];

	MAD_PASS(MADWaitForFlag(&calledBack, 5.0), "completion called");
	MAD_PASS(errors.count == (NSUInteger)0, "no errors");
}

static void testOnlyFailedConditionsContributeErrors(void) {
	MADStubCondition *satisfied = [[MADStubCondition alloc] init];
	satisfied.conditionName = @"Happy";
	satisfied.satisfied = YES;

	MADStubCondition *unsatisfied = [[MADStubCondition alloc] init];
	unsatisfied.conditionName = @"Sad";
	unsatisfied.satisfied = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	__block BOOL calledBack = NO;
	__block NSArray<NSError *> *errors = nil;
	void (^completion)(NSArray<NSError *> *) = [^(NSArray<NSError *> *failures) {
		errors = [failures retain];
		calledBack = YES;
	} copy];

	[MADOperationConditionResult evaluateConditions:@[satisfied, unsatisfied]
										  operation:operation
										 completion:completion];

	MAD_PASS(MADWaitForFlag(&calledBack, 5.0), "completion called");
	MAD_PASS(errors.count == (NSUInteger)1, "one error");
	MAD_PASS_EQUAL(errors.firstObject.userInfo[MADOperationConditionKey], @"Sad", "the failed condition is named");
}

static void testAsynchronousConditionsAreAwaited(void) {
	MADStubCondition *a = [[MADStubCondition alloc] init];
	a.completesAsynchronously = YES;
	a.satisfied = NO;
	a.conditionName = @"Async";

	MADStubCondition *b = [[MADStubCondition alloc] init];
	b.completesAsynchronously = YES;
	b.satisfied = NO;
	b.conditionName = @"Async2";

	MADOperation *operation = [[MADOperation alloc] init];
	__block BOOL calledBack = NO;
	__block NSArray<NSError *> *errors = nil;
	void (^completion)(NSArray<NSError *> *) = [^(NSArray<NSError *> *failures) {
		errors = [failures retain];
		calledBack = YES;
	} copy];

	[MADOperationConditionResult evaluateConditions:@[a, b]
										  operation:operation
										 completion:completion];

	MAD_PASS(MADWaitForFlag(&calledBack, 5.0), "completion called");
	MAD_PASS(errors.count == (NSUInteger)2, "two errors");
}

// A cancelled operation gets an extra synthetic error appended, on top of whatever the
// conditions themselves reported.
static void testCancelledOperationAddsACancellationError(void) {
	MADStubCondition *satisfied = [[MADStubCondition alloc] init];
	satisfied.satisfied = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation cancel];

	__block BOOL calledBack = NO;
	__block NSArray<NSError *> *errors = nil;
	void (^completion)(NSArray<NSError *> *) = [^(NSArray<NSError *> *failures) {
		errors = [failures retain];
		calledBack = YES;
	} copy];

	[MADOperationConditionResult evaluateConditions:@[satisfied]
										  operation:operation
										 completion:completion];

	MAD_PASS(MADWaitForFlag(&calledBack, 5.0), "completion called");
	MAD_PASS(errors.count == (NSUInteger)1, "one error");
	MAD_PASS_EQUAL(errors.firstObject.domain, @"OperationErrors", "cancellation error domain");
	MAD_PASS(errors.firstObject.code == (NSInteger)-82796, "cancellation error code");
}

static void testCompletionIsNotCalledBeforeTheMethodReturnsForTheAsyncPath(void) {
	// The general path is asynchronous: a caller that reads the result immediately
	// after -evaluateConditions:... returns would still see nothing.
	MADStubCondition *condition = [[MADStubCondition alloc] init];
	MADOperation *operation = [[MADOperation alloc] init];
	__block BOOL calledBack = NO;

	[MADOperationConditionResult evaluateConditions:@[condition]
										  operation:operation
										 completion:^(NSArray<NSError *> *failures) {
		calledBack = YES;
	}];

	MAD_PASS(!calledBack, "the non-empty path completes from a dispatch_group");
}

MAD_TEST_MAIN("MADOperationConditionResultTests",
	MAD_TEST(testSatisfiedResult),
	MAD_TEST(testSatisfiedResultVendsNoError),
	MAD_TEST(testFailedResultCarriesTheConditionName),
	MAD_TEST(testConditionKeyConstant),
	MAD_TEST(testFailedNotSatisfiedResultShape),
	MAD_TEST(testFailedResultKeepsTheSuppliedError),
	MAD_TEST(testFailedResultWithNilErrorSubstitutesAGenericError),
	MAD_TEST(testInitDefaultsToNotSatisfiedWithNoError),
	MAD_TEST(testNoConditionsCompletesSynchronouslyWithNoErrors),
	MAD_TEST(testAllSatisfiedConditionsReportNoErrors),
	MAD_TEST(testOnlyFailedConditionsContributeErrors),
	MAD_TEST(testAsynchronousConditionsAreAwaited),
	MAD_TEST(testCancelledOperationAddsACancellationError),
	MAD_TEST(testCompletionIsNotCalledBeforeTheMethodReturnsForTheAsyncPath));
