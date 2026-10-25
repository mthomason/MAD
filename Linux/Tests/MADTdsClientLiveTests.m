//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADTdsClientLiveTests.m
//  Linux/Tests
//
//  Ported from MADTdsClientTests/MADTdsClientLiveTests.m: integration tests
//  for MADTdsClient that talk to a real SQL Server -- this is the only way to
//  exercise the freetds calls behind -connect:andPassword:error:,
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
//  If the server cannot be reached the suite SKIPS rather than fails (MAD_SKIP),
//  so a machine without SQL Server still gets a green run for the offline tests in
//  MADTdsClientTests.m.
//
//  The Xcode suite's fixture state is explicit here.  MAD_SKIP returns early, so
//  each test skips first and only then opens what it needs, and closes it inside
//  the same function -- the tearDown that used to close _process with _database
//  has no equivalent, and the schema-reading tests are the only ones that still
//  hold an open connection when they end.
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

#import "MADTestSupport.h"
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

#import <math.h>

// Declared in MADDatabaseSQLServer.m but not in any published header. Declaring them
// here reaches the live paths without widening the framework's public API.
@interface MADDatabaseSQLServer (MADTdsClientLiveTestsInternal)
- (void *)connect:(NSString *)username andPassword:(NSString *)password error:(NSError * __autoreleasing *)error;
- (id)connectWithConnection:(MADDatabaseConnection *)connection
				 credentals:(MADCredential *)credentals
			connectionError:(NSError * __autoreleasing *)error;
- (void)closeConnection:(id)process;
- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)process
													error:(NSError * __autoreleasing *)outError;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
									 connection:(id)process
										  error:(NSError * __autoreleasing *)error;
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

#pragma mark - Fixtures

static NSDictionary<NSString *, NSString *> *testSettings(void) {
	NSDictionary<NSString *, NSString *> *env = [[NSProcessInfo processInfo] environment];
	return @{
		@"host"     : env[@"MAD_TDS_TEST_HOST"]     ?: @"127.0.0.1",
		@"user"     : env[@"MAD_TDS_TEST_USER"]     ?: @"sa",
		@"password" : env[@"MAD_TDS_TEST_PASSWORD"] ?: @"Root1@Root2",
		@"database" : env[@"MAD_TDS_TEST_DATABASE"] ?: @"AdventureWorksLT2022",
	};
}

static MADDatabaseConnectionSQLServer *testConnection(void) {
	NSDictionary<NSString *, NSString *> *settings = testSettings();
	NSString *host = settings[@"host"];
	return [[MADDatabaseConnectionSQLServer alloc] initWithHost:host
														 server:host
													   database:settings[@"database"]
														andPort:1433];
}

// Every test needs a server. Establishing the connection once proves reachability and
// is cached, so the suite skips as a unit when there is no SQL Server to talk to.
static BOOL serverIsAvailable(void) {
	static BOOL available = NO;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
		db.databaseConnection = testConnection();
		NSDictionary<NSString *, NSString *> *settings = testSettings();
		NSError *error = nil;
		DBPROCESS *dbconn = [db connect:settings[@"user"]
							andPassword:settings[@"password"]
								  error:&error];
		available = (dbconn != NULL && error == nil);
		if (dbconn != NULL) { dbclose(dbconn); }
	});
	return available;
}

// Opens a connection the way the Xcode suite's -openProcess did, handing back both
// the connection and the database that opened it: the schema-reading tests close the
// connection themselves at the end, and MADDatabaseProcessSQLServer is boxed the way
// -connectWithConnection:... boxes it, because the methods under test send -process
// to this argument rather than reading it as a bare pointer.
static id openProcess(MADDatabaseSQLServer **outDatabase) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MADDatabaseConnectionSQLServer *connection = testConnection();
	db.databaseConnection = connection;

	NSDictionary<NSString *, NSString *> *settings = testSettings();
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
	MAD_PASS(process != nil, "Expected to connect to the test server");

	if (outDatabase != NULL) { *outDatabase = db; }
	return process;
}

