//
//  MADOperationConditionTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADOperationConditionTests.m: coverage for
//  the condition classes MADFoundation ships with.  All of them look at the
//  conditionalized operation's dependencies, find the one that publishes the
//  result they care about, and turn its outcome into a
//  MADOperationConditionResult.
//
//  The dependencies are test-only NSOperation stubs.  XCTestExpectation is
//  not available on GNUstep, so the three async tests poll the run loop with
//  a deadline instead (the pattern the operation tests already use).
//

#import "MADTestSupport.h"
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

#pragma mark - MADOperationConditionHasResultString

static void testHasResultStringIdentity(void) {
	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];

	MAD_PASS_EQUAL(condition.key, @"username", "key");
	MAD_PASS_EQUAL(condition.name, @"MADOperationConditionHasResultString", "name");
	MAD_PASS(!condition.isMutuallyExclusive, "not mutually exclusive");
	MAD_PASS([condition dependencyForOperation:[[MADOperation alloc] init]] == nil, "no dependency found");
}

static void testHasResultStringWithoutDependenciesFails(void) {
	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperation *operation = [[MADOperation alloc] init];

	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(!result.isSucceed, "fails without dependencies");
	MAD_PASS_EQUAL(result.error.userInfo[MADOperationConditionKey], condition.name, "error carries the condition name");
}

static void testHasResultStringWithMatchingSuccessfulDependencySucceeds(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS(result.error == nil, "no error");
	// The successful path yields the richer subclass so the value travels with the result.
	MAD_PASS([result isKindOfClass:[MADOperationConditionHasResultStringResult class]], "richer result class");
	MAD_PASS_EQUAL(((MADOperationConditionHasResultStringResult *)result).result, @"orlando", "result value");
}

static void testHasResultStringWithMatchingFailingDependencyFails(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(!result.isSucceed, "fails when the read failed");
	MAD_PASS_EQUAL(result.error.userInfo[MADOperationConditionKey], condition.name, "error carries the condition name");
}

static void testHasResultStringWithNonMatchingKeyFails(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"password";
	dependency.value = @"hunter2";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(!result.isSucceed, "fails on a non-matching key");
}

// A dependency that does not publish a result string at all is skipped rather than
// mistaken for a match.
static void testHasResultStringIgnoresDependenciesThatDoNotPublishAResultString(void) {
	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:[[NSOperation alloc] init]];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(!result.isSucceed, "fails");
}

static void testHasResultStringFindsTheMatchingDependencyAmongMany(void) {
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

	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS_EQUAL(((MADOperationConditionHasResultStringResult *)result).result, @"orlando", "found the wanted dependency");
}

static void testHasResultStringAsyncEvaluationCallsBack(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionHasResultString *condition =
		[[MADOperationConditionHasResultString alloc] initWithKey:@"username"];

	__block BOOL called = NO;
	__block BOOL succeeded = NO;
	void (^completion)(MADOperationConditionResult *) = [^(MADOperationConditionResult *result) {
		called = YES;
		succeeded = result.isSucceed;
	} copy];
	[condition evaluateForOperation:operation completion:completion];

	MAD_PASS(MADWaitForFlag(&called, 5.0), "completion called");
	MAD_PASS(succeeded, "result succeeded");
}

#pragma mark - MADOperationConditionHasResultStringResult

static void testResultFactoryWithSatisfiedValue(void) {
	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationConditionResult:YES
																		 value:@"orlando"
																		  name:@"SomeCondition"];

	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS_EQUAL(result.result, @"orlando", "result value");
}

// The value is only meaningful on the satisfied path; a failure reports the condition
// name and drops it.
static void testResultFactoryWithUnsatisfiedValueDropsTheValue(void) {
	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationConditionResult:NO
																		 value:@"orlando"
																		  name:@"SomeCondition"];

	MAD_PASS(!result.isSucceed, "fails");
	MAD_PASS(result.result == nil, "value dropped");
	MAD_PASS_EQUAL(result.error.userInfo[MADOperationConditionKey], @"SomeCondition", "error carries the condition name");
}

