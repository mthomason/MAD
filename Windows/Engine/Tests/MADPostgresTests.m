//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADPostgresTests.m
//  Linux/Tests
//
//  Ported from MADPostgresTests/MADPostgresTests.m: offline unit tests for
//  MADPostgres.  Nothing in this file contacts a running server -- the
//  connection-failure path proves the failure is reported cleanly against a
//  dead port.  The tests that require the local PostgreSQL instance described
//  in docs/project/DEVELOPER.md are in MADPostgresLiveTests.m.
//

#import "MADTestSupport.h"
#include <math.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADCredential.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADQuery.h>

#import <MADPostgres/MADDatabasePostgres.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>
#import <MADPostgres/MADPostgresConnection.h>
#import <MADPostgres/MADDataTypePostgres.h>

@interface MADDatabasePostgres (MADPostgresTestsInternal)
+ (NSError *)errorCouldNotGetCredientals;
- (NSString *)domain;
@end

#pragma mark - Driver identity and registry

static void testDriverIdentityStrings(void) {
	MAD_PASS_EQUAL([MADDatabasePostgres driverName], @"PostgreSQL", "driverName is PostgreSQL");
	MAD_PASS_EQUAL([MADDatabasePostgres imageIconName], @"UIImageExportTypePostgres", "imageIconName is UIImageExportTypePostgres");

	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	db.databaseConnection = [MADDatabaseConnectionPostgres connectionWithHost:@"localhost"
																  andDatabase:@"chinook"];
	MAD_PASS_EQUAL([db identifier], @"PostgreSQL", "identifier is PostgreSQL");
	MAD_PASS_EQUAL([db domain], @"MADDatabasePostgres", "domain is MADDatabasePostgres");
}

static void testErrorCouldNotGetCredientalsShape(void) {
	NSError *error = [MADDatabasePostgres errorCouldNotGetCredientals];
	MAD_PASS_EQUAL(error.domain, @"MADDatabasePostgres", "error domain is MADDatabasePostgres");
	MAD_PASS(error.code == 43421, "error code is 43421");
	MAD_PASS(error.localizedDescription != nil, "localizedDescription is set");
	MAD_PASS(error.localizedFailureReason != nil, "localizedFailureReason is set");
}

static void testConnectionDriverMetadataAndRegistration(void) {
	MAD_PASS([MADDatabaseConnectionPostgres databaseType] == MADDatabaseTypePostgres, "databaseType is Postgres");
	MAD_PASS([MADDatabaseConnectionPostgres databaseClass] == [MADDatabasePostgres class], "databaseClass is MADDatabasePostgres");
	MAD_PASS_EQUAL([MADDatabaseConnectionPostgres Identifier], @"PostgreSQL", "Identifier is PostgreSQL");

	MAD_PASS([MADDatabaseDriverRegistry driverClassForType:MADDatabaseTypePostgres] == [MADDatabaseConnectionPostgres class],
			 "MADDatabaseDriverRegistry resolves MADDatabaseTypePostgres");
	MAD_PASS([[MADDatabaseDriverRegistry registeredDriverClasses] containsObject:[MADDatabaseConnectionPostgres class]],
			 "registeredDriverClasses contains MADDatabaseConnectionPostgres");
}

#pragma mark - MADDatabaseConnectionPostgres

static void testConnectionStoresHostPortAndDatabase(void) {
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:@"db.example.com"
													 port:15432
											  andDatabase:@"analytics"];

	MAD_PASS(conn != nil, "connection created");
	MAD_PASS(conn.databaseType == MADDatabaseTypePostgres, "databaseType is Postgres");
	MAD_PASS(conn.requiresCredentials, "requiresCredentials is YES");
	MAD_PASS_EQUAL(conn.identifier, @"PostgreSQL", "identifier is PostgreSQL");
	MAD_PASS_EQUAL(conn.host, @"db.example.com", "host is stored");
	MAD_PASS_EQUAL(conn.server, @"db.example.com", "server matches host");
	MAD_PASS(conn.port == 15432, "port is stored");
	MAD_PASS_EQUAL(conn.database, @"analytics", "database is stored");
	MAD_PASS_EQUAL(conn.connectionString, @"(PostgreSQL)[db.example.com:15432]analytics", "connectionString is formatted");
}

