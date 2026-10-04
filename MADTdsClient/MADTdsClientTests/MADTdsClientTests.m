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
+ (MADDataType)dataTypeForSystemTypeId:(NSInteger)systemTypeId;
+ (NSString *)bracketedIdentifierFromName:(NSString *)name;
+ (NSString *)IPAddressForServer:(NSString *)server;
- (NSString *)shortAliasFromQualifiedTable:(NSString *)qualifiedName;
- (void *)connect:(NSString *)username andPassword:(NSString *)password error:(NSError * __autoreleasing *)error;
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

- (void)testDataTypeForNativeTypeMapsModernDateTimeFamily {
	// The post-2005 types were unmapped and fell through to MADDataTypeString.
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATETIME2],      MADDataTypeDateTime);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATETIMEOFFSET], MADDataTypeDateTime);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBBIGDATETIME],      MADDataTypeDateTime);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBDATE],             MADDataTypeDate);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATE],           MADDataTypeDate);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBTIME],             MADDataTypeTime);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMSTIME],           MADDataTypeTime);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBBIGTIME],          MADDataTypeTime);
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
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBMONEY4], MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBREAL],   MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBFLT8],   MADDataTypeFloat);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBFLTN],   MADDataTypeFloat);
}

- (void)testDataTypeForNativeTypeMapsNumericToDecimal {
	// DECIMAL and NUMERIC are the same SQL Server type, and the more common DECIMAL
	// spelling (106) used to have no case, so DECIMAL columns were typed as strings.
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBNUMERIC], MADDataTypeDecimal);
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForNativeType:SYBDECIMAL], MADDataTypeDecimal);
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

#pragma mark - +dataTypeForSystemTypeId:

// sys.columns.system_type_id is a different numbering scheme from the sybdb SYB* codes
// +dataTypeForNativeType: takes, and -fieldsForTable:connection:error: used to feed it
// to the latter. The two overlap only for the legacy types, so the mapping was right by
// coincidence where it was right at all.

- (void)testDataTypeForSystemTypeIdMapsIntegralTypes {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:48],  MADDataTypeInteger); // tinyint
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:52],  MADDataTypeInteger); // smallint
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:56],  MADDataTypeInteger); // int
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:127], MADDataTypeInteger); // bigint
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:104], MADDataTypeBit);     // bit
}

- (void)testDataTypeForSystemTypeIdMapsNumericTypes {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:106], MADDataTypeDecimal); // decimal
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:108], MADDataTypeDecimal); // numeric
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:59],  MADDataTypeFloat);   // real
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:62],  MADDataTypeFloat);   // float
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:60],  MADDataTypeFloat);   // money
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:122], MADDataTypeFloat);   // smallmoney
}

- (void)testDataTypeForSystemTypeIdMapsTemporalTypes {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:58], MADDataTypeDateTime); // smalldatetime
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:61], MADDataTypeDateTime); // datetime
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:42], MADDataTypeDateTime); // datetime2
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:43], MADDataTypeDateTime); // datetimeoffset
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:40], MADDataTypeDate);     // date
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:41], MADDataTypeTime);     // time
}

- (void)testDataTypeForSystemTypeIdMapsBinaryFamilyToBlob {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:34],  MADDataTypeBlob); // image
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:173], MADDataTypeBlob); // binary
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:165], MADDataTypeBlob); // varbinary
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:189], MADDataTypeBlob); // rowversion
}

- (void)testDataTypeForSystemTypeIdMapsCharacterFamilyToString {
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:175], MADDataTypeString); // char
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:167], MADDataTypeString); // varchar
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:239], MADDataTypeString); // nchar
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:231], MADDataTypeString); // nvarchar
	XCTAssertEqual([MADDatabaseSQLServer dataTypeForSystemTypeId:(NSInteger)99999], MADDataTypeString);
}

#pragma mark - Identifier quoting

- (void)testNewSafeQueryFieldBracketsTableAndField {
	XCTAssertEqualObjects([MADDatabaseSQLServer newSafeQueryField:@"emp_no" andTable:@"employees"],
						  @"[employees].[emp_no]");
}

// The table half now routes through the identifier splitter, so a schema-qualified
// table becomes [schema].[table] rather than one bracket pair containing a dot.
- (void)testNewSafeQueryFieldSplitsSchemaQualifiedTable {
	XCTAssertEqualObjects([MADDatabaseSQLServer newSafeQueryField:@"emp_no" andTable:@"dbo.employees"],
						  @"[dbo].[employees].[emp_no]");
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

// The base emits a bare '...' literal; T-SQL wants the N prefix so the value is nvarchar
// and a non-ASCII character is not put through the database's collation on the way in.  The
// escaping itself is the base's -- T-SQL doubles an interior quote -- and this pins that the
// override kept it rather than dropping it for a plain format.
- (void)testNewSafeLiteralIsANvarcharLiteral {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	XCTAssertEqualObjects([db newSafeLiteral:@"London"], @"N'London'");
	XCTAssertEqualObjects([db newSafeLiteral:@"O'Brien"], @"N'O''Brien'");
	XCTAssertEqualObjects([db newSafeLiteral:@"Ütrecht"], @"N'Ütrecht'");
	XCTAssertEqualObjects([db newSafeLiteral:nil], @"NULL");
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

// -connectWithConnection:credentals:connectionError: used to rebind its own `error`
// parameter to a local instead of writing through to the caller's, so a failed
// connection returned nil with nothing downstream able to say why. It now writes the
// underlying error through to the caller.
- (void)testConnectWithConnectionReportsErrorToCaller {
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
	XCTAssertNotNil(error, @"Expected the failure to be reported to the caller");
	XCTAssertEqualObjects(error.domain, @"MTDatabaseTds");
}

@end
