//
//  MADAppOperationConditionTests.m
//  MADDesignerUnitTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The condition classes the app adds on top of the four MADFoundation ships with.
//  All of them follow the same shape as the framework ones: they look at the
//  conditionalized operation's *dependencies*, pick the one that answers their
//  question, and turn that answer into a MADOperationConditionResult.
//
//  The dependencies are test-only MADOperation subclasses. They have to be
//  MADOperation rather than plain NSOperation because the polar-question and
//  displayed-alert conditions match on `identifier`.
//
//  As in the other app test files, the app's classes are declared locally: their
//  implementations are in the host app, but MADDesigner/Source is not on this
//  bundle's header search path.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UIViewController.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADOperationTestResults.h>

#pragma mark - App interfaces

@protocol MADOperationConditionPolarQuestionResultProtocol <NSObject>
- (BOOL)result;
@end

@protocol MADOperationConditionDisplayedAlertProtocol <NSObject>
- (BOOL)alertDisplayed;
- (BOOL)alertDisplayedAffirmed;
@end

@protocol MADOperationHoldsCredentialsProtocol <NSObject>
- (MADCredential *)credentials;
- (BOOL)gotCredentials;
- (BOOL)manuallyInputtedCredentials;
@end

@interface MADOperationConditionPolarQuestionAffirmativeResult : MADOperationConditionResult
	<MADOperationConditionPolarQuestionResultProtocol>
@property (nonatomic, assign) BOOL result;
@end

@interface MADOperationConditionPolarQuestionNegativeResult : MADOperationConditionResult
	<MADOperationConditionPolarQuestionResultProtocol>
@property (nonatomic, assign) BOOL result;
@end

@interface MADOperationConditionPolarQuestionAffirmative : NSObject <MADOperationCondition>
- (instancetype)initWithOperationIdentifier:(NSUInteger)tag;
@end

@interface MADOperationConditionPolarQuestionNegative : NSObject <MADOperationCondition>
- (instancetype)initWithOperationIdentifier:(NSUInteger)tag;
@end

@interface MADOperationConditionDisplayedAlert : NSObject <MADOperationCondition>
- (instancetype)initWithOperationIdentifier:(NSUInteger)tag;
@property (nonatomic, assign) BOOL reverseCondition;
@end

@interface MADOperationConditionDisplayedAlertConfirm : NSObject <MADOperationCondition>
@property (nonatomic, assign) BOOL reverseCondition;
@end

@interface MADOperationConditionSuccess : NSObject <MADOperationCondition>
- (instancetype)initWithKey:(NSString *)key;
@property (nonatomic, assign) BOOL reverseCondition;
@end

@interface MADMutualExclusiveCondition : NSObject <MADOperationCondition>
+ (instancetype)newMutualExclusiveConditionForClass:(Class)class;
+ (instancetype)newMutualExclusiveConditionAlertMutex;
+ (instancetype)newMutualExclusiveConditionViewControllerMutex;
@end

#pragma mark - Test doubles

// Stands in for MADOperationPromptPolarQuestion: an operation that both asks the
// question and reports whether an alert was shown.
@interface MADAnswerStub : MADOperation <MADOperationConditionPolarQuestionResultProtocol,
										 MADOperationConditionDisplayedAlertProtocol>
@property (nonatomic, assign) BOOL result;
@property (nonatomic, assign) BOOL alertDisplayed;
@property (nonatomic, assign) BOOL alertDisplayedAffirmed;
@end

@implementation MADAnswerStub
@end

// Stands in for the credential-reading operations, which publish whether the user
// typed the credentials in by hand.
@interface MADCredentialsStub : MADOperation <MADOperationHoldsCredentialsProtocol>
@property (nonatomic, assign) BOOL manuallyInputtedCredentials;
@end

@implementation MADCredentialsStub

- (MADCredential *)credentials { return nil; }
- (BOOL)gotCredentials { return NO; }

@end

// Stands in for MADOperationDatabaseTestConnection, which publishes a pass/fail.
@interface MADTestResultStub : NSOperation <MADOperationTestResults>
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign, getter=isSuccess) BOOL success;
@end

@implementation MADTestResultStub
@end

#pragma mark - Tests