static void testConnectionDefaultsPortTo5432(void) {
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:@"localhost"
											  andDatabase:@"chinook"];

	MAD_PASS(conn != nil, "connection created");
	MAD_PASS(conn.port == 5432, "default port is 5432");

	MADDatabaseConnectionPostgres *zeroPort =
		[[MADDatabaseConnectionPostgres alloc] initWithHost:@"localhost"
													   port:0
												andDatabase:@"chinook"];
	MAD_PASS(zeroPort.port == 5432, "port 0 defaults to 5432");
}

static void testConnectionServerPropertyIsTrimmed(void) {
	MADDatabaseConnectionPostgres *conn =
		[[MADDatabaseConnectionPostgres alloc] initWithHost:@"  db.local \n"
												   database:@"chinook"
													andPort:5432];

	MAD_PASS_EQUAL(conn.server, @"db.local", "server trims whitespace and newlines");
}

static void testNewDatabaseConnectionFromPropertiesAndFactory(void) {
	MADDatabaseConnectionPostgres *seed =
		[[MADDatabaseConnectionPostgres alloc] initWithHost:@"db.example.com"
												   database:@"chinook"
													andPort:5432];
	MADDatabaseConnectionPostgres *built = [MADDatabaseConnectionPostgres newDatabaseConnection:seed];
	MAD_PASS_EQUAL(built.host, @"db.example.com", "built host matches");
	MAD_PASS_EQUAL(built.database, @"chinook", "built database matches");
	MAD_PASS(built.port == 5432, "built port matches");

	MADDatabaseConnectionPostgres *fromDriverHook =
		[MADDatabaseConnectionPostgres newDatabaseConnectionWithHost:@"db.example.com"
															database:@"chinook"
																port:0];
	MAD_PASS_EQUAL(fromDriverHook.host, @"db.example.com", "driver hook host matches");
	MAD_PASS_EQUAL(fromDriverHook.database, @"chinook", "driver hook database matches");
	MAD_PASS(fromDriverHook.port == 5432, "driver hook port 0 defaults to 5432");
}

static void testConnectionCopyAndSecureCodingRoundTrip(void) {
	MADDatabaseConnectionPostgres *original =
		[MADDatabaseConnectionPostgres connectionWithHost:@"pg.internal"
													 port:5433
											  andDatabase:@"warehouse"];

	MADDatabaseConnectionPostgres *copied = [original copy];
	MAD_PASS(copied != nil, "copy succeeded");
	MAD_PASS(copied != original, "copy is a distinct instance");
	MAD_PASS(copied.databaseType == MADDatabaseTypePostgres, "copy carries databaseType");
	MAD_PASS_EQUAL(copied.host, @"pg.internal", "copy carries host");
	MAD_PASS(copied.port == 5433, "copy carries port");
	MAD_PASS_EQUAL(copied.database, @"warehouse", "copy carries database");
	MAD_PASS_EQUAL(copied.connectionString, @"(PostgreSQL)[pg.internal:5433]warehouse", "copy carries connectionString");

	MAD_PASS([MADDatabaseConnectionPostgres supportsSecureCoding], "supportsSecureCoding is YES");
#if __APPLE__
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original requiringSecureCoding:YES error:NULL];
	MADDatabaseConnectionPostgres *decoded =
		[NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseConnectionPostgres class] fromData:data error:NULL];
#else
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original requiringSecureCoding:NO error:NULL];
	MADDatabaseConnectionPostgres *decoded =
		[NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:NULL];
