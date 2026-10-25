//
//  MADMySQLLiveTests.m
//  MADMySQLTests
//
//  Created by Michael Thomason on 9/30/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Integration tests for MADMySQL that talk to a real MySQL server -- this is the
//  only way to exercise MADMySQLConnection, MADMySQLFetch and MADMySQLFetch+DataTable, which
//  are thin wrappers over libmysqlclient.
//
//  The server is the local development instance documented in docs/project/DEVELOPER.md:
//
//      MySQL: 127.0.0.1, root, root, employees
//
//  Every credential can be overridden with an environment variable so the suite can
//  be pointed at another instance without editing code:
//
//      MAD_MYSQL_TEST_HOST, MAD_MYSQL_TEST_PORT, MAD_MYSQL_TEST_USER,
//      MAD_MYSQL_TEST_PASSWORD, MAD_MYSQL_TEST_SCHEMA
//
//  If the server cannot be reached the suite SKIPS rather than fails, so a machine
//  without MySQL still gets a green run for the offline tests in MADMySQLTests.m.
//
//  Note on the host: use 127.0.0.1, not "localhost". libmysqlclient interprets
//  "localhost" as a request for a Unix-domain socket, and there is no MySQL socket
//  inside the iOS Simulator; 127.0.0.1 forces TCP to the server on the Mac.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADCredential.h>

#import "MADDatabaseMySQL.h"
#import "MADDatabaseConnectionMySql.h"
#import "MADMySQLServer.h"
#import "MADMySQLConnection.h"
#import "MADMySQLFetch.h"
#import "MADMySQLFetch+DataTable.h"
#import "MADMySQLInsert.h"
#import "MADMySQLUpdate.h"
#import "MADMySQLDelete.h"
#import "MADMySQLTruncate.h"
#import "MADMySQLIndex.h"
#import "MADMySQLException.h"
#import "MADMySQLCommitException.h"
#import "MADMySQLRollbackException.h"
#import "NSString+MADMySQLEscape.h"

#import <mysql.h>

@interface MADMySQLLiveTests : XCTestCase

@end

@implementation MADMySQLLiveTests

#pragma mark - Fixtures

+ (MADMySQLServer *)testServer {
	NSDictionary<NSString *, NSString *> *env = [[NSProcessInfo processInfo] environment];
	MADMySQLServer *server = [[MADMySQLServer alloc] init];
	server.host     = env[@"MAD_MYSQL_TEST_HOST"]     ?: @"127.0.0.1";
	server.user     = env[@"MAD_MYSQL_TEST_USER"]     ?: @"root";
	server.password = env[@"MAD_MYSQL_TEST_PASSWORD"] ?: @"root";
	server.schema   = env[@"MAD_MYSQL_TEST_SCHEMA"]   ?: @"employees";
	NSString *port  = env[@"MAD_MYSQL_TEST_PORT"];
	server.port     = port.length > 0 ? (unsigned int)port.integerValue : 3306u;
	return server;
}

- (BOOL)serverIsAvailable {
	static BOOL available = NO;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		NSError *error = nil;
		MADMySQLConnection *connection = [MADMySQLConnection connectToServer:[[self class] testServer] error:&error];
		available = (connection != nil);
	});
	return available;
}

- (void)requireServer {
	XCTSkipIf(![self serverIsAvailable],
			  @"No MySQL server reachable; see docs/project/DEVELOPER.md for the expected test instance.");
}

- (MADMySQLConnection *)openConnection {
	return [self openConnectionForServer:[[self class] testServer]];
}

- (MADMySQLConnection *)openConnectionForServer:(MADMySQLServer *)server {
	NSError *error = nil;
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];
	XCTAssertNotNil(connection, @"Expected to connect to %@, got error: %@", server.host, error);
	XCTAssertNil(error);
	return connection;
}

- (MADDataTable *)fetch:(NSString *)sql onConnection:(MADMySQLConnection *)connection error:(NSError * __autoreleasing *)error {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *fetchError = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:sql dataTable:table onConnection:connection error:&fetchError];
	if (error != NULL) { *error = fetchError; }
	return table;
}

#pragma mark - Connection

- (void)testConnectToLocalServerSucceeds {
	[self requireServer];
	MADMySQLServer *server = [[self class] testServer];
	NSError *error = nil;
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];
	XCTAssertNotNil(connection);
	XCTAssertNil(error);
	XCTAssertEqualObjects(connection.server.host, server.host);
}

- (void)testConnectionDescriptionMentionsHostAndConnectedState {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSString *description = [connection description];
	XCTAssertTrue([description containsString:[[self class] testServer].host]);
	XCTAssertTrue([description containsString:@"YES"], @"Expected connected state in: %@", description);
}

