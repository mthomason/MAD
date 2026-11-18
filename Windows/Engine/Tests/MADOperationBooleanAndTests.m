//
//  MADOperationBooleanAndTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/MADOperationBooleanAndTests.m: coverage for
//  MADOperationBooleanAnd, the composite condition that folds a list of
//  conditions into one answer.  Pinned here: the vacuous truth for an empty
//  list, the all-must-succeed rule, the short-circuit (a failing condition
//  stops the scan, so later conditions are never evaluated), and the async
//  wrapper.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationBooleanAnd.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>

#pragma mark - Test double

@interface MADTestCondition : NSObject <MADOperationCondition>
@property (nonatomic, assign) BOOL succeeds;
@property (nonatomic, assign) NSUInteger evaluationCount;
@end

@implementation MADTestCondition

- (NSString *)name { return @"MADTestCondition"; }
- (BOOL)isMutuallyExclusive { return NO; }
- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	self.evaluationCount++;
	return self.succeeds ?
		[MADOperationConditionResult newOperationConditionResultSatisfied] :
		[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
}

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
	if (completion != nil) completion([self evaluateForOperation:operation]);
}

@end

#pragma mark - Identity

static void testConditionIdentity(void) {
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[]];

	MAD_PASS_EQUAL(condition.name, @"MADOperationBooleanAnd", "the condition's name");
	MAD_PASS(!condition.isMutuallyExclusive, "not mutually exclusive");
	MAD_PASS([condition dependencyForOperation:[[MADOperation alloc] init]] == nil, "no dependency");
}

#pragma mark - Evaluation

static void testEmptyConditionListSucceedsVacuously(void) {
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[]];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	MAD_PASS(result.isSucceed, "an empty list succeeds vacuously");
}

static void testAllConditionsSucceedingSucceeds(void) {
	MADTestCondition *first = [[MADTestCondition alloc] init];
	first.succeeds = YES;
	MADTestCondition *second = [[MADTestCondition alloc] init];
	second.succeeds = YES;
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[first, second]];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	MAD_PASS(result.isSucceed, "all conditions satisfied");
	MAD_PASS(first.evaluationCount == (NSUInteger)1, "the first condition was evaluated once");
	MAD_PASS(second.evaluationCount == (NSUInteger)1, "the second condition was evaluated once");
}

static void testOneFailingConditionFailsTheWhole(void) {
	MADTestCondition *first = [[MADTestCondition alloc] init];
	first.succeeds = YES;
	MADTestCondition *second = [[MADTestCondition alloc] init];
	second.succeeds = NO;
	MADTestCondition *third = [[MADTestCondition alloc] init];
	third.succeeds = YES;
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[first, second, third]];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	MAD_PASS(!result.isSucceed, "one failure fails the whole");
	MAD_PASS(first.evaluationCount == (NSUInteger)1, "the first condition was evaluated once");
	MAD_PASS(second.evaluationCount == (NSUInteger)1, "the second condition was evaluated once");
	// Short-circuit: the scan stops at the first failure.
	MAD_PASS(third.evaluationCount == (NSUInteger)0, "the third condition was never evaluated");
}

static void testAsyncEvaluationCallsBackWithTheSameAnswer(void) {
	MADTestCondition *failing = [[MADTestCondition alloc] init];
	failing.succeeds = NO;
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[failing]];

	__block MADOperationConditionResult *result = nil;
	[condition evaluateForOperation:[[MADOperation alloc] init] completion:^(MADOperationConditionResult *r) {
		result = [r retain];	// MRC __block variables do not retain
	}];

	MAD_PASS(result != nil, "the completion ran");
	MAD_PASS(!result.isSucceed, "the answer matches the synchronous evaluation");
}

static void testAsyncEvaluationToleratesANilCompletion(void) {
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[]];

	MAD_NO_THROW([condition evaluateForOperation:[[MADOperation alloc] init] completion:nil],
				 "a nil completion is tolerated");
}

MAD_TEST_MAIN("MADOperationBooleanAndTests",
	MAD_TEST(testConditionIdentity),
	MAD_TEST(testEmptyConditionListSucceedsVacuously),
	MAD_TEST(testAllConditionsSucceedingSucceeds),
	MAD_TEST(testOneFailingConditionFailsTheWhole),
	MAD_TEST(testAsyncEvaluationCallsBackWithTheSameAnswer),
	MAD_TEST(testAsyncEvaluationToleratesANilCompletion));
