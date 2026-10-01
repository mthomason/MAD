//
//  MADTdsClientLiveTests.m
//  MADTdsClientTests
//
//  Created by Michael Thomason on 9/30/26.
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Integration tests for MADTdsClient that talk to a real SQL Server -- this is the
//  only way to exercise the freetds calls behind -connect:andPassword:error:,
//  -getTablesFromConnection:error:, -fieldsForTable:connection:error: and
//  -runSQL:onDataTable:fieldKeys:process:.
//
//  The server is the local Docker instance documented in DEVELOPER.md:
//
//      SQL Server 2022 Developer Edition, 127.0.0.1, sa, Root1@Root2,
//      AdventureWorksLT2022
//
//  Every credential can be overridden with an environment variable so the suite can
//  be pointed at another instance without editing code:
//
//      MAD_TDS_TEST_HOST, MAD_TDS_TEST_USER, MAD_TDS_TEST_PASSWORD,
//      MAD_TDS_TEST_DATABASE
//
//  If the server cannot be reached the suite SKIPS rather than fails, so a machine
//  without SQL Server still gets a green run for the offline tests in
//  MADTdsClientTests.m.
//
//  The tests are read-only against the shipped AdventureWorksLT2022 tables. The one
//  test that has to write creates and drops its own table, dbo.mad_tds_dml_probe, and
//  drops it first so a re-run after an aborted test is self-healing.
//
//  Note on the port: this freetds build has no DBSETLPORT, so
//  -connect:andPassword:error: passes the port in the server string it hands to
//  dbopen() -- "host:port" -- which freetds parses. The tests below use 1433.
//
//  Note on connections: -runSQL:onDataTable:fieldKeys:process: closes the DBPROCESS it
//  is handed, so a statement cannot be run twice on one connection. Every query in
//  this file therefore opens its own, via -query: / -execute:. See
//  -testEachStatementNeedsItsOwnConnection.
//

#import <XCTest/XCTest.h>

#import <MADTdsClient/MADTdsClient.h>
#import <MADTds/sybdb.h>

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADCredential.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>

// Declared in MADDatabaseSQLServer.m but not in any published header. Declaring them
// here reaches the live paths without widening the framework's public API.
@interface MADDatabaseSQLServer (MADTdsClientLiveTestsInternal)
- (void *)connect:(NSString *)username andPassword:(NSString *)password error:(NSError **)error;
- (id)connectWithConnection:(MADDatabaseConnection *)connection
				 credentals:(MADCredential *)credentals
			connectionError:(NSError **)error;
- (void)closeConnection:(id)process;
- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)process
													error:(NSError **)outError;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
									 connection:(id)process
										  error:(NSError **)error;
- (BOOL)runSQL:(NSString *)sql
   onDataTable:(MADDataTable *)datatable
	 fieldKeys:(NSArray *)fieldKeys
	   process:(id)process;
- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion;
@end

// -getTables: calls -connectWithConnection:credentals:connectionError: with a nil
// credential, which makes the base class ask its delegate for the credentials of that
// connection string. Without a delegate nothing is vended, the connection is never
// opened and the block reports "No Connection" -- so the stub below is what the app's
// own controller supplies.
@interface MADTdsCredentialStub : NSObject <MADDatabaseResultsProtocol>
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end

@implementation MADTdsCredentialStub
- (MADCredential *)getCredentialsForKey:(NSString *)key {
	return [[MADCredential alloc] initWithUsername:self.username andPassword:self.password];
}
@end

@interface MADTdsClientLiveTests : XCTestCase

@end

@implementation MADTdsClientLiveTests {
	MADDatabaseSQLServer *_database;
	id _process;
}

#pragma mark - Fixtures

+ (NSDictionary<NSString *, NSString *> *)testSettings {
	NSDictionary<NSString *, NSString *> *env = [[NSProcessInfo processInfo] environment];
	return @{
		@"host"     : env[@"MAD_TDS_TEST_HOST"]     ?: @"127.0.0.1",
		@"user"     : env[@"MAD_TDS_TEST_USER"]     ?: @"sa",
		@"password" : env[@"MAD_TDS_TEST_PASSWORD"] ?: @"Root1@Root2",
		@"database" : env[@"MAD_TDS_TEST_DATABASE"] ?: @"AdventureWorksLT2022",
	};
}