- (void)testConnectWithWrongPasswordReportsAccessDenied {
	[self requireServer];
	MADMySQLServer *server = [[self class] testServer];
	server.password = @"definitely-not-the-password";

	NSError *error = nil;
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];

	XCTAssertNil(connection);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MADDatabaseMySQL");
	XCTAssertEqual(error.code, 1045, @"Expected MySQL access-denied; got: %@", error);
	XCTAssertEqualObjects(error.userInfo[@"MySQLErrorNumberKey"], @1045);
}

- (void)testConnectWithUnknownSchemaReportsUnknownDatabase {
	[self requireServer];
	MADMySQLServer *server = [[self class] testServer];
	server.schema = @"mad_no_such_schema";

	NSError *error = nil;
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];

	XCTAssertNil(connection);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 1049, @"Expected unknown-database; got: %@", error);
}

- (void)testConnectToServersReturnsFirstReachableCandidate {
	[self requireServer];
	MADMySQLServer *dead = [[MADMySQLServer alloc] init];
	dead.host = @"127.0.0.1";
	dead.port = 1;

	MADMySQLConnection *connection = [MADMySQLConnection connectToServers:@[dead, [[self class] testServer]]];
	XCTAssertNotNil(connection);
	XCTAssertEqualObjects(connection.server.host, [[self class] testServer].host);
}

#pragma mark - Escaping

- (void)testEscapeStringQuotesSingleQuote {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	// mysql_real_escape_string turns ' into \' (backslash + quote).
	XCTAssertEqualObjects([connection mysqlEscapeString:@"O'Brien"], @"O\\'Brien");
}

- (void)testEscapeStringDoublesBackslash {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	// One backslash in, two backslashes out.
	XCTAssertEqualObjects([connection mysqlEscapeString:@"a\\b"], @"a\\\\b");
}

- (void)testEscapeStringReturnsNilForNilInput {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	XCTAssertNil([connection mysqlEscapeString:nil]);
}

#pragma mark - Literal quoting through a live session

// The driver escapes string literals through the session it opened for the query
// (-newSafeLiteral:), because a backslash is an escape character in a MySQL literal:
// ANSI ''-doubling alone turns C:\temp into C:<TAB>emp.  These tests connect the way a
// query does, ask the driver for the literal, and then have the server read it back --
// the round trip is the assertion, since only the server's reading proves the escape.

- (MADDatabaseMySQL *)openDatabase:(MADMySQLConnection * __autoreleasing *)outSocket {
	MADMySQLServer *server = [[self class] testServer];
	MADDatabaseConnectionMySql *settings =
		[[MADDatabaseConnectionMySql alloc] initWithHost: server.host
												database: server.schema
												 andPort: server.port];
	MADCredential *credential = [[MADCredential alloc] initWithUsername: server.user
															andPassword: server.password];

	MADDatabaseMySQL *database = [[MADDatabaseMySQL alloc] init];
	database.databaseConnection = settings;

	NSError *error = nil;
	MADMySQLConnection *socket = [database connectWithConnection: settings
													credentals: credential
											   connectionError: &error];
	XCTAssertNotNil(socket, @"Expected to connect to %@: %@", server.host, error);
	if (outSocket != NULL) { *outSocket = socket; }
	return socket != nil ? database : nil;
}

- (void)testNewSafeLiteralEscapesABackslashThroughTheLiveSession {
	[self requireServer];
	MADMySQLConnection *socket = nil;
	MADDatabaseMySQL *database = [self openDatabase:&socket];
	if (database == nil) return;

	// The value is C:\temp; the text handed to the server has the backslash doubled.
	NSString *value = @"C:\\temp";
	NSString *literal = [database newSafeLiteral: value];
	XCTAssertEqualObjects(literal, @"'C:\\\\temp'",
						  @"The session should have doubled the backslash.");

	NSError *error = nil;
	MADDataTable *table = [self fetch:[NSString stringWithFormat:@"SELECT %@ AS `v`;", literal]
						 onConnection: socket
								error: &error];
	XCTAssertNil(error, @"The server rejected the literal: %@", error);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], value);
}

- (void)testNewSafeLiteralEscapesAnApostropheThroughTheLiveSession {
	[self requireServer];
	MADMySQLConnection *socket = nil;
	MADDatabaseMySQL *database = [self openDatabase:&socket];
	if (database == nil) return;

	NSString *value = @"O'Brien";
	NSString *literal = [database newSafeLiteral: value];
	XCTAssertEqualObjects(literal, @"'O\\'Brien'");

	NSError *error = nil;
	MADDataTable *table = [self fetch:[NSString stringWithFormat:@"SELECT %@ AS `v`;", literal]
						 onConnection: socket
								error: &error];
	XCTAssertNil(error, @"The server rejected the literal: %@", error);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], value);
}

- (void)testNewSafeLiteralReportsNullWithoutASession {
	[self requireServer];
	MADMySQLConnection *socket = nil;
	MADDatabaseMySQL *database = [self openDatabase:&socket];
	if (database == nil) return;

	// NULL is spelled without quotes, so it does not need the session at all.
	XCTAssertEqualObjects([database newSafeLiteral:nil], @"NULL");
}

