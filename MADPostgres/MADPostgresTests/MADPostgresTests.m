//
//  MADPostgresTests.m
//  MADPostgresTests
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADCredential.h>
#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADQuery.h>

#import "MADDatabasePostgres.h"
#import "MADDatabaseConnectionPostgres.h"
#import "MADPostgresConnection.h"
#import "MADDataTypePostgres.h"

@interface MADDatabasePostgres (MADPostgresTestsInternal)
+ (NSError *)errorCouldNotGetCredientals;
- (NSString *)domain;
@end

@interface MADPostgresTests : XCTestCase
@end

@implementation MADPostgresTests

#pragma mark - Driver identity and registry

- (void)testDriverIdentityStrings {
	XCTAssertEqualObjects([MADDatabasePostgres driverName], @"PostgreSQL");
	XCTAssertEqualObjects([MADDatabasePostgres imageIconName], @"UIImageExportTypePostgres");

	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	db.databaseConnection = [MADDatabaseConnectionPostgres connectionWithHost:@"localhost"
																  andDatabase:@"chinook"];
	XCTAssertEqualObjects([db identifier], @"PostgreSQL");
	XCTAssertEqualObjects([db domain], @"MADDatabasePostgres");
}

- (void)testErrorCouldNotGetCredientalsShape {
	NSError *error = [MADDatabasePostgres errorCouldNotGetCredientals];
	XCTAssertEqualObjects(error.domain, @"MADDatabasePostgres");
	XCTAssertEqual(error.code, 43421);
	XCTAssertNotNil(error.localizedDescription);
	XCTAssertNotNil(error.localizedFailureReason);
}

- (void)testConnectionDriverMetadataAndRegistration {
	XCTAssertEqual([MADDatabaseConnectionPostgres databaseType], MADDatabaseTypePostgres);
	XCTAssertEqual([MADDatabaseConnectionPostgres databaseClass], [MADDatabasePostgres class]);
	XCTAssertEqualObjects([MADDatabaseConnectionPostgres Identifier], @"PostgreSQL");

	XCTAssertEqual([MADDatabaseDriverRegistry driverClassForType:MADDatabaseTypePostgres],
				   [MADDatabaseConnectionPostgres class]);
	XCTAssertTrue([[MADDatabaseDriverRegistry registeredDriverClasses]
				   containsObject:[MADDatabaseConnectionPostgres class]]);
}

#pragma mark - MADDatabaseConnectionPostgres

- (void)testConnectionStoresHostPortAndDatabase {
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:@"db.example.com"
													 port:15432
											  andDatabase:@"analytics"];

	XCTAssertNotNil(conn);
	XCTAssertEqual(conn.databaseType, MADDatabaseTypePostgres);
	XCTAssertTrue(conn.requiresCredentials);
	XCTAssertEqualObjects(conn.identifier, @"PostgreSQL");
	XCTAssertEqualObjects(conn.host, @"db.example.com");
	XCTAssertEqualObjects(conn.server, @"db.example.com");
	XCTAssertEqual(conn.port, 15432);
	XCTAssertEqualObjects(conn.database, @"analytics");
	XCTAssertEqualObjects(conn.connectionString, @"(PostgreSQL)[db.example.com:15432]analytics");
}

- (void)testConnectionDefaultsPortTo5432 {
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:@"localhost"
											  andDatabase:@"chinook"];

	XCTAssertNotNil(conn);
	XCTAssertEqual(conn.port, 5432);

	MADDatabaseConnectionPostgres *zeroPort =
		[[MADDatabaseConnectionPostgres alloc] initWithHost:@"localhost"
													   port:0
												andDatabase:@"chinook"];
	XCTAssertEqual(zeroPort.port, 5432);
}

- (void)testConnectionServerPropertyIsTrimmed {
	MADDatabaseConnectionPostgres *conn =
		[[MADDatabaseConnectionPostgres alloc] initWithHost:@"  db.local \n"
												   database:@"chinook"
													andPort:5432];

	XCTAssertEqualObjects(conn.server, @"db.local");
}