+ (MADDatabaseConnectionSQLServer *)testConnection {
	NSDictionary<NSString *, NSString *> *settings = [self testSettings];
	NSString *host = settings[@"host"];
	return [[MADDatabaseConnectionSQLServer alloc] initWithHost:host
														 server:host
													   database:settings[@"database"]
														andPort:1433];
}

// Every test needs a server. Establishing the connection once proves reachability and
// is cached, so the suite skips as a unit when there is no SQL Server to talk to.
+ (BOOL)serverIsAvailable {
	static BOOL available = NO;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
		db.databaseConnection = [self testConnection];
		NSDictionary<NSString *, NSString *> *settings = [self testSettings];
		NSError *error = nil;
		DBPROCESS *dbconn = [db connect:settings[@"user"]
							andPassword:settings[@"password"]
								  error:&error];
		available = (dbconn != NULL && error == nil);
		if (dbconn != NULL) { dbclose(dbconn); }
	});
	return available;
}

- (void)requireServer {
	XCTSkipIf(![[self class] serverIsAvailable],
			  @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
}

- (id)openProcess {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MADDatabaseConnectionSQLServer *connection = [[self class] testConnection];
	db.databaseConnection = connection;

	NSDictionary<NSString *, NSString *> *settings = [[self class] testSettings];
	MADCredential *credential = [[MADCredential alloc] initWithUsername:settings[@"user"]
															andPassword:settings[@"password"]];

	// The error is deliberately not asked for: -connectWithConnection:... rebinds its
	// own error parameter to a local instead of writing through to the caller's, so a
	// nil return is the only signal it gives. Passing NULL also sidesteps the unguarded
	// *error dereferences in -connect:andPassword:error:.
	//
	// The DBPROCESS is boxed the way -connectWithConnection:... boxes it, because the
	// methods under test send -process to this argument rather than reading it as a
	// bare pointer.
	id process = [db connectWithConnection:connection
								credentals:credential
						  connectionError:NULL];
	XCTAssertNotNil(process, @"Expected to connect to %@", settings[@"host"]);

	_database = db;
	_process = process;
	return process;
}

- (void)tearDown {
	// Only the schema-reading tests still hold an open connection by this point; the
	// ones that ran a statement have had it closed underneath them by -runSQL:, so
	// closing it again would be a double free.
	if (_process != nil) {
		[_database closeConnection:_process];
	}
	_process = nil;
	_database = nil;
	[super tearDown];
}

// Runs one statement on a connection of its own and reports whether it succeeded.
- (BOOL)execute:(NSString *)sql {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	return [self execute:sql into:table];
}

- (BOOL)execute:(NSString *)sql into:(MADDataTable *)table {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MADDatabaseConnectionSQLServer *connection = [[self class] testConnection];
	db.databaseConnection = connection;

	NSDictionary<NSString *, NSString *> *settings = [[self class] testSettings];
	MADCredential *credential = [[MADCredential alloc] initWithUsername:settings[@"user"]
															andPassword:settings[@"password"]];
	id process = [db connectWithConnection:connection
								credentals:credential
						  connectionError:NULL];
	XCTAssertNotNil(process, @"Expected to connect to %@", settings[@"host"]);
	return [db runSQL:sql onDataTable:table fieldKeys:nil process:process];
}

// Runs one statement on a connection of its own and returns the rows it produced.
- (MADDataTable *)query:(NSString *)sql {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	[self execute:sql into:table];
	return table;
}

#pragma mark - Connection

- (void)testConnectToLocalServerSucceeds {
	[self requireServer];
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	db.databaseConnection = [[self class] testConnection];
	NSDictionary<NSString *, NSString *> *settings = [[self class] testSettings];

	NSError *error = nil;
	DBPROCESS *dbconn = [db connect:settings[@"user"]
						andPassword:settings[@"password"]
							  error:&error];

	XCTAssertTrue(dbconn != NULL, @"Expected a connection, got error: %@", error);
	XCTAssertNil(error);
	dbclose(dbconn);
}

// The database named in the connection is sent as the login's default catalog, so a
// query can name an unqualified table from it. If DBSETLDBNAME were dropped the login
// would land in master and this would fail.
- (void)testConnectedSessionUsesTheRequestedDatabase {
	[self requireServer];
	MADDataTable *table = [self query:@"SELECT DB_NAME() AS db"];

	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], [[self class] testSettings][@"database"]);
}

