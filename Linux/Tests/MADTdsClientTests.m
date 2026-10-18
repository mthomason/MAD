//
//  MADTdsClientTests.m
//  Linux/Tests
//
//  Ported from MADTdsClientTests/MADTdsClientTests.m: the offline suite --
//  type mapping, identifier quoting, the SQL fragments, the connection value
//  object and the process wrapper.  Nothing here needs a SQL Server; the live
//  suite is MADTdsClientLiveTests.m.
//

#import "MADTestSupport.h"
#import <MADTdsClient/MADTdsClient.h>
#import <MADTds/sybdb.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADCredential.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADDatabaseConnection.h>

// MADDatabaseProcessSQLServer lives in the framework's Headers phase with
// project visibility, not public visibility, and the umbrella header does not
// re-export it -- the class is plumbing between MADDatabaseSQLServer and
// freetds, not API.  Redeclaring the two methods reaches it without widening
// the framework's public surface.
@interface MADDatabaseProcessSQLServer : NSObject
- (instancetype)initWithProcess:(void /* DBPROCESS */ *)process;
- (void /* DBPROCESS */ *)process NS_RETURNS_INNER_POINTER;
@end

// These selectors are implemented in MADDatabaseSQLServer.m but are not
// declared in any header the framework publishes.  Declaring them here lets
// the tests reach them without widening MADDatabaseSQLServer's public API.
@interface MADDatabaseSQLServer (MADTdsClientTestsInternal)
+ (MADDataType)dataTypeForNativeType:(NSInteger)nativeType;
+ (MADDataType)dataTypeForSystemTypeId:(NSInteger)systemTypeId;
+ (NSString *)bracketedIdentifierFromName:(NSString *)name;
+ (NSString *)IPAddressForServer:(NSString *)server;
- (NSString *)shortAliasFromQualifiedTable:(NSString *)qualifiedName;
- (void *)connect:(NSString *)username andPassword:(NSString *)password error:(NSError * __autoreleasing *)error;
@end

#pragma mark - MADDatabaseSQLServer identity

static void testDriverMetadata(void) {
	MAD_PASS_EQUAL([MADDatabaseSQLServer driverName], @"SQL Server / TDS", "the driver name");
	MAD_PASS_EQUAL([MADDatabaseSQLServer imageIconName], @"UIImageExportTypeSqlServer", "the icon name");
}

#pragma mark - +dataTypeForNativeType:

static void testDataTypeForNativeTypeMapsDateTimeFamily(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBDATETIMN] == MADDataTypeDateTime, "DATETIMN is a date/time");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBDATETIME] == MADDataTypeDateTime, "DATETIME is a date/time");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBDATETIME4] == MADDataTypeDateTime, "DATETIME4 is a date/time");
}

static void testDataTypeForNativeTypeMapsModernDateTimeFamily(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATETIME2] == MADDataTypeDateTime, "DATETIME2");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATETIMEOFFSET] == MADDataTypeDateTime, "DATETIMEOFFSET");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBBIGDATETIME] == MADDataTypeDateTime, "BIGDATETIME");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBDATE] == MADDataTypeDate, "DATE");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBMSDATE] == MADDataTypeDate, "MSDATE");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBTIME] == MADDataTypeTime, "TIME");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBMSTIME] == MADDataTypeTime, "MSTIME");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBBIGTIME] == MADDataTypeTime, "BIGTIME");
}

static void testDataTypeForNativeTypeMapsCharacterFamily(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBCHAR] == MADDataTypeString, "CHAR");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBVARCHAR] == MADDataTypeString, "VARCHAR");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBTEXT] == MADDataTypeString, "TEXT");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBNTEXT] == MADDataTypeString, "NTEXT");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBNVARCHAR] == MADDataTypeString, "NVARCHAR");
}

static void testDataTypeForNativeTypeMapsBitFamily(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBBIT] == MADDataTypeBit, "BIT");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBBITN] == MADDataTypeBit, "BITN");
}

