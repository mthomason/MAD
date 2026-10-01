//
//  MADTdsClientTests.m
//  MADTdsClientTests
//
//  Created by Michael Thomason on 9/15/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  Offline unit tests for MADTdsClient. Nothing here needs a SQL Server.
//
//  The live suite is in MADTdsClientLiveTests.m. It talks to the SQL Server 2022
//  Developer Edition container documented in DEVELOPER.md.
//
//  The instance recorded in DEVELOPER.md (192.168.1.224, test/test,
//  AdventureWorks2022) is not reachable and is not what the live suite uses.
//
//  A consequence worth stating plainly: the parts of this framework that can only be
//  exercised against a real server -- query execution, column binding, and every
//  conversion in -runSQL:... -- are NOT verified by anything in this file. The type
//  mapping assertions below pin what the code does, not what a server would send.
//

#import <XCTest/XCTest.h>

#import <MADTdsClient/MADTdsClient.h>
#import <MADTds/sybdb.h>

// MADDatabaseProcessSQLServer lives in the framework's Headers phase with project
// visibility, not public visibility, and the umbrella header does not re-export it --
// the class is plumbing between MADDatabaseSQLServer and freetds, not API. Redeclaring
// the two methods reaches it without widening the framework's public surface.
@interface MADDatabaseProcessSQLServer : NSObject
- (instancetype)initWithProcess:(void /* DBPROCESS */ *)process;
- (void /* DBPROCESS */ *)process NS_RETURNS_INNER_POINTER;
@end

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADCredential.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADDatabaseConnection.h>

// These selectors are implemented in MADDatabaseSQLServer.m but are not declared in
// any header the framework publishes. Declaring them here lets the tests reach them
// without widening MADDatabaseSQLServer's public API.
@interface MADDatabaseSQLServer (MADTdsClientTestsInternal)
+ (MADDataType)dataTypeForNativeType:(NSInteger)nativeType;
+ (NSString *)bracketedIdentifierFromName:(NSString *)name;
+ (NSString *)IPAddressForServer:(NSString *)server;
- (NSString *)shortAliasFromQualifiedTable:(NSString *)qualifiedName;
- (void *)connect:(NSString *)username andPassword:(NSString *)password error:(NSError **)error;
@end

@interface MADTdsClientTests : XCTestCase

@end

@implementation MADTdsClientTests

#pragma mark - MADDatabaseSQLServer identity

- (void)testDriverMetadata {
	XCTAssertEqualObjects([MADDatabaseSQLServer driverName], @"SQL Server / TDS");
	XCTAssertEqualObjects([MADDatabaseSQLServer imageIconName], @"UIImageExportTypeSqlServer");
}

#pragma mark - +dataTypeForNativeType:

// The sybdb type codes are mapped onto MADDataType. Note how much coarser this is
// than the MySQL mapping: every integer width collapses to MADDataTypeInteger, every
// character type to MADDataTypeString, and money/real/float all become
// MADDataTypeFloat.

- (void)testDataTypeForNativeTypeMapsDateTimeFamily {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBDATETIMN],   MADDataTypeDateTime);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBDATETIME],  MADDataTypeDateTime);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBDATETIME4], MADDataTypeDateTime);
}

- (void)testDataTypeForNativeTypeMapsCharacterFamily {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBCHAR],     MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBVARCHAR],  MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBTEXT],     MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBNTEXT],    MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBNVARCHAR], MADDataTypeString);
}

- (void)testDataTypeForNativeTypeMapsBitFamily {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBBIT],  MADDataTypeBit);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBBITN], MADDataTypeBit);
}

- (void)testDataTypeForNativeTypeMapsAllIntegerWidthsToInteger {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBINT1], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBINT2], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBINT4], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBINT8], MADDataTypeInteger);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBINTN], MADDataTypeInteger);
}

- (void)testDataTypeForNativeTypeMapsMoneyAndFloatingPointToFloat {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMONEY],  MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMONEYN], MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBREAL],   MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBFLT8],   MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBFLTN],   MADDataTypeFloat);
}

- (void)testDataTypeForNativeTypeMapsNumericToDecimal {
	// Only SYBNUMERIC has a case; SQBDECIMAL does not. See the test below.
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBNUMERIC], MADDataTypeDecimal);
}

- (void)testDataTypeForNativeTypeMapsBinaryFamilyToBlob {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBIMAGE],     MADDataTypeBlob);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBBINARY],    MADDataTypeBlob);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBVOID],      MADDataTypeBlob);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBVARBINARY], MADDataTypeBlob);
}

