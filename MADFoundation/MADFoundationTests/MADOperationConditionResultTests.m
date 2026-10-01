//
//  MADOperationConditionResultTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADOperationConditionResult: the four public factories, the
//  `-error` accessor, and +evaluateConditions:operation:completion:.
//
//  The conditions evaluated here are test-only stubs. The real condition classes
//  are covered by MADOperationConditionTests.m.
//

#import <XCTest/XCTest.h>

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
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
			completion([self evaluateForOperation:operation]);
		});
	} else {
		completion([self evaluateForOperation:operation]);
	}
}

@end

@interface MADOperationConditionResultTests : XCTestCase
@end

@implementation MADOperationConditionResultTests

#pragma mark - Factories

- (void)testSatisfiedResult {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultSatisfied];
	XCTAssertTrue(result.isSucceed);
	XCTAssertNil(result.error);
}

- (void)testSatisfiedResultVendsNoError {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResult:YES
																								name:@"SomeCondition"];
	XCTAssertTrue(result.isSucceed);
	XCTAssertNil(result.error);
}

- (void)testFailedResultCarriesTheConditionName {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResult:NO
																								name:@"SomeCondition"];
	XCTAssertFalse(result.isSucceed);
	XCTAssertNotNil(result.error);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], @"SomeCondition");
}

// MADOperationConditionKey is the documented lookup key for "which condition failed".
- (void)testConditionKeyConstant {
	XCTAssertEqualObjects(MADOperationConditionKey, @"OperationCondition");
}

- (void)testFailedNotSatisfiedResultShape {
	MADOperationConditionResult *result =
		[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:@"SomeCondition"];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqual(result.error.code, (NSInteger)-82795);
	// The domain is the name of the result class, not the condition -- the condition
	// name travels in userInfo instead.
	XCTAssertEqualObjects(result.error.domain, @"MADOperationConditionResult");
	XCTAssertEqualObjects(result.error.userInfo[NSLocalizedFailureReasonErrorKey], @"Not Satisfied");
	XCTAssertEqualObjects(result.error.userInfo[NSLocalizedDescriptionKey],
						  @"Condition 'SomeCondition' not Satisfied");
}

- (void)testFailedResultKeepsTheSuppliedError {
	NSError *error = [NSError errorWithDomain:@"com.example" code:99 userInfo:nil];
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultFailed:error];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error, error);
}

// A "failed" result with no error is a programming error, so the factory substitutes
// a generic one rather than handing back a failure with nothing to report.
- (void)testFailedResultWithNilErrorSubstitutesAGenericError {
	MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultFailed:nil];

	XCTAssertFalse(result.isSucceed);
	XCTAssertNotNil(result.error);
	XCTAssertEqual(result.error.code, (NSInteger)32874);
	XCTAssertEqualObjects(result.error.userInfo[NSLocalizedFailureReasonErrorKey], @"Internal Error");
}

// A plain -init is possible because the class does not close it off. It lands in a
// state no factory produces: not satisfied, but with no error to explain why.
- (void)testInitDefaultsToNotSatisfiedWithNoError {
	MADOperationConditionResult *result = [[MADOperationConditionResult alloc] init];
	XCTAssertFalse(result.isSucceed);
	XCTAssertNil(result.error);
}

#pragma mark - +evaluateConditions:operation:completion:

// The no-conditions case short-circuits and calls back on the calling thread, unlike
// the general case below. Callers that assume an asynchronous callback would be wrong
// here, which is worth pinning.
- (void)testNoConditionsCompletesSynchronouslyWithNoErrors {
	MADOperation *operation = [[MADOperation alloc] init];
	__block BOOL calledBack = NO;
	__block NSArray *errors = nil;

	[MADOperationConditionResult evaluateConditions:@[]
										  operation:operation
										 completion:^(NSArray<NSError *> *failures) {
		calledBack = YES;
		errors = failures;
	}];

	XCTAssertTrue(calledBack, @"The empty-conditions path is synchronous");
	XCTAssertNotNil(errors);
	XCTAssertEqual(errors.count, (NSUInteger)0);
}

- (void)testAllSatisfiedConditionsReportNoErrors {
	MADStubCondition *a = [[MADStubCondition alloc] init];
	MADStubCondition *b = [[MADStubCondition alloc] init];
	MADOperation *operation = [[MADOperation alloc] init];

	XCTestExpectation *expectation = [self expectationWithDescription:@"conditions"];
	__block NSArray<NSError *> *errors = nil;

	[MADOperationConditionResult evaluateConditions:@[a, b]
										  operation:operation
										 completion:^(NSArray<NSError *> *failures) {
		errors = failures;
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	XCTAssertEqual(errors.count, (NSUInteger)0);
}

- (void)testOnlyFailedConditionsContributeErrors {
	MADStubCondition *satisfied = [[MADStubCondition alloc] init];
	satisfied.conditionName = @"Happy";
	satisfied.satisfied = YES;

	MADStubCondition *unsatisfied = [[MADStubCondition alloc] init];
	unsatisfied.conditionName = @"Sad";
	unsatisfied.satisfied = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	XCTestExpectation *expectation = [self expectationWithDescription:@"conditions"];
	__block NSArray<NSError *> *errors = nil;

	[MADOperationConditionResult evaluateConditions:@[satisfied, unsatisfied]
										  operation:operation
										 completion:^(NSArray<NSError *> *failures) {
		errors = failures;
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];

	XCTAssertEqual(errors.count, (NSUInteger)1);
	XCTAssertEqualObjects(errors.firstObject.userInfo[MADOperationConditionKey], @"Sad");
}

- (void)testAsynchronousConditionsAreAwaited {
	MADStubCondition *a = [[MADStubCondition alloc] init];
	a.completesAsynchronously = YES;
	a.satisfied = NO;
	a.conditionName = @"Async";

	MADStubCondition *b = [[MADStubCondition alloc] init];
	b.completesAsynchronously = YES;
	b.satisfied = NO;
	b.conditionName = @"Async2";

	MADOperation *operation = [[MADOperation alloc] init];
	XCTestExpectation *expectation = [self expectationWithDescription:@"conditions"];
	__block NSArray<NSError *> *errors = nil;

	[MADOperationConditionResult evaluateConditions:@[a, b]
										  operation:operation
										 completion:^(NSArray<NSError *> *failures) {
		errors = failures;
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	XCTAssertEqual(errors.count, (NSUInteger)2);
}

// A cancelled operation gets an extra synthetic error appended, on top of whatever the
// conditions themselves reported.
- (void)testCancelledOperationAddsACancellationError {
	MADStubCondition *satisfied = [[MADStubCondition alloc] init];
	satisfied.satisfied = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation cancel];

	XCTestExpectation *expectation = [self expectationWithDescription:@"conditions"];
	__block NSArray<NSError *> *errors = nil;

	[MADOperationConditionResult evaluateConditions:@[satisfied]
										  operation:operation
										 completion:^(NSArray<NSError *> *failures) {
		errors = failures;
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];

	XCTAssertEqual(errors.count, (NSUInteger)1);
	XCTAssertEqualObjects(errors.firstObject.domain, @"OperationErrors");
	XCTAssertEqual(errors.firstObject.code, (NSInteger)-82796);
}

- (void)testCompletionIsNotCalledBeforeTheMethodReturnsForTheAsyncPath {
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

	XCTAssertFalse(calledBack, @"The non-empty path completes from a dispatch_group");
}

@end
