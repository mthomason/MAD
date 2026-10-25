//
//  MADMySQLLiveTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MADMySQLLiveTests.m: integration tests for
//  MADMySQL that talk to a real MySQL server -- this is the only way to
//  exercise MADMySQLConnection, MADMySQLFetch and MADMySQLFetch+DataTable, which are
//  thin wrappers over libmysqlclient.
//
//  The server is the local development instance documented in DEVELOPER.md:
//
//      MySQL: 127.0.0.1, root, root, employees
//
//  Every credential can be overridden with an environment variable so the suite
//  can be pointed at another instance without editing code:
//
//      MAD_MYSQL_TEST_HOST, MAD_MYSQL_TEST_PORT, MAD_MYSQL_TEST_USER,
//      MAD_MYSQL_TEST_PASSWORD, MAD_MYSQL_TEST_SCHEMA
//
//  If the server cannot be reached the suite SKIPS rather than fails (MAD_SKIP),
//  so a machine without MySQL still gets a green run for the offline tests in
//  MADMySQLTests.m.  The Linux container has no MySQL server, so every
//  server-backed test below skips there; the tests marked offline run anywhere.
//
//  Note on the host: use 127.0.0.1, not "localhost". libmysqlclient interprets
//  "localhost" as a request for a Unix-domain socket, and on the test host the
//  server listens on TCP; 127.0.0.1 forces it.
//
//  The tests are read-only against the shipped employees dataset.  The ones
//  that have to write create and drop their own mad_scratch_* / mad_dml_* /
//  mad_type_probe / mad_meta_probe tables, dropping first so a re-run after an
//  aborted test is self-healing.
//

#import "MADTestSupport.h"

#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADMySQL/MADMySQLServer.h>
#import <MADMySQL/MADMySQLConnection.h>
#import <MADMySQL/MADMySQLFetch.h>
#import <MADMySQL/MADMySQLFetch+DataTable.h>
#import <MADMySQL/MADMySQLInsert.h>
#import <MADMySQL/MADMySQLUpdate.h>
#import <MADMySQL/MADMySQLDelete.h>
#import <MADMySQL/MADMySQLTruncate.h>
#import <MADMySQL/MADMySQLIndex.h>
#import <MADMySQL/MADMySQLException.h>
#import <MADMySQL/MADMySQLCommitException.h>
#import <MADMySQL/MADMySQLRollbackException.h>
#import <MADMySQL/NSString+MADMySQLEscape.h>

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADCredential.h>

#import <mysql.h>
#import <limits.h>

#pragma mark - Fixtures

static NSDictionary<NSString *, NSString *> *testSettings(void) {
	NSDictionary<NSString *, NSString *> *env = [[NSProcessInfo processInfo] environment];
	return @{
		@"host"     : env[@"MAD_MYSQL_TEST_HOST"]     ?: @"127.0.0.1",
		@"port"     : env[@"MAD_MYSQL_TEST_PORT"]     ?: @"3306",
		@"user"     : env[@"MAD_MYSQL_TEST_USER"]     ?: @"root",
		@"password" : env[@"MAD_MYSQL_TEST_PASSWORD"] ?: @"root",
		@"schema"   : env[@"MAD_MYSQL_TEST_SCHEMA"]   ?: @"employees",
	};
}

static MADMySQLServer *testServer(void) {
	NSDictionary<NSString *, NSString *> *settings = testSettings();
	MADMySQLServer *server = [[MADMySQLServer alloc] init];
	server.host     = settings[@"host"];
	server.user     = settings[@"user"];
	server.password = settings[@"password"];
	server.schema   = settings[@"schema"];
	NSString *port  = settings[@"port"];
	server.port     = port.length > 0 ? (unsigned int)port.integerValue : 3306u;
	return server;
}

// Every test needs a server. Establishing the connection once proves reachability and
// is cached, so the suite skips as a unit when there is no MySQL to talk to.
static BOOL serverIsAvailable(void) {
	static BOOL available = NO;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		NSError *error = nil;
		MADMySQLConnection *connection = [MADMySQLConnection connectToServer:testServer() error:&error];
		available = (connection != nil);
	});
	return available;
}

// Opens a connection the way the Xcode suite's -openConnection did.  Every test
// skips first, so a nil here means the server died mid-run and the assertions
// that follow fail rather than vanish.
static MADMySQLConnection *openConnection(void) {
	NSError *error = nil;
	MADMySQLServer *server = testServer();
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];
	MAD_PASS(connection != nil, "Expected to connect to the test server");
	MAD_PASS(error == nil, "a successful connection reports no error");
	return connection;
}

static MADDataTable *fetch(NSString *sql, MADMySQLConnection *connection, NSError **error) {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *fetchError = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:sql dataTable:table onConnection:connection error:&fetchError];
	if (error != NULL) { *error = fetchError; }
	return table;
}

// Runs a statement that returns no rows (DDL/DML) through the same
// prepared-statement path the fetches use, so the scratch tables below are
// built exactly the way the app would see it.
static void runStatement(NSString *sql, MADMySQLConnection *connection, NSError **error) {
	MADDataTable *scratch = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *statementError = nil;
	MADMySQLFetch *runner = [[MADMySQLFetch alloc] init];
	[runner fetchWithCommand:sql dataTable:scratch onConnection:connection error:&statementError];
	if (error != NULL) { *error = statementError; }
}

