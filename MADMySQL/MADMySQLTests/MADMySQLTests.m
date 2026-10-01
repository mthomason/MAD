//
//  MADMySQLTests.m
//  MADMySQLTests
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//
//  Offline unit tests for MADMySQL. Nothing in this file contacts a server;
//  see MADMySQLLiveTests.m for the tests that require the local MySQL instance
//  described in DEVELOPER.md (127.0.0.1, root, root, employees).
//

#import <XCTest/XCTest.h>
#import <string.h>

#import <MADMySQL/MADMySQL.h>

#import <MADFoundation/MADDataType.h>

#import "MADDataTypeMySQL.h"
#import "MADDatabaseMySQL.h"
#import "MADDatabaseConnectionMySql.h"
#import "MysqlServer.h"
#import "MysqlConnection.h"
#import "MysqlFetch.h"

#import <mysql.h>

// These selectors are implemented in MADDatabaseMySQL.m but are not declared in any
// @interface the framework exports. Declaring them here lets the tests reach them
// without widening MADDatabaseMySQL's public API.
@interface MADDatabaseMySQL (MADMySQLTestsInternal)
+ (NSError *)errorCouldNotGetCredientals;
- (NSString *)domain;
@end

@interface MADMySQLTests : XCTestCase

@end

@implementation MADMySQLTests

#pragma mark - MADDataTypeMySQL +dataTypeForNativeType:

// MySQL's native type codes are remapped onto the MADDataType enum. These tests
// pin the existing mapping rather than assert it is ideal; several entries are
// deliberately lossy (see the comments on the individual groups).

- (void)testDataTypeForNativeTypeMapsIntegralTypes {
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TINY],     MADDataTypeShort);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_SHORT],    MADDataTypeShort);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_LONG],     MADDataTypeLong);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_LONGLONG], MADDataTypeLongLong);
	// MYSQL_TYPE_INT24 (MEDIUMINT) maps to its own dedicated enum case, which every
	// downstream consumer groups with MADDataTypeInteger. The live suite exercises the
	// INT24 fetch path.
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_INT24],    MADDataTypeInt24);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_BIT],      MADDataTypeBit);
}

- (void)testDataTypeForNativeTypeMapsStringTypes {
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_STRING],     MADDataTypeString);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_VARCHAR],    MADDataTypeVarChar);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_VAR_STRING], MADDataTypeVarChar);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_ENUM],       MADDataTypeEnum);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_SET],        MADDataTypeSet);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_GEOMETRY],   MADDataTypeGeometry);
}

- (void)testDataTypeForNativeTypeMapsBlobVariants {
	// All four BLOB widths collapse to the single MADDataTypeBlob.
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TINY_BLOB],   MADDataTypeBlob);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_BLOB],        MADDataTypeBlob);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_MEDIUM_BLOB], MADDataTypeBlob);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_LONG_BLOB],   MADDataTypeBlob);
}

- (void)testDataTypeForNativeTypeMapsNumericTypes {
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DECIMAL],    MADDataTypeDecimal);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_NEWDECIMAL], MADDataTypeDecimal);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_FLOAT],      MADDataTypeFloat);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DOUBLE],     MADDataTypeDouble);
}

- (void)testDataTypeForNativeTypeMapsTemporalTypes {
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DATE],      MADDataTypeDate);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_NEWDATE],   MADDataTypeDate);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_DATETIME],  MADDataTypeDateTime);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TIMESTAMP], MADDataTypeTimeStamp);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_YEAR],      MADDataTypeYear);
	// NOTE: TIME maps to MADDataTypeDateTime, not the dedicated MADDataTypeTime.
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_TIME],      MADDataTypeDateTime);
}

- (void)testDataTypeForNativeTypeMapsNullToNumber {
	// NOTE: MYSQL_TYPE_NULL maps to MADDataTypeNumber rather than the dedicated
	// MADDataTypeNull. Documented, not corrected.
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:MYSQL_TYPE_NULL], MADDataTypeNumber);
}

- (void)testDataTypeForNativeTypeDefaultsToUnknownNativeCodesAreStrings {
	// Anything the switch does not recognise falls through to MADDataTypeString.
	// MADDataTypeUnknown is never produced by this mapping.
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:(NSInteger)-1],  MADDataTypeString);
	XCTAssertEqual((MADDataType)[MADDataTypeMySQL dataTypeForNativeType:(NSInteger)9999], MADDataTypeString);
}

#pragma mark - Identifier quoting

- (void)testNewSafeQueryFieldQualifiesAndQuotes {
	XCTAssertEqualObjects([MADDatabaseMySQL newSafeQueryField:@"emp_no" andTable:@"employees"],
						  @"`employees`.`emp_no`");
}

- (void)testNewSafeQueryFieldQuotesEmbeddedBackticksLiterally {
	// The helper quotes but does not escape; a name containing a backtick yields
	// a doubled backtick run. Pin the behaviour so a future escaping change is visible.
	XCTAssertEqualObjects([MADDatabaseMySQL newSafeQueryField:@"a`b" andTable:@"t"], @"`t`.`a`b`");
}