#pragma mark - Connection lifetime

// -runSQL:onDataTable:fieldKeys:process: calls dbclose() on the DBPROCESS it is given
// before returning, on every path. The DBPROCESS was opened by the caller --
// -executeQuery:... and -getTables: both connect and then hand the process to a callee
// -- so this frees memory the caller still considers live and leaves
// MADDatabaseProcessSQLServer holding a dangling pointer.
//
// The direct consequence is that a caller must not close the connection it opened, and
// that nothing may be run on it afterwards. Both abort the process inside freetds; the
// first was confirmed from a crash report:
//
//     dbstring_free -> dbclose -> -[MADDatabaseSQLServer closeConnection:]
//
// Neither is something a test can assert on, so what is pinned here is the pattern that
// does work, because it is the only one that does: one statement per connection.
//
// Contrast -getTablesFromConnection:error: and -fieldsForTable:connection:error:,
// which leave the connection open -- their dbclose calls are commented out.
- (void)testEachStatementNeedsItsOwnConnection {
	[self requireServer];
	XCTAssertEqualObjects([[self query:@"SELECT 1 AS a"] objectAtRow:0 column:0], @1);
	XCTAssertEqualObjects([[self query:@"SELECT 2 AS a"] objectAtRow:0 column:0], @2);
}

#pragma mark - Scalar round trips

- (void)testSelectIntegerLiteral {
	[self requireServer];
	MADDataTable *table = [self query:@"SELECT 255 AS f1"];

	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqual([table numberOfColumns], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @255);
}

- (void)testSelectStringLiteral {
	[self requireServer];
	MADDataTable *table = [self query:@"SELECT 'hello' AS greeting"];

	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"hello");
}

// A literal NULL has no declared type at all, so it takes a different path from a
// typed column that happens to hold NULL -- see -testSelectNullColumnValueYieldsNSNull.
- (void)testSelectNullLiteralYieldsNSNull {
	[self requireServer];
	MADDataTable *table = [self query:@"SELECT NULL AS n"];

	XCTAssertEqual([table numberOfColumns], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], [NSNull null]);
}

- (void)testSelectMultipleColumns {
	[self requireServer];
	// The float literal is cast explicitly: a bare "3.5" is DECIMAL(2,1) in T-SQL, not
	// FLOAT, and would take the decimal path exercised further down.
	MADDataTable *table = [self query:
		@"SELECT 1 AS a, 'two' AS b, CAST(3.5 AS FLOAT) AS c"];

	XCTAssertEqual([table numberOfColumns], 3u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @1);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @"two");
	XCTAssertEqualObjects([table objectAtRow:0 column:2], @3.5);
}

- (void)testSelectMultipleRows {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT n FROM (VALUES (1),(2),(3),(4),(5)) AS v(n) ORDER BY n"];

	XCTAssertEqual([table numberOfRows], 5u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @1);
	XCTAssertEqualObjects([table objectAtRow:4 column:0], @5);
}

- (void)testSelectNegativeNumbers {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT -1 AS i, CAST(-2.5 AS FLOAT) AS f, -300 AS s"];

	XCTAssertEqualObjects([table objectAtRow:0 column:0], @-1);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @-2.5);
	XCTAssertEqualObjects([table objectAtRow:0 column:2], @-300);
}

// SQL Server pads a CHAR column out to its declared width -- it reports DATALENGTH 5
// and LEN 2 for this expression -- but the trailing blanks do not reach the data table,
// because the column is bound as a NUL-terminated string. Pinned as the behaviour a
// report actually sees.
- (void)testSelectCharTrailingBlanksAreNotPreserved {
	[self requireServer];
	MADDataTable *table = [self query:@"SELECT CAST('ab' AS CHAR(5)) AS c"];

	XCTAssertEqualObjects([table objectAtRow:0 column:0], @"ab");
}