static void testDataTypeForNativeTypeMapsAllIntegerWidthsToInteger(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBINT1] == MADDataTypeInteger, "INT1");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBINT2] == MADDataTypeInteger, "INT2");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBINT4] == MADDataTypeInteger, "INT4");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBINT8] == MADDataTypeInteger, "INT8");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBINTN] == MADDataTypeInteger, "INTN");
}

static void testDataTypeForNativeTypeMapsMoneyAndFloatingPointToFloat(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBMONEY] == MADDataTypeFloat, "MONEY");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBMONEYN] == MADDataTypeFloat, "MONEYN");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBMONEY4] == MADDataTypeFloat, "MONEY4");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBREAL] == MADDataTypeFloat, "REAL");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBFLT8] == MADDataTypeFloat, "FLT8");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBFLTN] == MADDataTypeFloat, "FLTN");
}

static void testDataTypeForNativeTypeMapsNumericToDecimal(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBNUMERIC] == MADDataTypeDecimal, "NUMERIC");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBDECIMAL] == MADDataTypeDecimal, "DECIMAL");
}

static void testDataTypeForNativeTypeMapsBinaryFamilyToBlob(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBIMAGE] == MADDataTypeBlob, "IMAGE");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBBINARY] == MADDataTypeBlob, "BINARY");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBVOID] == MADDataTypeBlob, "VOID");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:SYBVARBINARY] == MADDataTypeBlob, "VARBINARY");
}

static void testDataTypeForNativeTypeDefaultsToIntegerForUnknownCodes(void) {
	// Anything unrecognised falls through to MADDataTypeString.
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:(NSInteger)-1] == MADDataTypeString, "minus one maps to String");
	MAD_PASS([MADDatabaseSQLServer dataTypeForNativeType:(NSInteger)99999] == MADDataTypeString, "99999 maps to String");
}

#pragma mark - +dataTypeForSystemTypeId:

static void testDataTypeForSystemTypeIdMapsIntegralTypes(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:48] == MADDataTypeInteger, "tinyint");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:52] == MADDataTypeInteger, "smallint");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:56] == MADDataTypeInteger, "int");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:127] == MADDataTypeInteger, "bigint");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:104] == MADDataTypeBit, "bit");
}

static void testDataTypeForSystemTypeIdMapsNumericTypes(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:106] == MADDataTypeDecimal, "decimal");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:108] == MADDataTypeDecimal, "numeric");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:59] == MADDataTypeFloat, "real");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:62] == MADDataTypeFloat, "float");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:60] == MADDataTypeFloat, "money");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:122] == MADDataTypeFloat, "smallmoney");
}

static void testDataTypeForSystemTypeIdMapsTemporalTypes(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:58] == MADDataTypeDateTime, "smalldatetime");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:61] == MADDataTypeDateTime, "datetime");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:42] == MADDataTypeDateTime, "datetime2");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:43] == MADDataTypeDateTime, "datetimeoffset");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:40] == MADDataTypeDate, "date");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:41] == MADDataTypeTime, "time");
}

static void testDataTypeForSystemTypeIdMapsBinaryFamilyToBlob(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:34] == MADDataTypeBlob, "image");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:173] == MADDataTypeBlob, "binary");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:165] == MADDataTypeBlob, "varbinary");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:189] == MADDataTypeBlob, "rowversion");
}

static void testDataTypeForSystemTypeIdMapsCharacterFamilyToString(void) {
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:175] == MADDataTypeString, "char");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:167] == MADDataTypeString, "varchar");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:239] == MADDataTypeString, "nchar");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:231] == MADDataTypeString, "nvarchar");
	MAD_PASS([MADDatabaseSQLServer dataTypeForSystemTypeId:(NSInteger)99999] == MADDataTypeString, "an unknown id");
}

#pragma mark - Identifier quoting

static void testNewSafeQueryFieldBracketsTableAndField(void) {
	MAD_PASS_EQUAL([MADDatabaseSQLServer newSafeQueryField:@"emp_no" andTable:@"employees"],
				   @"[employees].[emp_no]", "the table and field are bracketed");
}

