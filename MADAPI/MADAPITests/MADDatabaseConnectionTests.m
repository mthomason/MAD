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
//  on the shared protected ivars (and therefore do not throw).
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseType.h>

// A concrete connection shaped exactly like MADDatabaseConnectionMySql: it stores the
// protocol properties in the base class's protected ivars, as the driver contract says.
@interface MADTestConnection : MADDatabaseConnection
@end

@interface MADTestConnection ()
// The protocol declares these readonly; the concrete subclass is where they turn
// writable.
@property (nonatomic, assign, readwrite) MADDatabaseType databaseType;
@property (nonatomic, copy, readwrite) NSString *connectionString;
@property (nonatomic, assign, readwrite) BOOL requiresCredentials;
@property (nonatomic, copy, readwrite) NSString *identifier;
@end

@implementation MADTestConnection
- (MADDatabaseType)databaseType { return _databaseType; }
- (void)setDatabaseType:(MADDatabaseType)databaseType { _databaseType = databaseType; }
- (NSString *)connectionString { return _connectionString; }
- (void)setConnectionString:(NSString *)connectionString { _connectionString = [connectionString copy]; }
- (BOOL)requiresCredentials { return _requiresCredentials; }
- (void)setRequiresCredentials:(BOOL)requiresCredentials { _requiresCredentials = requiresCredentials; }
- (NSString *)identifier { return _identifier; }
- (void)setIdentifier:(NSString *)identifier { _identifier = [identifier copy]; }
@end

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

#pragma mark - Subclass state survives the base class's NSCopying / NSCoding

// The base class's -copyWithZone: and the coding methods read and write the protected
// ivars declared in MADDatabaseConnection.h, which the concrete subclass's accessors use
// too.  Driver-specific parameters live in the subclass and are carried by its own
// overrides (MADDatabaseConnectionMySql, ...Sqlite3 and ...SQLServer each do this).
- (void)testSubclassCopyCarriesSubclassState {
	MADTestConnection *connection = [[MADTestConnection alloc] init];
	connection.databaseType = MADDatabaseTypeMySQL;
	connection.connectionString = @"(MADTestConnection)[host:3306]db";
	connection.requiresCredentials = YES;
	connection.identifier = @"MADTestConnection";

	MADTestConnection *copy = [connection copy];

	XCTAssertNotNil(copy);
	XCTAssertEqualObjects(NSStringFromClass([copy class]), NSStringFromClass([MADTestConnection class]));
	XCTAssertEqual(copy.databaseType, MADDatabaseTypeMySQL);
	XCTAssertEqualObjects(copy.connectionString, @"(MADTestConnection)[host:3306]db");
	XCTAssertTrue(copy.requiresCredentials);
	XCTAssertEqualObjects(copy.identifier, @"MADTestConnection");
}

- (void)testSubclassNSCodingCarriesSubclassState {
	MADTestConnection *connection = [[MADTestConnection alloc] init];
	connection.databaseType = MADDatabaseTypeMySQL;
	connection.connectionString = @"(MADTestConnection)[host:3306]db";
	connection.requiresCredentials = YES;
	connection.identifier = @"MADTestConnection";

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:YES error:NULL];
	MADTestConnection *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADTestConnection class] fromData:data error:NULL];

	XCTAssertNotNil(decoded);
	XCTAssertEqual(decoded.databaseType, MADDatabaseTypeMySQL);
	XCTAssertEqualObjects(decoded.connectionString, @"(MADTestConnection)[host:3306]db");
	XCTAssertTrue(decoded.requiresCredentials);
	XCTAssertEqualObjects(decoded.identifier, @"MADTestConnection");
}

@end
