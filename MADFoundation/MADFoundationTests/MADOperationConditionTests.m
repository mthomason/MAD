//
//  MADOperationConditionTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the four condition classes that MADFoundation ships with. All four
//  work the same way: they look at the conditionalized operation's *dependencies*,
//  find the one that publishes the result they care about, and turn its outcome into
//  a MADOperationConditionResult.
//
//  The dependencies are test-only NSOperation stubs. In the app the real ones are the
//  keychain-read operations (which publish a result string) and the database
//  test-connection operation (which publishes pass/fail).
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADOperationConditionHasResultString.h>
#import <MADFoundation/MADOperationConditionHasResultStringResult.h>
#import <MADFoundation/MADOperationConditionMissingResultString.h>
#import <MADFoundation/MADOperationConditionTestConnectionSuccess.h>
#import <MADFoundation/MADOperationResultStringProtocol.h>
#import <MADFoundation/MADOperationTestResults.h>

#pragma mark - Test doubles

// Stands in for the keychain-read operations: publishes a value under a key, and
// whether the read succeeded.
@interface MADResultStringDependency : NSOperation <MADOperationResultStringProtocol>
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, assign) MADKeyChainReadOperationTypes readOperationType;
@end

@implementation MADResultStringDependency
- (instancetype)init {
	if (self = [super init]) { _readOperationType = MADKeyChainReadOperationTypeUsername; }
	return self;
}
@end

// Stands in for the database test-connection operation.
@interface MADTestConnectionDependency : NSOperation <MADOperationTestResults>
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign, getter=isSuccess) BOOL success;
@end

@implementation MADTestConnectionDependency
@end

@interface MADOperationConditionTests : XCTestCase
@end

@implementation MADOperationConditionTests

#pragma mark - MADOperationConditionHasResultString

- (void)testHasResultStringIdentity {
	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];

	XCTAssertEqualObjects(condition.key, @"username");
	XCTAssertEqualObjects(condition.name, @"MADOperationConditionHasResultString");
	XCTAssertFalse(condition.isMutuallyExclusive);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

- (void)testHasResultStringWithoutDependenciesFails {
	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperation *operation = [[MADOperation alloc] init];

	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

- (void)testHasResultStringWithMatchingSuccessfulDependencySucceeds {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertTrue(result.isSucceed);
	XCTAssertNil(result.error);
	// The successful path yields the richer subclass so the value travels with the result.
	XCTAssertTrue([result isKindOfClass:[MADOperationConditionHasResultStringResult class]]);
	XCTAssertEqualObjects(((MADOperationConditionHasResultStringResult *)result).result, @"orlando");
}

- (void)testHasResultStringWithMatchingFailingDependencyFails {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

- (void)testHasResultStringWithNonMatchingKeyFails {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"password";
	dependency.value = @"hunter2";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
}

// A dependency that does not publish a result string at all is skipped rather than
// mistaken for a match.
- (void)testHasResultStringIgnoresDependenciesThatDoNotPublishAResultString {
	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:[[NSOperation alloc] init]];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
}

- (void)testHasResultStringFindsTheMatchingDependencyAmongMany {
	MADResultStringDependency *other = [[MADResultStringDependency alloc] init];
	other.key = @"password";
	other.value = @"hunter2";
	other.success = YES;

	MADResultStringDependency *wanted = [[MADResultStringDependency alloc] init];
	wanted.key = @"username";
	wanted.value = @"orlando";
	wanted.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:other];
	[operation addDependency:wanted];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertTrue(result.isSucceed);
	XCTAssertEqualObjects(((MADOperationConditionHasResultStringResult *)result).result, @"orlando");
}

- (void)testHasResultStringAsyncEvaluationCallsBack {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];

	XCTestExpectation *expectation = [self expectationWithDescription:@"condition"];
	[condition evaluateForOperation:operation completion:^(MADOperationConditionResult *result) {
		XCTAssertTrue(result.isSucceed);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - MADOperationConditionHasResultStringResult

- (void)testResultFactoryWithSatisfiedValue {
	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationConditionResult:YES
																		 value:@"orlando"
																		  name:@"SomeCondition"];

	XCTAssertTrue(result.isSucceed);
	XCTAssertEqualObjects(result.result, @"orlando");
}

// The value is only meaningful on the satisfied path; a failure reports the condition
// name and drops it.
- (void)testResultFactoryWithUnsatisfiedValueDropsTheValue {
	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationConditionResult:NO
																		 value:@"orlando"
																		  name:@"SomeCondition"];

	XCTAssertFalse(result.isSucceed);
	XCTAssertNil(result.result);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], @"SomeCondition");
}

