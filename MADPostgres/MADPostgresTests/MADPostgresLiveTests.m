//
//  MADPostgresLiveTests.m
//  MADPostgresTests
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Integration tests for MADPostgres that talk to a real PostgreSQL server --
//  this is the only way to exercise MADPostgresConnection and the libpq calls
//  behind -connectWithConnection:credentals:connectionError:,
//  -getTablesFromConnection:error:, -fieldsForTable:connection:error:, and
//  -executeSQL:fieldKeys:onConnection:intoResultTable:withError:.
//
//  The server is the local Docker instance documented in docs/project/DEVELOPER.md:
//
//      PostgreSQL 17, 127.0.0.1:5432, mad, mad_test_pw, chinook
//
//  Every credential can be overridden with an environment variable so the suite
//  can be pointed at another instance without editing code:
//
//      MAD_PG_TEST_HOST, MAD_PG_TEST_PORT, MAD_PG_TEST_USER,
//      MAD_PG_TEST_PASSWORD, MAD_PG_TEST_DATABASE
//
//  If the server cannot be reached the suite SKIPS rather than fails, so a
//  machine without PostgreSQL still gets a green run for the offline tests in
//  MADPostgresTests.m.
//

#import <XCTest/XCTest.h>

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
#import <MADAPI/MADQuery.h>

#import "MADDatabasePostgres.h"
#import "MADDatabaseConnectionPostgres.h"
#import "MADPostgresConnection.h"
#import "MADDataTypePostgres.h"

@interface MADPostgresCredentialStub : NSObject <MADDatabaseResultsProtocol>
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end

@implementation MADPostgresCredentialStub
- (MADCredential *)getCredentialsForKey:(NSString * __unused)key {
	return [[MADCredential alloc] initWithUsername:self.username andPassword:self.password];
}
@end

@interface MADPostgresTestQuery : MADQuery <MADQueryFieldKeysProtocol>
@property (nonatomic, copy) NSString *sqlString;
@property (nonatomic, copy) NSArray<NSString *> *configuredKeys;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *fields;
@property (nonatomic, strong) NSMutableArray *fieldKeys;
@end

@implementation MADPostgresTestQuery
- (instancetype)initWithSQL:(NSString *)sql fieldKeys:(NSArray<NSString *> *)keys {
	if (self = [super initWithObject:nil]) {
		_sqlString = [sql copy];
		_configuredKeys = [keys copy];
		_fields = [[NSMutableDictionary alloc] init];
		_fieldKeys = [[NSMutableArray alloc] init];
	}
	return self;
}
- (NSString *)getSql:(NSError * __autoreleasing *)error {
	[super getSql:error];
	if (self.configuredKeys.count > 0) {
		[self.fieldKeys addObjectsFromArray:self.configuredKeys];
	}
	return self.sqlString;
}
@end

@interface MADPostgresLiveTests : XCTestCase
@end

@implementation MADPostgresLiveTests

#pragma mark - Fixtures

+ (NSDictionary<NSString *, NSString *> *)testSettings {
	NSDictionary<NSString *, NSString *> *env = [[NSProcessInfo processInfo] environment];
	return @{
		@"host"     : env[@"MAD_PG_TEST_HOST"]     ?: @"127.0.0.1",
		@"port"     : env[@"MAD_PG_TEST_PORT"]     ?: @"5432",
		@"user"     : env[@"MAD_PG_TEST_USER"]     ?: @"mad",
		@"password" : env[@"MAD_PG_TEST_PASSWORD"] ?: @"mad_test_pw",
		@"database" : env[@"MAD_PG_TEST_DATABASE"] ?: @"chinook",
	};
}

+ (MADDatabaseConnectionPostgres *)testConnection {
	NSDictionary<NSString *, NSString *> *settings = [self testSettings];
	NSInteger port = [settings[@"port"] integerValue];
	return [MADDatabaseConnectionPostgres connectionWithHost:settings[@"host"]
														port:(port > 0 ? port : 5432)
												 andDatabase:settings[@"database"]];
}

+ (MADCredential *)testCredential {
	NSDictionary<NSString *, NSString *> *settings = [self testSettings];
	return [[MADCredential alloc] initWithUsername:settings[@"user"]
									   andPassword:settings[@"password"]];
}

+ (BOOL)serverIsAvailable {
	static BOOL available = NO;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
		MADDatabaseConnectionPostgres *conn = [self testConnection];
		db.databaseConnection = conn;
		NSError *error = nil;
		id session = [db connectWithConnection:conn
									credentals:[self testCredential]
							   connectionError:&error];
		available = (session != nil && error == nil);
		if (session != nil) {
			[db closeConnection:session];
		}
	});
	return available;
}