static void testNewSafeQueryFieldSplitsSchemaQualifiedTable(void) {
	MAD_PASS_EQUAL([MADDatabaseSQLServer newSafeQueryField:@"emp_no" andTable:@"dbo.employees"],
				   @"[dbo].[employees].[emp_no]", "a schema-qualified table splits on its dot");
}

static void testBracketedIdentifierFromNameSplitsOnDots(void) {
	MAD_PASS_EQUAL([MADDatabaseSQLServer bracketedIdentifierFromName:@"dbo.employees"],
				   @"[dbo].[employees]", "a qualified name splits");
	MAD_PASS_EQUAL([MADDatabaseSQLServer bracketedIdentifierFromName:@"employees"],
				   @"[employees]", "a bare name brackets");
}

static void testBracketedIdentifierFromNameDropsEmptyComponents(void) {
	MAD_PASS_EQUAL([MADDatabaseSQLServer bracketedIdentifierFromName:@"a..b"], @"[a].[b]",
				   "empty components are dropped");
}

static void testNewSafeIdentifierBracketsBareName(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db newSafeIdentifier:@"employees"], @"[employees]", "a bare name brackets");
}

static void testNewSafeIdentifierSplitsQualifiedName(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db newSafeIdentifier:@"dbo.employees"], @"[dbo].[employees]", "a qualified name splits");
}

static void testQueryKeyMatchesNewSafeQueryField(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db queryKey:@"salary" table:@"salaries"],
				   [MADDatabaseSQLServer newSafeQueryField:@"salary" andTable:@"salaries"],
				   "the query key agrees with the safe field");
	MAD_PASS_EQUAL([db queryKey:@"salary" table:@"salaries"], @"[salaries].[salary]", "the query key shape");
}

static void testFieldAliasLeavesTableNameUnbracketed(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db fieldAliasForField:@"emp_no" withSafeTableName:@"employees"],
				   @"employees.[emp_no]", "a bare table name is not re-bracketed");
}

static void testFieldAliasWithBracketedTableName(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db fieldAliasForField:@"emp_no" withSafeTableName:@"[dbo].[employees]"],
				   @"[dbo].[employees].[emp_no]", "a bracketed table name passes through");
}

static void testShortAliasFromQualifiedTableTakesLastComponent(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db shortAliasFromQualifiedTable:@"dbo.employees"], @"employees", "the last component");
	MAD_PASS_EQUAL([db shortAliasFromQualifiedTable:@"[dbo].[employees]"], @"[employees]", "the last bracketed component");
	MAD_PASS_EQUAL([db shortAliasFromQualifiedTable:@"employees"], @"employees", "a bare name is its own alias");
}

#pragma mark - SQL fragments

static void testAggregateLengthFunctionIsDataLength(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db sqlAggregateFunctionLength], @"DATALENGTH", "SQL Server spells length DATALENGTH");
}

static void testSelectPart(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db selectPart], @"SELECT\n", "the select part");
}

static void testSelectPartWithLimitedResultsAppendsTop(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db selectPartWithLimitedResults:10], @"SELECT\nTOP 10\n", "the row cap is a TOP clause");
}

static void testSelectPartWithUnlimitedResultsOmitsTop(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db selectPartWithLimitedResults:NSUIntegerMax], @"SELECT\n", "the maximum means no TOP");
	MAD_PASS_EQUAL([db selectPartWithLimitedResults:0], @"SELECT\n", "zero means no TOP");
}

static void testSqlLimitClausesAreEmpty(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db sqlLimitClause], @"", "no LIMIT clause");
	MAD_PASS_EQUAL([db sqlLimitClause:10], @"", "no LIMIT clause even with a cap");
}

static void testSqlRangeClauseUsesOffsetFetch(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db sqlRangeClauseWithLimit:10 offset:20], @"OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY",
				   "the range clause is OFFSET/FETCH");
}

static void testDefaultRequiredOrderByClause(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db sqlDefaultRequiredOrderByClause], @"ORDER BY (SELECT NULL)",
				   "the ORDER BY OFFSET/FETCH requires");
}