static void createScratchTable(NSString *name, MADMySQLConnection *connection) {
	NSError *error = nil;
	runStatement([[NSString alloc] initWithFormat:@"DROP TABLE IF EXISTS %@;", name],
				 connection, &error);
	MAD_PASS(error == nil, "the scratch table is dropped first");

	runStatement([[NSString alloc] initWithFormat:
				  @"CREATE TABLE %@ (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, "
				  "label VARCHAR(32) NOT NULL, note VARCHAR(32) NULL, payload BLOB NULL);", name],
				 connection, &error);
	MAD_PASS(error == nil, "the scratch table is created");
}

static void dropScratchTable(NSString *name, MADMySQLConnection *connection) {
	NSError *error = nil;
	runStatement([[NSString alloc] initWithFormat:@"DROP TABLE %@;", name],
				 connection, &error);
	MAD_PASS(error == nil, "the scratch table is dropped");
}

static NSObject *scalar(NSString *sql, MADMySQLConnection *connection) {
	NSError *error = nil;
	MADDataTable *table = fetch(sql, connection, &error);
	MAD_PASS(error == nil, "the scalar query succeeds");
	return [table objectAtRow:0 column:0];
}

static NSObject *countOfTable(NSString *name, MADMySQLConnection *connection) {
	return scalar([[NSString alloc] initWithFormat:@"SELECT COUNT(*) AS `n` FROM %@;", name],
				  connection);
}

#pragma mark - Connection

static void testConnectToLocalServerSucceeds(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	NSError *error = nil;
	MADMySQLServer *server = testServer();
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];

	MAD_PASS(connection != nil, "the connection succeeds");
	MAD_PASS(error == nil, "a successful connection reports no error");
	MAD_PASS_EQUAL(connection.server.host, server.host, "the connection keeps the host it was built with");
}

static void testConnectionDescriptionMentionsHostAndConnectedState(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSString *description = [connection description];
	MAD_PASS([description containsString:testServer().host], "the description names the host");
	MAD_PASS([description containsString:@"YES"], "the description reports the connected state");
}

static void testConnectWithWrongPasswordReportsAccessDenied(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLServer *server = testServer();
	server.password = @"definitely-not-the-password";

	NSError *error = nil;
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];

	MAD_PASS(connection == nil, "the connection is refused");
	MAD_PASS(error != nil, "the refusal is reported");
	MAD_PASS_EQUAL(error.domain, @"MADDatabaseMySQL", "the error is in the MySQL domain");
	MAD_PASS(error.code == 1045, "the code is MySQL access-denied");
	MAD_PASS_EQUAL(error.userInfo[@"MySQLErrorNumberKey"], @1045, "the userInfo carries the server code");
}

static void testConnectWithUnknownSchemaReportsUnknownDatabase(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLServer *server = testServer();
	server.schema = @"mad_no_such_schema";

	NSError *error = nil;
	MADMySQLConnection *connection = [MADMySQLConnection connectToServer:server error:&error];

	MAD_PASS(connection == nil, "the connection is refused");
	MAD_PASS(error != nil, "the refusal is reported");
	MAD_PASS(error.code == 1049, "the code is unknown-database");
}

static void testConnectToServersReturnsFirstReachableCandidate(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLServer *dead = [[MADMySQLServer alloc] init];
	dead.host = @"127.0.0.1";
	dead.port = 1;

	MADMySQLConnection *connection = [MADMySQLConnection connectToServers:@[dead, testServer()]];
	MAD_PASS(connection != nil, "a reachable candidate further down the list is used");
	MAD_PASS_EQUAL(connection.server.host, testServer().host, "the reachable candidate's host is kept");
}

#pragma mark - Escaping

static void testEscapeStringQuotesSingleQuote(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	// mysql_real_escape_string turns ' into \' (backslash + quote).
	MAD_PASS_EQUAL([connection mysqlEscapeString:@"O'Brien"], @"O\\'Brien",
				   "a quote is backslash-escaped");
}

static void testEscapeStringDoublesBackslash(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	// One backslash in, two backslashes out.
	MAD_PASS_EQUAL([connection mysqlEscapeString:@"a\\b"], @"a\\\\b",
				   "a backslash is doubled");
}

static void testEscapeStringReturnsNilForNilInput(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	MAD_PASS([connection mysqlEscapeString:nil] == nil, "a nil string escapes to nil");
}

#pragma mark - Literal quoting through a live session

// The driver escapes string literals through the session it opened for the query
// (-newSafeLiteral:), because a backslash is an escape character in a MySQL literal:
// ANSI ''-doubling alone turns C:\temp into C:<TAB>emp.  These tests connect the way a
// query does, ask the driver for the literal, and then have the server read it back --
// the round trip is the assertion, since only the server's reading proves the escape.

// Opens the driver's session the way -connectWithConnection:... does and hands
// back both the database and the socket under it.
static MADDatabaseMySQL *openDatabase(MADMySQLConnection **outSocket) {
	MADMySQLServer *server = testServer();
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
	MAD_PASS(socket != nil, "Expected to connect to the test server");
	if (outSocket != NULL) { *outSocket = socket; }
	return socket != nil ? database : nil;
}