- (void)requireServer {
	XCTSkipIf(![[self class] serverIsAvailable],
			  @"No PostgreSQL server reachable; see docs/project/DEVELOPER.md for the expected test instance.");
}

- (MADPostgresConnection *)openSessionWithDatabase:(MADDatabasePostgres **)outDatabase {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	MADDatabaseConnectionPostgres *conn = [[self class] testConnection];
	db.databaseConnection = conn;
	NSError *error = nil;
	MADPostgresConnection *session = [db connectWithConnection:conn
													credentals:[[self class] testCredential]
											   connectionError:&error];
	XCTAssertNotNil(session, @"Expected to connect to PostgreSQL, got error: %@", error);
	XCTAssertNil(error);
	if (outDatabase != NULL) {
		*outDatabase = db;
	}
	return session;
}

#pragma mark - Connection

- (void)testConnectToLocalServerSucceeds {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];
	XCTAssertTrue(session.isConnected);
	XCTAssertTrue(session.pgConn != NULL);
	[db closeConnection:session];
	XCTAssertFalse(session.isConnected);
}

- (void)testConnectionDescriptionMentionsHostAndConnectedState {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];
	NSString *description = [session description];
	XCTAssertTrue([description containsString:[[self class] testSettings][@"host"]]);
	XCTAssertTrue([description containsString:@"YES"], @"Expected connected state in: %@", description);
	[db closeConnection:session];
}

- (void)testConnectWithWrongPasswordReportsAuthenticationFailure {
	[self requireServer];
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	MADDatabaseConnectionPostgres *conn = [[self class] testConnection];
	MADCredential *badCred = [[MADCredential alloc] initWithUsername:[[self class] testSettings][@"user"]
														 andPassword:@"definitely-not-the-password"];
	NSError *error = nil;
	id session = [db connectWithConnection:conn credentals:badCred connectionError:&error];
	XCTAssertNil(session);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MADDatabasePostgres");
}

- (void)testConnectWithUnknownDatabaseReportsError {
	[self requireServer];
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	NSDictionary<NSString *, NSString *> *settings = [[self class] testSettings];
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:settings[@"host"]
													 port:[settings[@"port"] integerValue]
											  andDatabase:@"mad_nonexistent_database_xyz"];
	NSError *error = nil;
	id session = [db connectWithConnection:conn credentals:[[self class] testCredential] connectionError:&error];
	XCTAssertNil(session);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MADDatabasePostgres");
}

#pragma mark - Live Escaping

- (void)testLiveEscapeLiteralAndIdentifier {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	XCTAssertEqualObjects([session escapeLiteral:@"O'Brien"], @"'O''Brien'");
	XCTAssertEqualObjects([session escapeIdentifier:@"album_id"], @"\"album_id\"");
	XCTAssertEqualObjects([session escapeIdentifier:@"a\"b"], @"\"a\"\"b\"");

	XCTAssertEqualObjects([db newSafeLiteral:@"AC/DC's Best"], @"'AC/DC''s Best'");

	[db closeConnection:session];
}

#pragma mark - Schema Discovery

- (void)testGetTablesFromConnectionFindsAllChinookTables {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	NSError *error = nil;
	NSArray<MADDatabaseTable *> *tables = [db getTablesFromConnection:session error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(tables);

	NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:tables.count];
	for (MADDatabaseTable *t in tables) {
		[names addObject:t.name];
	}

	NSArray<NSString *> *expected = @[
		@"album", @"artist", @"customer", @"employee", @"genre",
		@"invoice", @"invoice_line", @"media_type", @"playlist",
		@"playlist_track", @"track"
	];
	for (NSString *expectedName in expected) {
		XCTAssertTrue([names containsObject:expectedName], @"Missing Chinook table %@", expectedName);
	}
	XCTAssertFalse([names containsObject:@"pg_type"]);

	[db closeConnection:session];
}

- (void)testEnumerateTablesFromConnectionStreamsTablesAndHonorsStop {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	NSMutableArray<NSString *> *collected = [NSMutableArray array];
	__block BOOL completedSuccess = NO;
	__block NSError *completedError = nil;

	[db enumerateTablesFromConnection:session
						   usingBlock:^(MADDatabaseTable *table, NSUInteger __unused index, BOOL *stop) {
		[collected addObject:table.name];
		if (collected.count == 3) {
			*stop = YES;
		}
	}
						   completion:^(BOOL success, NSError *error, NSArray * __unused results) {
		completedSuccess = success;
		completedError = error;
	}];

	XCTAssertTrue(completedSuccess);
	XCTAssertNil(completedError);
	XCTAssertEqual(collected.count, 3u);

	[db closeConnection:session];
}

