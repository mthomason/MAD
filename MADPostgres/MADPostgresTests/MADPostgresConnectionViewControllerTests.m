//
//  MADPostgresConnectionViewControllerTests.m
//  MADPostgresTests
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <XCTest/XCTest.h>
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <MADAPI/MADDatabaseConnection.h>

#import "MADPostgresConnectionViewController.h"
#import "MADDatabaseConnectionPostgres.h"

@interface MADPostgresConnectionViewControllerTests : XCTestCase
@end

@implementation MADPostgresConnectionViewControllerTests

- (void)testDisplayNameIsPostgreSQL {
	MADPostgresConnectionViewController *controller = [[MADPostgresConnectionViewController alloc] init];

	XCTAssertEqualObjects([controller displayName], @"PostgreSQL");
}

- (void)testDatabaseConnectionIsBuiltFromTheFields {
	MADPostgresConnectionViewController *controller = [[MADPostgresConnectionViewController alloc] init];

	MADDatabaseConnection *connection = [controller databaseConnection];

	XCTAssertTrue([connection isKindOfClass:[MADDatabaseConnectionPostgres class]],
				  @"Expected a PostgreSQL connection, got: %@", [connection class]);
}

- (void)testDatabaseConnectionToleratesUnloadedFieldsAndDefaultsPortTo5432 {
	MADPostgresConnectionViewController *controller = [[MADPostgresConnectionViewController alloc] init];

	MADDatabaseConnectionPostgres *connection = (MADDatabaseConnectionPostgres *)[controller databaseConnection];

	XCTAssertNotNil(connection);
	XCTAssertNil(connection.host);
	XCTAssertNil(connection.database);
	XCTAssertEqual(connection.port, 5432);
}

- (void)testResetAndEnableUserInteractionRun {
	MADPostgresConnectionViewController *controller = [[MADPostgresConnectionViewController alloc] init];

	XCTAssertNoThrow([controller resetInterface]);
	XCTAssertNoThrow([controller enableUserInteraction]);
}

@end
#endif