static void testNewSafeLiteralEscapesABackslashThroughTheLiveSession(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *socket = nil;
	MADDatabaseMySQL *database = openDatabase(&socket);
	if (database == nil) return;

	// The value is C:\temp; the text handed to the server has the backslash doubled.
	NSString *value = @"C:\\temp";
	NSString *literal = [database newSafeLiteral: value];
	MAD_PASS_EQUAL(literal, @"'C:\\\\temp'", "the session doubled the backslash");

	NSError *error = nil;
	MADDataTable *table = fetch([[NSString alloc] initWithFormat:@"SELECT %@ AS `v`;", literal],
								socket, &error);
	MAD_PASS(error == nil, "the server accepted the literal");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], value, "the literal round-trips through the server");
}

static void testNewSafeLiteralEscapesAnApostropheThroughTheLiveSession(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *socket = nil;
	MADDatabaseMySQL *database = openDatabase(&socket);
	if (database == nil) return;

	NSString *value = @"O'Brien";
	NSString *literal = [database newSafeLiteral: value];
	MAD_PASS_EQUAL(literal, @"'O\\'Brien'", "the session escaped the apostrophe");

	NSError *error = nil;
	MADDataTable *table = fetch([[NSString alloc] initWithFormat:@"SELECT %@ AS `v`;", literal],
								socket, &error);
	MAD_PASS(error == nil, "the server accepted the literal");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], value, "the literal round-trips through the server");
}

static void testNewSafeLiteralReportsNullWithoutASession(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *socket = nil;
	MADDatabaseMySQL *database = openDatabase(&socket);
	if (database == nil) return;

	// NULL is spelled without quotes, so it does not need the session at all.
	MAD_PASS_EQUAL([database newSafeLiteral:nil], @"NULL", "nil literalises as NULL");
}

#pragma mark - Fetch: scalars and shapes

static void testFetchScalarSelect(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SELECT 255 AS `f1`;", connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS([table numberOfColumns] == 1u, "one column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @255, "the integer literal round trips");
}

static void testFetchKnownEmployeeRow(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SELECT emp_no, first_name, last_name, gender "
								@"FROM employees WHERE emp_no = 10001;", connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS([table numberOfColumns] == 4u, "four columns");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @10001, "the employee number");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @"Georgi", "the first name");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], @"Facello", "the last name");
	// gender is ENUM('M','F'); MySQL reports ENUM columns as strings on the wire.
	MAD_PASS_EQUAL([table objectAtRow:0 column:3], @"M", "the enum value");
}

static void testFetchRespectsLimitClause(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 25;",
								connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS([table numberOfRows] == 25u, "the cap is honoured");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @10001, "the first row");
	MAD_PASS_EQUAL([table objectAtRow:24 column:0], @10025, "the last row");
}

static void testFetchCountMatchesKnownTableSize(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SELECT COUNT(*) AS `total` FROM employees;", connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS([table numberOfRows] == 1u, "one row");
	// COUNT(*) is BIGINT -> MYSQL_TYPE_LONGLONG -> NSNumber.
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @300024, "the employees count");
}

static void testFetchShowTablesFindsEmployees(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SHOW TABLES;", connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	NSMutableArray<NSString *> *names = [NSMutableArray array];
	for (NSUInteger row = 0; row < [table numberOfRows]; row++) {
		id value = [table objectAtRow:row column:0];
		if ([value isKindOfClass:[NSString class]]) { [names addObject:value]; }
	}
	MAD_PASS([names containsObject:@"employees"], "SHOW TABLES lists employees");
}

#pragma mark - Fetch: column metadata

static void testFetchColumnMetadataForEmployees(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SELECT emp_no, first_name, birth_date FROM employees "
								@"WHERE emp_no = 10001;", connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS([table numberOfColumns] == 3u, "three columns");

	NSString *keyEmpNo = [table columnKeys][0];
	NSString *keyFirstName = [table columnKeys][1];
	NSString *keyBirthDate = [table columnKeys][2];

	MADDataColumn *empNo = table.columns[keyEmpNo];
	MAD_PASS(empNo.nativeType == (int16_t)MYSQL_TYPE_LONG, "emp_no is a native LONG");
	MAD_PASS(empNo.type == MADDataTypeLong, "emp_no is MADDataTypeLong");
	MAD_PASS_EQUAL(empNo.fieldName, keyEmpNo, "the column carries its key");

	MADDataColumn *firstName = table.columns[keyFirstName];
	MAD_PASS(firstName.nativeType == (int16_t)MYSQL_TYPE_VAR_STRING, "first_name is a native VAR_STRING");
	MAD_PASS(firstName.type == MADDataTypeVarChar, "first_name is MADDataTypeVarChar");

	MADDataColumn *birthDate = table.columns[keyBirthDate];
	MAD_PASS(birthDate.nativeType == (int16_t)MYSQL_TYPE_DATE, "birth_date is a native DATE");
	MAD_PASS(birthDate.type == MADDataTypeDate, "birth_date is MADDataTypeDate");
}

static void testFetchColumnKeysAreTableQualifiedWithExtendedNames(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees WHERE emp_no = 10001;"
				  dataTable:table
			   onConnection:connection
			  extendedNames:YES
					  error:&error];

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS_EQUAL([table columnKeys][0], @"`employees`.`emp_no`", "the key is table-qualified");
}

static void testFetchColumnKeysAreBareWithoutExtendedNames(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees WHERE emp_no = 10001;"
				  dataTable:table
			   onConnection:connection
			  extendedNames:NO
					  error:&error];

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS_EQUAL([table columnKeys][0], @"emp_no", "the key is bare");
}