- (void)testGetTablesUsesDelegateCredentials {
	[self requireServer];
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	db.databaseConnection = [[self class] testConnection];

	NSDictionary<NSString *, NSString *> *settings = [[self class] testSettings];
	MADPostgresCredentialStub *stub = [[MADPostgresCredentialStub alloc] init];
	stub.username = settings[@"user"];
	stub.password = settings[@"password"];
	db.delegate = stub;

	__block BOOL ok = NO;
	__block NSError *err = nil;
	__block NSArray<MADDatabaseTable *> *tables = nil;
	[db getTables:^(BOOL success, NSError *error, NSArray<MADDatabaseTable *> *result) {
		ok = success;
		err = error;
		tables = result;
	}];

	XCTAssertTrue(ok, @"Expected getTables: to succeed, got error: %@", err);
	XCTAssertNil(err);
	XCTAssertGreaterThanOrEqual(tables.count, 11u);
}

- (void)testFieldsForTableDiscoversColumnsTypesNullabilityAndPrimaryKey {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	NSError *error = nil;
	NSArray<MADDatabaseField *> *invoiceFields = [db fieldsForTable:@"invoice" connection:session error:&error];
	XCTAssertNil(error);
	XCTAssertEqual(invoiceFields.count, 9u);

	NSMutableDictionary<NSString *, MADDatabaseField *> *byName = [NSMutableDictionary dictionary];
	for (MADDatabaseField *f in invoiceFields) {
		byName[f.name] = f;
	}

	MADDatabaseField *invoiceId = byName[@"invoice_id"];
	XCTAssertNotNil(invoiceId);
	XCTAssertEqual(invoiceId.fieldType, MADDataTypeInteger);
	XCTAssertTrue(invoiceId.primaryKey);

	MADDatabaseField *invoiceDate = byName[@"invoice_date"];
	XCTAssertNotNil(invoiceDate);
	XCTAssertEqual(invoiceDate.fieldType, MADDataTypeDateTime);
	XCTAssertFalse(invoiceDate.primaryKey);

	MADDatabaseField *billingAddress = byName[@"billing_address"];
	XCTAssertNotNil(billingAddress);
	XCTAssertEqual(billingAddress.fieldType, MADDataTypeString);
	XCTAssertEqual(billingAddress.width, 70);

	MADDatabaseField *total = byName[@"total"];
	XCTAssertNotNil(total);
	XCTAssertEqual(total.fieldType, MADDataTypeDecimal);
	XCTAssertEqual(total.width, 10);
	XCTAssertEqual(total.decimals, 2);

	// Composite primary key table: playlist_track (playlist_id, track_id)
	NSArray<MADDatabaseField *> *ptFields = [db fieldsForTable:@"playlist_track" connection:session error:&error];
	XCTAssertNil(error);
	XCTAssertEqual(ptFields.count, 2u);
	XCTAssertTrue(ptFields[0].primaryKey);
	XCTAssertTrue(ptFields[1].primaryKey);

	[db closeConnection:session];
}