// Runs one statement on a connection of its own into the given table and reports
// whether it succeeded.
static BOOL executeInto(NSString *sql, MADDataTable *table) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MADDatabaseConnectionSQLServer *connection = testConnection();
	db.databaseConnection = connection;

	NSDictionary<NSString *, NSString *> *settings = testSettings();
	MADCredential *credential = [[MADCredential alloc] initWithUsername:settings[@"user"]
															andPassword:settings[@"password"]];
	id process = [db connectWithConnection:connection
								credentals:credential
						  connectionError:NULL];
	MAD_PASS(process != nil, "Expected to connect to the test server");
	return [db runSQL:sql onDataTable:table fieldKeys:nil process:process];
}

// Runs one statement on a connection of its own and reports whether it succeeded.
static BOOL execute(NSString *sql) {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	return executeInto(sql, table);
}

// Runs one statement on a connection of its own and returns the rows it produced.
static MADDataTable *query(NSString *sql) {
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	executeInto(sql, table);
	return table;
}

#pragma mark - Connection

static void testConnectToLocalServerSucceeds(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	db.databaseConnection = testConnection();
	NSDictionary<NSString *, NSString *> *settings = testSettings();

	NSError *error = nil;
	DBPROCESS *dbconn = [db connect:settings[@"user"]
						andPassword:settings[@"password"]
							  error:&error];

	MAD_PASS(dbconn != NULL, "Expected a connection from the test server");
	MAD_PASS(error == nil, "a successful connection reports no error");
	if (dbconn != NULL) { dbclose(dbconn); }
}

// The database named in the connection is sent as the login's default catalog, so a
// query can name an unqualified table from it. If DBSETLDBNAME were dropped the login
// would land in master and this would fail.
static void testConnectedSessionUsesTheRequestedDatabase(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT DB_NAME() AS db");
	NSString *database = testSettings()[@"database"];

	MAD_PASS([table numberOfRows] == 1u, "the database-name query returns one row");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], database, "the session is in the requested database");
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
static void testEachStatementNeedsItsOwnConnection(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MAD_PASS_EQUAL([query(@"SELECT 1 AS a") objectAtRow:0 column:0], @1,
				   "the first statement on its own connection returns 1");
	MAD_PASS_EQUAL([query(@"SELECT 2 AS a") objectAtRow:0 column:0], @2,
				   "the second statement on its own connection returns 2");
}

#pragma mark - Scalar round trips

static void testSelectIntegerLiteral(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT 255 AS f1");

	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS([table numberOfColumns] == 1u, "one column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @255, "the integer literal round trips");
}

static void testSelectStringLiteral(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT 'hello' AS greeting");

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"hello", "the string literal round trips");
}

// A literal NULL has no declared type at all, so it takes a different path from a
// typed column that happens to hold NULL -- see -testSelectNullColumnValueYieldsNSNull.
static void testSelectNullLiteralYieldsNSNull(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT NULL AS n");

	MAD_PASS([table numberOfColumns] == 1u, "one column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], [NSNull null], "an untyped NULL reads back as NSNull");
}

static void testSelectMultipleColumns(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	// The float literal is cast explicitly: a bare "3.5" is DECIMAL(2,1) in T-SQL, not
	// FLOAT, and would take the decimal path exercised further down.
	MADDataTable *table = query(
		@"SELECT 1 AS a, 'two' AS b, CAST(3.5 AS FLOAT) AS c");

	MAD_PASS([table numberOfColumns] == 3u, "three columns");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @1, "the first column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @"two", "the second column");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], @3.5, "the third column");
}

static void testSelectMultipleRows(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT n FROM (VALUES (1),(2),(3),(4),(5)) AS v(n) ORDER BY n");

	MAD_PASS([table numberOfRows] == 5u, "five rows");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @1, "the first row");
	MAD_PASS_EQUAL([table objectAtRow:4 column:0], @5, "the last row");
}

static void testSelectNegativeNumbers(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT -1 AS i, CAST(-2.5 AS FLOAT) AS f, -300 AS s");

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @-1, "the negative integer");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @-2.5, "the negative float");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], @-300, "the negative smallint");
}