#pragma mark - Fetch: scalars and shapes

- (void)testFetchScalarSelect {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT 255 AS `f1`;" onConnection:connection error:&error];

	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqual([table numberOfColumns], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @255);
}

- (void)testFetchKnownEmployeeRow {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT emp_no, first_name, last_name, gender "
									  @"FROM employees WHERE emp_no = 10001;"
						 onConnection:connection
								error:&error];

	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqual([table numberOfColumns], 4u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @10001);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @"Georgi");
	XCTAssertEqualObjects([table objectAtRow:0 column:2], @"Facello");
	// gender is ENUM('M','F'); MySQL reports ENUM columns as strings on the wire.
	XCTAssertEqualObjects([table objectAtRow:0 column:3], @"M");
}

- (void)testFetchRespectsLimitClause {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 25;"
						 onConnection:connection
								error:&error];

	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 25u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @10001);
	XCTAssertEqualObjects([table objectAtRow:24 column:0], @10025);
}

- (void)testFetchCountMatchesKnownTableSize {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT COUNT(*) AS `total` FROM employees;"
						 onConnection:connection
								error:&error];

	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 1u);
	// COUNT(*) is BIGINT -> MYSQL_TYPE_LONGLONG -> NSNumber.
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @300024);
}

- (void)testFetchShowTablesFindsEmployees {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SHOW TABLES;" onConnection:connection error:&error];

	XCTAssertNil(error);
	NSMutableArray<NSString *> *names = [NSMutableArray array];
	for (NSUInteger row = 0; row < [table numberOfRows]; row++) {
		id value = [table objectAtRow:row column:0];
		if ([value isKindOfClass:[NSString class]]) { [names addObject:value]; }
	}
	XCTAssertTrue([names containsObject:@"employees"], @"SHOW TABLES returned: %@", names);
}

#pragma mark - Fetch: column metadata

- (void)testFetchColumnMetadataForEmployees {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT emp_no, first_name, birth_date FROM employees "
									  @"WHERE emp_no = 10001;"
						 onConnection:connection
								error:&error];

	XCTAssertNil(error);
	XCTAssertEqual([table numberOfColumns], 3u);

	NSString *keyEmpNo = [table columnKeys][0];
	NSString *keyFirstName = [table columnKeys][1];
	NSString *keyBirthDate = [table columnKeys][2];

	MADDataColumn *empNo = table.columns[keyEmpNo];
	XCTAssertEqual(empNo.nativeType, (int16_t)MYSQL_TYPE_LONG);
	XCTAssertEqual(empNo.type, MADDataTypeLong);
	XCTAssertEqualObjects(empNo.fieldName, keyEmpNo);

	MADDataColumn *firstName = table.columns[keyFirstName];
	XCTAssertEqual(firstName.nativeType, (int16_t)MYSQL_TYPE_VAR_STRING);
	XCTAssertEqual(firstName.type, MADDataTypeVarChar);

	MADDataColumn *birthDate = table.columns[keyBirthDate];
	XCTAssertEqual(birthDate.nativeType, (int16_t)MYSQL_TYPE_DATE);
	XCTAssertEqual(birthDate.type, MADDataTypeDate);
}

- (void)testFetchColumnKeysAreTableQualifiedWithExtendedNames {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees WHERE emp_no = 10001;"
				  dataTable:table
			   onConnection:connection
			  extendedNames:YES
					  error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects([table columnKeys][0], @"`employees`.`emp_no`");
}

- (void)testFetchColumnKeysAreBareWithoutExtendedNames {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees WHERE emp_no = 10001;"
				  dataTable:table
			   onConnection:connection
			  extendedNames:NO
					  error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects([table columnKeys][0], @"emp_no");
}

- (void)testFetchDateColumnYieldsDateComponents {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT birth_date FROM employees WHERE emp_no = 10001;"
						 onConnection:connection
								error:&error];

	XCTAssertNil(error);
	id value = [table objectAtRow:0 column:0];
	// mysql_stmt_fetch returns DATE as MYSQL_TIME; the fetch code converts it to
	// NSDateComponents (unlike DATETIME/TIMESTAMP, which become NSDate).
	XCTAssertTrue([value isKindOfClass:[NSDateComponents class]], @"Got %@ (%@)", value, [value class]);
	NSDateComponents *components = value;
	XCTAssertEqual(components.year, 1953);
	XCTAssertEqual(components.month, 9);
	XCTAssertEqual(components.day, 2);
}

#pragma mark - Fetch: error handling

- (void)testFetchReportsErrorForInvalidSQL {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	[self fetch:@"SELECT * FROM mad_no_such_table_xyz;" onConnection:connection error:&error];

	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"mad");
	XCTAssertEqual(error.code, 1146, @"Expected unknown-table; got: %@", error);
}