- (void)testNonPublicSchemaTableDiscoveryAndFields {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	PGresult *res = PQexec(session.pgConn,
		"DROP SCHEMA IF EXISTS mad_pg_probe CASCADE;"
		"CREATE SCHEMA mad_pg_probe;"
		"CREATE TABLE mad_pg_probe.metrics ("
		"  metric_id INT PRIMARY KEY,"
		"  label VARCHAR(50) NOT NULL,"
		"  score NUMERIC(8,2)"
		");"
		"INSERT INTO mad_pg_probe.metrics VALUES (1, 'apdex', 98.50);");
	XCTAssertEqual(PQresultStatus(res), PGRES_COMMAND_OK, @"Setup failed: %s", PQerrorMessage(session.pgConn));
	PQclear(res);

	@try {
		NSError *error = nil;
		NSArray<MADDatabaseTable *> *tables = [db getTablesFromConnection:session error:&error];
		XCTAssertNil(error);
		NSMutableArray<NSString *> *tableNames = [NSMutableArray array];
		for (MADDatabaseTable *t in tables) {
			[tableNames addObject:t.name];
		}
		XCTAssertTrue([tableNames containsObject:@"mad_pg_probe.metrics"]);

		NSArray<MADDatabaseField *> *fields = [db fieldsForTable:@"mad_pg_probe.metrics"
													  connection:session
														   error:&error];
		XCTAssertNil(error);
		XCTAssertEqual(fields.count, 3u);
		XCTAssertEqualObjects(fields[0].name, @"metric_id");
		XCTAssertTrue(fields[0].primaryKey);
		XCTAssertEqual(fields[0].fieldType, MADDataTypeInteger);
		XCTAssertEqualObjects(fields[1].name, @"label");
		XCTAssertEqual(fields[1].fieldType, MADDataTypeString);
		XCTAssertEqual(fields[1].width, 50);
		XCTAssertEqualObjects(fields[2].name, @"score");
		XCTAssertEqual(fields[2].fieldType, MADDataTypeDecimal);
		XCTAssertEqual(fields[2].width, 8);
		XCTAssertEqual(fields[2].decimals, 2);

		MADDataTable *resultTable = [[MADDataTableVirtual alloc] initWithId:1];
		NSString *sql = [NSString stringWithFormat:@"SELECT %@, %@, %@ FROM %@",
						 [db queryKey:@"metric_id" table:@"mad_pg_probe.metrics"],
						 [db queryKey:@"label" table:@"mad_pg_probe.metrics"],
						 [db queryKey:@"score" table:@"mad_pg_probe.metrics"],
						 [db newSafeIdentifier:@"mad_pg_probe.metrics"]];
		BOOL ok = [db executeSQL:sql
					   fieldKeys:nil
					onConnection:session
				 intoResultTable:resultTable
					   withError:&error];
		XCTAssertTrue(ok, @"Query failed: %@", error);
		XCTAssertEqual([resultTable numberOfRows], 1u);
		XCTAssertEqualObjects([resultTable objectAtRow:0 column:0], @(1LL));
		XCTAssertEqualObjects([resultTable objectAtRow:0 column:1], @"apdex");
		XCTAssertEqualObjects([resultTable objectAtRow:0 column:2],
							  [NSDecimalNumber decimalNumberWithString:@"98.50"]);
	} @finally {
		PGresult *cleanup = PQexec(session.pgConn, "DROP SCHEMA IF EXISTS mad_pg_probe CASCADE;");
		PQclear(cleanup);
		[db closeConnection:session];
	}
}

#pragma mark - Query Execution and Data Types

- (void)testExecuteSQLReadsChinookArtistsAndTracks {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	MADDataTable *artists = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	BOOL ok = [db executeSQL:@"SELECT \"artist_id\", \"name\" FROM \"artist\" ORDER BY \"artist_id\""
				   fieldKeys:@[@"artist.artist_id", @"artist.name"]
				onConnection:session
			 intoResultTable:artists
				   withError:&error];
	XCTAssertTrue(ok, @"Expected query to succeed, got error: %@", error);
	XCTAssertNil(error);
	XCTAssertEqual([artists numberOfRows], 275u);
	XCTAssertEqual([artists numberOfColumns], 2u);
	XCTAssertEqualObjects(artists.columnKeys[0], @"artist.artist_id");
	XCTAssertEqualObjects(artists.columnKeys[1], @"artist.name");
	XCTAssertEqualObjects([artists objectAtRow:0 column:0], @(1LL));
	XCTAssertEqualObjects([artists objectAtRow:0 column:1], @"AC/DC");

	[db closeConnection:session];
}

- (void)testExecuteSQLReportsSyntaxError {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	BOOL ok = [db executeSQL:@"SELECT * FROM definitely_not_a_table_xyz"
				   fieldKeys:nil
				onConnection:session
			 intoResultTable:table
				   withError:&error];
	XCTAssertFalse(ok);
	XCTAssertNotNil(error);
	XCTAssertEqualObjects(error.domain, @"MADDatabasePostgres");
	XCTAssertNotNil(error.userInfo[@"PostgresSQLStateKey"]);

	[db closeConnection:session];
}

- (void)testExecuteQueryViaDelegateCredentials {
	[self requireServer];
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	db.databaseConnection = [[self class] testConnection];

	NSDictionary<NSString *, NSString *> *settings = [[self class] testSettings];
	MADPostgresCredentialStub *stub = [[MADPostgresCredentialStub alloc] init];
	stub.username = settings[@"user"];
	stub.password = settings[@"password"];
	db.delegate = stub;

	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	MADPostgresTestQuery *query =
		[[MADPostgresTestQuery alloc] initWithSQL:@"SELECT \"genre_id\", \"name\" FROM \"genre\" ORDER BY \"genre_id\" LIMIT 5"
										fieldKeys:@[@"genre.genre_id", @"genre.name"]];
	NSError *error = nil;
	BOOL ok = [db executeQuery:query withDataTable:table andError:&error];
	XCTAssertTrue(ok, @"Expected executeQuery: to succeed, got error: %@", error);
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 5u);
	XCTAssertEqualObjects([table objectAtRow:0 column:0], @(1LL));
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @"Rock");
}

