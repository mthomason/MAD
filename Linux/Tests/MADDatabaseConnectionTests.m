//
//  MADDatabaseConnectionTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADDatabaseConnectionTests.m: the abstract-class
//  contract of the connection factory base -- accessors throw until a
//  concrete subclass implements them, while NSCopying/NSCoding work on the
//  shared protected ivars.  The Xcode suite's secure-coding round trip runs
//  on the permissive path off Apple, as the toolchain probe records.
//

#import "MADTestSupport.h"
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

#pragma mark - Subclass state survives the base class's NSCopying / NSCoding

// The base class's -copyWithZone: and the coding methods read and write the protected
// ivars declared in MADDatabaseConnection.h, which the concrete subclass's accessors use
// too.  Driver-specific parameters live in the subclass and are carried by its own
// overrides (MADDatabaseConnectionMySql, ...Sqlite3 and ...SQLServer each do this).
static void testSubclassCopyCarriesSubclassState(void) {
	MADTestConnection *connection = [[MADTestConnection alloc] init];
	connection.databaseType = MADDatabaseTypeMySQL;
	connection.connectionString = @"(MADTestConnection)[host:3306]db";
	connection.requiresCredentials = YES;
	connection.identifier = @"MADTestConnection";

	MADTestConnection *copy = [connection copy];

	MAD_PASS(copy != nil, "the copy exists");
	MAD_PASS_EQUAL(NSStringFromClass([copy class]), NSStringFromClass([MADTestConnection class]), "the copy keeps the subclass");
	MAD_PASS(copy.databaseType == MADDatabaseTypeMySQL, "the copy's type survives");
	MAD_PASS_EQUAL(copy.connectionString, @"(MADTestConnection)[host:3306]db", "the copy's connection string survives");
	MAD_PASS(copy.requiresCredentials, "the copy requires credentials");
	MAD_PASS_EQUAL(copy.identifier, @"MADTestConnection", "the copy's identifier survives");
}

static void testSubclassNSCodingCarriesSubclassState(void) {
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
	MAD_PASS(decoded.databaseType == MADDatabaseTypeMySQL, "the decoded type survives");
	MAD_PASS_EQUAL(decoded.connectionString, @"(MADTestConnection)[host:3306]db", "the decoded connection string survives");
	MAD_PASS(decoded.requiresCredentials, "the decoded connection requires credentials");
	MAD_PASS_EQUAL(decoded.identifier, @"MADTestConnection", "the decoded identifier survives");
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
	MAD_TEST(testSubclassCopyCarriesSubclassState),
	MAD_TEST(testSubclassNSCodingCarriesSubclassState));
