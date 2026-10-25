//
//  MADQueryTestTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADQueryTest: the trivial connection probe.  It selects the literal
//  255 under a safe identifier, which is enough to prove a connection answers.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQueryType.h>

#import "MADMock.h"
#import "MADQuery+Extras.h"
#import "MADQueryTest.h"

@interface MADQueryTestTests : XCTestCase
@end

@implementation MADQueryTestTests

- (void)testSqlSelectsTheLiteral {
	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:nil];
	query.database = [MADMock mockDatabase];

	XCTAssertEqualObjects([query getSql:NULL], @"SELECT\n 255 AS f1");
}

- (void)testTypeAndDefaults {
	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:nil];

	XCTAssertEqual(query.type, MADQueryTypeConnectionTest);
	XCTAssertTrue(query.returnsResults);
}

@end
