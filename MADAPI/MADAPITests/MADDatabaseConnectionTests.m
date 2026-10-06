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

// A concrete connection shaped exactly like MADDatabaseConnectionMySql: the subclass
// declares its own storage for the protocol properties.  See the shadowing tests below.
@interface MADTestConnection : MADDatabaseConnection
@end

@interface MADTestConnection ()
// The protocol declares these readonly; the concrete subclass is where they turn
// writable, exactly as the base class does in its own class extension.
@property (nonatomic, assign, readwrite) MADDatabaseType databaseType;
@property (nonatomic, copy, readwrite) NSString *connectionString;
@property (nonatomic, assign, readwrite) BOOL requiresCredentials;
@property (nonatomic, copy, readwrite) NSString *identifier;
@end

@implementation MADTestConnection
@synthesize databaseType = _databaseType;
@synthesize connectionString = _connectionString;
@synthesize requiresCredentials = _requiresCredentials;
@synthesize identifier = _identifier;
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

#pragma mark - Subclass state does not survive the base class's NSCopying / NSCoding

// Characterization of a latent defect, documented in BUGS.md ("MADDatabaseConnection
// subclasses do not survive NSCopying / NSCoding").  The base class's -copyWithZone: and
// -encodeWithCoder: read and write the base class's *own* private ivars, which a concrete
// subclass cannot see and therefore shadows with its own storage.  The base class's
// accessors are never invoked: the subclass's synthesized getters win.  MADDatabaseConnectionMySql
// works around the copy half by overriding -copyWithZone:; nothing overrides the coding
// half.  Nothing in the app archives a connection today, so the defect is latent.
- (void)testSubclassCopyDoesNotCarrySubclassState {
	MADTestConnection *connection = [[MADTestConnection alloc] init];
	connection.databaseType = MADDatabaseTypeMySQL;
	connection.connectionString = @"(MADTestConnection)[host:3306]db";
	connection.requiresCredentials = YES;
	connection.identifier = @"MADTestConnection";

	MADTestConnection *copy = [connection copy];

	XCTAssertNotNil(copy);
	XCTAssertEqualObjects(NSStringFromClass([copy class]), NSStringFromClass([MADTestConnection class]));
	// The base class's -copyWithZone: copies only its own ivars, so the subclass's
	// state reads back as defaults.
	XCTAssertEqual(copy.databaseType, MADDatabaseTypeUnknown);
	XCTAssertNil(copy.connectionString);
	XCTAssertFalse(copy.requiresCredentials);
	XCTAssertNil(copy.identifier);
}

- (void)testSubclassNSCodingDoesNotCarrySubclassState {
	MADTestConnection *connection = [[MADTestConnection alloc] init];
	connection.databaseType = MADDatabaseTypeMySQL;
	connection.connectionString = @"(MADTestConnection)[host:3306]db";
	connection.requiresCredentials = YES;
	connection.identifier = @"MADTestConnection";

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:YES error:NULL];
	MADTestConnection *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADTestConnection class] fromData:data error:NULL];

	XCTAssertNotNil(decoded);
	// The base class's -encodeWithCoder: wrote only its own ivars; the subclass's
	// state reads back as defaults.
	XCTAssertEqual(decoded.databaseType, MADDatabaseTypeUnknown);
	XCTAssertNil(decoded.connectionString);
	XCTAssertFalse(decoded.requiresCredentials);
	XCTAssertNil(decoded.identifier);
}

@end