// SQL Server pads a CHAR column out to its declared width -- it reports DATALENGTH 5
// and LEN 2 for this expression -- but the trailing blanks do not reach the data table,
// because the column is bound as a NUL-terminated string. Pinned as the behaviour a
// report actually sees.
static void testSelectCharTrailingBlanksAreNotPreserved(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT CAST('ab' AS CHAR(5)) AS c");

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @"ab", "the trailing blanks are not preserved");
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
static void testSelectDecimalReturnedValues(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT CAST(3.5 AS DECIMAL(2,1)) AS pos, CAST(1 AS DECIMAL(10,2)) AS whole, "
		 "CAST(123.456 AS DECIMAL(10,3)) AS frac");

	MAD_PASS([table numberOfColumns] == 3u, "three columns");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], [NSDecimalNumber decimalNumberWithString:@"3.5"],
				   "the positive decimal");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], [NSDecimalNumber decimalNumberWithString:@"1.00"],
				   "the whole decimal keeps its scale");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], [NSDecimalNumber decimalNumberWithString:@"123.456"],
				   "the fractional decimal");
}

// The sign-bearing case the old separator search corrupted.
static void testSelectNegativeDecimalKeepsItsSign(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT CAST(-2.5 AS DECIMAL(4,1)) AS neg");

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], [NSDecimalNumber decimalNumberWithString:@"-2.5"],
				   "the negative decimal keeps its sign");
}

#pragma mark - Column metadata

// The column type reported by the server is normalised before it reaches
// +dataTypeForNativeType:. SYBDECIMAL is rewritten to SYBNUMERIC and SYBMONEY4 to
// SYBMONEY, which is why those two -- unmapped in the method itself, see the offline
// suite -- still classify correctly when a real query is run.
static void testSelectColumnMetadataForScalars(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT CAST(1 AS INT) AS i, CAST('x' AS VARCHAR(4)) AS v, "
		 "CAST(1.25 AS FLOAT) AS f, CAST(123.45 AS DECIMAL(10,2)) AS d, "
		 "CAST(12.34 AS MONEY) AS m");

	NSArray<NSString *> *keys = [table columnKeys];
	MAD_PASS(keys.count == 5u, "five columns");

	MAD_PASS(table.columns[keys[0]].type == MADDataTypeInteger, "INT is Integer");
	MAD_PASS(table.columns[keys[1]].type == MADDataTypeString, "VARCHAR is String");
	MAD_PASS(table.columns[keys[2]].type == MADDataTypeFloat, "FLOAT is Float");
	// DECIMAL arrives as SYBDECIMAL, is rewritten to SYBNUMERIC, and so maps to Decimal.
	MAD_PASS(table.columns[keys[3]].type == MADDataTypeDecimal, "DECIMAL is Decimal");
	// MONEY arrives as SYBMONEY, which is mapped directly. SMALLMONEY is the one that
	// arrives as SYBMONEY4 and needs the rewrite; see the test below.
	MAD_PASS(table.columns[keys[4]].type == MADDataTypeFloat, "MONEY is Float");
}

static void testSelectSmallMoneyIsRewrittenToMoney(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT CAST(12.34 AS SMALLMONEY) AS sm");

	NSString *key = [table columnKeys][0];
	// SYBMONEY4 would map to MADDataTypeString if it were not rewritten first.
	MAD_PASS(table.columns[key].type == MADDataTypeFloat, "SMALLMONEY is rewritten to MONEY and maps to Float");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @12.34, "the smallmoney value round trips");
}

// Reads a returned value back out as UTC calendar components, so the assertions below
// can name what went into the query rather than an instant that shifts with the
// runner's time zone. The driver builds its dates in GMT, so the reading is in GMT too.
static NSDateComponents *MADUTCComponents(NSDate *date) {
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	return [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
								 NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
					   fromDate:date];
}

