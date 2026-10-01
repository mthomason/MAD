//
//  MADMySQLLiveTests.m
//  MADMySQLTests
//
//  Created by Michael Thomason on 9/30/26.
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Integration tests for MADMySQL that talk to a real MySQL server -- this is the
//  only way to exercise MysqlConnection, MysqlFetch and MysqlFetch+DataTable, which
//  are thin wrappers over libmysqlclient.
//
//  The server is the local development instance documented in DEVELOPER.md:
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

#import "MysqlServer.h"
#import "MysqlConnection.h"
#import "MysqlFetch.h"
#import "MysqlFetch+DataTable.h"

#import <mysql.h>

@interface MADMySQLLiveTests : XCTestCase

@end

@implementation MADMySQLLiveTests

#pragma mark - Fixtures

+ (MysqlServer *)testServer {
	NSDictionary<NSString *, NSString *> *env = [[NSProcessInfo processInfo] environment];
	MysqlServer *server = [[MysqlServer alloc] init];
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
		MysqlConnection *connection = [MysqlConnection connectToServer:[[self class] testServer] error:&error];
		available = (connection != nil);
	});
	return available;
}

- (void)requireServer {
	XCTSkipIf(![self serverIsAvailable],
			  @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
}

- (MysqlConnection *)openConnection {
	return [self openConnectionForServer:[[self class] testServer]];
}

- (MysqlConnection *)openConnectionForServer:(MysqlServer *)server {
	NSError *error = nil;
	MysqlConnection *connection = [MysqlConnection connectToServer:server error:&error];
	XCTAssertNotNil(connection, @"Expected to connect to %@, got error: %@", server.host, error);
	XCTAssertNil(error);
	return connection;
}

- (MADDataTable *)fetch:(NSString *)sql onConnection:(MysqlConnection *)connection error:(NSError **)error {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *fetchError = nil;
	MysqlFetch *fetch = [[MysqlFetch alloc] init];
	[fetch fetchWithCommand:sql dataTable:&table onConnection:connection error:&fetchError];
	if (error != NULL) { *error = fetchError; }
	return table;
}

#pragma mark - Connection

- (void)testConnectToLocalServerSucceeds {
	[self requireServer];
	MysqlServer *server = [[self class] testServer];
	NSError *error = nil;
	MysqlConnection *connection = [MysqlConnection connectToServer:server error:&error];
	XCTAssertNotNil(connection);
	XCTAssertNil(error);
	XCTAssertEqualObjects(connection.server.host, server.host);
}

- (void)testConnectionDescriptionMentionsHostAndConnectedState {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
	NSString *description = [connection description];
	XCTAssertTrue([description containsString:[[self class] testServer].host]);
	XCTAssertTrue([description containsString:@"YES"], @"Expected connected state in: %@", description);
}

- (void)testConnectWithWrongPasswordReportsAccessDenied {
	[self requireServer];
	MysqlServer *server = [[self class] testServer];
	server.password = @"definitely-not-the-password";

	NSError *error = nil;
	MysqlConnection *connection = [MysqlConnection connectToServer:server error:&error];

	XCTAssertNil(connection);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MADDatabaseMySQL");
	XCTAssertEqual(error.code, 1045, @"Expected MySQL access-denied; got: %@", error);
	XCTAssertEqualObjects(error.userInfo[@"MySQLErrorNumberKey"], @1045);
}

- (void)testConnectWithUnknownSchemaReportsUnknownDatabase {
	[self requireServer];
	MysqlServer *server = [[self class] testServer];
	server.schema = @"mad_no_such_schema";

	NSError *error = nil;
	MysqlConnection *connection = [MysqlConnection connectToServer:server error:&error];

	XCTAssertNil(connection);
	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 1049, @"Expected unknown-database; got: %@", error);
}