#endif
	MAD_PASS(decoded != nil, "decoded connection is not nil");
	MAD_PASS(decoded.databaseType == MADDatabaseTypePostgres, "decoded databaseType is Postgres");
	MAD_PASS_EQUAL(decoded.host, @"pg.internal", "decoded host survives");
	MAD_PASS(decoded.port == 5433, "decoded port survives");
	MAD_PASS_EQUAL(decoded.database, @"warehouse", "decoded database survives");
	MAD_PASS_EQUAL(decoded.connectionString, @"(PostgreSQL)[pg.internal:5433]warehouse", "decoded connectionString survives");
}

#pragma mark - SQL dialect and identifier/literal quoting

static void testIdentifierQuotingUsesANSIDoubleQuotes(void) {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	MAD_PASS_EQUAL([MADDatabasePostgres identifierQuoteCharacters], @"\"\"", "identifierQuoteCharacters is double quotes");
	MAD_PASS_EQUAL([MADDatabasePostgres newSafeIdentifier:@"Artist"], @"\"Artist\"", "class newSafeIdentifier quotes identifier");
	MAD_PASS_EQUAL([db newSafeIdentifier:@"Artist"], @"\"Artist\"", "instance newSafeIdentifier quotes identifier");
	MAD_PASS_EQUAL([MADDatabasePostgres newSafeIdentifier:@"a\"b"], @"\"a\"\"b\"", "embedded quote is doubled");
	MAD_PASS_EQUAL([MADDatabasePostgres newSafeIdentifier:@"sales.orders"], @"\"sales\".\"orders\"", "schema-qualified identifier quotes each part");
	MAD_PASS_EQUAL([db newSafeIdentifier:@"sales.orders"], @"\"sales\".\"orders\"", "instance schema-qualified identifier quotes each part");
	MAD_PASS_EQUAL([MADDatabasePostgres newSafeIdentifier:@"sales..orders"], @"\"sales\".\"orders\"", "empty dot component is skipped");
	MAD_PASS_EQUAL([MADDatabasePostgres newSafeIdentifier:@""], @"", "empty identifier returns empty string");
	MAD_PASS_EQUAL([MADDatabasePostgres newSafeIdentifier:nil], @"", "nil identifier returns empty string");
}

static void testSafeQueryFieldAndTable(void) {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	MAD_PASS_EQUAL([MADDatabasePostgres newSafeQueryField:@"Name" andTable:@"Artist"],
				   @"\"Artist\".\"Name\"", "class newSafeQueryField quotes table and field");
	MAD_PASS_EQUAL([db queryKey:@"Name" table:@"Artist"],
				   @"\"Artist\".\"Name\"", "instance queryKey quotes table and field");
	MAD_PASS_EQUAL([MADDatabasePostgres newSafeQueryField:@"total" andTable:@"sales.orders"],
				   @"\"sales\".\"orders\".\"total\"", "class newSafeQueryField quotes schema.table.field");
	MAD_PASS_EQUAL([db queryKey:@"total" table:@"sales.orders"],
				   @"\"sales\".\"orders\".\"total\"", "instance queryKey quotes schema.table.field");
}

static void testSafeLiteralQuotingOffline(void) {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	MAD_PASS_EQUAL([db newSafeLiteral:@"hello"], @"'hello'", "plain literal is single-quoted");
	MAD_PASS_EQUAL([db newSafeLiteral:@"O'Brien"], @"'O''Brien'", "embedded single quote is doubled");
	MAD_PASS_EQUAL([db newSafeLiteral:@""], @"''", "empty string literal is ''");
	MAD_PASS_EQUAL([db newSafeLiteral:nil], @"NULL", "nil literal is NULL");
}

