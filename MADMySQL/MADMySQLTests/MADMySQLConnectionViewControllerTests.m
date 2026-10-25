//
//  MADMySQLConnectionViewControllerTests.m
//  MADMySQLTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Offline coverage for MADMySQLConnectionViewController, the My-SQL half of
//  the "add a connection" form. The controller is built from a nib in the app,
//  so the text fields are nil here; that is exactly what the mapping has to
//  tolerate, and it is what these tests pin: a connection object comes back
//  built from whatever the fields hold.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabaseConnection.h>

#import "MADMySQLConnectionViewController.h"
#import "MADDatabaseConnectionMySql.h"

@interface MADMySQLConnectionViewControllerTests : XCTestCase
@end

@implementation MADMySQLConnectionViewControllerTests

- (void)testDisplayNameIsMySQL {
	MADMySQLConnectionViewController *controller = [[MADMySQLConnectionViewController alloc] init];

	XCTAssertEqualObjects([controller displayName], @"MySQL");
}

- (void)testDatabaseConnectionIsABuiltFromTheFields {
	MADMySQLConnectionViewController *controller = [[MADMySQLConnectionViewController alloc] init];

	MADDatabaseConnection *connection = [controller databaseConnection];

	XCTAssertTrue([connection isKindOfClass:[MADDatabaseConnectionMySql class]],
				  @"Expected a My-SQL connection, got: %@", [connection class]);
}

- (void)testDatabaseConnectionToleratesUnloadedFields {
	// No nib has been loaded, so every field is nil: the controller must answer
	// a connection object instead of raising.
	MADMySQLConnectionViewController *controller = [[MADMySQLConnectionViewController alloc] init];

	MADDatabaseConnectionMySql *connection = (MADDatabaseConnectionMySql *)[controller databaseConnection];

	XCTAssertNotNil(connection);
	XCTAssertNil(connection.host);
	XCTAssertNil(connection.database);
}

- (void)testResetAndEnableUserInteractionRun {
	MADMySQLConnectionViewController *controller = [[MADMySQLConnectionViewController alloc] init];

	// Both overrides call super; neither has fields to touch before the nib
	// loads, so they must be safe to call.
	XCTAssertNoThrow([controller resetInterface]);
	XCTAssertNoThrow([controller enableUserInteraction]);
}

@end
