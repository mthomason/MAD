//
//  MADOperationBackgroundTaskEndTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  MADOperationBackgroundTaskEnd is a no-op today: -execute finishes immediately,
//  and the body that walked its dependencies for a
//  MADOperationBackgroundTaskProtocol conformance is commented out below the
//  `return`.  These tests pin that the dependency scan is gone -- an unfinished
//  dependency changes nothing.
//

#import <XCTest/XCTest.h>

#import "MADOperationBackgroundTaskEnd.h"
#import "MADOperationBackgroundTaskBegin.h"

@interface MADOperationBackgroundTaskEndTests : XCTestCase
@end

@implementation MADOperationBackgroundTaskEndTests

- (void)testInitDefaults {
	MADOperationBackgroundTaskEnd *operation = [[MADOperationBackgroundTaskEnd alloc] init];

	XCTAssertNotNil(operation);
	XCTAssertTrue(operation.isAsynchronous);
	XCTAssertEqual(operation.state, MADOperationStateInitialized);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testExecuteFinishesCleanly {
	MADOperationBackgroundTaskEnd *operation = [[MADOperationBackgroundTaskEnd alloc] init];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.state, MADOperationStateFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
}

- (void)testExecuteIgnoresDependencies {
	// The begin operation never reaches Done here, but the end operation no longer
	// reads its dependencies at all, so it still finishes.
	MADOperationBackgroundTaskBegin *dependency = [[MADOperationBackgroundTaskBegin alloc] init];
	MADOperationBackgroundTaskEnd *operation = [[MADOperationBackgroundTaskEnd alloc] init];
	[operation addDependency:dependency];

	[operation execute];

	XCTAssertTrue(operation.isFinished);
	XCTAssertEqual(operation.errors.count, (NSUInteger)0);
	XCTAssertFalse(dependency.isFinished);
}

@end