static void testSQLDialectHooks(void) {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	MAD_PASS_EQUAL([db tableAliasConnector], @" AS ", "tableAliasConnector is AS");
	MAD_PASS_EQUAL([db sqlLimitClause:25], @"\nLIMIT 25", "sqlLimitClause formats LIMIT");
	MAD_PASS_EQUAL([db sqlLimitClause:0], @"", "sqlLimitClause 0 is empty");
	MAD_PASS_EQUAL([db sqlLimitClause:NSUIntegerMax], @"", "sqlLimitClause NSUIntegerMax is empty");
	MAD_PASS_EQUAL([db sqlRangeClauseWithLimit:25 offset:50], @"LIMIT 25 OFFSET 50", "sqlRangeClauseWithLimit formats LIMIT OFFSET");
	MAD_PASS_EQUAL([db sqlAggregateFunctionLength], @"LENGTH", "sqlAggregateFunctionLength is LENGTH");
}

#pragma mark - PostgreSQL OID and type name mapping

static void testPostgresOIDMapping(void) {
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:BOOLOID] == MADDataTypeBit, "BOOLOID is Bit");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:INT2OID] == MADDataTypeInteger, "INT2OID is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:INT4OID] == MADDataTypeInteger, "INT4OID is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:INT8OID] == MADDataTypeInteger, "INT8OID is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:OIDOID] == MADDataTypeInteger, "OIDOID is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:FLOAT4OID] == MADDataTypeFloat, "FLOAT4OID is Float");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:FLOAT8OID] == MADDataTypeFloat, "FLOAT8OID is Float");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:CASHOID] == MADDataTypeFloat, "CASHOID is Float");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:NUMERICOID] == MADDataTypeDecimal, "NUMERICOID is Decimal");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:DATEOID] == MADDataTypeDate, "DATEOID is Date");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:TIMEOID] == MADDataTypeTime, "TIMEOID is Time");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:TIMETZOID] == MADDataTypeTime, "TIMETZOID is Time");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:TIMESTAMPOID] == MADDataTypeDateTime, "TIMESTAMPOID is DateTime");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:TIMESTAMPTZOID] == MADDataTypeDateTime, "TIMESTAMPTZOID is DateTime");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:BYTEAOID] == MADDataTypeBlob, "BYTEAOID is Blob");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:VARCHAROID] == MADDataTypeString, "VARCHAROID is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:TEXTOID] == MADDataTypeString, "TEXTOID is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:BPCHAROID] == MADDataTypeString, "BPCHAROID is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:UUIDOID] == MADDataTypeString, "UUIDOID is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:JSONOID] == MADDataTypeString, "JSONOID is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:JSONBOID] == MADDataTypeString, "JSONBOID is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresOID:999999U] == MADDataTypeString, "unknown OID falls back to String");
}

static void testPostgresTypeNameMapping(void) {
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"boolean"] == MADDataTypeBit, "boolean is Bit");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"BOOL"] == MADDataTypeBit, "BOOL is Bit");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"smallint"] == MADDataTypeInteger, "smallint is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"integer"] == MADDataTypeInteger, "integer is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"bigint"] == MADDataTypeInteger, "bigint is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"int4"] == MADDataTypeInteger, "int4 is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"serial"] == MADDataTypeInteger, "serial is Integer");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"real"] == MADDataTypeFloat, "real is Float");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"double precision"] == MADDataTypeFloat, "double precision is Float");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"money"] == MADDataTypeFloat, "money is Float");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"numeric"] == MADDataTypeDecimal, "numeric is Decimal");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"decimal"] == MADDataTypeDecimal, "decimal is Decimal");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"date"] == MADDataTypeDate, "date is Date");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"time without time zone"] == MADDataTypeTime, "time without tz is Time");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"time with time zone"] == MADDataTypeTime, "time with tz is Time");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"timestamp without time zone"] == MADDataTypeDateTime, "timestamp without tz is DateTime");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"timestamp with time zone"] == MADDataTypeDateTime, "timestamp with tz is DateTime");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"bytea"] == MADDataTypeBlob, "bytea is Blob");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"character varying"] == MADDataTypeString, "character varying is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"text"] == MADDataTypeString, "text is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"uuid"] == MADDataTypeString, "uuid is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"jsonb"] == MADDataTypeString, "jsonb is String");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:nil] == MADDataTypeUnknown, "nil type name is Unknown");
	MAD_PASS([MADDataTypePostgres madDataTypeFromPostgresTypeName:@""] == MADDataTypeUnknown, "empty type name is Unknown");
}