// Needs no server: a nil connection is rejected before any I/O.
- (void)testFetchReportsErrorWhenConnectionIsNil {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT 1;" dataTable:table onConnection:nil error:&error];

	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 3492);
	XCTAssertEqualObjects(error.localizedDescription, @"Connection is empty.");
}

#pragma mark - Fetch: table reuse

- (void)testFetchReusesAndClearsProvidedTable {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	NSError *error = nil;

	[fetch fetchWithCommand:@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 50;"
				  dataTable:table onConnection:connection error:&error];
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 50u);

	// Re-using the same table must not append; the fetch clears it first.
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 3;"
				  dataTable:table onConnection:connection error:&error];
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 3u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @10001);
}

#pragma mark - Fetch: statements that return no result set

// Regression: mysql_stmt_bind_result used to be called unconditionally, and it fails
// with code 3534 when the statement reports field_count == 0. That aborted the call
// before mysql_stmt_execute, so DDL and DML were impossible through MADMySQLFetch. The
// table is created and dropped rather than TEMPORARY so the rows are visible to the
// SELECTs below across statement boundaries.
- (void)testStatementWithNoResultSetExecutes {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;

	[self runStatement:@"DROP TABLE IF EXISTS mad_dml_probe;" onConnection:connection error:&error];
	XCTAssertNil(error, @"DROP IF EXISTS should be a no-op, got: %@", error);

	[self runStatement:@"CREATE TABLE mad_dml_probe (id INT, label VARCHAR(16));"
		  onConnection:connection
				 error:&error];
	XCTAssertNil(error, @"CREATE failed: %@", error);

	[self runStatement:@"INSERT INTO mad_dml_probe VALUES (1, 'alpha'), (2, 'beta');"
		  onConnection:connection
				 error:&error];
	XCTAssertNil(error, @"INSERT failed: %@", error);

	MADDataTable *table = [self fetch:@"SELECT id, label FROM mad_dml_probe ORDER BY id;"
						 onConnection:connection
								error:&error];
	XCTAssertNil(error, @"SELECT failed: %@", error);
	XCTAssertEqual([table numberOfRows], 2u);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @"alpha");
	XCTAssertEqualObjects([table objectAtRow:1 column:1], @"beta");

	[self runStatement:@"UPDATE mad_dml_probe SET label = 'gamma' WHERE id = 2;"
		  onConnection:connection
				 error:&error];
	XCTAssertNil(error, @"UPDATE failed: %@", error);

	[self runStatement:@"DELETE FROM mad_dml_probe WHERE id = 1;" onConnection:connection error:&error];
	XCTAssertNil(error, @"DELETE failed: %@", error);

	table = [self fetch:@"SELECT id, label FROM mad_dml_probe;" onConnection:connection error:&error];
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @2);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @"gamma");

	[self runStatement:@"DROP TABLE mad_dml_probe;" onConnection:connection error:&error];
	XCTAssertNil(error, @"DROP failed: %@", error);
}

// A no-result-set statement that the server rejects must report an error rather than
// fail silently, and must leave the connection usable.
- (void)testFailingStatementWithNoResultSetReportsError {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;

	[self runStatement:@"DROP TABLE IF EXISTS mad_dml_dup;" onConnection:connection error:&error];
	XCTAssertNil(error);
	[self runStatement:@"CREATE TABLE mad_dml_dup (id INT PRIMARY KEY, label VARCHAR(8));"
		  onConnection:connection
				 error:&error];
	XCTAssertNil(error);
	[self runStatement:@"INSERT INTO mad_dml_dup VALUES (1, 'first');" onConnection:connection error:&error];
	XCTAssertNil(error);

	// Duplicate primary key: rejected at execute time, not at prepare time.
	error = nil;
	[self runStatement:@"INSERT INTO mad_dml_dup VALUES (1, 'second');" onConnection:connection error:&error];
	XCTAssertNotNil(error, @"A duplicate key insert must report an error");
	XCTAssertTrue([error.localizedDescription containsString:@"MySQL says"],
				  @"Expected a server-reported error, got: %@", error);

	// The table is still usable afterwards; the failed statement left no residue.
	error = nil;
	MADDataTable *table = [self fetch:@"SELECT COUNT(*) AS `n` FROM mad_dml_dup;"
						 onConnection:connection
								error:&error];
	XCTAssertNil(error);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @1);

	[self runStatement:@"DROP TABLE mad_dml_dup;" onConnection:connection error:&error];
}

// SELECT NULL literal: the server reports MYSQL_TYPE_NULL, which takes its own branch
// in both -bindDataForStatement:andField: and -fetchResultsFromConnection:.
- (void)testFetchLiteralNullYieldsNSNull {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT NULL AS `n`;" onConnection:connection error:&error];

	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], [NSNull null]);
}

#pragma mark - Fetch: type conversion round-trip