static void testFetchDateColumnYieldsDateComponents(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SELECT birth_date FROM employees WHERE emp_no = 10001;",
								connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	id value = [table objectAtRow:0 column:0];
	// mysql_stmt_fetch returns DATE as MYSQL_TIME; the fetch code converts it to
	// NSDateComponents (unlike DATETIME/TIMESTAMP, which become NSDate).
	MAD_PASS([value isKindOfClass:[NSDateComponents class]], "the DATE came back as NSDateComponents");
	NSDateComponents *components = value;
	MAD_PASS(components.year == 1953, "the year");
	MAD_PASS(components.month == 9, "the month");
	MAD_PASS(components.day == 2, "the day");
}

#pragma mark - Fetch: error handling

static void testFetchReportsErrorForInvalidSQL(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	fetch(@"SELECT * FROM mad_no_such_table_xyz;", connection, &error);

	MAD_PASS(error != nil, "the failure is reported");
	MAD_PASS_EQUAL(error.domain, @"mad", "the error is in mad's domain");
	MAD_PASS(error.code == 1146, "the code is unknown-table");
}

// Needs no server: a nil connection is rejected before any I/O.
static void testFetchReportsErrorWhenConnectionIsNil(void) {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	[fetch fetchWithCommand:@"SELECT 1;" dataTable:table onConnection:nil error:&error];

	MAD_PASS(error != nil, "a nil connection is reported");
	MAD_PASS(error.code == 3492, "the code is the connection guard's");
	MAD_PASS_EQUAL(error.localizedDescription, @"Connection is empty.", "the message names the empty connection");
}

#pragma mark - Fetch: table reuse

static void testFetchReusesAndClearsProvidedTable(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	MADMySQLFetch *fetch = [[MADMySQLFetch alloc] init];
	NSError *error = nil;

	[fetch fetchWithCommand:@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 50;"
				  dataTable:table onConnection:connection error:&error];
	MAD_PASS(error == nil, "the first fetch reports no error");
	MAD_PASS([table numberOfRows] == 50u, "the first fetch's rows");

	// Re-using the same table must not append; the fetch clears it first.
	[fetch fetchWithCommand:@"SELECT emp_no FROM employees ORDER BY emp_no LIMIT 3;"
				  dataTable:table onConnection:connection error:&error];
	MAD_PASS(error == nil, "the second fetch reports no error");
	MAD_PASS([table numberOfRows] == 3u, "the table was cleared, not appended to");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @10001, "the first row of the second fetch");
}

#pragma mark - Fetch: statements that return no result set

// Regression: mysql_stmt_bind_result used to be called unconditionally, and it fails
// with code 3534 when the statement reports field_count == 0. That aborted the call
// before mysql_stmt_execute, so DDL and DML were impossible through MADMySQLFetch. The
// table is created and dropped rather than TEMPORARY so the rows are visible to the
// SELECTs below across statement boundaries.
static void testStatementWithNoResultSetExecutes(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;

	runStatement(@"DROP TABLE IF EXISTS mad_dml_probe;", connection, &error);
	MAD_PASS(error == nil, "DROP IF EXISTS is a no-op");

	runStatement(@"CREATE TABLE mad_dml_probe (id INT, label VARCHAR(16));", connection, &error);
	MAD_PASS(error == nil, "CREATE succeeds");

	runStatement(@"INSERT INTO mad_dml_probe VALUES (1, 'alpha'), (2, 'beta');", connection, &error);
	MAD_PASS(error == nil, "INSERT succeeds");

	MADDataTable *table = fetch(@"SELECT id, label FROM mad_dml_probe ORDER BY id;", connection, &error);
	MAD_PASS(error == nil, "SELECT succeeds");
	MAD_PASS([table numberOfRows] == 2u, "both rows are present");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @"alpha", "the first label");
	MAD_PASS_EQUAL([table objectAtRow:1 column:1], @"beta", "the second label");

	runStatement(@"UPDATE mad_dml_probe SET label = 'gamma' WHERE id = 2;", connection, &error);
	MAD_PASS(error == nil, "UPDATE succeeds");

	runStatement(@"DELETE FROM mad_dml_probe WHERE id = 1;", connection, &error);
	MAD_PASS(error == nil, "DELETE succeeds");

	table = fetch(@"SELECT id, label FROM mad_dml_probe;", connection, &error);
	MAD_PASS(error == nil, "the second SELECT succeeds");
	MAD_PASS([table numberOfRows] == 1u, "one row remains");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @2, "the surviving row id");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @"gamma", "the updated label");

	runStatement(@"DROP TABLE mad_dml_probe;", connection, &error);
	MAD_PASS(error == nil, "DROP succeeds");
}

// A no-result-set statement that the server rejects must report an error rather than
// fail silently, and must leave the connection usable.
static void testFailingStatementWithNoResultSetReportsError(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;

	runStatement(@"DROP TABLE IF EXISTS mad_dml_dup;", connection, &error);
	MAD_PASS(error == nil, "DROP IF EXISTS is a no-op");
	runStatement(@"CREATE TABLE mad_dml_dup (id INT PRIMARY KEY, label VARCHAR(8));", connection, &error);
	MAD_PASS(error == nil, "CREATE succeeds");
	runStatement(@"INSERT INTO mad_dml_dup VALUES (1, 'first');", connection, &error);
	MAD_PASS(error == nil, "the first INSERT succeeds");

	// Duplicate primary key: rejected at execute time, not at prepare time.
	error = nil;
	runStatement(@"INSERT INTO mad_dml_dup VALUES (1, 'second');", connection, &error);
	MAD_PASS(error != nil, "a duplicate key insert reports an error");
	MAD_PASS([error.localizedDescription containsString:@"MySQL says"], "the error is the server's");

	// The table is still usable afterwards; the failed statement left no residue.
	error = nil;
	MADDataTable *table = fetch(@"SELECT COUNT(*) AS `n` FROM mad_dml_dup;", connection, &error);
	MAD_PASS(error == nil, "the connection survives the failed statement");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @1, "the table still holds its one row");

	runStatement(@"DROP TABLE mad_dml_dup;", connection, &error);
}