#pragma mark - Cell value parsing

static void testObjectValueConversionCoversAllDataTypes(void) {
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:NULL isNull:YES dataType:MADDataTypeString],
				   [NSNull null], "NULL cstring is NSNull");
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"ignored" isNull:YES dataType:MADDataTypeInteger],
				   [NSNull null], "isNull YES is NSNull");

	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"t" isNull:NO dataType:MADDataTypeBit], @YES, "'t' is YES");
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"true" isNull:NO dataType:MADDataTypeBit], @YES, "'true' is YES");
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"1" isNull:NO dataType:MADDataTypeBit], @YES, "'1' is YES");
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"f" isNull:NO dataType:MADDataTypeBit], @NO, "'f' is NO");
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"0" isNull:NO dataType:MADDataTypeBit], @NO, "'0' is NO");

	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"42" isNull:NO dataType:MADDataTypeInteger], @(42LL), "42 is @(42LL)");
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"-9000" isNull:NO dataType:MADDataTypeInteger], @(-9000LL), "-9000 is @(-9000LL)");

	NSNumber *floatVal = [MADDatabasePostgres objectValueForCString:"3.25" isNull:NO dataType:MADDataTypeFloat];
	MAD_PASS(fabs(floatVal.doubleValue - 3.25) < 0.0001, "3.25 float parses");

	NSNumber *moneyVal = [MADDatabasePostgres objectValueForCString:"$1,234.50" isNull:NO dataType:MADDataTypeFloat];
	MAD_PASS(fabs(moneyVal.doubleValue - 1234.50) < 0.0001, "money string parses");

	NSDecimalNumber *decVal = [MADDatabasePostgres objectValueForCString:"99.95" isNull:NO dataType:MADDataTypeDecimal];
	MAD_PASS_EQUAL(decVal, [NSDecimalNumber decimalNumberWithString:@"99.95"], "decimal 99.95 parses");
	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"NaN" isNull:NO dataType:MADDataTypeDecimal],
				   [NSNull null], "NaN decimal maps to NSNull");

	NSDateComponents *dateVal = [MADDatabasePostgres objectValueForCString:"2026-10-28" isNull:NO dataType:MADDataTypeDate];
	MAD_PASS([dateVal isKindOfClass:[NSDateComponents class]], "dateVal is NSDateComponents");
	MAD_PASS(dateVal.year == 2026 && dateVal.month == 10 && dateVal.day == 28, "dateVal components match");

	NSDateComponents *timeVal = [MADDatabasePostgres objectValueForCString:"14:35:20" isNull:NO dataType:MADDataTypeTime];
	MAD_PASS([timeVal isKindOfClass:[NSDateComponents class]], "timeVal is NSDateComponents");
	MAD_PASS(timeVal.hour == 14 && timeVal.minute == 35 && timeVal.second == 20, "timeVal components match");

	NSDateComponents *tsVal = [MADDatabasePostgres objectValueForCString:"2026-10-28 14:35:20" isNull:NO dataType:MADDataTypeDateTime];
	MAD_PASS([tsVal isKindOfClass:[NSDateComponents class]], "tsVal is NSDateComponents");
	MAD_PASS(tsVal.year == 2026 && tsVal.month == 10 && tsVal.day == 28 &&
			 tsVal.hour == 14 && tsVal.minute == 35 && tsVal.second == 20, "tsVal components match");

	NSData *blobVal = [MADDatabasePostgres objectValueForCString:"\\x48656c6c6f" isNull:NO dataType:MADDataTypeBlob];
	MAD_PASS_EQUAL(blobVal, [@"Hello" dataUsingEncoding:NSUTF8StringEncoding], "hex bytea parses to NSData");

	MAD_PASS_EQUAL([MADDatabasePostgres objectValueForCString:"Chinook" isNull:NO dataType:MADDataTypeString],
				   @"Chinook", "string parses to NSString");
}

