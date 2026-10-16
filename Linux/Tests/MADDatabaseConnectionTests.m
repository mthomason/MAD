//
//  MADDatabaseConnectionTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADDatabaseConnectionTests.m: the abstract-class
//  contract of the connection factory base -- accessors throw until a
//  concrete subclass implements them, while NSCopying/NSCoding work on the
//  backing ivars.  The Xcode suite's secure-coding round trip runs on the
//  permissive path off Apple, as the toolchain probe records.
//

#import "MADTestSupport.h"
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

static void testSupportsSecureCoding(void) {
	MAD_PASS([MADDatabaseConnection supportsSecureCoding], "the class claims secure coding");
}

#pragma mark - Abstract-class contract

static void testDatabaseTypeGetterThrows(void) {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	MAD_THROWS_NAMED([connection databaseType], NSInternalInconsistencyException, "databaseType throws");
}

static void testConnectionStringGetterThrows(void) {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	MAD_THROWS_NAMED([connection connectionString], NSInternalInconsistencyException, "connectionString throws");
}

static void testRequiresCredentialsGetterThrows(void) {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	MAD_THROWS_NAMED([connection requiresCredentials], NSInternalInconsistencyException, "requiresCredentials throws");
}

static void testIdentifierGetterThrows(void) {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	MAD_THROWS_NAMED([connection identifier], NSInternalInconsistencyException, "identifier throws");
}

static void testClassIdentifierThrows(void) {
	MAD_THROWS_NAMED([MADDatabaseConnection Identifier], NSInternalInconsistencyException, "the class Identifier throws");
}

#pragma mark - Copying and coding operate on ivars, not the throwing getters

static void testCopyDoesNotThrow(void) {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
	MADDatabaseConnection *copy = [connection copy];
	MAD_PASS(copy != nil, "the copy exists");
	MAD_PASS(copy != connection, "the copy is a different object");
}

static void testNSCodingRoundTripDoesNotThrow(void) {
	MADDatabaseConnection *connection = [[MADDatabaseConnection alloc] init];
#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:YES error:NULL];
	MADDatabaseConnection *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseConnection class] fromData:data error:NULL];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:NO error:NULL];
	MADDatabaseConnection *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
#endif
	MAD_PASS(decoded != nil, "the connection round trips");
}

#pragma mark - Subclass state does not survive the base class's NSCopying / NSCoding

// Characterization of a latent defect, documented in BUGS.md ("MADDatabaseConnection
// subclasses do not survive NSCopying / NSCoding").  The base class's -copyWithZone: and
// -encodeWithCoder: read and write the base class's *own* private ivars, which a concrete
// subclass cannot see and therefore shadows with its own storage.  The base class's
// accessors are never invoked: the subclass's synthesized getters win.
static void testSubclassCopyDoesNotCarrySubclassState(void) {
	MADTestConnection *connection = [[MADTestConnection alloc] init];
	connection.databaseType = MADDatabaseTypeMySQL;
	connection.connectionString = @"(MADTestConnection)[host:3306]db";
	connection.requiresCredentials = YES;
	connection.identifier = @"MADTestConnection";

	MADTestConnection *copy = [connection copy];

	MAD_PASS(copy != nil, "the copy exists");
	MAD_PASS_EQUAL(NSStringFromClass([copy class]), NSStringFromClass([MADTestConnection class]), "the copy keeps the subclass");
	// The base class's -copyWithZone: copies only its own ivars, so the subclass's
	// state reads back as defaults.
	MAD_PASS(copy.databaseType == MADDatabaseTypeUnknown, "the copy's type is the default");
	MAD_PASS(copy.connectionString == nil, "the copy's connection string is nil");
	MAD_PASS(!copy.requiresCredentials, "the copy does not require credentials");
	MAD_PASS(copy.identifier == nil, "the copy's identifier is nil");
}

static void testSubclassNSCodingDoesNotCarrySubclassState(void) {
	MADTestConnection *connection = [[MADTestConnection alloc] init];
	connection.databaseType = MADDatabaseTypeMySQL;
	connection.connectionString = @"(MADTestConnection)[host:3306]db";
	connection.requiresCredentials = YES;
	connection.identifier = @"MADTestConnection";

#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:YES error:NULL];
	MADTestConnection *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADTestConnection class] fromData:data error:NULL];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:connection requiringSecureCoding:NO error:NULL];
	MADTestConnection *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
#endif
	MAD_PASS(decoded != nil, "the connection round trips");
	// The base class's -encodeWithCoder: wrote only its own ivars; the subclass's
	// state reads back as defaults.
	MAD_PASS(decoded.databaseType == MADDatabaseTypeUnknown, "the decoded type is the default");
	MAD_PASS(decoded.connectionString == nil, "the decoded connection string is nil");
	MAD_PASS(!decoded.requiresCredentials, "the decoded connection does not require credentials");
	MAD_PASS(decoded.identifier == nil, "the decoded identifier is nil");
}

MAD_TEST_MAIN("MADDatabaseConnectionTests",
	MAD_TEST(testSupportsSecureCoding),
	MAD_TEST(testDatabaseTypeGetterThrows),
	MAD_TEST(testConnectionStringGetterThrows),
	MAD_TEST(testRequiresCredentialsGetterThrows),
	MAD_TEST(testIdentifierGetterThrows),
	MAD_TEST(testClassIdentifierThrows),
	MAD_TEST(testCopyDoesNotThrow),
	MAD_TEST(testNSCodingRoundTripDoesNotThrow),
	MAD_TEST(testSubclassCopyDoesNotCarrySubclassState),
	MAD_TEST(testSubclassNSCodingDoesNotCarrySubclassState));