// SELECT NULL literal: the server reports MYSQL_TYPE_NULL, which takes its own branch
// in both -bindDataForStatement:andField: and -fetchResultsFromConnection:.
static void testFetchLiteralNullYieldsNSNull(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;
	MADDataTable *table = fetch(@"SELECT NULL AS `n`;", connection, &error);

	MAD_PASS(error == nil, "the fetch reports no error");
	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], [NSNull null], "a NULL literal reads back as NSNull");
}

#pragma mark - Fetch: type conversion round-trip

// Drives one row through every conversion branch in -fetchResultsFromConnection: that
// the probe table can reach. TEMPORARY, so it disappears with the connection and the
// employees schema is untouched.
static void testFetchTypeConversionRoundTrip(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
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

	runStatement(create, connection, &error);
	MAD_PASS(error == nil, "CREATE succeeds");
	runStatement(insert, connection, &error);
	MAD_PASS(error == nil, "INSERT succeeds");

	MADDataTable *table = fetch(@"SELECT * FROM mad_type_probe;", connection, &error);
	MAD_PASS(error == nil, "SELECT succeeds");
	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS([table numberOfColumns] == 13u, "thirteen columns");

	// Integral widths.
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @7, "TINYINT");          // TINYINT
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @300, "SMALLINT");       // SMALLINT
	// MEDIUMINT used to fall through into the DOUBLE case, which re-read the 4-byte
	// int buffer as an 8-byte double: a heap over-read that also overwrote the correct
	// value with a garbage one. The missing break is fixed; this pins the value.
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], @400000, "MEDIUMINT");   // MEDIUMINT
	MAD_PASS_EQUAL([table objectAtRow:0 column:3], @70000, "INT");          // INT
	MAD_PASS_EQUAL([table objectAtRow:0 column:4], @4294967296, "BIGINT");  // BIGINT

	// DECIMAL arrives as NSDecimalNumber, not NSNumber.
	id decimal = [table objectAtRow:0 column:5];
	MAD_PASS([decimal isKindOfClass:[NSDecimalNumber class]], "DECIMAL is an NSDecimalNumber");
	MAD_PASS_EQUAL([decimal stringValue], @"1234.56", "the decimal value");

	MAD_PASS_EQUAL([table objectAtRow:0 column:6], @2.5, "DOUBLE");         // DOUBLE

	// Character types.
	MAD_PASS_EQUAL([table objectAtRow:0 column:7], @"abcd", "CHAR");        // CHAR
	MAD_PASS_EQUAL([table objectAtRow:0 column:8], @"hello", "VARCHAR");    // VARCHAR
	MAD_PASS_EQUAL([table objectAtRow:0 column:11], @"b", "ENUM");          // ENUM

	// DATE becomes NSDateComponents directly (see -fetchResultsFromConnection:).
	id date = [table objectAtRow:0 column:9];
	MAD_PASS([date isKindOfClass:[NSDateComponents class]], "DATE is an NSDateComponents");
	MAD_PASS(((NSDateComponents *)date).year == 2024, "the DATE year");
	MAD_PASS(((NSDateComponents *)date).month == 3, "the DATE month");
	MAD_PASS(((NSDateComponents *)date).day == 15, "the DATE day");

	// DATETIME is assembled into an NSDate via the current calendar.
	id datetime = [table objectAtRow:0 column:10];
	MAD_PASS([datetime isKindOfClass:[NSDate class]], "DATETIME is an NSDate");
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *parts = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
										  fromDate:datetime];
	MAD_PASS(parts.year == 2024, "the DATETIME year");
	MAD_PASS(parts.month == 3, "the DATETIME month");
	MAD_PASS(parts.day == 15, "the DATETIME day");

	// A NULL in a typed column must surface as NSNull, not as a missing value.
	MAD_PASS_EQUAL([table objectAtRow:0 column:12], [NSNull null], "a NULL column reads back as NSNull");
}