// Runs a statement that returns no rows (DDL/DML) through the same prepared-statement
// path the fetches use, so the probe table below is built exactly the way the app
// would see it.
- (void)runStatement:(NSString *)sql onConnection:(MADMySQLConnection *)connection error:(NSError * __autoreleasing *)error {
	MADDataTable *scratch = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *statementError = nil;
	MADMySQLFetch *runner = [[MADMySQLFetch alloc] init];
	[runner fetchWithCommand:sql dataTable:scratch onConnection:connection error:&statementError];
	if (error != NULL) { *error = statementError; }
}

// Drives one row through every conversion branch in -fetchResultsFromConnection: that
// the probe table can reach. TEMPORARY, so it disappears with the connection and the
// employees schema is untouched.
- (void)testFetchTypeConversionRoundTrip {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;

	NSString *create =
		@"CREATE TEMPORARY TABLE mad_type_probe ("
		 "c_tiny TINYINT, c_short SMALLINT, c_medium MEDIUMINT, c_int INT, "
		 "c_big BIGINT, c_decimal DECIMAL(10,2), c_double DOUBLE, c_char CHAR(4), "
		 "c_varchar VARCHAR(16), c_date DATE, c_datetime DATETIME, "
		 "c_enum ENUM('a','b'), c_nullable VARCHAR(8) NULL);";
	NSString *insert =
		@"INSERT INTO mad_type_probe VALUES ("
		 "7, 300, 400000, 70000, 4294967296, 1234.56, 2.5, "
		 "'abcd', 'hello', '2024-03-15', '2024-03-15 13:45:59', 'b', NULL);";

	[self runStatement:create onConnection:connection error:&error];
	XCTAssertNil(error, @"CREATE failed: %@", error);
	[self runStatement:insert onConnection:connection error:&error];
	XCTAssertNil(error, @"INSERT failed: %@", error);

	MADDataTable *table = [self fetch:@"SELECT * FROM mad_type_probe;" onConnection:connection error:&error];
	XCTAssertNil(error, @"SELECT failed: %@", error);
	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqual([table numberOfColumns], 13u);

	// Integral widths.
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @7);           // TINYINT
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @300);         // SMALLINT
	// MEDIUMINT used to fall through into the DOUBLE case, which re-read the 4-byte
	// int buffer as an 8-byte double: a heap over-read that also overwrote the correct
	// value with a garbage one. The missing break is fixed; this pins the value.
	XCTAssertEqualObjects([table objectAtRow:0 column:2], @400000);      // MEDIUMINT
	XCTAssertEqualObjects([table objectAtRow:0 column:3], @70000);       // INT
	XCTAssertEqualObjects([table objectAtRow:0 column:4], @4294967296);  // BIGINT

	// DECIMAL arrives as NSDecimalNumber, not NSNumber.
	id decimal = [table objectAtRow:0 column:5];
	XCTAssertTrue([decimal isKindOfClass:[NSDecimalNumber class]], @"DECIMAL gave %@ (%@)", decimal, [decimal class]);
	XCTAssertEqualObjects([decimal stringValue], @"1234.56");

	XCTAssertEqualObjects([table objectAtRow:0 column:6], @2.5);         // DOUBLE

	// Character types.
	XCTAssertEqualObjects([table objectAtRow:0 column:7], @"abcd");      // CHAR
	XCTAssertEqualObjects([table objectAtRow:0 column:8], @"hello");     // VARCHAR
	XCTAssertEqualObjects([table objectAtRow:0 column:11], @"b");        // ENUM

	// DATE becomes NSDateComponents directly (see -fetchResultsFromConnection:).
	id date = [table objectAtRow:0 column:9];
	XCTAssertTrue([date isKindOfClass:[NSDateComponents class]], @"DATE gave %@ (%@)", date, [date class]);
	XCTAssertEqual(((NSDateComponents *)date).year, 2024);
	XCTAssertEqual(((NSDateComponents *)date).month, 3);
	XCTAssertEqual(((NSDateComponents *)date).day, 15);

	// DATETIME is assembled into an NSDate via the current calendar.
	id datetime = [table objectAtRow:0 column:10];
	XCTAssertTrue([datetime isKindOfClass:[NSDate class]], @"DATETIME gave %@ (%@)", datetime, [datetime class]);
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *parts = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
										  fromDate:datetime];
	XCTAssertEqual(parts.year, 2024);
	XCTAssertEqual(parts.month, 3);
	XCTAssertEqual(parts.day, 15);

	// A NULL in a typed column must surface as NSNull, not as a missing value.
	XCTAssertEqualObjects([table objectAtRow:0 column:12], [NSNull null]);
}