- (void)testExecuteSQLAllPostgresDataTypesRoundTrip {
	[self requireServer];
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = [self openSessionWithDatabase:&db];

	NSString *sql =
		@"SELECT "
		@"TRUE AS col_bool, "
		@"CAST(12 AS SMALLINT) AS col_int2, "
		@"CAST(345678 AS INTEGER) AS col_int4, "
		@"CAST(9876543210 AS BIGINT) AS col_int8, "
		@"CAST(1.5 AS REAL) AS col_float4, "
		@"CAST(2.75 AS DOUBLE PRECISION) AS col_float8, "
		@"CAST(19.99 AS NUMERIC(10,2)) AS col_numeric, "
		@"DATE '2026-10-28' AS col_date, "
		@"TIME '14:35:20' AS col_time, "
		@"TIMESTAMP '2026-10-28 14:35:20' AS col_ts, "
		@" decode('48656c6c6f', 'hex') AS col_bytea, "
		@"CAST('Chinook' AS VARCHAR(20)) AS col_varchar, "
		@"CAST('PostgreSQL' AS TEXT) AS col_text, "
		@"CAST('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' AS UUID) AS col_uuid, "
		@"CAST('{\"k\":1}' AS JSONB) AS col_jsonb, "
		@"CAST(NULL AS TEXT) AS col_null";

	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	BOOL ok = [db executeSQL:sql
				   fieldKeys:nil
				onConnection:session
			 intoResultTable:table
				   withError:&error];
	XCTAssertTrue(ok, @"Expected type round-trip query to succeed, got error: %@", error);
	XCTAssertNil(error);
	XCTAssertEqual([table numberOfRows], 1u);
	XCTAssertEqual([table numberOfColumns], 16u);

	XCTAssertEqualObjects([table objectAtRow:0 column:0], @YES);
	XCTAssertEqualObjects([table objectAtRow:0 column:1], @(12LL));
	XCTAssertEqualObjects([table objectAtRow:0 column:2], @(345678LL));
	XCTAssertEqualObjects([table objectAtRow:0 column:3], @(9876543210LL));
	XCTAssertEqualWithAccuracy([[table objectAtRow:0 column:4] doubleValue], 1.5, 0.0001);
	XCTAssertEqualWithAccuracy([[table objectAtRow:0 column:5] doubleValue], 2.75, 0.0001);
	XCTAssertEqualObjects([table objectAtRow:0 column:6], [NSDecimalNumber decimalNumberWithString:@"19.99"]);

	NSDateComponents *dateComp = [table objectAtRow:0 column:7];
	XCTAssertTrue([dateComp isKindOfClass:[NSDateComponents class]]);
	XCTAssertEqual(dateComp.year, 2026);
	XCTAssertEqual(dateComp.month, 10);
	XCTAssertEqual(dateComp.day, 28);

	NSDateComponents *timeComp = [table objectAtRow:0 column:8];
	XCTAssertTrue([timeComp isKindOfClass:[NSDateComponents class]]);
	XCTAssertEqual(timeComp.hour, 14);
	XCTAssertEqual(timeComp.minute, 35);
	XCTAssertEqual(timeComp.second, 20);

	NSDateComponents *tsComp = [table objectAtRow:0 column:9];
	XCTAssertTrue([tsComp isKindOfClass:[NSDateComponents class]]);
	XCTAssertEqual(tsComp.year, 2026);
	XCTAssertEqual(tsComp.month, 10);
	XCTAssertEqual(tsComp.day, 28);
	XCTAssertEqual(tsComp.hour, 14);
	XCTAssertEqual(tsComp.minute, 35);
	XCTAssertEqual(tsComp.second, 20);

	XCTAssertEqualObjects([table objectAtRow:0 column:10], [@"Hello" dataUsingEncoding:NSUTF8StringEncoding]);
	XCTAssertEqualObjects([table objectAtRow:0 column:11], @"Chinook");
	XCTAssertEqualObjects([table objectAtRow:0 column:12], @"PostgreSQL");
	XCTAssertEqualObjects([table objectAtRow:0 column:13], @"a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11");
	XCTAssertEqualObjects([table objectAtRow:0 column:14], @"{\"k\": 1}");
	XCTAssertEqualObjects([table objectAtRow:0 column:15], [NSNull null]);

	[db closeConnection:session];
}

@end