// The post-2005 date/time types map to the date/time cases of MADDataType instead of
// falling through to the String default, and now carry their values: the row conversion
// hands the raw column buffer to dbanydatecrack(), which is told the column's own type
// code and does the layout work itself. Nothing is bound for these types; freetds keeps
// each value in the row buffer in a layout only the type code explains.
static void testSelectModernDateTimeTypes(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT CAST('2020-01-15' AS DATE) AS d, "
		 "CAST('13:45:00' AS TIME) AS t, "
		 "CAST('2020-12-31T13:45:00' AS DATETIME2) AS dt2, "
		 "CAST('2020-01-15T13:45:00+00:00' AS DATETIMEOFFSET) AS dto");

	NSArray<NSString *> *keys = [table columnKeys];
	MAD_PASS(keys.count == 4u, "four columns");
	MAD_PASS(table.columns[keys[0]].type == MADDataTypeDate, "DATE is Date");
	MAD_PASS(table.columns[keys[1]].type == MADDataTypeTime, "TIME is Time");
	MAD_PASS(table.columns[keys[2]].type == MADDataTypeDateTime, "DATETIME2 is DateTime");
	MAD_PASS(table.columns[keys[3]].type == MADDataTypeDateTime, "DATETIMEOFFSET is DateTime");

	MAD_PASS([table numberOfRows] == 1u, "one row");

	NSDate *date = [table objectAtRow:0 column:0];
	MAD_PASS([date isKindOfClass:[NSDate class]], "DATE came back as an NSDate");
	NSDateComponents *dateParts = MADUTCComponents(date);
	MAD_PASS(dateParts.year == 2020, "DATE year");
	MAD_PASS(dateParts.month == 1, "DATE month");
	MAD_PASS(dateParts.day == 15, "DATE day");

	// A bare TIME has no day of its own, so freetds cracks it onto its epoch day,
	// 1900-01-01. Only the clock is meaningful here.
	NSDate *time = [table objectAtRow:0 column:1];
	MAD_PASS([time isKindOfClass:[NSDate class]], "TIME came back as an NSDate");
	NSDateComponents *timeParts = MADUTCComponents(time);
	MAD_PASS(timeParts.hour == 13, "TIME hour");
	MAD_PASS(timeParts.minute == 45, "TIME minute");
	MAD_PASS(timeParts.second == 0, "TIME second");

	// December, not January: a month that is already its own successor catches an
	// unwanted +1 that a January value would hide.
	NSDate *dateTime2 = [table objectAtRow:0 column:2];
	MAD_PASS([dateTime2 isKindOfClass:[NSDate class]], "DATETIME2 came back as an NSDate");
	NSDateComponents *dateTime2Parts = MADUTCComponents(dateTime2);
	MAD_PASS(dateTime2Parts.year == 2020, "DATETIME2 year");
	MAD_PASS(dateTime2Parts.month == 12, "DATETIME2 month");
	MAD_PASS(dateTime2Parts.day == 31, "DATETIME2 day");
	MAD_PASS(dateTime2Parts.hour == 13, "DATETIME2 hour");
	MAD_PASS(dateTime2Parts.minute == 45, "DATETIME2 minute");

	// The offset is zero here, so this pins the value without committing to how a
	// non-zero offset is folded.
	NSDate *offset = [table objectAtRow:0 column:3];
	MAD_PASS([offset isKindOfClass:[NSDate class]], "DATETIMEOFFSET came back as an NSDate");
	NSDateComponents *offsetParts = MADUTCComponents(offset);
	MAD_PASS(offsetParts.year == 2020, "DATETIMEOFFSET year");
	MAD_PASS(offsetParts.month == 1, "DATETIMEOFFSET month");
	MAD_PASS(offsetParts.day == 15, "DATETIMEOFFSET day");
	MAD_PASS(offsetParts.hour == 13, "DATETIMEOFFSET hour");
	MAD_PASS(offsetParts.minute == 45, "DATETIMEOFFSET minute");
}