- (void)testFetchProbeTableColumnMetadata {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;

	[self runStatement:@"CREATE TEMPORARY TABLE mad_meta_probe ("
					   "c_big BIGINT, c_medium MEDIUMINT, c_decimal DECIMAL(10,2), "
					   "c_varchar VARCHAR(16), c_date DATE);"
			  onConnection:connection
					 error:&error];
	XCTAssertNil(error, @"CREATE failed: %@", error);

	MADDataTable *table = [self fetch:@"SELECT * FROM mad_meta_probe;" onConnection:connection error:&error];
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfColumns], 5u);

	MADDataColumn *big = table.columns[[table columnKeys][0]];
	XCTAssertEqual(big.nativeType, (int16_t)MYSQL_TYPE_LONGLONG);
	XCTAssertEqual(big.type, MADDataTypeLongLong);

	MADDataColumn *medium = table.columns[[table columnKeys][1]];
	XCTAssertEqual(medium.nativeType, (int16_t)MYSQL_TYPE_INT24);
	// MEDIUMINT maps onto its dedicated MADDataTypeInt24; see MADMySQLTests.m.
	XCTAssertEqual(medium.type, MADDataTypeInt24);

	MADDataColumn *decimal = table.columns[[table columnKeys][2]];
	XCTAssertEqual(decimal.nativeType, (int16_t)MYSQL_TYPE_NEWDECIMAL);
	XCTAssertEqual(decimal.type, MADDataTypeDecimal);

	MADDataColumn *varchar = table.columns[[table columnKeys][3]];
	XCTAssertEqual(varchar.nativeType, (int16_t)MYSQL_TYPE_VAR_STRING);
	XCTAssertEqual(varchar.type, MADDataTypeVarChar);

	MADDataColumn *date = table.columns[[table columnKeys][4]];
	XCTAssertEqual(date.nativeType, (int16_t)MYSQL_TYPE_DATE);
	XCTAssertEqual(date.type, MADDataTypeDate);
}

#pragma mark - DML: scratch tables

// The write-side classes (MADMySQLInsert, MADMySQLUpdate, MADMySQLDelete,
// MADMySQLTruncate) are the app's DML path and can only be exercised against a
// server.  Every test here works on a scratch table that is created and
// dropped inside the test, so the employees dataset is never written to.

- (void)createScratchTableNamed:(NSString *)name onConnection:(MADMySQLConnection *)connection {
	NSError *error = nil;
	[self runStatement:[[NSString alloc] initWithFormat:@"DROP TABLE IF EXISTS %@;", name]
		  onConnection:connection
				 error:&error];
	XCTAssertNil(error, @"DROP IF EXISTS failed: %@", error);

	[self runStatement:[[NSString alloc] initWithFormat:
						@"CREATE TABLE %@ (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, "
						"label VARCHAR(32) NOT NULL, note VARCHAR(32) NULL, payload BLOB NULL);", name]
		  onConnection:connection
				 error:&error];
	XCTAssertNil(error, @"CREATE failed: %@", error);
}

- (void)dropScratchTableNamed:(NSString *)name onConnection:(MADMySQLConnection *)connection {
	NSError *error = nil;
	[self runStatement:[[NSString alloc] initWithFormat:@"DROP TABLE %@;", name]
		  onConnection:connection
				 error:&error];
	XCTAssertNil(error, @"DROP failed: %@", error);
}

- (NSObject *)scalar:(NSString *)sql onConnection:(MADMySQLConnection *)connection {
	NSError *error = nil;
	MADDataTable *table = [self fetch:sql onConnection:connection error:&error];
	XCTAssertNil(error, @"%@ failed: %@", sql, error);
	return [table objectAtRow:0 column:0];
}

- (NSObject *)countOfTable:(NSString *)table onConnection:(MADMySQLConnection *)connection {
	return [self scalar:[[NSString alloc] initWithFormat:@"SELECT COUNT(*) AS `n` FROM %@;", table]
		   onConnection:connection];
}

#pragma mark - MADMySQLInsert

- (void)testInsertWritesARowAndReportsTheNewId {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_insert" onConnection:connection];

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_insert";
	insert.rowData = @{@"label": @"alpha"};
	[insert execute];

	XCTAssertEqualObjects(insert.affectedRows, @1);
	XCTAssertEqualObjects(insert.rowid, @1, @"AUTO_INCREMENT starts at 1");
	XCTAssertEqualObjects([self scalar:@"SELECT label FROM mad_scratch_insert;" onConnection:connection],
						  @"alpha");

	[self dropScratchTableNamed:@"mad_scratch_insert" onConnection:connection];
}

- (void)testInsertBindsNullsAndBlobs {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_blob" onConnection:connection];

	NSData *payload = [NSData dataWithBytes:"\x01\x02\x03" length:3];
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_blob";
	insert.rowData = @{@"label": @"blob", @"note": [NSNull null], @"payload": payload};
	[insert execute];

	XCTAssertEqualObjects([self scalar:@"SELECT note IS NULL FROM mad_scratch_blob;" onConnection:connection], @1);
	XCTAssertEqualObjects([self scalar:@"SELECT LENGTH(payload) FROM mad_scratch_blob;" onConnection:connection], @3);
	XCTAssertEqualObjects([self scalar:@"SELECT HEX(payload) FROM mad_scratch_blob;" onConnection:connection], @"010203");

	[self dropScratchTableNamed:@"mad_scratch_blob" onConnection:connection];
}