#pragma mark - DECIMAL / NUMERIC conversion

// DECIMAL and NUMERIC values survive the round trip with their sign and scale intact.
//
// The SYBNUMERIC case in -runSQL: used to derive a "separator" by trimming decimal
// digits off both ends of the value string -- which for "3.5" leaves ".", for "-2.5"
// leaves "-2." and for "1.00" leaves "." -- and then assigned the working copy of the
// string only when that bogus separator differed from the locale separator. Whenever no
// replacement was wanted the working copy stayed nil, and -initWithString: on nil
// yields notANumber, so the value was simply lost. The negative case was worse: the
// derived separator "-2." occurs inside the string being rewritten, so "-2.5" became
// ".5" and was reported as 0.5 -- a plausible number that was silently wrong.
- (void)testSelectDecimalReturnedValues {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT CAST(3.5 AS DECIMAL(2,1)) AS pos, CAST(1 AS DECIMAL(10,2)) AS whole, "
		 "CAST(123.456 AS DECIMAL(10,3)) AS frac"];

	XCTAssertEqual([table numberOfColumns], 3u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], [NSDecimalNumber decimalNumberWithString:@"3.5"]);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], [NSDecimalNumber decimalNumberWithString:@"1.00"]);
	XCTAssertEqualObjects([table objectAtRow:0 column:2], [NSDecimalNumber decimalNumberWithString:@"123.456"]);
}

// The sign-bearing case the old separator search corrupted.
- (void)testSelectNegativeDecimalKeepsItsSign {
	[self requireServer];
	MADDataTable *table = [self query:@"SELECT CAST(-2.5 AS DECIMAL(4,1)) AS neg"];

	XCTAssertEqualObjects([table objectAtRow:0 column:0], [NSDecimalNumber decimalNumberWithString:@"-2.5"]);
}

#pragma mark - Column metadata

// The column type reported by the server is normalised before it reaches
// +dataTypeForNativeType:. SYBDECIMAL is rewritten to SYBNUMERIC and SYBMONEY4 to
// SYBMONEY, which is why those two -- unmapped in the method itself, see the offline
// suite -- still classify correctly when a real query is run.
- (void)testSelectColumnMetadataForScalars {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT CAST(1 AS INT) AS i, CAST('x' AS VARCHAR(4)) AS v, "
		 "CAST(1.25 AS FLOAT) AS f, CAST(123.45 AS DECIMAL(10,2)) AS d, "
		 "CAST(12.34 AS MONEY) AS m"];

	NSArray<NSString *> *keys = [table columnKeys];
	XCTAssertEqual(keys.count, 5u);

	XCTAssertEqual(table.columns[keys[0]].type, MADDataTypeInteger);
	XCTAssertEqual(table.columns[keys[1]].type, MADDataTypeString);
	XCTAssertEqual(table.columns[keys[2]].type, MADDataTypeFloat);
	// DECIMAL arrives as SYBDECIMAL, is rewritten to SYBNUMERIC, and so maps to Decimal.
	XCTAssertEqual(table.columns[keys[3]].type, MADDataTypeDecimal);
	// MONEY arrives as SYBMONEY, which is mapped directly. SMALLMONEY is the one that
	// arrives as SYBMONEY4 and needs the rewrite; see the test below.
	XCTAssertEqual(table.columns[keys[4]].type, MADDataTypeFloat);
}

- (void)testSelectSmallMoneyIsRewrittenToMoney {
	[self requireServer];
	MADDataTable *table = [self query:@"SELECT CAST(12.34 AS SMALLMONEY) AS sm"];

	NSString *key = [table columnKeys][0];
	// SYBMONEY4 would map to MADDataTypeString if it were not rewritten first.
	XCTAssertEqual(table.columns[key].type, MADDataTypeFloat);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @12.34);
}

