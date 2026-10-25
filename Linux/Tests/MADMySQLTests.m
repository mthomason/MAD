//
//  MADMySQLTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MADMySQLTests.m: offline unit tests for
//  MADMySQL.  Nothing in this file contacts a server -- the one that needs one,
//  the connection-failure paths prove the failure is reported cleanly against
//  a dead port.  The tests that require the local MySQL instance described in
//  DEVELOPER.md (127.0.0.1, root, root, employees) are in MADMySQLLiveTests.m.
//
//  The Xcode file opens with <MADMySQL/MADMySQL.h>; the umbrella header lives
//  at the framework's root and re-exports the mysqlclient plugin headers the
//  Xcode target flattens into its Headers dir.  The Linux shim is the Source
//  directory, so the tests import the source headers directly -- the same
//  declarations, without the plugin headers nothing here uses.
//

#import "MADTestSupport.h"

#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADMySQL/MADDataTypeMySQL.h>
#import <MADMySQL/MADMySQLServer.h>
#import <MADMySQL/MADMySQLConnection.h>
#import <MADMySQL/MADMySQLFetch.h>

#import <MADFoundation/MADDataType.h>
#import <MADAPI/MADDatabaseType.h>

#import <mysql.h>

// These selectors are implemented in MADDatabaseMySQL.m but are not declared in any
// @interface the framework exports. Declaring them here lets the tests reach them
// without widening MADDatabaseMySQL's public API.
@interface MADDatabaseMySQL (MADMySQLTestsInternal)
+ (NSError *)errorCouldNotGetCredientals;
- (NSString *)domain;
@end

#pragma mark - MADDataTypeMySQL +dataTypeForNativeType:

// MySQL's native type codes are remapped onto the MADDataType enum. These tests
// pin the existing mapping rather than assert it is ideal; several entries are
// deliberately lossy (see the comments on the individual groups).

static void testDataTypeForNativeTypeMapsIntegralTypes(void) {
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TINY] == MADDataTypeShort, "TINY is Short");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_SHORT] == MADDataTypeShort, "SHORT is Short");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_LONG] == MADDataTypeLong, "LONG is Long");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_LONGLONG] == MADDataTypeLongLong, "LONGLONG is LongLong");
	// MYSQL_TYPE_INT24 (MEDIUMINT) maps to its own dedicated enum case, which every
	// downstream consumer groups with MADDataTypeInteger. The live suite exercises the
	// INT24 fetch path.
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_INT24] == MADDataTypeInt24, "INT24 is Int24");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_BIT] == MADDataTypeBit, "BIT is Bit");
}

static void testDataTypeForNativeTypeMapsStringTypes(void) {
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_STRING] == MADDataTypeString, "STRING is String");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_VARCHAR] == MADDataTypeVarChar, "VARCHAR is VarChar");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_VAR_STRING] == MADDataTypeVarChar, "VAR_STRING is VarChar");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_ENUM] == MADDataTypeEnum, "ENUM is Enum");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_SET] == MADDataTypeSet, "SET is Set");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_GEOMETRY] == MADDataTypeGeometry, "GEOMETRY is Geometry");
}

static void testDataTypeForNativeTypeMapsBlobVariants(void) {
	// All four BLOB widths collapse to the single MADDataTypeBlob.
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TINY_BLOB] == MADDataTypeBlob, "TINY_BLOB is Blob");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_BLOB] == MADDataTypeBlob, "BLOB is Blob");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_MEDIUM_BLOB] == MADDataTypeBlob, "MEDIUM_BLOB is Blob");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_LONG_BLOB] == MADDataTypeBlob, "LONG_BLOB is Blob");
}

static void testDataTypeForNativeTypeMapsNumericTypes(void) {
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DECIMAL] == MADDataTypeDecimal, "DECIMAL is Decimal");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_NEWDECIMAL] == MADDataTypeDecimal, "NEWDECIMAL is Decimal");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_FLOAT] == MADDataTypeFloat, "FLOAT is Float");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DOUBLE] == MADDataTypeDouble, "DOUBLE is Double");
}

static void testDataTypeForNativeTypeMapsTemporalTypes(void) {
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DATE] == MADDataTypeDate, "DATE is Date");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_NEWDATE] == MADDataTypeDate, "NEWDATE is Date");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DATETIME] == MADDataTypeDateTime, "DATETIME is DateTime");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TIMESTAMP] == MADDataTypeTimeStamp, "TIMESTAMP is TimeStamp");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_YEAR] == MADDataTypeYear, "YEAR is Year");
	// TIME is the dedicated MADDataTypeTime: the fetch code puts only hour/minute/second
	// into the NSDate, so a date-part formatter showed a date the value never had.
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TIME] == MADDataTypeTime, "TIME is Time");
}