- (void)testNewDatabaseConnectionFromPropertiesAndFactory {
	MADDatabaseConnectionPostgres *seed =
		[[MADDatabaseConnectionPostgres alloc] initWithHost:@"db.example.com"
												   database:@"chinook"
													andPort:5432];
	MADDatabaseConnectionPostgres *built = [MADDatabaseConnectionPostgres newDatabaseConnection:seed];
	XCTAssertEqualObjects(built.host, @"db.example.com");
	XCTAssertEqualObjects(built.database, @"chinook");
	XCTAssertEqual(built.port, 5432);

	MADDatabaseConnectionPostgres *fromDriverHook =
		[MADDatabaseConnectionPostgres newDatabaseConnectionWithHost:@"db.example.com"
															database:@"chinook"
																port:0];
	XCTAssertEqualObjects(fromDriverHook.host, @"db.example.com");
	XCTAssertEqualObjects(fromDriverHook.database, @"chinook");
	XCTAssertEqual(fromDriverHook.port, 5432);
}

- (void)testConnectionCopyAndSecureCodingRoundTrip {
	MADDatabaseConnectionPostgres *original =
		[MADDatabaseConnectionPostgres connectionWithHost:@"pg.internal"
													 port:5433
											  andDatabase:@"warehouse"];

	MADDatabaseConnectionPostgres *copied = [original copy];
	XCTAssertNotNil(copied);
	XCTAssertNotEqual(copied, original);
	XCTAssertEqual(copied.databaseType, MADDatabaseTypePostgres);
	XCTAssertEqualObjects(copied.host, @"pg.internal");
	XCTAssertEqual(copied.port, 5433);
	XCTAssertEqualObjects(copied.database, @"warehouse");
	XCTAssertEqualObjects(copied.connectionString, @"(PostgreSQL)[pg.internal:5433]warehouse");

	XCTAssertTrue([MADDatabaseConnectionPostgres supportsSecureCoding]);
	NSError *archiveError = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original
										 requiringSecureCoding:YES
														 error:&archiveError];
	XCTAssertNotNil(data, @"Archive failed: %@", archiveError);

	NSError *unarchiveError = nil;
	MADDatabaseConnectionPostgres *decoded =
		[NSKeyedUnarchiver unarchivedObjectOfClass:[MADDatabaseConnectionPostgres class]
										  fromData:data
											 error:&unarchiveError];
	XCTAssertNotNil(decoded, @"Unarchive failed: %@", unarchiveError);
	XCTAssertEqual(decoded.databaseType, MADDatabaseTypePostgres);
	XCTAssertEqualObjects(decoded.host, @"pg.internal");
	XCTAssertEqual(decoded.port, 5433);
	XCTAssertEqualObjects(decoded.database, @"warehouse");
	XCTAssertEqualObjects(decoded.connectionString, @"(PostgreSQL)[pg.internal:5433]warehouse");
}

#pragma mark - SQL dialect and identifier/literal quoting

- (void)testIdentifierQuotingUsesANSIDoubleQuotes {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	XCTAssertEqualObjects([MADDatabasePostgres identifierQuoteCharacters], @"\"\"");
	XCTAssertEqualObjects([MADDatabasePostgres newSafeIdentifier:@"Artist"], @"\"Artist\"");
	XCTAssertEqualObjects([db newSafeIdentifier:@"Artist"], @"\"Artist\"");
	XCTAssertEqualObjects([MADDatabasePostgres newSafeIdentifier:@"a\"b"], @"\"a\"\"b\"");
	XCTAssertEqualObjects([MADDatabasePostgres newSafeIdentifier:@"sales.orders"], @"\"sales\".\"orders\"");
	XCTAssertEqualObjects([db newSafeIdentifier:@"sales.orders"], @"\"sales\".\"orders\"");
	XCTAssertEqualObjects([MADDatabasePostgres newSafeIdentifier:@"sales..orders"], @"\"sales\".\"orders\"");
	XCTAssertEqualObjects([MADDatabasePostgres newSafeIdentifier:@""], @"");
	XCTAssertEqualObjects([MADDatabasePostgres newSafeIdentifier:nil], @"");
}

- (void)testSafeQueryFieldAndTable {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	XCTAssertEqualObjects([MADDatabasePostgres newSafeQueryField:@"Name" andTable:@"Artist"],
						  @"\"Artist\".\"Name\"");
	XCTAssertEqualObjects([db queryKey:@"Name" table:@"Artist"],
						  @"\"Artist\".\"Name\"");
	XCTAssertEqualObjects([MADDatabasePostgres newSafeQueryField:@"total" andTable:@"sales.orders"],
						  @"\"sales\".\"orders\".\"total\"");
	XCTAssertEqualObjects([db queryKey:@"total" table:@"sales.orders"],
						  @"\"sales\".\"orders\".\"total\"");
}