@interface MADAppOperationConditionTests : XCTestCase
@end

@implementation MADAppOperationConditionTests

#pragma mark - MADMutualExclusiveCondition

- (void)testMutualExclusiveConditionNamesTheClassItExcludes {
	MADMutualExclusiveCondition *condition =
		[MADMutualExclusiveCondition newMutualExclusiveConditionForClass:[NSString class]];

	XCTAssertEqualObjects(condition.name, @"MutuallyExclusive<NSString>");
	XCTAssertTrue(condition.isMutuallyExclusive);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

// The condition carries no state to evaluate -- exclusivity is enforced by the queue,
// not here -- so it reports satisfied whether or not anything depends on it.
- (void)testMutualExclusiveConditionIsAlwaysSatisfied {
	MADMutualExclusiveCondition *condition =
		[MADMutualExclusiveCondition newMutualExclusiveConditionForClass:[NSString class]];
	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:[[NSOperation alloc] init]];

	XCTAssertTrue([condition evaluateForOperation:operation].isSucceed);
	XCTAssertTrue([condition evaluateForOperation:[[MADOperation alloc] init]].isSucceed);
}

- (void)testMutualExclusiveConditionFactoriesNameTheirClass {
	// Built in steps rather than inline: the preprocessor splits macro arguments on
	// commas that sit inside square brackets, so a message send with more than one
	// argument cannot be passed straight to XCTAssertEqualObjects.
	NSString *alert = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex].name;
	NSString *viewController =
		[MADMutualExclusiveCondition newMutualExclusiveConditionViewControllerMutex].name;

	NSString *alertExpected =
		[@"MutuallyExclusive<" stringByAppendingFormat:@"%@>",
		 NSStringFromClass([UIAlertController class])];
	NSString *viewControllerExpected =
		[@"MutuallyExclusive<" stringByAppendingFormat:@"%@>",
		 NSStringFromClass([UIViewController class])];

	XCTAssertEqualObjects(alert, alertExpected);
	XCTAssertEqualObjects(viewController, viewControllerExpected);
}

#pragma mark - MADOperationConditionPolarQuestionAffirmative