- (void)testNewSafeIdentifierQuotesBareName {
	// -newSafeIdentifier: is declared as an instance method; the class-level variant
	// exists in the implementation but is not part of the published interface.
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	XCTAssertEqualObjects([db newSafeIdentifier:@"employees"], @"`employees`");
}

- (void)testQueryKeyTableMatchesSafeQueryField {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	XCTAssertEqualObjects([db queryKey:@"salary" table:@"salaries"],
						  [MADDatabaseMySQL newSafeQueryField:@"salary" andTable:@"salaries"]);
	XCTAssertEqualObjects([db queryKey:@"salary" table:@"salaries"], @"`salaries`.`salary`");
}

- (void)testInstanceNewSafeIdentifierQuotesName {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	XCTAssertEqualObjects([db newSafeIdentifier:@"dept_emp"], @"`dept_emp`");
}

#pragma mark - Literal quoting

// The complete escape needs the live session (see -newSafeLiteral:), and the live
// suite covers that. This pins the path taken when there is none: the base's ANSI
// quoting, which is what a preview that never connects gets. A backslash is NOT
// escaped on that path, and this test says so out loud rather than leaving it implied.
- (void)testNewSafeLiteralWithoutASessionFallsBackToAnsiQuoting {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	XCTAssertEqualObjects([db newSafeLiteral:@"London"], @"'London'");
	XCTAssertEqualObjects([db newSafeLiteral:@"O'Brien"], @"'O''Brien'");
	XCTAssertEqualObjects([db newSafeLiteral:@"C:\\temp"], @"'C:\\temp'");
	XCTAssertEqualObjects([db newSafeLiteral:nil], @"NULL");
}

#pragma mark - MADDatabaseMySQL identity

- (void)testDriverMetadata {
	XCTAssertEqualObjects([MADDatabaseMySQL driverName], @"MySQL Native Client");
	XCTAssertEqualObjects([MADDatabaseMySQL imageIconName], @"UIImageExportTypeMySQL");
}

- (void)testDomainIsClassName {
	MADDatabaseMySQL *db = [[MADDatabaseMySQL alloc] init];
	XCTAssertEqualObjects([db domain], @"MADDatabaseMySQL");
}

- (void)testErrorCouldNotGetCredientalsShape {
	NSError *error = [MADDatabaseMySQL errorCouldNotGetCredientals];
	XCTAssertEqualObjects(error.domain, @"MADDatabaseMySQL");
	XCTAssertEqual(error.code, 43421);
	XCTAssertNotNil(error.localizedDescription);
	XCTAssertNotNil(error.localizedFailureReason);
}

#pragma mark - MADDatabaseConnectionMySql

- (void)testConnectionInitializationStoresProperties {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	XCTAssertEqualObjects(conn.host, @"db.example.com");
	XCTAssertEqualObjects(conn.server, @"db.example.com");
	XCTAssertEqualObjects(conn.database, @"employees");
	XCTAssertEqual(conn.port, 3306);
	XCTAssertEqual(conn.databaseType, MADDatabaseTypeMySQL);
	XCTAssertTrue(conn.requiresCredentials);
}

- (void)testConnectionServerPropertyIsTrimmedButHostIsNot {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"  db.example.com \n"
											   database:@"employees"
												andPort:3306];
	XCTAssertEqualObjects(conn.server, @"db.example.com");
	XCTAssertEqualObjects(conn.host, @"  db.example.com \n");
}

- (void)testConnectionIdentifier {
	XCTAssertEqualObjects([MADDatabaseConnectionMySql Identifier], @"MySQL");
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"h" database:@"d" andPort:1];
	XCTAssertEqualObjects(conn.identifier, @"MySQL");
}

- (void)testConnectionStringFormat {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	XCTAssertEqualObjects(conn.connectionString, @"(MySQL)[db.example.com:3306]employees");
}

- (void)testConnectionCopyIsIndependent {
	MADDatabaseConnectionMySql *conn =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	MADDatabaseConnectionMySql *copy = [conn copyWithZone:nil];
	XCTAssertEqualObjects(copy.host, conn.host);
	XCTAssertEqualObjects(copy.database, conn.database);
	XCTAssertEqual(copy.port, conn.port);
	XCTAssertEqualObjects(copy.connectionString, conn.connectionString);
}

- (void)testNewDatabaseConnectionFromProperties {
	MADDatabaseConnectionMySql *seed =
		[[MADDatabaseConnectionMySql alloc] initWithHost:@"db.example.com"
											   database:@"employees"
												andPort:3306];
	MADDatabaseConnectionMySql *built = [MADDatabaseConnectionMySql newDatabaseConnection:seed];
	XCTAssertEqualObjects(built.host, @"db.example.com");
	XCTAssertEqualObjects(built.database, @"employees");
	XCTAssertEqual(built.port, 3306);
}

#pragma mark - MysqlServer defaults

- (void)testMysqlServerDefaults {
	MysqlServer *server = [[MysqlServer alloc] init];
	XCTAssertEqualObjects(server.host, @"localhost");
	XCTAssertEqualObjects(server.user, @"username");
	XCTAssertEqualObjects(server.password, @"password");
	XCTAssertEqualObjects(server.schema, @"test");
	XCTAssertEqual(server.port, 3306u);
	XCTAssertEqual(server.flags, (unsigned long)CLIENT_FOUND_ROWS);
	XCTAssertEqual(server.connectionTimeout, 30u);
}