// The classic DATETIME and DATETIMN types go through dbdatecrack, not dbanydatecrack,
// but both land in the same freetds record and so share its month convention.
static void testSelectClassicDateTimeKeepsItsMonth(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT CAST('2020-01-15T13:45:00' AS DATETIME) AS dt, "
		 "CAST('2020-12-15T13:45:00' AS DATETIME) AS dt2");

	MAD_PASS([table numberOfRows] == 1u, "one row");

	NSDate *january = [table objectAtRow:0 column:0];
	MAD_PASS([january isKindOfClass:[NSDate class]], "the January DATETIME came back as an NSDate");
	NSDateComponents *januaryParts = MADUTCComponents(january);
	MAD_PASS(januaryParts.year == 2020, "January year");
	MAD_PASS(januaryParts.month == 1, "January month");
	MAD_PASS(januaryParts.day == 15, "January day");

	NSDate *december = [table objectAtRow:0 column:1];
	MAD_PASS([december isKindOfClass:[NSDate class]], "the December DATETIME came back as an NSDate");
	NSDateComponents *decemberParts = MADUTCComponents(december);
	MAD_PASS(decemberParts.year == 2020, "December year");
	MAD_PASS(decemberParts.month == 12, "December month");
	MAD_PASS(decemberParts.day == 15, "December day");
}

// A NULL of any of these types must still read back as [NSNull null] rather than being
// cracked out of a zero-length buffer.
static void testSelectModernDateTimeTypesNull(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT CAST(NULL AS DATE) AS d, "
		 "CAST(NULL AS TIME) AS t, "
		 "CAST(NULL AS DATETIME2) AS dt2");

	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], [NSNull null], "a NULL DATE reads back as NSNull");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], [NSNull null], "a NULL TIME reads back as NSNull");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], [NSNull null], "a NULL DATETIME2 reads back as NSNull");
}

#pragma mark - Type conversion round trip

// One query that exercises every type code the framework binds. Values are chosen so
// each conversion is distinguishable from the others.
static void testTypeConversionRoundTrip(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT CAST(1 AS BIT) AS b, CAST(300 AS SMALLINT) AS s, "
		 "CAST(70000 AS INT) AS i, CAST(5000000000 AS BIGINT) AS bi, "
		 "CAST(1.5 AS REAL) AS r, CAST(1.25 AS FLOAT) AS f, "
		 "CAST(123.456 AS DECIMAL(10,3)) AS d, CAST(12.34 AS MONEY) AS m, "
		 "CAST('abc' AS VARCHAR(10)) AS vc, CAST('def' AS NVARCHAR(10)) AS nvc, "
		 "CAST('2020-01-15T13:45:00' AS DATETIME) AS dt");

	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS([table numberOfColumns] == 11u, "eleven columns");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0],  @1, "BIT");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1],  @300, "SMALLINT");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2],  @70000, "INT");
	MAD_PASS_EQUAL([table objectAtRow:0 column:3],  @5000000000, "BIGINT");
	MAD_PASS_EQUAL([table objectAtRow:0 column:4],  @1.5, "REAL");
	MAD_PASS_EQUAL([table objectAtRow:0 column:5],  @1.25, "FLOAT");
	MAD_PASS_EQUAL([table objectAtRow:0 column:6],  [NSDecimalNumber decimalNumberWithString:@"123.456"], "DECIMAL");
	MAD_PASS_EQUAL([table objectAtRow:0 column:7],  @12.34, "MONEY");
	MAD_PASS_EQUAL([table objectAtRow:0 column:8],  @"abc", "VARCHAR");
	MAD_PASS_EQUAL([table objectAtRow:0 column:9],  @"def", "NVARCHAR");
}

/// A FLOAT column carries an 8-byte value, and the fetch path must not narrow it
/// to float on the way into the NSNumber.  0.1 has no exact float representation,
/// so a narrowing round-trip would land on 0.10000000149011612 instead.
///
/// Scope note: this exercises the SYBFLT8 case.  The SYBREAL and SYBFLTN cases
/// cannot be told apart by any value -- a 4-byte REAL is float-exact by definition,
/// and SQL Server sends FLOAT as FLT8 -- so this test guards the 8-byte path rather
/// than discriminating those two cases.
static void testSelectFloatKeepsDoublePrecision(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(@"SELECT CAST(0.1 AS FLOAT) AS f");

	NSNumber *value = [table objectAtRow:0 column:0];
	MAD_PASS(fabs([value doubleValue] - 0.1) <= 1e-15, "the FLOAT value is 0.1 within 1e-15");
	MAD_PASS(fabs([value doubleValue] - (double)(float)0.1) > 1e-12,
			 "the FLOAT value was not narrowed to float precision");
}

