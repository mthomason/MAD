//
//  MADStorageStateTests.m
//  MADFileManagerTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADStorageState, a plain value object carrying the storage
//  location plus a couple of iCloud flags.
//

#import <XCTest/XCTest.h>

#import <MADFileManager/MADStorageState.h>

@interface MADStorageStateTests : XCTestCase
@end

@implementation MADStorageStateTests

- (void)testDefaults {
	MADStorageState *state = [[MADStorageState alloc] init];
	XCTAssertEqual(state.storageOption, MADAppStorageNotSet);
	XCTAssertFalse(state.accountDidChange);
	XCTAssertFalse(state.cloudAvailable);
}

- (void)testSetters {
	MADStorageState *state = [[MADStorageState alloc] init];
	state.storageOption = MADAppStorageCloud;
	state.accountDidChange = YES;
	state.cloudAvailable = YES;

	XCTAssertEqual(state.storageOption, MADAppStorageCloud);
	XCTAssertTrue(state.accountDidChange);
	XCTAssertTrue(state.cloudAvailable);
}

@end