static void testTableAliasConnector(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db tableAliasConnector], @" AS ", "the alias connector");
}

static void testSampleDataQueryShape(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	NSString *sql = [db sqlSampleDataForField:@"emp_no" andTable:@"employees"];

	MAD_PASS([sql hasPrefix:@"SELECT DISTINCT TOP 511 "], "the statement opens with DISTINCT TOP 511");
	MAD_PASS([sql containsString:@"[employees].[emp_no]"], "the field is bracketed");
	MAD_PASS([sql containsString:MADSqlTextFromPart], "the FROM part is the base's");
	MAD_PASS([sql containsString:@"[employees]"], "the table is bracketed");
	MAD_PASS(![sql containsString:@"LIMIT"], "no LIMIT survives into T-SQL");
	MAD_PASS(![sql containsString:@"DATALENGTH"], "the base's aggregate spelling is not used");
}

static void testNewSafeLiteralIsANvarcharLiteral(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MAD_PASS_EQUAL([db newSafeLiteral:@"London"], @"N'London'", "a plain value gets the N prefix");
	MAD_PASS_EQUAL([db newSafeLiteral:@"O'Brien"], @"N'O''Brien'", "an interior quote is doubled");
	MAD_PASS_EQUAL([db newSafeLiteral:@"Ütrecht"], @"N'Ütrecht'", "a non-ASCII value stays");
	MAD_PASS_EQUAL([db newSafeLiteral:nil], @"NULL", "nil literalises as NULL");
}

#pragma mark - MADDatabaseConnectionSQLServer

static void testConnectionInitializationStoresProperties(void) {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	MAD_PASS_EQUAL(conn.host, @"db.example.com", "the host is stored");
	MAD_PASS_EQUAL(conn.server, @"INSTANCE", "the server is stored");
	MAD_PASS_EQUAL(conn.database, @"AdventureWorks2022", "the database is stored");
	MAD_PASS(conn.port == 1433, "the port is stored");
	MAD_PASS(conn.databaseType == MADDatabaseTypeTDS, "the type is TDS");
	MAD_PASS(conn.requiresCredentials, "a TDS connection requires credentials");
}

static void testConnectionServerIsTrimmedButHostIsNot(void) {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"  db.example.com \n"
													  server:@"  INSTANCE \n"
													database:@"d"
													 andPort:1];
	MAD_PASS_EQUAL(conn.host, @"  db.example.com \n", "the host is not trimmed");
	MAD_PASS_EQUAL(conn.server, @"INSTANCE", "the server is trimmed");
}

static void testConnectionIdentifier(void) {
	MAD_PASS_EQUAL([MADDatabaseConnectionSQLServer Identifier], @"TDS", "the class identifier");
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"h" server:@"s" database:@"d" andPort:1];
	MAD_PASS_EQUAL(conn.identifier, @"TDS", "the instance identifier");
}

static void testConnectionStringIncludesHostServerPortAndDatabase(void) {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	MAD_PASS_EQUAL(conn.connectionString, @"(TDS)[db.example.com:INSTANCE:1433]AdventureWorks2022",
				   "the connection string carries host, server, port and database");
}

static void testConnectionStringIsMemoised(void) {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	MAD_PASS(conn.connectionString == conn.connectionString, "repeated reads hand back the same object");
}

static void testConnectionCopyIsIndependent(void) {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	MADDatabaseConnectionSQLServer *copy = [conn copyWithZone:nil];
	MAD_PASS_EQUAL(copy.host, conn.host, "the copy carries the host");
	MAD_PASS_EQUAL(copy.server, conn.server, "the copy carries the server");
	MAD_PASS_EQUAL(copy.database, conn.database, "the copy carries the database");
	MAD_PASS(copy.port == conn.port, "the copy carries the port");
	MAD_PASS(copy.databaseType == MADDatabaseTypeTDS, "the copy carries the type");
}

static void testConnectionCodingRoundTripCarriesTheConnectionState(void) {
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];

