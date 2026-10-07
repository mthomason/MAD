//
//  MADOperationBackgroundTaskBeginTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  MADOperationBackgroundTaskBegin is a no-op today: -execute finishes
//  immediately, and the UIApplication beginBackgroundTask body sits commented
//  out below the `return`.  A logic test has no UIApplication anyway, so the
//  tests pin the observable end state -- asynchronous, clean finish, no errors --
//  rather than any background-task side effect.
//

#import <XCTest/XCTest.h>

#import "MADOperationBackgroundTaskBegin.h"

@interface MADOperationBackgroundTaskBeginTests : XCTestCase
@end

@implementation MADOperationBackgroundTaskBeginTests

- (void)testInitDefaults {
	MADOperationBackgroundTaskBegin *operation = [[MADOperationBackgroundTaskBegin alloc] init];

	XCTAssertNotNil(operation);
	XCTAssertTrue(operation.isAsynchronous);
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testExecuteFinishesCleanly {
	MADOperationBackgroundTaskBegin *operation = [[MADOperationBackgroundTaskBegin alloc] init];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.state, MADOperationStateFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

// MADOperationBackgroundTaskProtocol is declared in the header, but the class does
// not adopt it and no other class in the tree does either; the commented-out body
// above -execute is its only (former) user, so there is no live conformance to
// assert here.

@end