- (void)testAffirmativeIdentity {
	MADOperationConditionPolarQuestionAffirmative *condition =
		[[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:7];

	XCTAssertEqualObjects(condition.name, @"MADOperationConditionPolarQuestionAffirmative");
	XCTAssertFalse(condition.isMutuallyExclusive);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

- (void)testAffirmativeWithoutDependenciesFails {
	MADOperationConditionPolarQuestionAffirmative *condition =
		[[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:7];

	MADOperationConditionResult *result =
		[condition evaluateForOperation:[[MADOperation alloc] init]];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

// The dependency answered yes, and that answer reaches the result. -evaluateForOperation:
// used to call `+newOperationConditionResult:name:` with the dependency object in the
// BOOL position; on arm64, where BOOL is _Bool, the pointer converted to YES by way of
// "not null" rather than by way of the answer, so a satisfied result came back with its
// own `result` property still at NO. It now goes through the same factory the negative
// condition uses.
- (void)testAffirmativeCarriesTheAnswerItWasGiven {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 7;
	dependency.result = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionAffirmative *condition =
		[[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:7];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertTrue(result.isSucceed);
	XCTAssertTrue([result isKindOfClass:[MADOperationConditionPolarQuestionAffirmativeResult class]]);
	XCTAssertTrue(((MADOperationConditionPolarQuestionAffirmativeResult *)result).result);
}

- (void)testAffirmativeWithANegativeAnswerFails {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 7;
	dependency.result = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionAffirmative *condition =
		[[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:7];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
}

- (void)testAffirmativeIgnoresAnswersWithADifferentIdentifier {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 8;
	dependency.result = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionAffirmative *condition =
		[[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:7];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testAffirmativeIgnoresDependenciesThatDoNotAnswerTheQuestion {
	NSOperation *dependency = [[NSOperation alloc] init];

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionAffirmative *condition =
		[[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:7];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testAffirmativeAsyncEvaluationCallsBack {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 7;
	dependency.result = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionAffirmative *condition =
		[[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:7];

	XCTestExpectation *expectation = [self expectationWithDescription:@"condition"];
	[condition evaluateForOperation:operation completion:^(MADOperationConditionResult *result) {
		XCTAssertTrue(result.isSucceed);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - MADOperationConditionPolarQuestionNegative

- (void)testNegativeIdentity {
	MADOperationConditionPolarQuestionNegative *condition =
		[[MADOperationConditionPolarQuestionNegative alloc] initWithOperationIdentifier:7];

	XCTAssertEqualObjects(condition.name, @"MADOperationConditionPolarQuestionNegative");
	XCTAssertFalse(condition.isMutuallyExclusive);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

- (void)testNegativeWithoutDependenciesFails {
	MADOperationConditionPolarQuestionNegative *condition =
		[[MADOperationConditionPolarQuestionNegative alloc] initWithOperationIdentifier:7];

	XCTAssertFalse([condition evaluateForOperation:[[MADOperation alloc] init]].isSucceed);
}

// The mirror image of the affirmative case, and the one that gets it right: the
// negative condition goes through `+newOperationCondition:name:`, which sets the
// result's own `result` property. The asymmetry between the two is the defect
// documented on the affirmative condition above.
- (void)testNegativeWithANegativeAnswerSucceedsAndKeepsTheAnswer {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 7;
	dependency.result = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionNegative *condition =
		[[MADOperationConditionPolarQuestionNegative alloc] initWithOperationIdentifier:7];
	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertTrue(result.isSucceed);
	XCTAssertTrue([result isKindOfClass:[MADOperationConditionPolarQuestionNegativeResult class]]);
	XCTAssertTrue(((MADOperationConditionPolarQuestionNegativeResult *)result).result);
}

- (void)testNegativeWithAnAffirmativeAnswerFails {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 7;
	dependency.result = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionNegative *condition =
		[[MADOperationConditionPolarQuestionNegative alloc] initWithOperationIdentifier:7];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testNegativeIgnoresAnswersWithADifferentIdentifier {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 8;
	dependency.result = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionPolarQuestionNegative *condition =
		[[MADOperationConditionPolarQuestionNegative alloc] initWithOperationIdentifier:7];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

#pragma mark - MADOperationConditionDisplayedAlert

- (void)testDisplayedAlertIdentity {
	MADOperationConditionDisplayedAlert *condition =
		[[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:3];

	XCTAssertEqualObjects(condition.name, @"MADOperationConditionDisplayedAlert");
	XCTAssertFalse(condition.isMutuallyExclusive);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

- (void)testDisplayedAlertWithoutDependenciesFails {
	MADOperationConditionDisplayedAlert *condition =
		[[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:3];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

- (void)testDisplayedAlertSucceedsWhenTheAlertWasShown {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 3;
	dependency.alertDisplayed = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlert *condition =
		[[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:3];

	XCTAssertTrue([condition evaluateForOperation:operation].isSucceed);
}

- (void)testDisplayedAlertFailsWhenTheAlertWasNotShown {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 3;
	dependency.alertDisplayed = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlert *condition =
		[[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:3];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testDisplayedAlertReverseConditionInvertsTheAnswer {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 3;
	dependency.alertDisplayed = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlert *condition =
		[[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:3];
	condition.reverseCondition = YES;

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testDisplayedAlertIgnoresAnswersWithADifferentIdentifier {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.identifier = 4;
	dependency.alertDisplayed = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlert *condition =
		[[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:3];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

#pragma mark - MADOperationConditionDisplayedAlertConfirm

- (void)testDisplayedAlertConfirmWithoutDependenciesFails {
	MADOperationConditionDisplayedAlertConfirm *condition =
		[[MADOperationConditionDisplayedAlertConfirm alloc] init];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

// Unlike the other two alert conditions this one does not match on `identifier`; it
// takes the first dependency that can answer at all.
- (void)testDisplayedAlertConfirmUsesTheAffirmedAnswer {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.alertDisplayedAffirmed = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlertConfirm *condition =
		[[MADOperationConditionDisplayedAlertConfirm alloc] init];

	XCTAssertTrue([condition evaluateForOperation:operation].isSucceed);
}

- (void)testDisplayedAlertConfirmFailsWhenTheAlertWasRefused {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.alertDisplayedAffirmed = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlertConfirm *condition =
		[[MADOperationConditionDisplayedAlertConfirm alloc] init];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testDisplayedAlertConfirmFallsBackToManuallyInputtedCredentials {
	MADCredentialsStub *dependency = [[MADCredentialsStub alloc] init];
	dependency.manuallyInputtedCredentials = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlertConfirm *condition =
		[[MADOperationConditionDisplayedAlertConfirm alloc] init];

	XCTAssertTrue([condition evaluateForOperation:operation].isSucceed);
}

- (void)testDisplayedAlertConfirmReverseConditionInverts {
	MADAnswerStub *dependency = [[MADAnswerStub alloc] init];
	dependency.alertDisplayedAffirmed = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionDisplayedAlertConfirm *condition =
		[[MADOperationConditionDisplayedAlertConfirm alloc] init];
	condition.reverseCondition = YES;

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

// A dependency that can answer neither way leaves the loop without setting a result. The
// method used to return nil from a nonnull method; it now reports the same failure the
// empty-dependency case does.
- (void)testDisplayedAlertConfirmFailsWhenNoDependencyCanAnswer {
	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:[[NSOperation alloc] init]];

	MADOperationConditionDisplayedAlertConfirm *condition =
		[[MADOperationConditionDisplayedAlertConfirm alloc] init];

	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertNotNil(result);
	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

#pragma mark - MADOperationConditionSuccess

- (void)testSuccessIdentity {
	MADOperationConditionSuccess *condition =
		[[MADOperationConditionSuccess alloc] initWithKey:@"SomeOperation"];

	XCTAssertEqualObjects(condition.name, @"MADOperationConditionSuccess");
	XCTAssertFalse(condition.isMutuallyExclusive);
	XCTAssertFalse(condition.reverseCondition);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

- (void)testSuccessWithoutDependenciesFails {
	MADOperationConditionSuccess *condition =
		[[MADOperationConditionSuccess alloc] initWithKey:@"SomeOperation"];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

// The key is matched against the dependency's NSOperation `name`, not its class.
- (void)testSuccessMatchesTheDependencyByName {
	MADTestResultStub *dependency = [[MADTestResultStub alloc] init];
	dependency.name = @"SomeOperation";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionSuccess *condition =
		[[MADOperationConditionSuccess alloc] initWithKey:@"SomeOperation"];

	XCTAssertTrue([condition evaluateForOperation:operation].isSucceed);
}

- (void)testSuccessFailsWhenTheNamedDependencyFailed {
	MADTestResultStub *dependency = [[MADTestResultStub alloc] init];
	dependency.name = @"SomeOperation";
	dependency.success = NO;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionSuccess *condition =
		[[MADOperationConditionSuccess alloc] initWithKey:@"SomeOperation"];

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

- (void)testSuccessReverseConditionInverts {
	MADTestResultStub *dependency = [[MADTestResultStub alloc] init];
	dependency.name = @"SomeOperation";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionSuccess *condition =
		[[MADOperationConditionSuccess alloc] initWithKey:@"SomeOperation"];
	condition.reverseCondition = YES;

	XCTAssertFalse([condition evaluateForOperation:operation].isSucceed);
}

// When no dependency matches the key, the condition fails quietly. It used to hit
// `NSAssert(result != nil, @"We expect dependencies.")`, which aborted the caller in
// Debug while Release -- which defines NS_BLOCK_ASSERTIONS -- fell through to the same
// failure this test now asserts in both configurations.
- (void)testSuccessFailsWhenNoDependencyMatchesTheKey {
	MADTestResultStub *dependency = [[MADTestResultStub alloc] init];
	dependency.name = @"SomeOtherOperation";
	dependency.success = YES;

	MADOperation *operation = [[MADOperation alloc] init];
	[operation addDependency:dependency];

	MADOperationConditionSuccess *condition =
		[[MADOperationConditionSuccess alloc] initWithKey:@"SomeOperation"];

	MADOperationConditionResult *result = [condition evaluateForOperation:operation];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqualObjects(result.error.userInfo[MADOperationConditionKey], condition.name);
}

@end