static void testFetchProbeTableColumnMetadata(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;

	runStatement(@"CREATE TEMPORARY TABLE mad_meta_probe ("
				  "c_big BIGINT, c_medium MEDIUMINT, c_decimal DECIMAL(10,2), "
				  "c_varchar VARCHAR(16), c_date DATE);", connection, &error);
	MAD_PASS(error == nil, "CREATE succeeds");

	MADDataTable *table = fetch(@"SELECT * FROM mad_meta_probe;", connection, &error);
	MAD_PASS(error == nil, "SELECT succeeds");
	MAD_PASS([table numberOfColumns] == 5u, "five columns");

	MADDataColumn *big = table.columns[[table columnKeys][0]];
	MAD_PASS(big.nativeType == (int16_t)MYSQL_TYPE_LONGLONG, "c_big is a native LONGLONG");
	MAD_PASS(big.type == MADDataTypeLongLong, "c_big is MADDataTypeLongLong");

	MADDataColumn *medium = table.columns[[table columnKeys][1]];
	MAD_PASS(medium.nativeType == (int16_t)MYSQL_TYPE_INT24, "c_medium is a native INT24");
	// MEDIUMINT maps onto its dedicated MADDataTypeInt24; see MADMySQLTests.m.
	MAD_PASS(medium.type == MADDataTypeInt24, "c_medium is MADDataTypeInt24");

	MADDataColumn *decimal = table.columns[[table columnKeys][2]];
	MAD_PASS(decimal.nativeType == (int16_t)MYSQL_TYPE_NEWDECIMAL, "c_decimal is a native NEWDECIMAL");
	MAD_PASS(decimal.type == MADDataTypeDecimal, "c_decimal is MADDataTypeDecimal");

	MADDataColumn *varchar = table.columns[[table columnKeys][3]];
	MAD_PASS(varchar.nativeType == (int16_t)MYSQL_TYPE_VAR_STRING, "c_varchar is a native VAR_STRING");
	MAD_PASS(varchar.type == MADDataTypeVarChar, "c_varchar is MADDataTypeVarChar");

	MADDataColumn *date = table.columns[[table columnKeys][4]];
	MAD_PASS(date.nativeType == (int16_t)MYSQL_TYPE_DATE, "c_date is a native DATE");
	MAD_PASS(date.type == MADDataTypeDate, "c_date is MADDataTypeDate");
}

#pragma mark - DML: scratch tables

// The write-side classes (MADMySQLInsert, MADMySQLUpdate, MADMySQLDelete,
// MADMySQLTruncate) are the app's DML path and can only be exercised against a
// server.  Every test here works on a scratch table that is created and
// dropped inside the test, so the employees dataset is never written to.

#pragma mark - MADMySQLInsert

static void testInsertWritesARowAndReportsTheNewId(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_insert", connection);

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_insert";
	insert.rowData = @{@"label": @"alpha"};
	[insert execute];

	MAD_PASS_EQUAL(insert.affectedRows, @1, "one row is affected");
	MAD_PASS_EQUAL(insert.rowid, @1, "AUTO_INCREMENT starts at 1");
	MAD_PASS_EQUAL(scalar(@"SELECT label FROM mad_scratch_insert;", connection), @"alpha",
				   "the inserted label");

	dropScratchTable(@"mad_scratch_insert", connection);
}

static void testInsertBindsNullsAndBlobs(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_blob", connection);

	NSData *payload = [NSData dataWithBytes:"\x01\x02\x03" length:3];
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_blob";
	insert.rowData = @{@"label": @"blob", @"note": [NSNull null], @"payload": payload};
	[insert execute];

	MAD_PASS_EQUAL(scalar(@"SELECT note IS NULL FROM mad_scratch_blob;", connection), @1,
				   "the NSNull bound as NULL");
	MAD_PASS_EQUAL(scalar(@"SELECT LENGTH(payload) FROM mad_scratch_blob;", connection), @3,
				   "the blob length");
	MAD_PASS_EQUAL(scalar(@"SELECT HEX(payload) FROM mad_scratch_blob;", connection), @"010203",
				   "the blob bytes");

	dropScratchTable(@"mad_scratch_blob", connection);
}

static void testInsertRejectsADuplicateKeyUnlessToldToIgnoreIt(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_dupe", connection);

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_dupe";
	insert.rowData = @{@"id": @1, @"label": @"first"};
	[insert execute];

	// The second insert collides on the primary key and raises.
	insert.rowData = @{@"id": @1, @"label": @"second"};
	MAD_THROWS_NAMED([insert execute], @"MADMySQLException", "a duplicate key raises");

	// With the flag set the same collision is swallowed and the row stands.
	insert.ignoreDuplicateErrors = YES;
	MAD_NO_THROW([insert execute], "the ignore flag swallows the collision");
	// BUGS.md: the ignored statement still failed, and -affectedRows is read
	// straight off mysql_affected_rows, which answers (my_ulonglong)-1 for a
	// failed statement -- so the count is ULONG_MAX rather than 0.
	MAD_PASS(insert.affectedRows.unsignedLongLongValue == ULLONG_MAX,
			 "a swallowed failure reports ULONG_MAX, not zero");
	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_dupe", connection), @1, "the first row stands");
	MAD_PASS_EQUAL(scalar(@"SELECT label FROM mad_scratch_dupe;", connection), @"first",
				   "and it is the first insert");

	dropScratchTable(@"mad_scratch_dupe", connection);
}

#pragma mark - MADMySQLUpdate

static void testUpdateChangesOnlyTheQualifiedRows(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_update", connection);

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

	MAD_PASS_EQUAL(update.affectedRows, @1, "one row is affected");
	MAD_PASS_EQUAL(scalar(@"SELECT label FROM mad_scratch_update WHERE id = 1;", connection), @"beta",
				   "the qualified row is updated");
	MAD_PASS_EQUAL(scalar(@"SELECT label FROM mad_scratch_update WHERE id = 2;", connection), @"alpha",
				   "the other row is untouched");

	dropScratchTable(@"mad_scratch_update", connection);
}