static void testResultFactoryFromADelegate(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationCondition:dependency name:@"SomeCondition"];

	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS_EQUAL(result.result, @"orlando", "result value");
}

static void testResultFactoryFromAFailingDelegate(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.value = @"orlando";
	dependency.success = NO;

	MADOperationConditionHasResultStringResult *result =
		[MADOperationConditionHasResultStringResult newOperationCondition:dependency name:@"SomeCondition"];

	MAD_PASS(!result.isSucceed, "fails");
	MAD_PASS(result.result == nil, "value dropped");
}

#pragma mark - MADOperationConditionMissingResultString

static void testMissingResultStringIdentity(void) {
	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];

	MAD_PASS_EQUAL(condition.key, @"username", "key");
	MAD_PASS_EQUAL(condition.name, @"MADOperationConditionMissingResultString", "name");
	MAD_PASS(!condition.isMutuallyExclusive, "not mutually exclusive");
	MAD_PASS([condition dependencyForOperation:[[MADOperation alloc] init]] == nil, "no dependency found");
}

static void testMissingResultStringWithoutDependenciesFails(void) {
	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];
	MAD_PASS(!result.isSucceed, "fails without dependencies");
}

// The inverse of MADOperationConditionHasResultString: it is satisfied when the read
// *failed*, which is how the app knows it has to prompt for credentials.
static void testMissingResultStringSucceedsWhenTheMatchingReadFailed(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"";
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(result.isSucceed, "succeeds when the read failed");
	MAD_PASS(result.error == nil, "no error");
}

static void testMissingResultStringFailsWhenTheMatchingReadSucceeded(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"username";
	dependency.value = @"orlando";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(!result.isSucceed, "fails when the read succeeded");
}

static void testMissingResultStringWithNonMatchingKeyFails(void) {
	MADResultStringDependency *dependency = [[MADResultStringDependency alloc] init];
	dependency.key = @"password";
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(!result.isSucceed, "fails on a non-matching key");
}

static void testMissingResultStringAsyncEvaluationCallsBack(void) {
	MADOperationConditionMissingResultString *condition =
		[[MADOperationConditionMissingResultString alloc] initWithKey:@"username"];

	__block BOOL called = NO;
	__block BOOL succeeded = YES;
	void (^completion)(MADOperationConditionResult *) = [^(MADOperationConditionResult *result) {
		called = YES;
		succeeded = result.isSucceed;
	} copy];
	[condition evaluateForOperation:[[MADOperation alloc] init] completion:completion];

	MAD_PASS(MADWaitForFlag(&called, 5.0), "completion called");
	MAD_PASS(!succeeded, "result failed");
}

#pragma mark - MADOperationConditionTestConnection

static void testTestConnectionBaseClassIsAbstract(void) {
	// MADOperationConditionTestConnection is an abstract middle class: only its two
	// subclasses implement -evaluateForOperation:. The base asserts rather than
	// returning nil into the protocol's nonnull result.
	MADOperationConditionTestConnection *condition = [[MADOperationConditionTestConnection alloc] init];
#if defined(DEBUG) && DEBUG
	BOOL raised = NO;
	@try {
		[condition evaluateForOperation:[[MADOperation alloc] init]];
	} @catch (NSException *e) {
		raised = YES;
	}
	MAD_PASS(raised, "abstract base raises");
#else
	MAD_PASS([condition evaluateForOperation:[[MADOperation alloc] init]] == nil, "abstract base returns nil");
#endif
}

static void testTestConnectionSuccessSucceedsWhenTheDependencySucceeded(void) {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS_EQUAL(condition.name, @"MADOperationConditionTestConnectionSuccess", "name");
}

static void testTestConnectionSuccessFailsWhenTheDependencyFailed(void) {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(!result.isSucceed, "fails");
	MAD_PASS_EQUAL(result.error.userInfo[MADOperationConditionKey], condition.name, "error carries the condition name");
}

static void testTestConnectionSuccessFailsWithoutDependencies(void) {
	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];
	MAD_PASS(!result.isSucceed, "fails without dependencies");
}