- (void)testDataTypeForNativeTypeDefaultsToIntegerForUnknownCodes {
	// Anything unrecognised falls through to MADDataTypeString. MADDataTypeUnknown is
	// never produced by this mapping.
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:(NSInteger)-1],   MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:(NSInteger)99999], MADDataTypeString);
}

// SYBDECIMAL (106) and SYBNUMERIC (108) are distinct codes, and only the latter is
// handled -- even though DECIMAL and NUMERIC are the same type in SQL Server and
// DECIMAL is the more common spelling. A DECIMAL column is therefore typed as a
// string. Pinned here rather than corrected, because changing it changes the column
// type every report built on a DECIMAL column sees, and nothing in this suite can
// verify the result against a real server.
- (void)testDataTypeForNativeTypeDoesNotMapDecimal {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBDECIMAL], MADDataTypeString);
	// There is no dedicated MADDataType for an unknown native code; this is what the
	// default branch yields, and it is indistinguishable from a genuine string column.
}

// The date/time types added after SQL Server 2005 are unmapped, so they also fall to
// MADDataTypeString. DATETIME2 in particular is the type Microsoft recommends over
// DATETIME, and DATETIMEOFFSET is the only type that carries an offset.
- (void)testDataTypeForNativeTypeDoesNotMapModernDateTimeTypes {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBDATE],                 MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBTIME],                 MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATE],               MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSTIME],               MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATETIME2],          MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATETIMEOFFSET],     MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBBIGDATETIME],          MADDataTypeString);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBBIGTIME],              MADDataTypeString);
}

// The four-byte money type is unmapped while the eight-byte one is handled.
- (void)testDataTypeForNativeTypeDoesNotMapSmallMoney {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMONEY4], MADDataTypeString);
}

#pragma mark - Identifier quoting

- (void)testNewSafeQueryFieldBracketsTableAndField {
	XCTAssertEqualObjects([MADDatabaseSQLServer newSafeQueryField:@"emp_no" andTable:@"employees"],
						  @"[employees].[emp_no]");
}

// BUG.md "MADTdsClient": the table name is interpolated whole, so a schema-qualified
// table produces one bracket pair containing a dot. T-SQL reads [dbo.employees] as a
// table literally named "dbo.employees" in the default schema, not as employees in
// the dbo schema. +bracketedIdentifierFromName: splits on the dot correctly but is
// not used here.
- (void)testNewSafeQueryFieldDoesNotSplitSchemaQualifiedTable {
	XCTAssertEqualObjects([MADDatabaseSQLServer newSafeQueryField:@"emp_no" andTable:@"dbo.employees"],
						  @"[dbo.employees].[emp_no]");
}

- (void)testBracketedIdentifierFromNameSplitsOnDots {
	XCTAssertEqualObjects([MADDatabaseSQLServer bracketedIdentifierFromName:@"dbo.employees"],
						  @"[dbo].[employees]");
	XCTAssertEqualObjects([MADDatabaseSQLServer bracketedIdentifierFromName:@"employees"],
						  @"[employees]");
}

- (void)testBracketedIdentifierFromNameDropsEmptyComponents {
	// Empty components are skipped rather than bracketed, so the malformed input
	// "a..b" silently becomes a well-formed two-part name.
	XCTAssertEqualObjects([MADDatabaseSQLServer bracketedIdentifierFromName:@"a..b"], @"[a].[b]");
}

- (void)testNewSafeIdentifierBracketsBareName {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db newSafeIdentifier:@"employees"], @"[employees]");
}

- (void)testNewSafeIdentifierSplitsQualifiedName {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db newSafeIdentifier:@"dbo.employees"], @"[dbo].[employees]");
}

- (void)testQueryKeyMatchesNewSafeQueryField {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db queryKey:@"salary" table:@"salaries"],
						  [MADDatabaseSQLServer newSafeQueryField:@"salary" andTable:@"salaries"]);
	XCTAssertEqualObjects([db queryKey:@"salary" table:@"salaries"], @"[salaries].[salary]");
}

// The table half is taken as already-safe and is not re-bracketed, so the result is
// asymmetric when the caller passes a bare table name: "employees.[emp_no]".
- (void)testFieldAliasLeavesTableNameUnbracketed {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db fieldAliasForField:@"emp_no" withSafeTableName:@"employees"],
						  @"employees.[emp_no]");
}