- (void)testSafeLiteralQuotingOffline {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	XCTAssertEqualObjects([db newSafeLiteral:@"hello"], @"'hello'");
	XCTAssertEqualObjects([db newSafeLiteral:@"O'Brien"], @"'O''Brien'");
	XCTAssertEqualObjects([db newSafeLiteral:@""], @"''");
	XCTAssertEqualObjects([db newSafeLiteral:nil], @"NULL");
}

- (void)testSQLDialectHooks {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];

	XCTAssertEqualObjects([db tableAliasConnector], @" AS ");
	XCTAssertEqualObjects([db sqlLimitClause:25], @"\nLIMIT 25");
	XCTAssertEqualObjects([db sqlLimitClause:0], @"");
	XCTAssertEqualObjects([db sqlLimitClause:NSUIntegerMax], @"");
	XCTAssertEqualObjects([db sqlRangeClauseWithLimit:25 offset:50], @"LIMIT 25 OFFSET 50");
	XCTAssertEqualObjects([db sqlAggregateFunctionLength], @"LENGTH");
}

#pragma mark - PostgreSQL OID and type name mapping

- (void)testPostgresOIDMapping {
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:BOOLOID], MADDataTypeBit);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:INT2OID], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:INT4OID], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:INT8OID], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:OIDOID], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:FLOAT4OID], MADDataTypeFloat);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:FLOAT8OID], MADDataTypeFloat);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:CASHOID], MADDataTypeFloat);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:NUMERICOID], MADDataTypeDecimal);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:DATEOID], MADDataTypeDate);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:TIMEOID], MADDataTypeTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:TIMETZOID], MADDataTypeTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:TIMESTAMPOID], MADDataTypeDateTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:TIMESTAMPTZOID], MADDataTypeDateTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:BYTEAOID], MADDataTypeBlob);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:VARCHAROID], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:TEXTOID], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:BPCHAROID], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:UUIDOID], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:JSONOID], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:JSONBOID], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresOID:999999U], MADDataTypeString);
}

- (void)testPostgresTypeNameMapping {
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"boolean"], MADDataTypeBit);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"BOOL"], MADDataTypeBit);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"smallint"], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"integer"], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"bigint"], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"int4"], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"serial"], MADDataTypeInteger);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"real"], MADDataTypeFloat);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"double precision"], MADDataTypeFloat);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"money"], MADDataTypeFloat);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"numeric"], MADDataTypeDecimal);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"decimal"], MADDataTypeDecimal);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"date"], MADDataTypeDate);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"time without time zone"], MADDataTypeTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"time with time zone"], MADDataTypeTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"timestamp without time zone"], MADDataTypeDateTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"timestamp with time zone"], MADDataTypeDateTime);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"bytea"], MADDataTypeBlob);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"character varying"], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"text"], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"uuid"], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@"jsonb"], MADDataTypeString);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:nil], MADDataTypeUnknown);
	XCTAssertEqual([MADDataTypePostgres madDataTypeFromPostgresTypeName:@""], MADDataTypeUnknown);
}

#pragma mark - Cell value parsing