// A dependency that does not publish test results leaves the simple scan at NO, so the
// "success" condition reports failure rather than crashing on a message the stub does
// not implement.
static void testTestConnectionSuccessIgnoresDependenciesThatDoNotPublishTestResults(void) {
	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:[[NSOperation alloc] init]];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];

	MAD_PASS(![condition evaluateForOperation:operation].isSucceed, "fails");
}

static void testTestConnectionFailuareIsTheInverse(void) {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionFailuare *condition =
		[[MADOperationConditionTestConnectionFailuare alloc] init];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	MAD_PASS(result.isSucceed, "succeeds");
	MAD_PASS_EQUAL(condition.name, @"MADOperationConditionTestConnectionFailuare", "name");
}

static void testTestConnectionFailuareFailsWhenTheDependencySucceeded(void) {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionFailuare *condition =
		[[MADOperationConditionTestConnectionFailuare alloc] init];

	MAD_PASS(![condition evaluateForOperation:operation].isSucceed, "fails");
}

static void testTestConnectionSuccessAsyncEvaluationCallsBack(void) {
	MADTestConnectionDependency *dependency = [[MADTestConnectionDependency alloc] init];
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionTestConnectionSuccess *condition =
		[[MADOperationConditionTestConnectionSuccess alloc] init];

	__block BOOL called = NO;
	__block BOOL succeeded = NO;
	void (^completion)(MADOperationConditionResult *) = [^(MADOperationConditionResult *result) {
		called = YES;
		succeeded = result.isSucceed;
	} copy];
	[condition evaluateForOperation:operation completion:completion];

	MAD_PASS(MADWaitForFlag(&called, 5.0), "completion called");
	MAD_PASS(succeeded, "result succeeded");
}

MAD_TEST_MAIN("MADOperationConditionTests",
	MAD_TEST(testHasResultStringIdentity),
	MAD_TEST(testHasResultStringWithoutDependenciesFails),
	MAD_TEST(testHasResultStringWithMatchingSuccessfulDependencySucceeds),
	MAD_TEST(testHasResultStringWithMatchingFailingDependencyFails),
	MAD_TEST(testHasResultStringWithNonMatchingKeyFails),
	MAD_TEST(testHasResultStringIgnoresDependenciesThatDoNotPublishAResultString),
	MAD_TEST(testHasResultStringFindsTheMatchingDependencyAmongMany),
	MAD_TEST(testHasResultStringAsyncEvaluationCallsBack),
	MAD_TEST(testResultFactoryWithSatisfiedValue),
	MAD_TEST(testResultFactoryWithUnsatisfiedValueDropsTheValue),
	MAD_TEST(testResultFactoryFromADelegate),
	MAD_TEST(testResultFactoryFromAFailingDelegate),
	MAD_TEST(testMissingResultStringIdentity),
	MAD_TEST(testMissingResultStringWithoutDependenciesFails),
	MAD_TEST(testMissingResultStringSucceedsWhenTheMatchingReadFailed),
	MAD_TEST(testMissingResultStringFailsWhenTheMatchingReadSucceeded),
	MAD_TEST(testMissingResultStringWithNonMatchingKeyFails),
	MAD_TEST(testMissingResultStringAsyncEvaluationCallsBack),
	MAD_TEST(testTestConnectionBaseClassIsAbstract),
	MAD_TEST(testTestConnectionSuccessSucceedsWhenTheDependencySucceeded),
	MAD_TEST(testTestConnectionSuccessFailsWhenTheDependencyFailed),
	MAD_TEST(testTestConnectionSuccessFailsWithoutDependencies),
	MAD_TEST(testTestConnectionSuccessIgnoresDependenciesThatDoNotPublishTestResults),
	MAD_TEST(testTestConnectionFailuareIsTheInverse),
	MAD_TEST(testTestConnectionFailuareFailsWhenTheDependencySucceeded),
	MAD_TEST(testTestConnectionSuccessAsyncEvaluationCallsBack));
