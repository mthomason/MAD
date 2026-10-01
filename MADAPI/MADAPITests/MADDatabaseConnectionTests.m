//
//  MADDatabaseConnectionTests.m
//  MADAPITests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 3 coverage for MADDatabaseConnection, the factory base class for
//  database connection descriptors.  This documents the "abstract class"
//  contract: property accessors and the class-level Identifier throw until a
//  concrete subclass implements them, while NSCopying / NSSecureCoding operate
//  on the backing ivars directly (and therefore do not throw).
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseType.h>

@interface MADDatabaseConnectionTests : XCTestCase
@end

@implementation MADDatabaseConnectionTests

- (void)testSupportsSecureCoding {
	XCTAssertTrue([MADDatabaseConnection supportsSecureCoding]);
}

#pragma mark - Abstract-class contract

- (void)testDatabaseTypeGetterThrows {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	XCTAssertThrowsSpecificNamed([connection databaseType], NSException, NSInternalInconsistencyException);
}

- (void)testConnectionStringGetterThrows {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	XCTAssertThrowsSpecificNamed([connection connectionString], NSException, NSInternalInconsistencyException);
}

- (void)testRequiresCredentialsGetterThrows {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	XCTAssertThrowsSpecificNamed([connection requiresCredentials], NSException, NSInternalInconsistencyException);
}

- (void)testIdentifierGetterThrows {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	XCTAssertThrowsSpecificNamed([connection identifier], NSException, NSInternalInconsistencyException);
}

- (void)testClassIdentifierThrows {
	XCTAssertThrowsSpecificNamed([MADDatabaseConnection Identifier], NSException, NSInternalInconsistencyException);
}

#pragma mark - Copying and coding operate on ivars, not the throwing getters

- (void)testCopyDoesNotThrow {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	MADDatabaseConnection *copy = [connection copy];
	XCTAssertNotNil(copy);
	XCTAssertNotEqual(copy, connection);
}

- (void)testNSCodingRoundTripDoesNotThrow {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:YES error:NULL];
	MADDatabaseConnection *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseConnection class] fromData:data error:NULL];
	XCTAssertNotNil(decoded);
}

@end
