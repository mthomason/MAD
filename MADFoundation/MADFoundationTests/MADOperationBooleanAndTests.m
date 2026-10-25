//
//  MADOperationBooleanAndTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperationBooleanAnd: the composite condition that folds a list of
//  conditions into one answer.  Pinned here: the vacuous truth for an empty list, the
//  all-must-succeed rule, the short-circuit (a failing condition stops the scan, so
//  later conditions are never evaluated), and the async wrapper.
//

#import <XCTest/XCTest.h>

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

@interface MADOperationBooleanAndTests : XCTestCase
@end

@implementation MADOperationBooleanAndTests

#pragma mark - Identity

- (void)testConditionIdentity {
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[]];

	XCTAssertEqualObjects(condition.name, @"MADOperationBooleanAnd");
	XCTAssertFalse(condition.isMutuallyExclusive);
	XCTAssertNil([condition dependencyForOperation:[[MADOperation alloc] init]]);
}

#pragma mark - Evaluation

- (void)testEmptyConditionListSucceedsVacuously {
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[]];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	XCTAssertTrue(result.isSucceed);
}

- (void)testAllConditionsSucceedingSucceeds {
	MADTestCondition *first = [[MADTestCondition alloc] init];
	first.succeeds = YES;
	MADTestCondition *second = [[MADTestCondition alloc] init];
	second.succeeds = YES;
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[first, second]];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	XCTAssertTrue(result.isSucceed);
	XCTAssertEqual(first.evaluationCount, (NSUInteger)1);
	XCTAssertEqual(second.evaluationCount, (NSUInteger)1);
}

- (void)testOneFailingConditionFailsTheWhole {
	MADTestCondition *first = [[MADTestCondition alloc] init];
	first.succeeds = YES;
	MADTestCondition *second = [[MADTestCondition alloc] init];
	second.succeeds = NO;
	MADTestCondition *third = [[MADTestCondition alloc] init];
	third.succeeds = YES;
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[first, second, third]];

	MADOperationConditionResult *result = [condition evaluateForOperation:[[MADOperation alloc] init]];

	XCTAssertFalse(result.isSucceed);
	XCTAssertEqual(first.evaluationCount, (NSUInteger)1);
	XCTAssertEqual(second.evaluationCount, (NSUInteger)1);
	// Short-circuit: the scan stops at the first failure.
	XCTAssertEqual(third.evaluationCount, (NSUInteger)0);
}

- (void)testAsyncEvaluationCallsBackWithTheSameAnswer {
	MADTestCondition *failing = [[MADTestCondition alloc] init];
	failing.succeeds = NO;
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[failing]];

	__block MADOperationConditionResult *result = nil;
	[condition evaluateForOperation:[[MADOperation alloc] init] completion:^(MADOperationConditionResult *r) {
		result = r;
	}];

	XCTAssertNotNil(result);
	XCTAssertFalse(result.isSucceed);
}

- (void)testAsyncEvaluationToleratesANilCompletion {
	MADOperationBooleanAnd *condition = [[MADOperationBooleanAnd alloc] initWithConditions:@[]];

	XCTAssertNoThrow([condition evaluateForOperation:[[MADOperation alloc] init] completion:nil]);
}

@end