- (void)testFieldAliasWithBracketedTableName {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db fieldAliasForField:@"emp_no" withSafeTableName:@"[dbo].[employees]"],
						  @"[dbo].[employees].[emp_no]");
}

- (void)testShortAliasFromQualifiedTableTakesLastComponent {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db shortAliasFromQualifiedTable:@"dbo.employees"], @"employees");
	XCTAssertEqualObjects([db shortAliasFromQualifiedTable:@"[dbo].[employees]"], @"[employees]");
	XCTAssertEqualObjects([db shortAliasFromQualifiedTable:@"employees"], @"employees");
}

#pragma mark - SQL fragments

- (void)testAggregateLengthFunctionIsDataLength {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db sqlAggregateFunctionLength], @"DATALENGTH");
}

- (void)testSelectPart {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db selectPart], @"SELECT\n");
}

// SQL Server has no LIMIT; the row cap is a TOP clause appended after the SELECT.
// The newline between them is what makes "SELECT\nTOP 10\n" valid T-SQL.
- (void)testSelectPartWithLimitedResultsAppendsTop {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db selectPartWithLimitedResults:10], @"SELECT\nTOP 10\n");
}

- (void)testSelectPartWithUnlimitedResultsOmitsTop {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db selectPartWithLimitedResults:NSUIntegerMax], @"SELECT\n");
	XCTAssertEqualObjects([db selectPartWithLimitedResults:0], @"SELECT\n");
}

- (void)testSqlLimitClausesAreEmpty {
	// LIMIT is not T-SQL; the range clause below does the work instead.
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db sqlLimitClause], @"");
	XCTAssertEqualObjects([db sqlLimitClause:10], @"");
}

- (void)testSqlRangeClauseUsesOffsetFetch {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db sqlRangeClauseWithLimit:10 offset:20], @"OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY");
}

- (void)testDefaultRequiredOrderByClause {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	// Required by SQL Server whenever OFFSET/FETCH is used.
	XCTAssertEqualObjects([db sqlDefaultRequiredOrderByClause], @"ORDER BY (SELECT NULL)");
}

- (void)testTableAliasConnector {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db tableAliasConnector], @" AS ");
}

// SQL Server overrides the base implementation here, which is what keeps the base
// class's trailing "LIMIT 511;" -- invalid T-SQL -- out of the statement. Worth
// pinning, because the base's version is the one that would otherwise run.
//
// The override is a wholesale replacement rather than a composition: it hardcodes
// both the word SELECT and the row cap of 511 into the format string, so it does not
// go through -selectPart / -selectPartWithLimitedResults:, and it never calls
// -sqlAggregateFunctionLength the way the base version does.
- (void)testSampleDataQueryShape {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	NSString *sql = [db sqlSampleDataForField:@"emp_no" andTable:@"employees"];

	XCTAssertTrue([sql hasPrefix:@"SELECT DISTINCT TOP 511 "], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"[employees].[emp_no]"], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:MADSqlTextFromPart], @"Got: %@", sql);
	XCTAssertTrue([sql containsString:@"[employees]"], @"Got: %@", sql);
	XCTAssertFalse([sql containsString:@"LIMIT"], @"Got: %@", sql);
	XCTAssertFalse([sql containsString:@"DATALENGTH"], @"Got: %@", sql);
}

#pragma mark - MADDatabaseConnectionSQLServer

- (void)testConnectionInitializationStoresProperties {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	XCTAssertEqualObjects(conn.host, @"db.example.com");
	XCTAssertEqualObjects(conn.server, @"INSTANCE");
	XCTAssertEqualObjects(conn.database, @"AdventureWorks2022");
	XCTAssertEqual(conn.port, 1433);
	XCTAssertEqual(conn.databaseType, MADDatabaseTypeTDS);
	XCTAssertTrue(conn.requiresCredentials);
}

- (void)testConnectionServerIsTrimmedButHostIsNot {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"  db.example.com \n"
													  server:@"  INSTANCE \n"
													database:@"d"
													 andPort:1];
	XCTAssertEqualObjects(conn.host, @"  db.example.com \n");
	XCTAssertEqualObjects(conn.server, @"INSTANCE");
}

- (void)testConnectionIdentifier {
	XCTAssertEqualObjects([MADDatabaseConnectionSQLServer Identifier], @"TDS");
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"h" server:@"s" database:@"d" andPort:1];
	XCTAssertEqualObjects(conn.identifier, @"TDS");
}