- (void)testMysqlServerDescriptionOmitsPassword {
	MysqlServer *server = [[MysqlServer alloc] init];
	server.host = @"db.example.com";
	server.user = @"alice";
	server.password = @"super-secret";
	NSString *description = [server description];
	XCTAssertTrue([description containsString:@"db.example.com"]);
	XCTAssertTrue([description containsString:@"alice"]);
	XCTAssertFalse([description containsString:@"super-secret"]);
}

#pragma mark - mySQLTypeForType

- (void)testMySqlTypeForTypeNamesCommonTypes {
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_TINY)),      @"MYSQL_TYPE_TINY");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_SHORT)),     @"MYSQL_TYPE_SHORT");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_LONG)),      @"MYSQL_TYPE_LONG");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_LONGLONG)),  @"MYSQL_TYPE_LONGLONG");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_INT24)),     @"MYSQL_TYPE_INT24");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_FLOAT)),     @"MYSQL_TYPE_FLOAT");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_DOUBLE)),    @"MYSQL_TYPE_DOUBLE");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_NEWDECIMAL)),@"MYSQL_TYPE_NEWDECIMAL");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_DATE)),      @"MYSQL_TYPE_DATE");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_TIME)),      @"MYSQL_TYPE_TIME");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_DATETIME)),  @"MYSQL_TYPE_DATETIME");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_TIMESTAMP)), @"MYSQL_TYPE_TIMESTAMP");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_YEAR)),      @"MYSQL_TYPE_YEAR");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_VARCHAR)),   @"MYSQL_TYPE_VARCHAR");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_STRING)),    @"MYSQL_TYPE_STRING");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_BLOB)),      @"MYSQL_TYPE_BLOB");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_TINY_BLOB)), @"MYSQL_TYPE_TINY_BLOB");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_ENUM)),      @"MYSQL_TYPE_ENUM");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_SET)),       @"MYSQL_TYPE_SET");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_BIT)),       @"MYSQL_TYPE_BIT");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_GEOMETRY)),  @"MYSQL_TYPE_GEOMETRY");
}

// MYSQL_TYPE_MEDIUM_BLOB and MYSQL_TYPE_LONG_BLOB both used to return the string
// "MYSQL_TYPE_DECIMAL" -- a copy/paste slip in this diagnostics-only helper. Fixed
// in MysqlFetch.m; these assertions keep it fixed. Likewise MYSQL_TYPE_LONGLONG had
// no case at all and fell through to "Unknown".
- (void)testMySqlTypeForTypeNamesBlobAndLongLongTypes {
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_MEDIUM_BLOB)), @"MYSQL_TYPE_MEDIUM_BLOB");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_LONG_BLOB)),   @"MYSQL_TYPE_LONG_BLOB");
	XCTAssertEqualObjects(@(mySQLTypeForType(MYSQL_TYPE_LONGLONG)),    @"MYSQL_TYPE_LONGLONG");
}

- (void)testMySqlTypeForTypeUnknownFallsBack {
	XCTAssertEqualObjects(@(mySQLTypeForType((enum enum_field_types)12345)), @"Unknown");
}

#pragma mark - Connection failure paths (no server required)

- (void)testConnectToServerWithNoListenerFailsCleanly {
	MysqlServer *server = [[MysqlServer alloc] init];
	server.host = @"127.0.0.1";
	server.port = 1;            // privileged, nothing listens here
	server.user = @"root";
	server.password = @"root";
	server.schema = @"employees";

	NSError *error = nil;
	MysqlConnection *connection = [MysqlConnection connectToServer:server error:&error];

	XCTAssertNil(connection);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MADDatabaseMySQL");
	XCTAssertNotEqual(error.code, 0);
	XCTAssertNotNil(error.userInfo[@"MySQLErrorNumberKey"]);
	XCTAssertEqualObjects(error.userInfo[@"MySQLHostnameKey"], @"127.0.0.1");
	XCTAssertEqualObjects(error.userInfo[@"MySQLSchemaKey"], @"employees");
}

- (void)testConnectToServerWithoutErrorPointerStillReturnsNil {
	MysqlServer *server = [[MysqlServer alloc] init];
	server.host = @"127.0.0.1";
	server.port = 1;
	XCTAssertNil([MysqlConnection connectToServer:server]);
}

- (void)testConnectToServersReturnsNilWhenAllCandidatesFail {
	MysqlServer *first = [[MysqlServer alloc] init];
	first.host = @"127.0.0.1";
	first.port = 1;

	MysqlServer *second = [[MysqlServer alloc] init];
	second.host = @"127.0.0.1";
	second.port = 1;

	// Bind to a local first: a comma inside an @[...] literal would otherwise be
	// taken as an extra argument to the XCTest macro.
	NSArray *candidates = @[first, second];
	XCTAssertNil([MysqlConnection connectToServers:candidates]);
}

@end
