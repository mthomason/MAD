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

MAD_TEST_MAIN("MADDatabaseConnectionTests",
	MAD_TEST(testSupportsSecureCoding),
	MAD_TEST(testDatabaseTypeGetterThrows),
	MAD_TEST(testConnectionStringGetterThrows),
	MAD_TEST(testRequiresCredentialsGetterThrows),
	MAD_TEST(testIdentifierGetterThrows),
	MAD_TEST(testClassIdentifierThrows),
	MAD_TEST(testCopyDoesNotThrow),
	MAD_TEST(testNSCodingRoundTripDoesNotThrow));