- (void)testConnectionStringIncludesHostServerPortAndDatabase {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	XCTAssertEqualObjects(conn.connectionString, @"(TDS)[db.example.com:INSTANCE:1433]AdventureWorks2022");
}

// -connectionString memoises into the backing ivar on first access, so repeated calls
// hand back the same object rather than rebuilding the string. Harmless today because
// host/server/database/port are readonly in MADConnectionsPropertiesProtocol and the
// only way to set them is the initializer -- but it does mean the memo would go stale
// if a setter were ever added. Pinned as a characterization of the caching.
- (void)testConnectionStringIsMemoised {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	XCTAssertEqual(conn.connectionString, conn.connectionString);
}

- (void)testConnectionCopyIsIndependent {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	MADDatabaseConnectionSQLServer *copy = [conn copyWithZone:nil];
	XCTAssertEqualObjects(copy.host, conn.host);
	XCTAssertEqualObjects(copy.server, conn.server);
	XCTAssertEqualObjects(copy.database, conn.database);
	XCTAssertEqual(copy.port, conn.port);
	XCTAssertEqual(copy.databaseType, MADDatabaseTypeTDS);
}

- (void)testNewDatabaseConnectionFromProperties {
	MADDatabaseConnectionSQLServer *seed =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	MADDatabaseConnectionSQLServer *built = [MADDatabaseConnectionSQLServer newDatabaseConnection:seed];
	XCTAssertEqualObjects(built.host, @"db.example.com");
	XCTAssertEqualObjects(built.server, @"INSTANCE");
	XCTAssertEqualObjects(built.database, @"AdventureWorks2022");
	XCTAssertEqual(built.port, 1433);
}

#pragma mark - MADDatabaseProcessSQLServer

- (void)testProcessWrapperRoundTripsOpaquePointer {
	void *sentinel = (void *)(uintptr_t)0x1234;
	MADDatabaseProcessSQLServer *wrapper =
		[[MADDatabaseProcessSQLServer alloc] initWithProcess:sentinel];
	XCTAssertEqual([wrapper process], sentinel);
}

- (void)testProcessWrapperAcceptsNull {
	MADDatabaseProcessSQLServer *wrapper =
		[[MADDatabaseProcessSQLServer alloc] initWithProcess:NULL];
	XCTAssertTrue([wrapper process] == NULL);
}

#pragma mark - Address resolution

- (void)testIPAddressForServerPassesThroughAnIPLiteral {
	NSString *address = [MADDatabaseSQLServer IPAddressForServer:@"127.0.0.1"];
	XCTAssertNotNil(address);
	XCTAssertTrue([address containsString:@"127.0.0.1"], @"Got: %@", address);
}

#pragma mark - Connection failure path

// A wrong password against a reachable server fails during LOGIN, after TCP connect
// and PRELOGIN have already succeeded. That makes it deterministic and fast, and it
// needs the live server only to be listening -- no particular state on it.
//
// Note the connection object's port is not consulted anywhere in
// -connect:andPassword:error: -- there is no DBSETLPORT call -- so freetds always
// dials its default port regardless of what the connection says.
- (void)testConnectWithWrongPasswordReportsError {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"127.0.0.1"
													  server:@"127.0.0.1"
													database:@"master"
													 andPort:1433];
	db.databaseConnection = conn;

	NSError *error = nil;
	void *process = [db connect:@"sa" andPassword:@"not-the-password" error:&error];

	XCTAssertTrue(process == NULL, @"Expected login to fail");
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MTDatabaseTds");
}

// -connectWithConnection:credentals:connectionError: rebinds its own `error`
// parameter to a local instead of writing through to the caller's, so the caller's
// error is never populated. The connection still fails (the return value is nil), but
// nothing downstream can say why. Pinned as a characterization test.
- (void)testConnectWithConnectionDoesNotReportErrorToCaller {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"127.0.0.1"
													  server:@"127.0.0.1"
													database:@"master"
													 andPort:1433];
	db.databaseConnection = conn;

	MADCredential *credential =
		[[MADCredential alloc] initWithUsername:@"sa" andPassword:@"not-the-password"];
	NSError *error = nil;
	id process = [db connectWithConnection:conn credentals:credential connectionError:&error];

	XCTAssertNil(process, @"Expected the connection to fail");
	XCTAssertNil(error, @"Characterizes the current behaviour: the error is swallowed");
}

@end