#pragma mark - Real table data

static void testSelectKnownCustomerRow(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT TOP 5 CustomerID, FirstName, LastName "
		 "FROM SalesLT.Customer ORDER BY CustomerID");

	MAD_PASS([table numberOfRows] == 5u, "five rows");
	MAD_PASS([table numberOfColumns] == 3u, "three columns");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @1, "the first customer id");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @"Orlando", "the first customer first name");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], @"Gee", "the first customer last name");
}

static void testSelectCountMatchesKnownRowCount(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT COUNT(*) AS total FROM SalesLT.Customer");

	MAD_PASS([table numberOfRows] == 1u, "one row");
	// COUNT(*) is BIGINT -> SYBINT8.
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @847, "the customer count");
}

// A NULL in a real column takes the is_null path rather than the untyped-literal path,
// because the column still has a declared type and a bind buffer. CustomerID 2 is one
// of the seeded rows whose MiddleName really is NULL; CustomerID 1 is "N.".
static void testSelectNullColumnValueYieldsNSNull(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = query(
		@"SELECT MiddleName FROM SalesLT.Customer WHERE CustomerID = 2");

	MAD_PASS([table numberOfRows] == 1u, "one row");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], [NSNull null], "a real NULL column value reads back as NSNull");
}

#pragma mark - Statements with no result set

// A statement that returns no rows has to come back without hanging and without
// inventing columns. SET NOCOUNT ON is used because it produces no result set and,
// unlike DDL, leaves nothing behind on the server.
static void testStatementWithNoResultSetReturnsEmptyTable(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	BOOL success = executeInto(@"SET NOCOUNT ON", table);

	MAD_PASS(success, "the statement succeeds");
	MAD_PASS([table numberOfColumns] == 0u, "no columns are invented");
	MAD_PASS([table numberOfRows] == 0u, "no rows are invented");
}

// DML is proven against a real table rather than a #temp table, because a #temp table
// is scoped to a single connection and each statement here needs its own.
static void testInsertUpdateDeleteRoundTrip(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	NSString *table = @"dbo.mad_tds_dml_probe";

	// Self-healing: clears anything an earlier aborted run left behind.
	execute([[NSString alloc] initWithFormat:
		@"IF OBJECT_ID('%@') IS NOT NULL DROP TABLE %@", table, table]);
	execute([[NSString alloc] initWithFormat:
		@"CREATE TABLE %@ (id INT NOT NULL PRIMARY KEY, label NVARCHAR(20))", table]);

	// INSERT ... SELECT is used so the statement has no row-returning clause; the write
	// is verified by reading it back below.
	execute([[NSString alloc] initWithFormat:
		@"INSERT INTO %@ (id, label) SELECT 1, 'alpha' UNION ALL SELECT 2, 'beta'", table]);

	MADDataTable *rows = query([[NSString alloc] initWithFormat:
		@"SELECT id, label FROM %@ ORDER BY id", table]);
	MAD_PASS([rows numberOfRows] == 2u, "both inserted rows are present");
	MAD_PASS_EQUAL([rows objectAtRow:0 column:0], @1, "the first row id");
	MAD_PASS_EQUAL([rows objectAtRow:0 column:1], @"alpha", "the first row label");
	MAD_PASS_EQUAL([rows objectAtRow:1 column:0], @2, "the second row id");
	MAD_PASS_EQUAL([rows objectAtRow:1 column:1], @"beta", "the second row label");

	execute([[NSString alloc] initWithFormat:
		@"UPDATE %@ SET label = 'gamma' WHERE id = 1", table]);
	execute([[NSString alloc] initWithFormat:
		@"DELETE FROM %@ WHERE id = 2", table]);

	rows = query([[NSString alloc] initWithFormat:
		@"SELECT id, label FROM %@ ORDER BY id", table]);
	MAD_PASS([rows numberOfRows] == 1u, "one row remains after the update and delete");
	MAD_PASS_EQUAL([rows objectAtRow:0 column:0], @1, "the surviving row id");
	MAD_PASS_EQUAL([rows objectAtRow:0 column:1], @"gamma", "the updated label");

	execute([[NSString alloc] initWithFormat:@"DROP TABLE %@", table]);
}