- (void)testObjectValueConversionCoversAllDataTypes {
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:NULL isNull:YES dataType:MADDataTypeString],
						  [NSNull null]);
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"ignored" isNull:YES dataType:MADDataTypeInteger],
						  [NSNull null]);

	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"t" isNull:NO dataType:MADDataTypeBit], @YES);
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"true" isNull:NO dataType:MADDataTypeBit], @YES);
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"1" isNull:NO dataType:MADDataTypeBit], @YES);
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"f" isNull:NO dataType:MADDataTypeBit], @NO);
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"0" isNull:NO dataType:MADDataTypeBit], @NO);

	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"42" isNull:NO dataType:MADDataTypeInteger], @(42LL));
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"-9000" isNull:NO dataType:MADDataTypeInteger], @(-9000LL));

	NSNumber *floatVal = [MADDatabasePostgres objectValueForCString:"3.25" isNull:NO dataType:MADDataTypeFloat];
	XCTAssertEqualWithAccuracy(floatVal.doubleValue, 3.25, 0.0001);

	NSNumber *moneyVal = [MADDatabasePostgres objectValueForCString:"$1,234.50" isNull:NO dataType:MADDataTypeFloat];
	XCTAssertEqualWithAccuracy(moneyVal.doubleValue, 1234.50, 0.0001);

	NSDecimalNumber *decVal = [MADDatabasePostgres objectValueForCString:"99.95" isNull:NO dataType:MADDataTypeDecimal];
	XCTAssertEqualObjects(decVal, [NSDecimalNumber decimalNumberWithString:@"99.95"]);
	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"NaN" isNull:NO dataType:MADDataTypeDecimal],
						  [NSNull null]);

	NSDateComponents *dateVal = [MADDatabasePostgres objectValueForCString:"2026-10-28" isNull:NO dataType:MADDataTypeDate];
	XCTAssertTrue([dateVal isKindOfClass:[NSDateComponents class]]);
	XCTAssertEqual(dateVal.year, 2026);
	XCTAssertEqual(dateVal.month, 10);
	XCTAssertEqual(dateVal.day, 28);

	NSDateComponents *timeVal = [MADDatabasePostgres objectValueForCString:"14:35:20" isNull:NO dataType:MADDataTypeTime];
	XCTAssertTrue([timeVal isKindOfClass:[NSDateComponents class]]);
	XCTAssertEqual(timeVal.hour, 14);
	XCTAssertEqual(timeVal.minute, 35);
	XCTAssertEqual(timeVal.second, 20);

	NSDateComponents *tsVal = [MADDatabasePostgres objectValueForCString:"2026-10-28 14:35:20" isNull:NO dataType:MADDataTypeDateTime];
	XCTAssertTrue([tsVal isKindOfClass:[NSDateComponents class]]);
	XCTAssertEqual(tsVal.year, 2026);
	XCTAssertEqual(tsVal.month, 10);
	XCTAssertEqual(tsVal.day, 28);
	XCTAssertEqual(tsVal.hour, 14);
	XCTAssertEqual(tsVal.minute, 35);
	XCTAssertEqual(tsVal.second, 20);

	NSData *blobVal = [MADDatabasePostgres objectValueForCString:"\\x48656c6c6f" isNull:NO dataType:MADDataTypeBlob];
	XCTAssertEqualObjects(blobVal, [@"Hello" dataUsingEncoding:NSUTF8StringEncoding]);

	XCTAssertEqualObjects([MADDatabasePostgres objectValueForCString:"Chinook" isNull:NO dataType:MADDataTypeString],
						  @"Chinook");
}

#pragma mark - Disconnected and failure guards

- (void)testDisconnectedDatabaseAndConnectionGuards {
	MADPostgresConnection *pgConn = [[MADPostgresConnection alloc] init];
	XCTAssertFalse(pgConn.isConnected);
	XCTAssertTrue(pgConn.pgConn == NULL);
	XCTAssertNil([pgConn escapeLiteral:@"test"]);
	XCTAssertNil([pgConn escapeIdentifier:@"test"]);
	XCTAssertNoThrow([pgConn disconnect]);

	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	NSError *err = nil;
	XCTAssertEqualObjects([db getTablesFromConnection:nil error:&err], @[]);
	XCTAssertEqualObjects([db fieldsForTable:@"Artist" connection:nil error:&err], @[]);

	MADDataTable *table = [[MADDataTable alloc] init];
	MADQuery *query = [[MADQuery alloc] initWithObject:@"SELECT 1"];
	XCTAssertFalse([db executeQuery:query withDataTable:table andError:&err]);
	XCTAssertFalse([db executeSQL:@"SELECT 1" fieldKeys:nil onConnection:nil intoResultTable:table withError:&err]);
	XCTAssertNoThrow([db closeConnection:pgConn]);
}

- (void)testConnectWithNoListenerFailsCleanlyAndPopulatesError {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:@"127.0.0.1"
													 port:1
											  andDatabase:@"chinook"];
	MADCredential *cred = [[MADCredential alloc] initWithUsername:@"postgres" andPassword:@"postgres"];
	NSError *error = nil;
	id session = [db connectWithConnection:conn credentals:cred connectionError:&error];
	XCTAssertNil(session);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MADDatabasePostgres");
}

@end