// The post-2005 date/time types now map to the date/time cases of MADDataType instead
// of falling through to the String default.
//
// Only the column *type* is covered here. These type codes still have no bind array in
// -runSQL: -- neither dbbind nor dbnullbind is called for them -- so the row conversion
// hits its default branch and every value comes back [NSNull null]. Fetching the values
// is a separate piece of work; this test pins the typing half.
- (void)testSelectModernDateTimeTypes {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT CAST('2020-01-15' AS DATE) AS d, "
		 "CAST('13:45:00' AS TIME) AS t, "
		 "CAST('2020-01-15T13:45:00' AS DATETIME2) AS dt2, "
		 "CAST('2020-01-15T13:45:00+00:00' AS DATETIMEOFFSET) AS dto"];

	NSArray<NSString *> *keys = [table columnKeys];
	XCTAssertEqual(keys.count, 4u);
	XCTAssertEqual(table.columns[keys[0]].type, MADDataTypeDate);
	XCTAssertEqual(table.columns[keys[1]].type, MADDataTypeTime);
	XCTAssertEqual(table.columns[keys[2]].type, MADDataTypeDateTime);
	XCTAssertEqual(table.columns[keys[3]].type, MADDataTypeDateTime);
}

#pragma mark - Type conversion round trip

// One query that exercises every type code the framework binds. Values are chosen so
// each conversion is distinguishable from the others.
- (void)testTypeConversionRoundTrip {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT CAST(1 AS BIT) AS b, CAST(300 AS SMALLINT) AS s, "
		 "CAST(70000 AS INT) AS i, CAST(5000000000 AS BIGINT) AS bi, "
		 "CAST(1.5 AS REAL) AS r, CAST(1.25 AS FLOAT) AS f, "
		 "CAST(123.456 AS DECIMAL(10,3)) AS d, CAST(12.34 AS MONEY) AS m, "
		 "CAST('abc' AS VARCHAR(10)) AS vc, CAST('def' AS NVARCHAR(10)) AS nvc, "
		 "CAST('2020-01-15T13:45:00' AS DATETIME) AS dt"];

	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqual([table numberOfColumns], 11u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0],  @1);
	XCTAssertEqualObjects([table objectAtRow:0 column:1],  @300);
	XCTAssertEqualObjects([table objectAtRow:0 column:2],  @70000);
	XCTAssertEqualObjects([table objectAtRow:0 column:3],  @5000000000);
	XCTAssertEqualObjects([table objectAtRow:0 column:4],  @1.5);
	XCTAssertEqualObjects([table objectAtRow:0 column:5],  @1.25);
	XCTAssertEqualObjects([table objectAtRow:0 column:6],  [NSDecimalNumber decimalNumberWithString:@"123.456"]);
	XCTAssertEqualObjects([table objectAtRow:0 column:7],  @12.34);
	XCTAssertEqualObjects([table objectAtRow:0 column:8],  @"abc");
	XCTAssertEqualObjects([table objectAtRow:0 column:9],  @"def");
}

#pragma mark - Real table data

- (void)testSelectKnownCustomerRow {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT TOP 5 CustomerID, FirstName, LastName "
		 "FROM SalesLT.Customer ORDER BY CustomerID"];

	XCTAssertEqual([table numberOfRows], 5u);
	XCTAssertEqual([table numberOfColumns], 3u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @1);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @"Orlando");
	XCTAssertEqualObjects([table objectAtRow:0 column:2], @"Gee");
}

- (void)testSelectCountMatchesKnownRowCount {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT COUNT(*) AS total FROM SalesLT.Customer"];

	XCTAssertEqual([table numberOfRows], 1u);
	// COUNT(*) is BIGINT -> SYBINT8.
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @847);
}

// A NULL in a real column takes the is_null path rather than the untyped-literal path,
// because the column still has a declared type and a bind buffer. CustomerID 2 is one
// of the seeded rows whose MiddleName really is NULL; CustomerID 1 is "N.".
- (void)testSelectNullColumnValueYieldsNSNull {
	[self requireServer];
	MADDataTable *table = [self query:
		@"SELECT MiddleName FROM SalesLT.Customer WHERE CustomerID = 2"];

	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], [NSNull null]);
}

#pragma mark - Statements with no result set