#pragma mark - Disconnected and failure guards

static void testDisconnectedDatabaseAndConnectionGuards(void) {
	MADPostgresConnection *pgConn = [[MADPostgresConnection alloc] init];
	MAD_PASS(!pgConn.isConnected, "new MADPostgresConnection is not connected");
	MAD_PASS(pgConn.pgConn == NULL, "new MADPostgresConnection pgConn is NULL");
	MAD_PASS([pgConn escapeLiteral:@"test"] == nil, "escapeLiteral when disconnected is nil");
	MAD_PASS([pgConn escapeIdentifier:@"test"] == nil, "escapeIdentifier when disconnected is nil");
	[pgConn disconnect];

	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	NSError *err = nil;
	MAD_PASS_EQUAL([db getTablesFromConnection:nil error:&err], @[], "getTablesFromConnection:nil returns @[]");
	MAD_PASS_EQUAL([db fieldsForTable:@"Artist" connection:nil error:&err], @[], "fieldsForTable:connection:nil returns @[]");

	MADDataTable *table = [[MADDataTable alloc] init];
	MADQuery *query = [[MADQuery alloc] initWithObject:@"SELECT 1"];
	MAD_PASS(![db executeQuery:query withDataTable:table andError:&err], "executeQuery without connection returns NO");
	MAD_PASS(![db executeSQL:@"SELECT 1" fieldKeys:nil onConnection:nil intoResultTable:table withError:&err],
			 "executeSQL with nil connection returns NO");
	[db closeConnection:pgConn];
}

static void testConnectWithNoListenerFailsCleanlyAndPopulatesError(void) {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:@"127.0.0.1"
													 port:1
											  andDatabase:@"chinook"];
	MADCredential *cred = [[MADCredential alloc] initWithUsername:@"postgres" andPassword:@"postgres"];
	NSError *error = nil;
	id session = [db connectWithConnection:conn credentals:cred connectionError:&error];
	MAD_PASS(session == nil, "connect to port 1 returns nil");
	MAD_PASS(error != nil, "connect to port 1 populates error");
	MAD_PASS_EQUAL(error.domain, @"MADDatabasePostgres", "error domain is MADDatabasePostgres");
}

MAD_TEST_MAIN("MADPostgresTests",
	MAD_TEST(testDriverIdentityStrings),
	MAD_TEST(testErrorCouldNotGetCredientalsShape),
	MAD_TEST(testConnectionDriverMetadataAndRegistration),
	MAD_TEST(testConnectionStoresHostPortAndDatabase),
	MAD_TEST(testConnectionDefaultsPortTo5432),
	MAD_TEST(testConnectionServerPropertyIsTrimmed),
	MAD_TEST(testNewDatabaseConnectionFromPropertiesAndFactory),
	MAD_TEST(testConnectionCopyAndSecureCodingRoundTrip),
	MAD_TEST(testIdentifierQuotingUsesANSIDoubleQuotes),
	MAD_TEST(testSafeQueryFieldAndTable),
	MAD_TEST(testSafeLiteralQuotingOffline),
	MAD_TEST(testSQLDialectHooks),
	MAD_TEST(testPostgresOIDMapping),
	MAD_TEST(testPostgresTypeNameMapping),
	MAD_TEST(testObjectValueConversionCoversAllDataTypes),
	MAD_TEST(testDisconnectedDatabaseAndConnectionGuards),
	MAD_TEST(testConnectWithNoListenerFailsCleanlyAndPopulatesError));