#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:conn requiringSecureCoding:YES error:NULL];
	MADDatabaseConnectionSQLServer *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseConnectionSQLServer class] fromData:data error:NULL];
#else
	// GNUstep has no secure-coding path (the toolchain probe records the need);
	// the round trip is asserted on the permissive path it does have.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:conn requiringSecureCoding:NO error:NULL];
	MADDatabaseConnectionSQLServer *decoded = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
#endif
	MAD_PASS(decoded != nil, "the connection round trips");
	MAD_PASS_EQUAL(decoded.host, @"db.example.com", "the host survives");
	MAD_PASS_EQUAL(decoded.server, @"INSTANCE", "the server survives");
	MAD_PASS_EQUAL(decoded.database, @"AdventureWorks2022", "the database survives");
	MAD_PASS(decoded.port == 1433, "the port survives");
	MAD_PASS(decoded.databaseType == MADDatabaseTypeTDS, "the type survives");
	MAD_PASS_EQUAL(decoded.connectionString, @"(TDS)[db.example.com:INSTANCE:1433]AdventureWorks2022",
				   "the connection string survives");
}

static void testNewDatabaseConnectionFromProperties(void) {
	MADDatabaseConnectionSQLServer *seed =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"db.example.com"
													  server:@"INSTANCE"
													database:@"AdventureWorks2022"
													 andPort:1433];
	MADDatabaseConnectionSQLServer *built = [MADDatabaseConnectionSQLServer newDatabaseConnection:seed];
	MAD_PASS_EQUAL(built.host, @"db.example.com", "the host is copied");
	MAD_PASS_EQUAL(built.server, @"INSTANCE", "the server is copied");
	MAD_PASS_EQUAL(built.database, @"AdventureWorks2022", "the database is copied");
	MAD_PASS(built.port == 1433, "the port is copied");
}

#pragma mark - MADDatabaseProcessSQLServer

static void testProcessWrapperRoundTripsOpaquePointer(void) {
	void *sentinel = (void *)(uintptr_t)0x1234;
	MADDatabaseProcessSQLServer *wrapper =
		[[MADDatabaseProcessSQLServer alloc] initWithProcess:sentinel];
	MAD_PASS([wrapper process] == sentinel, "the opaque pointer round trips");
}

static void testProcessWrapperAcceptsNull(void) {
	MADDatabaseProcessSQLServer *wrapper =
		[[MADDatabaseProcessSQLServer alloc] initWithProcess:NULL];
	MAD_PASS([wrapper process] == NULL, "a NULL pointer is accepted");
}

#pragma mark - Address resolution

static void testIPAddressForServerPassesThroughAnIPLiteral(void) {
	NSString *address = [MADDatabaseSQLServer IPAddressForServer:@"127.0.0.1"];
	MAD_PASS(address != nil, "the literal resolves to an address");
	MAD_PASS([address containsString:@"127.0.0.1"], "the literal comes back");
}

#pragma mark - Connection failure path

// A wrong password against a reachable server fails during LOGIN, after TCP
// connect and PRELOGIN have already succeeded.  With no server listening the
// TCP connect itself fails; either way the caller must see nil and an error
// in this framework's domain, which is what the pair below pins.
static void testConnectWithWrongPasswordReportsError(void) {
	MADDatabaseSQLServer *db = [[MADDatabaseSQLServer alloc] init];
	MADDatabaseConnectionSQLServer *conn =
		[[MADDatabaseConnectionSQLServer alloc] initWithHost:@"127.0.0.1"
													  server:@"127.0.0.1"
													database:@"master"
													 andPort:1433];
	db.databaseConnection = conn;

	NSError *error = nil;
	void *process = [db connect:@"sa" andPassword:@"not-the-password" error:&error];

	MAD_PASS(process == NULL, "the connection attempt fails");
	MAD_PASS(error != nil, "the failure is reported");
	MAD_PASS_EQUAL(error.domain, @"MTDatabaseTds", "the error is in the TDS domain");
}