// A statement that returns no rows has to come back without hanging and without
// inventing columns. SET NOCOUNT ON is used because it produces no result set and,
// unlike DDL, leaves nothing behind on the server.
- (void)testStatementWithNoResultSetReturnsEmptyTable {
	[self requireServer];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	BOOL success = [self execute:@"SET NOCOUNT ON" into:table];

	XCTAssertTrue(success);
	XCTAssertEqual([table numberOfColumns], 0u);
	XCTAssertEqual([table numberOfRows], 0u);
}

// DML is proven against a real table rather than a #temp table, because a #temp table
// is scoped to a single connection and each statement here needs its own.
- (void)testInsertUpdateDeleteRoundTrip {
	[self requireServer];
	NSString *table = @"dbo.mad_tds_dml_probe";

	// Self-healing: clears anything an earlier aborted run left behind.
	[self execute:[NSString stringWithFormat:
		@"IF OBJECT_ID('%@') IS NOT NULL DROP TABLE %@", table, table]];
	[self execute:[NSString stringWithFormat:
		@"CREATE TABLE %@ (id INT NOT NULL PRIMARY KEY, label NVARCHAR(20))", table]];

	// INSERT ... SELECT is used so the statement has no row-returning clause; the write
	// is verified by reading it back below.
	[self execute:[NSString stringWithFormat:
		@"INSERT INTO %@ (id, label) SELECT 1, 'alpha' UNION ALL SELECT 2, 'beta'", table]];

	MADDataTable *rows = [self query:[NSString stringWithFormat:
		@"SELECT id, label FROM %@ ORDER BY id", table]];
	XCTAssertEqual([rows numberOfRows], 2u);
	XCTAssertEqualObjects([rows objectAtRow:0 column:0], @1);
	XCTAssertEqualObjects([rows objectAtRow:0 column:1], @"alpha");
	XCTAssertEqualObjects([rows objectAtRow:1 column:0], @2);
	XCTAssertEqualObjects([rows objectAtRow:1 column:1], @"beta");

	[self execute:[NSString stringWithFormat:
		@"UPDATE %@ SET label = 'gamma' WHERE id = 1", table]];
	[self execute:[NSString stringWithFormat:
		@"DELETE FROM %@ WHERE id = 2", table]];

	rows = [self query:[NSString stringWithFormat:
		@"SELECT id, label FROM %@ ORDER BY id", table]];
	XCTAssertEqual([rows numberOfRows], 1u);
	XCTAssertEqualObjects([rows objectAtRow:0 column:0], @1);
	XCTAssertEqualObjects([rows objectAtRow:0 column:1], @"gamma");

	[self execute:[NSString stringWithFormat:@"DROP TABLE %@", table]];
}

// A failing statement returns NO and yields no columns. -runSQL: has no error
// out-parameter at all, so the return value is the only thing a caller can see.
- (void)testFailingStatementReturnsNo {
	[self requireServer];
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	BOOL success = [self execute:@"SELECT * FROM mad_no_such_table_xyz" into:table];

	XCTAssertFalse(success);
	XCTAssertEqual([table numberOfColumns], 0u);
	XCTAssertEqual([table numberOfRows], 0u);
}

#pragma mark - Schema discovery

- (void)testGetTablesFindsShippedTables {
	[self requireServer];
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];

	NSError *error = nil;
	NSArray<MADDatabaseTable *> *tables = [db getTablesFromConnection:[self openProcess]
															   error:&error];

	XCTAssertNil(error);
	XCTAssertGreaterThan(tables.count, 0u);

	NSMutableArray<NSString *> *names = [NSMutableArray array];
	for (MADDatabaseTable *table in tables) { [names addObject:table.name]; }

	// The query qualifies each name with its schema.
	XCTAssertTrue([names containsObject:@"SalesLT.Customer"], @"Got: %@", names);
	XCTAssertTrue([names containsObject:@"SalesLT.Product"], @"Got: %@", names);
}

