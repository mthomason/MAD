//
//  madlogTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for madlog: the framework's os_log facility.  The log object is created
//  once (dispatch_once) and reused, so every MADLog* macro in the framework writes to
//  the same channel.
//

#import <XCTest/XCTest.h>

#import "madlog.h"

@interface madlogTests : XCTestCase
@end

@implementation madlogTests

- (void)testFoundationLogIsCreated {
	os_log_t log = GetFoundationLog();

	XCTAssertNotNil(log);
	XCTAssertFalse(log == OS_LOG_DISABLED);
}

- (void)testFoundationLogIsStableAcrossCalls {
	XCTAssertEqual(GetFoundationLog(), GetFoundationLog());
}

@end