static void testDataTypeForNativeTypeMapsNullToNumber(void) {
	// MYSQL_TYPE_NULL stays MADDataTypeNumber, deliberately. See BUGS.md, MADMySQL:
	// MADDataTypeNull is the binding-null used for null parameters, not a column type,
	// and it has no schema display case.
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_NULL] == MADDataTypeNumber, "NULL is Number");
}

static void testDataTypeForNativeTypeDefaultsToUnknownNativeCodesAreStrings(void) {
	// Anything the switch does not recognise falls through to MADDataTypeString.
	// MADDataTypeUnknown is never produced by this mapping.
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:(NSInteger)-1] == MADDataTypeString, "minus one is String");
	MAD_PASS((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:(NSInteger)9999] == MADDataTypeString, "9999 is String");
}

#pragma mark - Identifier quoting

static void testNewSafeQueryFieldQualifiesAndQuotes(void) {
	MAD_PASS_EQUAL([MADDatabaseMySQL newSafeQueryField:@"emp_no" andTable:@"employees"],
				   @"`employees`.`emp_no`", "the table and field are backticked");
}

static void testNewSafeQueryFieldQuotesEmbeddedBackticksLiterally(void) {
	// The helper quotes but does not escape; a name containing a backtick yields
	// a doubled backtick run. Pin the behaviour so a future escaping change is visible.
	MAD_PASS_EQUAL([MADDatabaseMySQL newSafeQueryField:@"a`b" andTable:@"t"], @"`t`.`a`b`",
				   "an embedded backtick is passed through");
}

static void testNewSafeIdentifierQuotesBareName(void) {
	// -newSafeIdentifier: is declared as an instance method; the class-level variant
	// exists in the implementation but is not part of the published interface.
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	MAD_PASS_EQUAL([db newSafeIdentifier:@"employees"], @"`employees`", "a bare name is backticked");
}

static void testQueryKeyTableMatchesSafeQueryField(void) {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	MAD_PASS_EQUAL([db queryKey:@"salary" table:@"salaries"],
				   [MADDatabaseMySQL newSafeQueryField:@"salary" andTable:@"salaries"],
				   "the query key agrees with the safe field");
	MAD_PASS_EQUAL([db queryKey:@"salary" table:@"salaries"], @"`salaries`.`salary`", "the query key shape");
}

static void testInstanceNewSafeIdentifierQuotesName(void) {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	MAD_PASS_EQUAL([db newSafeIdentifier:@"dept_emp"], @"`dept_emp`", "an instance backticks the name");
}

#pragma mark - Literal quoting

// The complete escape needs the live session (see -newSafeLiteral:), and the live
// suite covers that. This pins the path taken when there is none: the base's ANSI
// quoting, which is what a preview that never connects gets. A backslash is NOT
// escaped on that path, and this test says so out loud rather than leaving it implied.
static void testNewSafeLiteralWithoutASessionFallsBackToAnsiQuoting(void) {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	MAD_PASS_EQUAL([db newSafeLiteral:@"London"], @"'London'", "a plain value is single-quoted");
	MAD_PASS_EQUAL([db newSafeLiteral:@"O'Brien"], @"'O''Brien'", "an apostrophe is doubled");
	MAD_PASS_EQUAL([db newSafeLiteral:@"C:\\temp"], @"'C:\\temp'", "a backslash is left alone without a session");
	MAD_PASS_EQUAL([db newSafeLiteral:nil], @"NULL", "nil literalises as NULL");
}

#pragma mark - MADDatabaseMySQL identity

static void testDriverMetadata(void) {
	MAD_PASS_EQUAL([MADDatabaseMySQL driverName], @"MySQL Native Client", "the driver name");
	MAD_PASS_EQUAL([MADDatabaseMySQL imageIconName], @"UIImageExportTypeMySQL", "the icon name");
}

static void testDomainIsClassName(void) {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	MAD_PASS_EQUAL([db domain], @"MADDatabaseMySQL", "the error domain is the class name");
}

static void testErrorCouldNotGetCredientalsShape(void) {
	NSError *error = [MADDatabaseMySQL errorCouldNotGetCredientals];
	MAD_PASS_EQUAL(error.domain, @"MADDatabaseMySQL", "the error domain");
	MAD_PASS(error.code == 43421, "the error code");
	MAD_PASS(error.localizedDescription != nil, "the error has a description");
	MAD_PASS(error.localizedFailureReason != nil, "the error has a failure reason");
}

#pragma mark - MADDatabaseConnectionMySql