// This test is also a regression guard. -getTables: used to bridge-cast the result of
// -connectWithConnection:credentals:connectionError: straight to a DBPROCESS *, but that
// method returns a MADDatabaseProcessSQLServer wrapping the DBPROCESS. Handing the
// wrapper to dbcmd() realloc'd at an offset inside the object instead of the command
// buffer, so every call aborted the process:
//
//     tds_realloc -> dbcmd -> __-[MADDatabaseSQLServer getTables:]_block_invoke_2
//
// The connection also has to come from a delegate, because -getTables: passes a nil
// credential and the base class then asks its delegate for them.
- (void)testGetTablesIsAsyncAndReportsSuccess {
	[self requireServer];
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	db.databaseConnection = [[self class] testConnection];

	NSDictionary<NSString *, NSString *> *settings = [[self class] testSettings];
	MADTdsCredentialStub *stub = [[MADTdsCredentialStub alloc] init];
	stub.username = settings[@"user"];
	stub.password = settings[@"password"];
	db.delegate = stub;

	XCTestExpectation *expectation = [self expectationWithDescription:@"getTables"];
	__block BOOL sawSuccess = NO;
	__block NSError *sawError = nil;
	__block NSArray *sawTables = nil;

	[db getTables:^(BOOL success, NSError *error, NSArray<MADDatabaseTable *> *tables) {
		sawSuccess = success;
		sawError = error;
		sawTables = tables;
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:30.0 handler:nil];

	XCTAssertNil(sawError);
	XCTAssertTrue(sawSuccess);
	XCTAssertGreaterThan(sawTables.count, 0u);
}

// -fieldsForTable:connection:error: reads sys.columns.system_type_id -- SQL Server's
// own internal type id -- and passes it to +dataTypeForNativeType:, which expects a
// sybdb type code. The two numbering schemes overlap for the common types (int is 56
// in both, for instance) but diverge for others, so the mapping is right by
// coincidence where it is right at all.
- (void)testFieldsForTableMapsCommonTypes {
	[self requireServer];
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];

	NSError *error = nil;
	NSArray<MADDatabaseField *> *fields = [db fieldsForTable:@"SalesLT.Product"
												  connection:[self openProcess]
													   error:&error];

	XCTAssertNil(error);
	NSMutableDictionary<NSString *, MADDatabaseField *> *byName = [NSMutableDictionary dictionary];
	for (MADDatabaseField *field in fields) { byName[field.name] = field; }

	XCTAssertNotNil(byName[@"ProductID"]);
	XCTAssertEqual(byName[@"ProductID"].fieldType, MADDataTypeInteger);

	XCTAssertNotNil(byName[@"Name"]);
	XCTAssertEqual(byName[@"Name"].fieldType, MADDataTypeString);

	XCTAssertNotNil(byName[@"ListPrice"]);
	XCTAssertEqual(byName[@"ListPrice"].fieldType, MADDataTypeFloat);

	XCTAssertNotNil(byName[@"SellStartDate"]);
	XCTAssertEqual(byName[@"SellStartDate"].fieldType, MADDataTypeDateTime);
}

// system_type_id for DECIMAL is 106 and for VARBINARY is 165. 106 is SYBDECIMAL in
// sybdb, which had no case, and 165 is not a sybdb code at all, so both used to fall to
// the default branch and were reported as strings. -fieldsForTable: now maps
// system_type_id through its own table (+dataTypeForSystemTypeId:) instead.
- (void)testFieldsForTableMapsDecimalAndBinary {
	[self requireServer];
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];

	NSError *error = nil;
	NSArray<MADDatabaseField *> *fields = [db fieldsForTable:@"SalesLT.Product"
												  connection:[self openProcess]
													   error:&error];
	XCTAssertNil(error);

	NSMutableDictionary<NSString *, MADDatabaseField *> *byName = [NSMutableDictionary dictionary];
	for (MADDatabaseField *field in fields) { byName[field.name] = field; }

	XCTAssertNotNil(byName[@"Weight"], @"Expected a Weight column on SalesLT.Product");
	XCTAssertEqual(byName[@"Weight"].fieldType, MADDataTypeDecimal);

	XCTAssertNotNil(byName[@"ThumbNailPhoto"], @"Expected a ThumbNailPhoto column");
	XCTAssertEqual(byName[@"ThumbNailPhoto"].fieldType, MADDataTypeBlob);
}

@end