- (void)testInsertRejectsADuplicateKeyUnlessToldToIgnoreIt {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_dupe" onConnection:connection];

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_dupe";
	insert.rowData = @{@"id": @1, @"label": @"first"};
	[insert execute];

	// The second insert collides on the primary key and raises.
	insert.rowData = @{@"id": @1, @"label": @"second"};
	XCTAssertThrowsSpecificNamed([insert execute], MADMySQLException, @"MADMySQLException");

	// With the flag set the same collision is swallowed and the row stands.
	insert.ignoreDuplicateErrors = YES;
	XCTAssertNoThrow([insert execute]);
	// docs/project/BUGS.md: the ignored statement still failed, and -affectedRows is read
	// straight off mysql_affected_rows, which answers (my_ulonglong)-1 for a
	// failed statement -- so the count is ULONG_MAX rather than 0.
	XCTAssertEqual(insert.affectedRows.unsignedLongLongValue, ULLONG_MAX);
	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_dupe" onConnection:connection], @1);
	XCTAssertEqualObjects([self scalar:@"SELECT label FROM mad_scratch_dupe;" onConnection:connection], @"first");

	[self dropScratchTableNamed:@"mad_scratch_dupe" onConnection:connection];
}

#pragma mark - MADMySQLUpdate

- (void)testUpdateChangesOnlyTheQualifiedRows {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_update" onConnection:connection];

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_update";
	insert.rowData = @{@"label": @"alpha"};
	[insert execute];
	insert.rowData = @{@"label": @"alpha"};
	[insert execute];

	MADMySQLUpdate *update = [MADMySQLUpdate updateWithConnection:connection];
	update.table = @"mad_scratch_update";
	update.rowData = @{@"label": @"beta"};
	update.qualifier = @{@"id": @1};
	[update execute];

	XCTAssertEqualObjects(update.affectedRows, @1);
	XCTAssertEqualObjects([self scalar:@"SELECT label FROM mad_scratch_update WHERE id = 1;" onConnection:connection],
						  @"beta");
	XCTAssertEqualObjects([self scalar:@"SELECT label FROM mad_scratch_update WHERE id = 2;" onConnection:connection],
						  @"alpha");

	[self dropScratchTableNamed:@"mad_scratch_update" onConnection:connection];
}

- (void)testUpdateQualifierHandlesStringsAndNulls {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_qual" onConnection:connection];

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_qual";
	insert.rowData = @{@"label": @"alpha"};
	[insert execute];

	// String qualifiers are escaped and quoted, NSNull becomes "is null".
	MADMySQLUpdate *update = [MADMySQLUpdate updateWithConnection:connection];
	update.table = @"mad_scratch_qual";
	update.rowData = @{@"note": @"quoted"};
	update.qualifier = @{@"label": @"alpha"};
	[update execute];
	XCTAssertEqualObjects(update.affectedRows, @1);

	update.rowData = @{@"note": [NSNull null]};
	update.qualifier = @{@"note": @"quoted"};
	[update execute];
	XCTAssertEqualObjects(update.affectedRows, @1);
	XCTAssertEqualObjects([self scalar:@"SELECT note IS NULL FROM mad_scratch_qual;" onConnection:connection], @1);

	[self dropScratchTableNamed:@"mad_scratch_qual" onConnection:connection];
}

- (void)testUpdateWithoutAQualifierRaisesTheUpdatesOwnError {
	// docs/project/BUGS.md: a nil qualifier left the WHERE-clause buffer empty, and -execute
	// deleted four characters off the front of it instead of telling the caller
	// to qualify the update.  The guard runs before any session call, so the
	// offline suite covers it too; this keeps the live connection in the loop.
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_noqual" onConnection:connection];

	MADMySQLUpdate *update = [MADMySQLUpdate updateWithConnection:connection];
	update.table = @"mad_scratch_noqual";
	update.rowData = @{@"label": @"beta"};

	@try {
		[update execute];
		XCTFail(@"An update with no qualifier must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.reason, @"a qualifier must be specified to perform an update");
		XCTAssertNil(exception.userInfo);
	}

	[self dropScratchTableNamed:@"mad_scratch_noqual" onConnection:connection];
}

#pragma mark - MADMySQLDelete

- (void)testDeleteRemovesTheQualifiedRows {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_delete" onConnection:connection];

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_delete";
	for (NSString *label in @[@"alpha", @"beta", @"alpha"]) {
		insert.rowData = @{@"label": label};
		[insert execute];
	}
	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_delete" onConnection:connection], @3);

	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:connection];
	delete.tableName = @"mad_scratch_delete";
	delete.qualifier = @"label='alpha'";
	[delete execute];

	XCTAssertEqualObjects(delete.affectedRows, @2);
	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_delete" onConnection:connection], @1);
	XCTAssertEqualObjects([self scalar:@"SELECT label FROM mad_scratch_delete;" onConnection:connection], @"beta");

	[self dropScratchTableNamed:@"mad_scratch_delete" onConnection:connection];
}