static void testConnectionInitializationStoresProperties(void) {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	MAD_PASS_EQUAL(conn.host, @"db.example.com", "the host is stored");
	MAD_PASS_EQUAL(conn.server, @"db.example.com", "the server mirrors the host");
	MAD_PASS_EQUAL(conn.database, @"employees", "the database is stored");
	MAD_PASS(conn.port == 3306, "the port is stored");
	MAD_PASS(conn.databaseType == MADDatabaseTypeMySQL, "the type is MySQL");
	MAD_PASS(conn.requiresCredentials, "a MySQL connection requires credentials");
}

static void testConnectionServerPropertyIsTrimmedButHostIsNot(void) {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"  db.example.com \n"
											   database:@"employees"
												andPort:3306];
	MAD_PASS_EQUAL(conn.server, @"db.example.com", "the server is trimmed");
	MAD_PASS_EQUAL(conn.host, @"  db.example.com \n", "the host is not");
}

static void testConnectionIdentifier(void) {
	MAD_PASS_EQUAL([MADDatabaseConnectionMySql Identifier], @"MySQL", "the class identifier");
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"h" database:@"d" andPort:1];
	MAD_PASS_EQUAL(conn.identifier, @"MySQL", "the instance identifier");
}

static void testConnectionStringFormat(void) {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	MAD_PASS_EQUAL(conn.connectionString, @"(MySQL)[db.example.com:3306]employees",
				   "host, port and database spell the connection string");
}

static void testConnectionCopyIsIndependent(void) {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	MADDatabaseConnectionMySql *copy = [conn copyWithZone:nil];
	MAD_PASS_EQUAL(copy.host, conn.host, "the copy carries the host");
	MAD_PASS_EQUAL(copy.database, conn.database, "the copy carries the database");
	MAD_PASS(copy.port == conn.port, "the copy carries the port");
	MAD_PASS_EQUAL(copy.connectionString, conn.connectionString, "the copy carries the connection string");
}

static void testConnectionCodingRoundTripCarriesTheConnectionState(void) {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];

#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:conn requiringSecureCoding:YES error:NULL];
	MADDatabaseConnectionMySql *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseConnectionMySql class] fromData:data error:NULL];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:conn requiringSecureCoding:NO error:NULL];
	MADDatabaseConnectionMySql *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
#endif
	MAD_PASS(decoded != nil, "the connection round trips");
	MAD_PASS_EQUAL(decoded.host, @"db.example.com", "the host survives");
	MAD_PASS_EQUAL(decoded.server, @"db.example.com", "the server is derived again");
	MAD_PASS_EQUAL(decoded.database, @"employees", "the database survives");
	MAD_PASS(decoded.port == 3306, "the port survives");
	MAD_PASS(decoded.databaseType == MADDatabaseTypeMySQL, "the type survives");
	MAD_PASS_EQUAL(decoded.connectionString, @"(MySQL)[db.example.com:3306]employees", "the connection string survives");
}

static void testNewDatabaseConnectionFromProperties(void) {
	MADDatabaseConnectionMySql *seed =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	MADDatabaseConnectionMySql *built = [MADDatabaseConnectionMySql newDatabaseConnection:seed];
	MAD_PASS_EQUAL(built.host, @"db.example.com", "the host is copied");
	MAD_PASS_EQUAL(built.database, @"employees", "the database is copied");
	MAD_PASS(built.port == 3306, "the port is copied");
}

#pragma mark - MADMySQLServer defaults

static void testMADMySQLServerDefaults(void) {
	MADMySQLServer *server = [[MADMySQLServer alloc] init];
	MAD_PASS_EQUAL(server.host, @"localhost", "the default host");
	MAD_PASS_EQUAL(server.user, @"username", "the default user");
	MAD_PASS_EQUAL(server.password, @"password", "the default password");
	MAD_PASS_EQUAL(server.schema, @"test", "the default schema");
	MAD_PASS(server.port == 3306u, "the default port");
	MAD_PASS(server.flags == (unsigned long)CLIENT_FOUND_ROWS, "the default flags");
	MAD_PASS(server.connectionTimeout == 30u, "the default connection timeout");
}

static void testMADMySQLServerDescriptionOmitsPassword(void) {
	MADMySQLServer *server = [[MADMySQLServer alloc] init];
	server.host = @"db.example.com";
	server.user = @"alice";
	server.password = @"super-secret";
	NSString *description = [server description];
	MAD_PASS([description containsString:@"db.example.com"], "the description names the host");
	MAD_PASS([description containsString:@"alice"], "the description names the user");
	MAD_PASS(![description containsString:@"super-secret"], "the description omits the password");
}