- (void)testConnectToServersReturnsFirstReachableCandidate {
	[self requireServer];
	MysqlServer *dead = [[MysqlServer alloc] init];
	dead.host = @"127.0.0.1";
	dead.port = 1;

	MysqlConnection *connection = [MysqlConnection connectToServers:@[dead, [[self class] testServer]]];
	XCTAssertNotNil(connection);
	XCTAssertEqualObjects(connection.server.host, [[self class] testServer].host);
}

#pragma mark - Escaping

- (void)testEscapeStringQuotesSingleQuote {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
	// mysql_real_escape_string turns ' into \' (backslash + quote).
	XCTAssertEqualObjects([connection mysqlEscapeString:@"O'Brien"], @"O\\'Brien");
}

- (void)testEscapeStringDoublesBackslash {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
	// One backslash in, two backslashes out.
	XCTAssertEqualObjects([connection mysqlEscapeString:@"a\\b"], @"a\\\\b");
}

- (void)testEscapeStringReturnsNilForNilInput {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
	XCTAssertNil([connection mysqlEscapeString:nil]);
}

#pragma mark - Fetch: scalars and shapes

- (void)testFetchScalarSelect {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
	NSError *error = nil;
	MADDataTable *table = [self fetch:@"SELECT 255 AS `f1`;" onConnection:connection error:&error];

	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqual([table numberOfColumns], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @255);
}

- (void)testFetchKnownEmployeeRow {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MysqlFetch *fetch = [[MysqlFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees WHERE emp_no = 10001;"
				  dataTable:&table
			   onConnection:connection
			  extendedNames:YES
					  error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects([table columnKeys][0], @"`employees`.`emp_no`");
}

- (void)testFetchColumnKeysAreBareWithoutExtendedNames {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MysqlFetch *fetch = [[MysqlFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees WHERE emp_no = 10001;"
				  dataTable:&table
			   onConnection:connection
			  extendedNames:NO
					  error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects([table columnKeys][0], @"emp_no");
}

- (void)testFetchDateColumnYieldsDateComponents {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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
	MysqlFetch *fetch = [[MysqlFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT 1;" dataTable:&table onConnection:nil error:&error];

	XCTAssertNotNil(error);
	XCTAssertEqual(error.code, 3492);
	XCTAssertEqualObjects(error.localizedDescription, @"Connection is empty.");
}

#pragma mark - Fetch: table reuse

- (void)testFetchReusesAndClearsProvidedTable {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	MysqlFetch *fetch = [[MysqlFetch alloc] init];
	NSError *error = nil;

	[fetch fetchWithCommand:@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 50;"
				  dataTable:&table onConnection:connection error:&error];
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 50u);

	// Re-using the same table must not append; the fetch clears it first.
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 3;"
				  dataTable:&table onConnection:connection error:&error];
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 3u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @10001);
}

#pragma mark - Fetch: statements that return no result set

// Regression: mysql_stmt_bind_result used to be called unconditionally, and it fails
// with code 3534 when the statement reports field_count == 0. That aborted the call
// before mysql_stmt_execute, so DDL and DML were impossible through MysqlFetch. The
// table is created and dropped rather than TEMPORARY so the rows are visible to the
// SELECTs below across statement boundaries.
- (void)testStatementWithNoResultSetExecutes {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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
- (void)runStatement:(NSString *)sql onConnection:(MysqlConnection *)connection error:(NSError **)error {
	MADDataTable *scratch = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *statementError = nil;
	MysqlFetch *runner = [[MysqlFetch alloc] init];
	[runner fetchWithCommand:sql dataTable:&scratch onConnection:connection error:&statementError];
	if (error != NULL) { *error = statementError; }
}

// Drives one row through every conversion branch in -fetchResultsFromConnection: that
// the probe table can reach. TEMPORARY, so it disappears with the connection and the
// employees schema is untouched.
- (void)testFetchTypeConversionRoundTrip {
	[self requireServer];
	MysqlConnection *connection = [self openConnection];
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
	MysqlConnection *connection = [self openConnection];
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

@end