- (void)testDeleteWithARubbishQualifierRaises {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_badqual" onConnection:connection];

	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:connection];
	delete.tableName = @"mad_scratch_badqual";
	delete.qualifier = @"no_such_column = 1";

	XCTAssertThrowsSpecificNamed([delete execute], MADMySQLException, @"MADMySQLException");

	[self dropScratchTableNamed:@"mad_scratch_badqual" onConnection:connection];
}

#pragma mark - MADMySQLTruncate

- (void)testTruncateEmptiesATable {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_truncate" onConnection:connection];

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_truncate";
	insert.rowData = @{@"label": @"alpha"};
	[insert execute];
	insert.rowData = @{@"label": @"beta"};
	[insert execute];
	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_truncate" onConnection:connection], @2);

	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connection
														   forTable:@"mad_scratch_truncate"];
	XCTAssertNoThrow([truncate execute]);

	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_truncate" onConnection:connection], @0);

	[self dropScratchTableNamed:@"mad_scratch_truncate" onConnection:connection];
}

#pragma mark - MADMySQLIndex

- (void)testIndexFactoryKeepsALiveConnection {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];

	XCTAssertEqual([MADMySQLIndex indexWithConnection:connection].connection, connection);
}

#pragma mark - Transactions

- (void)testRollbackDiscardsAndCommitKeeps {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	[self createScratchTableNamed:@"mad_scratch_tx" onConnection:connection];

	XCTAssertFalse(connection.transactionsEnabled);
	[connection enableTransactions];
	XCTAssertTrue(connection.transactionsEnabled);

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_tx";
	insert.rowData = @{@"label": @"rolled-back"};
	[insert execute];
	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_tx" onConnection:connection], @1,
						  @"The row is visible inside its own transaction");

	[connection rollbackTransaction];
	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_tx" onConnection:connection], @0);

	insert.rowData = @{@"label": @"kept"};
	[insert execute];
	[connection commitTransaction];
	XCTAssertEqualObjects([self countOfTable:@"mad_scratch_tx" onConnection:connection], @1);

	[connection disableTransactions];
	XCTAssertFalse(connection.transactionsEnabled);

	[self dropScratchTableNamed:@"mad_scratch_tx" onConnection:connection];
}

#pragma mark - Session settings and error reporting

- (void)testEnableStrictSqlTurnsOnTheMode {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];

	XCTAssertNoThrow([connection enableStrictSql]);

	NSString *mode = (NSString *)[self scalar:@"SELECT @@sql_mode AS `m`;" onConnection:connection];
	XCTAssertTrue([[mode uppercaseString] containsString:@"STRICT_ALL_TABLES"], @"sql_mode was: %@", mode);
}

- (void)testTriggerTogglesSetAndClearTheSessionFlag {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];

	XCTAssertNoThrow([connection disableTriggers]);
	XCTAssertEqualObjects([self scalar:@"SELECT @DISABLE_TRIGGERS AS `v`;" onConnection:connection], @1);

	XCTAssertNoThrow([connection enableTriggers]);
	XCTAssertEqualObjects([self scalar:@"SELECT @DISABLE_TRIGGERS AS `v`;" onConnection:connection],
						  [NSNull null]);
}

- (void)testErrorNumberAndErrorTextReportTheLastFailure {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];
	NSError *error = nil;

	[self fetch:@"SELECT * FROM mad_no_such_table;" onConnection:connection error:&error];
	XCTAssertNotNil(error);

	XCTAssertNotEqual([connection errorNumber], (unsigned int)0);
	const char *text = [connection errorText];
	XCTAssertTrue(text != NULL);
	XCTAssertTrue([[NSString stringWithUTF8String:text] containsString:@"mad_no_such_table"],
				  @"errorText was: %s", text);
}

- (void)testErrorWithConnectionDescribesTheServerState {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];

	NSError *error = [MADMySQLException errorWithConnection:connection domain:@"MADMySQLTests" andCode:7];

	XCTAssertEqualObjects(error.domain, @"MADMySQLTests");
	XCTAssertEqual(error.code, 7);
	XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey], @"Executing Error");
	XCTAssertTrue([error.localizedDescription hasPrefix:@"MySQL says"], @"was: %@", error.localizedDescription);
}

#pragma mark - Escaping through the connection

- (void)testEscapeInConnectionMatchesTheConnectionHelper {
	[self requireServer];
	MADMySQLConnection *connection = [self openConnection];

	// The NSString category and the connection's own helper are two entry
	// points to mysql_real_escape_string; they must agree.
	XCTAssertEqualObjects([@"O'Brien" mysqlEscapeInConnection:connection],
						  [connection mysqlEscapeString:@"O'Brien"]);
}

@end