static void testConnectWithConnectionReportsErrorToCaller(void) {
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

	MAD_PASS(process == nil, "the connection attempt fails");
	MAD_PASS(error != nil, "the failure is written through to the caller");
	MAD_PASS_EQUAL(error.domain, @"MTDatabaseTds", "the error is in the TDS domain");
}

MAD_TEST_MAIN("MADTdsClientTests",
	MAD_TEST(testDriverMetadata),
	MAD_TEST(testDataTypeForNativeTypeMapsDateTimeFamily),
	MAD_TEST(testDataTypeForNativeTypeMapsModernDateTimeFamily),
	MAD_TEST(testDataTypeForNativeTypeMapsCharacterFamily),
	MAD_TEST(testDataTypeForNativeTypeMapsBitFamily),
	MAD_TEST(testDataTypeForNativeTypeMapsAllIntegerWidthsToInteger),
	MAD_TEST(testDataTypeForNativeTypeMapsMoneyAndFloatingPointToFloat),
	MAD_TEST(testDataTypeForNativeTypeMapsNumericToDecimal),
	MAD_TEST(testDataTypeForNativeTypeMapsBinaryFamilyToBlob),
	MAD_TEST(testDataTypeForNativeTypeDefaultsToIntegerForUnknownCodes),
	MAD_TEST(testDataTypeForSystemTypeIdMapsIntegralTypes),
	MAD_TEST(testDataTypeForSystemTypeIdMapsNumericTypes),
	MAD_TEST(testDataTypeForSystemTypeIdMapsTemporalTypes),
	MAD_TEST(testDataTypeForSystemTypeIdMapsBinaryFamilyToBlob),
	MAD_TEST(testDataTypeForSystemTypeIdMapsCharacterFamilyToString),
	MAD_TEST(testNewSafeQueryFieldBracketsTableAndField),
	MAD_TEST(testNewSafeQueryFieldSplitsSchemaQualifiedTable),
	MAD_TEST(testBracketedIdentifierFromNameSplitsOnDots),
	MAD_TEST(testBracketedIdentifierFromNameDropsEmptyComponents),
	MAD_TEST(testNewSafeIdentifierBracketsBareName),
	MAD_TEST(testNewSafeIdentifierSplitsQualifiedName),
	MAD_TEST(testQueryKeyMatchesNewSafeQueryField),
	MAD_TEST(testFieldAliasLeavesTableNameUnbracketed),
	MAD_TEST(testFieldAliasWithBracketedTableName),
	MAD_TEST(testShortAliasFromQualifiedTableTakesLastComponent),
	MAD_TEST(testAggregateLengthFunctionIsDataLength),
	MAD_TEST(testSelectPart),
	MAD_TEST(testSelectPartWithLimitedResultsAppendsTop),
	MAD_TEST(testSelectPartWithUnlimitedResultsOmitsTop),
	MAD_TEST(testSqlLimitClausesAreEmpty),
	MAD_TEST(testSqlRangeClauseUsesOffsetFetch),
	MAD_TEST(testDefaultRequiredOrderByClause),
	MAD_TEST(testTableAliasConnector),
	MAD_TEST(testSampleDataQueryShape),
	MAD_TEST(testNewSafeLiteralIsANvarcharLiteral),
	MAD_TEST(testConnectionInitializationStoresProperties),
	MAD_TEST(testConnectionServerIsTrimmedButHostIsNot),
	MAD_TEST(testConnectionIdentifier),
	MAD_TEST(testConnectionStringIncludesHostServerPortAndDatabase),
	MAD_TEST(testConnectionStringIsMemoised),
	MAD_TEST(testConnectionCopyIsIndependent),
	MAD_TEST(testConnectionCodingRoundTripCarriesTheConnectionState),
	MAD_TEST(testNewDatabaseConnectionFromProperties),
	MAD_TEST(testProcessWrapperRoundTripsOpaquePointer),
	MAD_TEST(testProcessWrapperAcceptsNull),
	MAD_TEST(testIPAddressForServerPassesThroughAnIPLiteral),
	MAD_TEST(testConnectWithWrongPasswordReportsError),
	MAD_TEST(testConnectWithConnectionReportsErrorToCaller));