static void testUpdateQualifierHandlesStringsAndNulls(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_qual", connection);

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
	MAD_PASS_EQUAL(update.affectedRows, @1, "the string qualifier matches");

	update.rowData = @{@"note": [NSNull null]};
	update.qualifier = @{@"note": @"quoted"};
	[update execute];
	MAD_PASS_EQUAL(update.affectedRows, @1, "the second update matches");
	MAD_PASS_EQUAL(scalar(@"SELECT note IS NULL FROM mad_scratch_qual;", connection), @1,
				   "the null was written");

	dropScratchTable(@"mad_scratch_qual", connection);
}

static void testUpdateWithoutAQualifierRaisesTheUpdatesOwnError(void) {
	// BUGS.md: a nil qualifier left the WHERE-clause buffer empty, and -execute
	// deleted four characters off the front of it instead of telling the caller
	// to qualify the update.  The guard runs before any session call, so the
	// offline suite covers it too; this keeps the live connection in the loop.
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_noqual", connection);

	MADMySQLUpdate *update = [MADMySQLUpdate updateWithConnection:connection];
	update.table = @"mad_scratch_noqual";
	update.rowData = @{@"label": @"beta"};

	BOOL raised = NO;
	@try {
		[update execute];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason, @"a qualifier must be specified to perform an update",
					   "the reason names the missing qualifier");
		MAD_PASS(exception.userInfo == nil, "the guard carries no connection");
	}
	MAD_PASS(raised, "an unqualified update raises the update's own error");

	dropScratchTable(@"mad_scratch_noqual", connection);
}

#pragma mark - MADMySQLDelete

static void testDeleteRemovesTheQualifiedRows(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_delete", connection);

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_delete";
	for (NSString *label in @[@"alpha", @"beta", @"alpha"]) {
		insert.rowData = @{@"label": label};
		[insert execute];
	}
	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_delete", connection), @3, "three rows are inserted");

	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:connection];
	delete.tableName = @"mad_scratch_delete";
	delete.qualifier = @"label='alpha'";
	[delete execute];

	MAD_PASS_EQUAL(delete.affectedRows, @2, "two rows are deleted");
	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_delete", connection), @1, "one row remains");
	MAD_PASS_EQUAL(scalar(@"SELECT label FROM mad_scratch_delete;", connection), @"beta",
				   "the survivor is beta");

	dropScratchTable(@"mad_scratch_delete", connection);
}

static void testDeleteWithARubbishQualifierRaises(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_badqual", connection);

	MADMySQLDelete *delete = [MADMySQLDelete deleteWithConnection:connection];
	delete.tableName = @"mad_scratch_badqual";
	delete.qualifier = @"no_such_column = 1";

	MAD_THROWS_NAMED([delete execute], @"MADMySQLException", "a bad qualifier raises");

	dropScratchTable(@"mad_scratch_badqual", connection);
}

#pragma mark - MADMySQLTruncate

static void testTruncateEmptiesATable(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_truncate", connection);

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_truncate";
	insert.rowData = @{@"label": @"alpha"};
	[insert execute];
	insert.rowData = @{@"label": @"beta"};
	[insert execute];
	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_truncate", connection), @2, "two rows are inserted");

	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connection
														   forTable:@"mad_scratch_truncate"];
	MAD_NO_THROW([truncate execute], "the truncate does not throw");

	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_truncate", connection), @0, "the table is empty");

	dropScratchTable(@"mad_scratch_truncate", connection);
}

#pragma mark - MADMySQLIndex

static void testIndexFactoryKeepsALiveConnection(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();

	MAD_PASS([MADMySQLIndex indexWithConnection:connection].connection == connection,
			 "the index holds the live connection");
}

#pragma mark - Transactions

static void testRollbackDiscardsAndCommitKeeps(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	createScratchTable(@"mad_scratch_tx", connection);

	MAD_PASS(!connection.transactionsEnabled, "transactions start disabled");
	[connection enableTransactions];
	MAD_PASS(connection.transactionsEnabled, "transactions are enabled");

	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.table = @"mad_scratch_tx";
	insert.rowData = @{@"label": @"rolled-back"};
	[insert execute];
	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_tx", connection), @1,
				   "the row is visible inside its own transaction");

	[connection rollbackTransaction];
	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_tx", connection), @0, "the rollback discards it");

	insert.rowData = @{@"label": @"kept"};
	[insert execute];
	[connection commitTransaction];
	MAD_PASS_EQUAL(countOfTable(@"mad_scratch_tx", connection), @1, "the commit keeps it");

	[connection disableTransactions];
	MAD_PASS(!connection.transactionsEnabled, "transactions are disabled again");

	dropScratchTable(@"mad_scratch_tx", connection);
}

#pragma mark - Session settings and error reporting

static void testEnableStrictSqlTurnsOnTheMode(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();

	MAD_NO_THROW([connection enableStrictSql], "the strict mode is set without throwing");

	NSString *mode = (NSString *)scalar(@"SELECT @@sql_mode AS `m`;", connection);
	MAD_PASS([[mode uppercaseString] containsString:@"STRICT_ALL_TABLES"], "sql_mode carries STRICT_ALL_TABLES");
}

static void testTriggerTogglesSetAndClearTheSessionFlag(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();

	MAD_NO_THROW([connection disableTriggers], "triggers are disabled without throwing");
	MAD_PASS_EQUAL(scalar(@"SELECT @DISABLE_TRIGGERS AS `v`;", connection), @1,
				   "the session flag is set");

	MAD_NO_THROW([connection enableTriggers], "triggers are enabled without throwing");
	MAD_PASS_EQUAL(scalar(@"SELECT @DISABLE_TRIGGERS AS `v`;", connection), [NSNull null],
				   "the session flag is cleared");
}