- (void)testResultFactoryFromADelegate {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationCondition:dependency name:@"SomeCondition"];

	XCTAssertTrue(result.isSucceed);
	XCTAssertEqualObjects(result.result, @"orlando");
}

- (void)testResultFactoryFromAFailingDelegate {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.value = @"orlando";
	dependency.success = NO;

	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationCondition:dependency name:@"SomeCondition"];

	XCTAssertFalse(result.isSucceed);
	XCTAssertNil(result.result);
}

#pragma mark - MADOperationConditionMissingResultString

- (void)testMissingResultStringIdentity {
	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];

	XCTAssertEqualObjects(condition.key, @"username");
	XCTAssertEqualObjects(condition.name, @"MADOperationConditionMissingResultString");
	XCTAssertFalse(condition.isMutuallyExclusive);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

- (void)testMissingResultStringWithoutDependenciesFails {
	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];
	XCTAssertFalse(result.isSucceed);
}

// The inverse of MADOperationConditionHasResultString: it is satisfied when the read
// *failed*, which is how the app knows it has to prompt for credentials.
- (void)testMissingResultStringSucceedsWhenTheMatchingReadFailed {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"";
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertTrue(result.isSucceed);
	XCTAssertNil(result.error);
}

- (void)testMissingResultStringFailsWhenTheMatchingReadSucceeded {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
}

- (void)testMissingResultStringWithNonMatchingKeyFails {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"password";
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
}

- (void)testMissingResultStringAsyncEvaluationCallsBack {
	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];

	XCTestExpectation *expectation = [self expectationWithDescription:@"condition"];
	[condition evaluateForOperation:[[MADOperation alloc] init]
						 completion:^(MADOperationConditionResult *result) {
		XCTAssertFalse(result.isSucceed);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - MADOperationConditionTestConnection

- (void)testTestConnectionBaseClassIsAbstract {
	// MADOperationConditionTestConnection is an abstract middle class: only its two
	// subclasses implement -evaluateForOperation:. The base asserts rather than
	// returning nil into the protocol's nonnull result.
	MADOperationConditionTestConnection *condition = [[MADOperationConditionTestConnection alloc] init];
#if defined(DEBUG) && DEBUG
	XCTAssertThrows([condition evaluateForOperation:[[MADOperation alloc] init]]);
#else
	XCTAssertNil([condition evaluateForOperation:[[MADOperation alloc] init]]);
#endif
}

- (void)testTestConnectionSuccessSucceedsWhenTheDependencySucceeded {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertTrue(result.isSucceed);
	XCTAssertEqualObjects(condition.name, @"MADOperationConditionTestConnectionSuccess");
}

- (void)testTestConnectionSuccessFailsWhenTheDependencyFailed {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

- (void)testTestConnectionSuccessFailsWithoutDependencies {
	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];
	XCTAssertFalse(result.isSucceed);
}

// A dependency that does not publish test results leaves the simple scan at NO, so the
// "success" condition reports failure rather than crashing on a message the stub does
// not implement.
- (void)testTestConnectionSuccessIgnoresDependenciesThatDoNotPublishTestResults {
	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:[[NSOperation alloc] init]];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testTestConnectionFailuareIsTheInverse {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionFailuare *condition =
		[[MADOperationConditionTestConnectionFailuare alloc] init];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertTrue(result.isSucceed);
	XCTAssertEqualObjects(condition.name, @"MADOperationConditionTestConnectionFailuare");
}

- (void)testTestConnectionFailuareFailsWhenTheDependencySucceeded {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionFailuare *condition =
		[[MADOperationConditionTestConnectionFailuare alloc] init];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testTestConnectionSuccessAsyncEvaluationCallsBack {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];

	XCTestExpectation *expectation = [self expectationWithDescription:@"condition"];
	[condition evaluateForOperation:operation completion:^(MADOperationConditionResult *result) {
		XCTAssertTrue(result.isSucceed);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