// A failing statement returns NO and yields no columns. -runSQL: has no error
// out-parameter at all, so the return value is the only thing a caller can see.
static void testFailingStatementReturnsNo(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	BOOL success = executeInto(@"SELECT * FROM mad_no_such_table_xyz", table);

	MAD_PASS(!success, "the failing statement reports NO");
	MAD_PASS([table numberOfColumns] == 0u, "no columns are yielded");
	MAD_PASS([table numberOfRows] == 0u, "no rows are yielded");
}

#pragma mark - Schema discovery

static void testGetTablesFindsShippedTables(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDatabaseSQLServer *db = nil;
	id process = openProcess(&db);

	NSError *error = nil;
	NSArray<MADDatabaseTable *> *tables = [db getTablesFromConnection:process
																error:&error];

	MAD_PASS(error == nil, "schema discovery reports no error");
	MAD_PASS(tables.count > 0u, "the server has tables");

	NSMutableArray<NSString *> *names = [NSMutableArray array];
	for (MADDatabaseTable *table in tables) { [names addObject:table.name]; }

	// The query qualifies each name with its schema.
	MAD_PASS([names containsObject:@"SalesLT.Customer"], "SalesLT.Customer is listed");
	MAD_PASS([names containsObject:@"SalesLT.Product"], "SalesLT.Product is listed");

	// The schema readers leave the connection open; only -runSQL: closes its own.
	if (process != nil) {
		[db closeConnection:process];
	}
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
static void testGetTablesIsAsyncAndReportsSuccess(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	db.databaseConnection = testConnection();

	NSDictionary<NSString *, NSString *> *settings = testSettings();
	MADTdsCredentialStub *stub = [[MADTdsCredentialStub alloc] init];
	stub.username = settings[@"user"];
	stub.password = settings[@"password"];
	db.delegate = stub;

	__block BOOL sawCallback = NO;
	__block BOOL sawSuccess = NO;
	__block NSError *sawError = nil;
	__block NSArray *sawTables = nil;

	[db getTables:^(BOOL success, NSError *error, NSArray<MADDatabaseTable *> *tables) {
		sawSuccess = success;
		// MRC __block variables do not retain, and the completion's objects die
		// with its autorelease pool; hold on to what the assertions read.
		sawError = [error retain];
		sawTables = [tables retain];
		sawCallback = YES;
	}];

	MAD_PASS(MADWaitForFlag(&sawCallback, 30.0), "the completion is called");
	MAD_PASS(sawError == nil, "the async call reports no error");
	MAD_PASS(sawSuccess, "the async call reports success");
	MAD_PASS(sawTables.count > 0u, "the async call carries tables");
}

// -fieldsForTable:connection:error: reads sys.columns.system_type_id -- SQL Server's
// own internal type id -- and passes it to +dataTypeForNativeType:, which expects a
// sybdb type code. The two numbering schemes overlap for the common types (int is 56
// in both, for instance) but diverge for others, so the mapping is right by
// coincidence where it is right at all.
static void testFieldsForTableMapsCommonTypes(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDatabaseSQLServer *db = nil;
	id process = openProcess(&db);

	NSError *error = nil;
	NSArray<MADDatabaseField *> *fields = [db fieldsForTable:@"SalesLT.Product"
												  connection:process
													   error:&error];

	MAD_PASS(error == nil, "field discovery reports no error");
	NSMutableDictionary<NSString *, MADDatabaseField *> *byName = [NSMutableDictionary dictionary];
	for (MADDatabaseField *field in fields) { byName[field.name] = field; }

	MAD_PASS(byName[@"ProductID"] != nil, "ProductID is present");
	MAD_PASS(byName[@"ProductID"].fieldType == MADDataTypeInteger, "ProductID is Integer");

	MAD_PASS(byName[@"Name"] != nil, "Name is present");
	MAD_PASS(byName[@"Name"].fieldType == MADDataTypeString, "Name is String");

	MAD_PASS(byName[@"ListPrice"] != nil, "ListPrice is present");
	MAD_PASS(byName[@"ListPrice"].fieldType == MADDataTypeFloat, "ListPrice is Float");

	MAD_PASS(byName[@"SellStartDate"] != nil, "SellStartDate is present");
	MAD_PASS(byName[@"SellStartDate"].fieldType == MADDataTypeDateTime, "SellStartDate is DateTime");

	// The schema readers leave the connection open; only -runSQL: closes its own.
	if (process != nil) {
		[db closeConnection:process];
	}
}

// system_type_id for DECIMAL is 106 and for VARBINARY is 165. 106 is SYBDECIMAL in
// sybdb, which had no case, and 165 is not a sybdb code at all, so both used to fall to
// the default branch and were reported as strings. -fieldsForTable: now maps
// system_type_id through its own table (+dataTypeForSystemTypeId:) instead.
static void testFieldsForTableMapsDecimalAndBinary(void) {
	MAD_SKIP(!serverIsAvailable(), @"No SQL Server reachable; see DEVELOPER.md for the expected test instance.");
	MADDatabaseSQLServer *db = nil;
	id process = openProcess(&db);

	NSError *error = nil;
	NSArray<MADDatabaseField *> *fields = [db fieldsForTable:@"SalesLT.Product"
												  connection:process
													   error:&error];
	MAD_PASS(error == nil, "field discovery reports no error");

	NSMutableDictionary<NSString *, MADDatabaseField *> *byName = [NSMutableDictionary dictionary];
	for (MADDatabaseField *field in fields) { byName[field.name] = field; }

	MAD_PASS(byName[@"Weight"] != nil, "the Weight column is present");
	MAD_PASS(byName[@"Weight"].fieldType == MADDataTypeDecimal, "Weight is Decimal");

	MAD_PASS(byName[@"ThumbNailPhoto"] != nil, "the ThumbNailPhoto column is present");
	MAD_PASS(byName[@"ThumbNailPhoto"].fieldType == MADDataTypeBlob, "ThumbNailPhoto is Blob");

	// The schema readers leave the connection open; only -runSQL: closes its own.
	if (process != nil) {
		[db closeConnection:process];
	}
}

MAD_TEST_MAIN("MADTdsClientLiveTests",
	MAD_TEST(testConnectToLocalServerSucceeds),
	MAD_TEST(testConnectedSessionUsesTheRequestedDatabase),
	MAD_TEST(testEachStatementNeedsItsOwnConnection),
	MAD_TEST(testSelectIntegerLiteral),
	MAD_TEST(testSelectStringLiteral),
	MAD_TEST(testSelectNullLiteralYieldsNSNull),
	MAD_TEST(testSelectMultipleColumns),
	MAD_TEST(testSelectMultipleRows),
	MAD_TEST(testSelectNegativeNumbers),
	MAD_TEST(testSelectCharTrailingBlanksAreNotPreserved),
	MAD_TEST(testSelectDecimalReturnedValues),
	MAD_TEST(testSelectNegativeDecimalKeepsItsSign),
	MAD_TEST(testSelectColumnMetadataForScalars),
	MAD_TEST(testSelectSmallMoneyIsRewrittenToMoney),
	MAD_TEST(testSelectModernDateTimeTypes),
	MAD_TEST(testSelectClassicDateTimeKeepsItsMonth),
	MAD_TEST(testSelectModernDateTimeTypesNull),
	MAD_TEST(testTypeConversionRoundTrip),
	MAD_TEST(testSelectFloatKeepsDoublePrecision),
	MAD_TEST(testSelectKnownCustomerRow),
	MAD_TEST(testSelectCountMatchesKnownRowCount),
	MAD_TEST(testSelectNullColumnValueYieldsNSNull),
	MAD_TEST(testStatementWithNoResultSetReturnsEmptyTable),
	MAD_TEST(testInsertUpdateDeleteRoundTrip),
	MAD_TEST(testFailingStatementReturnsNo),
	MAD_TEST(testGetTablesFindsShippedTables),
	MAD_TEST(testGetTablesIsAsyncAndReportsSuccess),
	MAD_TEST(testFieldsForTableMapsCommonTypes),
	MAD_TEST(testFieldsForTableMapsDecimalAndBinary));