#pragma mark - mySQLTypeForType

static void testMySqlTypeForTypeNamesCommonTypes(void) {
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_TINY)),      @"MYSQL_TYPE_TINY", "TINY");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_SHORT)),     @"MYSQL_TYPE_SHORT", "SHORT");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_LONG)),      @"MYSQL_TYPE_LONG", "LONG");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_LONGLONG)),  @"MYSQL_TYPE_LONGLONG", "LONGLONG");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_INT24)),     @"MYSQL_TYPE_INT24", "INT24");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_FLOAT)),     @"MYSQL_TYPE_FLOAT", "FLOAT");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_DOUBLE)),    @"MYSQL_TYPE_DOUBLE", "DOUBLE");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_NEWDECIMAL)),@"MYSQL_TYPE_NEWDECIMAL", "NEWDECIMAL");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_DATE)),      @"MYSQL_TYPE_DATE", "DATE");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_TIME)),      @"MYSQL_TYPE_TIME", "TIME");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_DATETIME)),  @"MYSQL_TYPE_DATETIME", "DATETIME");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_TIMESTAMP)), @"MYSQL_TYPE_TIMESTAMP", "TIMESTAMP");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_YEAR)),      @"MYSQL_TYPE_YEAR", "YEAR");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_VARCHAR)),   @"MYSQL_TYPE_VARCHAR", "VARCHAR");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_STRING)),    @"MYSQL_TYPE_STRING", "STRING");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_BLOB)),      @"MYSQL_TYPE_BLOB", "BLOB");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_TINY_BLOB)), @"MYSQL_TYPE_TINY_BLOB", "TINY_BLOB");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_ENUM)),      @"MYSQL_TYPE_ENUM", "ENUM");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_SET)),       @"MYSQL_TYPE_SET", "SET");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_BIT)),       @"MYSQL_TYPE_BIT", "BIT");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_GEOMETRY)),  @"MYSQL_TYPE_GEOMETRY", "GEOMETRY");
}

// MYSQL_TYPE_MEDIUM_BLOB and MYSQL_TYPE_LONG_BLOB both used to return the string
// "MYSQL_TYPE_DECIMAL" -- a copy/paste slip in this diagnostics-only helper. Fixed
// in MADMySQLFetch.m; these assertions keep it fixed. Likewise MYSQL_TYPE_LONGLONG had
// no case at all and fell through to "Unknown".
static void testMySqlTypeForTypeNamesBlobAndLongLongTypes(void) {
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_MEDIUM_BLOB)), @"MYSQL_TYPE_MEDIUM_BLOB", "MEDIUM_BLOB");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_LONG_BLOB)),   @"MYSQL_TYPE_LONG_BLOB", "LONG_BLOB");
	MAD_PASS_EQUAL(@(mySQLTypeForType(MYSQL_TYPE_LONGLONG)),    @"MYSQL_TYPE_LONGLONG", "LONGLONG");
}

static void testMySqlTypeForTypeUnknownFallsBack(void) {
	MAD_PASS_EQUAL(@(mySQLTypeForType((enum enum_field_types)12345)), @"Unknown", "an unknown code says Unknown");
}

#pragma mark - Connection failure paths (no server required)

static void testConnectToServerWithNoListenerFailsCleanly(void) {
	MADMySQLServer *server = [[MADMySQLServer alloc] init];
	server.host = @"127.0.0.1";
	server.port = 1;            // privileged, nothing listens here
	server.user = @"root";
	server.password = @"root";
	server.schema = @"employees";

	NSError *error = nil;
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];

	MAD_PASS(connection == nil, "the connection attempt fails");
	MAD_PASS(error != nil, "the failure is reported");
	MAD_PASS_EQUAL(error.domain, @"MADDatabaseMySQL", "the error is in the MySQL domain");
	MAD_PASS(error.code != 0, "the error carries a client code");
	MAD_PASS(error.userInfo[@"MySQLErrorNumberKey"] != nil, "the client error number is reported");
	MAD_PASS_EQUAL(error.userInfo[@"MySQLHostnameKey"], @"127.0.0.1", "the host is reported");
	MAD_PASS_EQUAL(error.userInfo[@"MySQLSchemaKey"], @"employees", "the schema is reported");
}

static void testConnectToServerWithoutErrorPointerStillReturnsNil(void) {
	MADMySQLServer *server = [[MADMySQLServer alloc] init];
	server.host = @"127.0.0.1";
	server.port = 1;
	MAD_PASS([MADMySQLConnection connectToServer:server] == nil, "no error pointer, still nil");
}