static void testErrorNumberAndErrorTextReportTheLastFailure(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();
	NSError *error = nil;

	fetch(@"SELECT * FROM mad_no_such_table;", connection, &error);
	MAD_PASS(error != nil, "the failing statement is reported");

	MAD_PASS([connection errorNumber] != 0u, "the connection remembers the error number");
	const char *text = [connection errorText];
	MAD_PASS(text != NULL, "the error text is a C string");
	MAD_PASS([[NSString stringWithUTF8String:text] containsString:@"mad_no_such_table"],
			 "the error text names the missing table");
}

static void testErrorWithConnectionDescribesTheServerState(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();

	NSError *error = [MADMySQLException errorWithConnection:connection domain:@"MADMySQLTests" andCode:7];

	MAD_PASS_EQUAL(error.domain, @"MADMySQLTests", "the caller's domain is kept");
	MAD_PASS(error.code == 7, "the caller's code is kept");
	MAD_PASS_EQUAL(error.userInfo[NSLocalizedFailureReasonErrorKey], @"Executing Error",
				   "the failure reason is fixed");
	MAD_PASS([error.localizedDescription hasPrefix:@"MySQL says"], "the description quotes the server");
}

#pragma mark - Escaping through the connection

static void testEscapeInConnectionMatchesTheConnectionHelper(void) {
	MAD_SKIP(!serverIsAvailable(), @"No MySQL server reachable; see DEVELOPER.md for the expected test instance.");
	MADMySQLConnection *connection = openConnection();

	// The NSString category and the connection's own helper are two entry
	// points to mysql_real_escape_string; they must agree.
	MAD_PASS_EQUAL([@"O'Brien" mysqlEscapeInConnection:connection],
				   [connection mysqlEscapeString:@"O'Brien"],
				   "the category and the helper agree");
}

MAD_TEST_MAIN("MADMySQLLiveTests",
	MAD_TEST(testConnectToLocalServerSucceeds),
	MAD_TEST(testConnectionDescriptionMentionsHostAndConnectedState),
	MAD_TEST(testConnectWithWrongPasswordReportsAccessDenied),
	MAD_TEST(testConnectWithUnknownSchemaReportsUnknownDatabase),
	MAD_TEST(testConnectToServersReturnsFirstReachableCandidate),
	MAD_TEST(testEscapeStringQuotesSingleQuote),
	MAD_TEST(testEscapeStringDoublesBackslash),
	MAD_TEST(testEscapeStringReturnsNilForNilInput),
	MAD_TEST(testNewSafeLiteralEscapesABackslashThroughTheLiveSession),
	MAD_TEST(testNewSafeLiteralEscapesAnApostropheThroughTheLiveSession),
	MAD_TEST(testNewSafeLiteralReportsNullWithoutASession),
	MAD_TEST(testFetchScalarSelect),
	MAD_TEST(testFetchKnownEmployeeRow),
	MAD_TEST(testFetchRespectsLimitClause),
	MAD_TEST(testFetchCountMatchesKnownTableSize),
	MAD_TEST(testFetchShowTablesFindsEmployees),
	MAD_TEST(testFetchColumnMetadataForEmployees),
	MAD_TEST(testFetchColumnKeysAreTableQualifiedWithExtendedNames),
	MAD_TEST(testFetchColumnKeysAreBareWithoutExtendedNames),
	MAD_TEST(testFetchDateColumnYieldsDateComponents),
	MAD_TEST(testFetchReportsErrorForInvalidSQL),
	MAD_TEST(testFetchReportsErrorWhenConnectionIsNil),
	MAD_TEST(testFetchReusesAndClearsProvidedTable),
	MAD_TEST(testStatementWithNoResultSetExecutes),
	MAD_TEST(testFailingStatementWithNoResultSetReportsError),
	MAD_TEST(testFetchLiteralNullYieldsNSNull),
	MAD_TEST(testFetchTypeConversionRoundTrip),
	MAD_TEST(testFetchProbeTableColumnMetadata),
	MAD_TEST(testInsertWritesARowAndReportsTheNewId),
	MAD_TEST(testInsertBindsNullsAndBlobs),
	MAD_TEST(testInsertRejectsADuplicateKeyUnlessToldToIgnoreIt),
	MAD_TEST(testUpdateChangesOnlyTheQualifiedRows),
	MAD_TEST(testUpdateQualifierHandlesStringsAndNulls),
	MAD_TEST(testUpdateWithoutAQualifierRaisesTheUpdatesOwnError),
	MAD_TEST(testDeleteRemovesTheQualifiedRows),
	MAD_TEST(testDeleteWithARubbishQualifierRaises),
	MAD_TEST(testTruncateEmptiesATable),
	MAD_TEST(testIndexFactoryKeepsALiveConnection),
	MAD_TEST(testRollbackDiscardsAndCommitKeeps),
	MAD_TEST(testEnableStrictSqlTurnsOnTheMode),
	MAD_TEST(testTriggerTogglesSetAndClearTheSessionFlag),
	MAD_TEST(testErrorNumberAndErrorTextReportTheLastFailure),
	MAD_TEST(testErrorWithConnectionDescribesTheServerState),
	MAD_TEST(testEscapeInConnectionMatchesTheConnectionHelper));