static void testConnectToServersReturnsNilWhenAllCandidatesFail(void) {
	MADMySQLServer *first = [[MADMySQLServer alloc] init];
	first.host = @"127.0.0.1";
	first.port = 1;

	MADMySQLServer *second = [[MADMySQLServer alloc] init];
	second.host = @"127.0.0.1";
	second.port = 1;

	// Bind to a local first: a comma inside an @[...] literal would otherwise be
	// taken as an extra argument to the macro.
	NSArray *candidates = @[first, second];
	MAD_PASS([MADMySQLConnection connectToServers:candidates] == nil, "every candidate fails");
}

#pragma mark - MADMySQLConnection without a server behind it

// -[MADMySQLConnection init] is not how the app builds connections (the factories
// answer nil when the server cannot be reached), but it produces the state
// these tests need: an object whose handle is NULL.  Reading from it is safe;
// the mutating session commands are not (see BUGS.md).

static void testErrorAccessorsOnAConnectionWithoutAServer(void) {
	MADMySQLConnection *connection = [[MADMySQLConnection alloc] init];

	// The client library checks for a NULL handle, so the "why did it not
	// connect?" accessors answer instead of faulting.
	MAD_PASS([connection errorNumber] == 0u, "a disconnected connection reports no error number");
	const char *text = [connection errorText];
	MAD_PASS(text != NULL, "the error text is a C string");
	MAD_PASS_EQUAL([NSString stringWithUTF8String:text], @"", "the error text is empty");
}

static void testTransactionsFlagStartsOff(void) {
	MADMySQLConnection *connection = [[MADMySQLConnection alloc] init];
	MAD_PASS(!connection.transactionsEnabled, "transactions start disabled");
}

static void testDescriptionOfAConnectionWithoutAServer(void) {
	MADMySQLConnection *connection = [[MADMySQLConnection alloc] init];

	NSString *description = [connection description];
	MAD_PASS([description containsString:@"NO"], "the description reports the disconnected state");
}

MAD_TEST_MAIN("MADMySQLTests",
	MAD_TEST(testDataTypeForNativeTypeMapsIntegralTypes),
	MAD_TEST(testDataTypeForNativeTypeMapsStringTypes),
	MAD_TEST(testDataTypeForNativeTypeMapsBlobVariants),
	MAD_TEST(testDataTypeForNativeTypeMapsNumericTypes),
	MAD_TEST(testDataTypeForNativeTypeMapsTemporalTypes),
	MAD_TEST(testDataTypeForNativeTypeMapsNullToNumber),
	MAD_TEST(testDataTypeForNativeTypeDefaultsToUnknownNativeCodesAreStrings),
	MAD_TEST(testNewSafeQueryFieldQualifiesAndQuotes),
	MAD_TEST(testNewSafeQueryFieldQuotesEmbeddedBackticksLiterally),
	MAD_TEST(testNewSafeIdentifierQuotesBareName),
	MAD_TEST(testQueryKeyTableMatchesSafeQueryField),
	MAD_TEST(testInstanceNewSafeIdentifierQuotesName),
	MAD_TEST(testNewSafeLiteralWithoutASessionFallsBackToAnsiQuoting),
	MAD_TEST(testDriverMetadata),
	MAD_TEST(testDomainIsClassName),
	MAD_TEST(testErrorCouldNotGetCredientalsShape),
	MAD_TEST(testConnectionInitializationStoresProperties),
	MAD_TEST(testConnectionServerPropertyIsTrimmedButHostIsNot),
	MAD_TEST(testConnectionIdentifier),
	MAD_TEST(testConnectionStringFormat),
	MAD_TEST(testConnectionCopyIsIndependent),
	MAD_TEST(testConnectionCodingRoundTripCarriesTheConnectionState),
	MAD_TEST(testNewDatabaseConnectionFromProperties),
	MAD_TEST(testMADMySQLServerDefaults),
	MAD_TEST(testMADMySQLServerDescriptionOmitsPassword),
	MAD_TEST(testMySqlTypeForTypeNamesCommonTypes),
	MAD_TEST(testMySqlTypeForTypeNamesBlobAndLongLongTypes),
	MAD_TEST(testMySqlTypeForTypeUnknownFallsBack),
	MAD_TEST(testConnectToServerWithNoListenerFailsCleanly),
	MAD_TEST(testConnectToServerWithoutErrorPointerStillReturnsNil),
	MAD_TEST(testConnectToServersReturnsNilWhenAllCandidatesFail),
	MAD_TEST(testErrorAccessorsOnAConnectionWithoutAServer),
	MAD_TEST(testTransactionsFlagStartsOff),
	MAD_TEST(testDescriptionOfAConnectionWithoutAServer));
