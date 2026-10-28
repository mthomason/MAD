//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADPostgresLiveTests.m
//  Linux/Tests
//
//  Ported from MADPostgresTests/MADPostgresLiveTests.m: integration tests for
//  MADPostgres that talk to a real PostgreSQL server -- the local instance
//  documented in docs/project/DEVELOPER.md (127.0.0.1:5432, mad, mad_test_pw,
//  chinook).  Every credential can be overridden with MAD_PG_TEST_*, and the
//  suite SKIPS when the server cannot be reached.
//

#import "MADTestSupport.h"
#include <math.h>

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

#import <MADPostgres/MADDatabasePostgres.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>
#import <MADPostgres/MADPostgresConnection.h>
#import <MADPostgres/MADDataTypePostgres.h>

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
@property (nonatomic, retain) NSMutableDictionary<NSString *, id> *fields;
@property (nonatomic, retain) NSMutableArray *fieldKeys;
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

#pragma mark - Fixtures

static NSDictionary<NSString *, NSString *> *testSettings(void) {
	NSDictionary<NSString *, NSString *> *env = [[NSProcessInfo processInfo] environment];
	return @{
		@"host"     : env[@"MAD_PG_TEST_HOST"]     ?: @"127.0.0.1",
		@"port"     : env[@"MAD_PG_TEST_PORT"]     ?: @"5432",
		@"user"     : env[@"MAD_PG_TEST_USER"]     ?: @"mad",
		@"password" : env[@"MAD_PG_TEST_PASSWORD"] ?: @"mad_test_pw",
		@"database" : env[@"MAD_PG_TEST_DATABASE"] ?: @"chinook",
	};
}

static MADDatabaseConnectionPostgres *testConnection(void) {
	NSDictionary<NSString *, NSString *> *settings = testSettings();
	NSInteger port = [settings[@"port"] integerValue];
	return [MADDatabaseConnectionPostgres connectionWithHost:settings[@"host"]
														port:(port > 0 ? port : 5432)
												 andDatabase:settings[@"database"]];
}

static MADCredential *testCredential(void) {
	NSDictionary<NSString *, NSString *> *settings = testSettings();
	return [[MADCredential alloc] initWithUsername:settings[@"user"]
									   andPassword:settings[@"password"]];
}

static BOOL serverIsAvailable(void) {
	static BOOL available = NO;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
		MADDatabaseConnectionPostgres *conn = testConnection();
		db.databaseConnection = conn;
		NSError *error = nil;
		id session = [db connectWithConnection:conn
									credentals:testCredential()
							   connectionError:&error];
		available = (session != nil && error == nil);
		if (session != nil) {
			[db closeConnection:session];
		}
	});
	return available;
}

#define REQUIRE_SERVER() \
	MAD_SKIP(!serverIsAvailable(), \
			 @"No PostgreSQL server reachable; see docs/project/DEVELOPER.md for the expected test instance.")

static MADPostgresConnection *openSessionWithDatabase(MADDatabasePostgres **outDatabase) {
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	MADDatabaseConnectionPostgres *conn = testConnection();
	db.databaseConnection = conn;
	NSError *error = nil;
	MADPostgresConnection *session = [db connectWithConnection:conn
													credentals:testCredential()
											   connectionError:&error];
	MAD_PASS(session != nil, "connected to PostgreSQL");
	MAD_PASS(error == nil, "no connection error");
	if (outDatabase != NULL) {
		*outDatabase = db;
	}
	return session;
}

#pragma mark - Connection

static void testConnectToLocalServerSucceeds(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);
	MAD_PASS(session.isConnected, "session isConnected is YES");
	MAD_PASS(session.pgConn != NULL, "session pgConn is non-NULL");
	[db closeConnection:session];
	MAD_PASS(!session.isConnected, "session isConnected is NO after closeConnection:");
}

static void testConnectionDescriptionMentionsHostAndConnectedState(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);
	NSString *description = [session description];
	MAD_PASS([description containsString:testSettings()[@"host"]], "description mentions host");
	MAD_PASS([description containsString:@"YES"], "description mentions connected state");
	[db closeConnection:session];
}

static void testConnectWithWrongPasswordReportsAuthenticationFailure(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	MADDatabaseConnectionPostgres *conn = testConnection();
	MADCredential *badCred = [[MADCredential alloc] initWithUsername:testSettings()[@"user"]
														 andPassword:@"definitely-not-the-password"];
	NSError *error = nil;
	id session = [db connectWithConnection:conn credentals:badCred connectionError:&error];
	MAD_PASS(session == nil, "wrong password returns nil session");
	MAD_PASS(error != nil, "wrong password populates error");
	MAD_PASS_EQUAL(error.domain, @"MADDatabasePostgres", "error domain is MADDatabasePostgres");
}

static void testConnectWithUnknownDatabaseReportsError(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	NSDictionary<NSString *, NSString *> *settings = testSettings();
	MADDatabaseConnectionPostgres *conn =
		[MADDatabaseConnectionPostgres connectionWithHost:settings[@"host"]
													 port:[settings[@"port"] integerValue]
											  andDatabase:@"mad_nonexistent_database_xyz"];
	NSError *error = nil;
	id session = [db connectWithConnection:conn credentals:testCredential() connectionError:&error];
	MAD_PASS(session == nil, "unknown database returns nil session");
	MAD_PASS(error != nil, "unknown database populates error");
	MAD_PASS_EQUAL(error.domain, @"MADDatabasePostgres", "error domain is MADDatabasePostgres");
}

#pragma mark - Live Escaping

static void testLiveEscapeLiteralAndIdentifier(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

	MAD_PASS_EQUAL([session escapeLiteral:@"O'Brien"], @"'O''Brien'", "PQescapeLiteral escapes single quote");
	MAD_PASS_EQUAL([session escapeIdentifier:@"album_id"], @"\"album_id\"", "PQescapeIdentifier quotes identifier");
	MAD_PASS_EQUAL([session escapeIdentifier:@"a\"b"], @"\"a\"\"b\"", "PQescapeIdentifier doubles embedded quote");
	MAD_PASS_EQUAL([db newSafeLiteral:@"AC/DC's Best"], @"'AC/DC''s Best'", "newSafeLiteral uses live connection");

	[db closeConnection:session];
}

#pragma mark - Schema Discovery

static void testGetTablesFromConnectionFindsAllChinookTables(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

	NSError *error = nil;
	NSArray<MADDatabaseTable *> *tables = [db getTablesFromConnection:session error:&error];
	MAD_PASS(error == nil, "getTablesFromConnection error is nil");
	MAD_PASS(tables != nil, "getTablesFromConnection returned tables");

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
		MAD_PASS([names containsObject:expectedName], "Chinook table is present");
	}
	MAD_PASS(![names containsObject:@"pg_type"], "system catalog tables are excluded");

	[db closeConnection:session];
}

static void testEnumerateTablesFromConnectionStreamsTablesAndHonorsStop(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

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

	MAD_PASS(completedSuccess, "enumerateTablesFromConnection completed with success");
	MAD_PASS(completedError == nil, "enumerateTablesFromConnection error is nil");
	MAD_PASS(collected.count == 3u, "enumerateTablesFromConnection stopped at 3 tables");

	[db closeConnection:session];
}

static void testGetTablesUsesDelegateCredentials(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	db.databaseConnection = testConnection();

	NSDictionary<NSString *, NSString *> *settings = testSettings();
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

	MAD_PASS(ok, "getTables: succeeded");
	MAD_PASS(err == nil, "getTables: error is nil");
	MAD_PASS(tables.count >= 11u, "getTables: found at least 11 Chinook tables");
}

static void testFieldsForTableDiscoversColumnsTypesNullabilityAndPrimaryKey(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

	NSError *error = nil;
	NSArray<MADDatabaseField *> *invoiceFields = [db fieldsForTable:@"invoice" connection:session error:&error];
	MAD_PASS(error == nil, "fieldsForTable:invoice error is nil");
	MAD_PASS(invoiceFields.count == 9u, "invoice has 9 columns");

	NSMutableDictionary<NSString *, MADDatabaseField *> *byName = [NSMutableDictionary dictionary];
	for (MADDatabaseField *f in invoiceFields) {
		byName[f.name] = f;
	}

	MADDatabaseField *invoiceId = byName[@"invoice_id"];
	MAD_PASS(invoiceId != nil, "invoice_id found");
	MAD_PASS(invoiceId.fieldType == MADDataTypeInteger, "invoice_id is Integer");
	MAD_PASS(invoiceId.primaryKey, "invoice_id is primary key");

	MADDatabaseField *invoiceDate = byName[@"invoice_date"];
	MAD_PASS(invoiceDate != nil, "invoice_date found");
	MAD_PASS(invoiceDate.fieldType == MADDataTypeDateTime, "invoice_date is DateTime");
	MAD_PASS(!invoiceDate.primaryKey, "invoice_date is not primary key");

	MADDatabaseField *billingAddress = byName[@"billing_address"];
	MAD_PASS(billingAddress != nil, "billing_address found");
	MAD_PASS(billingAddress.fieldType == MADDataTypeString, "billing_address is String");
	MAD_PASS(billingAddress.width == 70, "billing_address width is 70");

	MADDatabaseField *total = byName[@"total"];
	MAD_PASS(total != nil, "total found");
	MAD_PASS(total.fieldType == MADDataTypeDecimal, "total is Decimal");
	MAD_PASS(total.width == 10, "total precision is 10");
	MAD_PASS(total.decimals == 2, "total scale is 2");

	NSArray<MADDatabaseField *> *ptFields = [db fieldsForTable:@"playlist_track" connection:session error:&error];
	MAD_PASS(error == nil, "fieldsForTable:playlist_track error is nil");
	MAD_PASS(ptFields.count == 2u, "playlist_track has 2 columns");
	MAD_PASS(ptFields[0].primaryKey && ptFields[1].primaryKey, "composite primary key columns marked");

	[db closeConnection:session];
}

static void testNonPublicSchemaTableDiscoveryAndFields(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

	PGresult *res = PQexec(session.pgConn,
		"DROP SCHEMA IF EXISTS mad_pg_probe CASCADE;"
		"CREATE SCHEMA mad_pg_probe;"
		"CREATE TABLE mad_pg_probe.metrics ("
		"  metric_id INT PRIMARY KEY,"
		"  label VARCHAR(50) NOT NULL,"
		"  score NUMERIC(8,2)"
		");"
		"INSERT INTO mad_pg_probe.metrics VALUES (1, 'apdex', 98.50);");
	MAD_PASS(PQresultStatus(res) == PGRES_COMMAND_OK, "created mad_pg_probe schema and table");
	PQclear(res);

	@try {
		NSError *error = nil;
		NSArray<MADDatabaseTable *> *tables = [db getTablesFromConnection:session error:&error];
		MAD_PASS(error == nil, "getTablesFromConnection error is nil");
		NSMutableArray<NSString *> *tableNames = [NSMutableArray array];
		for (MADDatabaseTable *t in tables) {
			[tableNames addObject:t.name];
		}
		MAD_PASS([tableNames containsObject:@"mad_pg_probe.metrics"], "non-public table discovered as schema.table");

		NSArray<MADDatabaseField *> *fields = [db fieldsForTable:@"mad_pg_probe.metrics"
													  connection:session
														   error:&error];
		MAD_PASS(error == nil, "fieldsForTable:mad_pg_probe.metrics error is nil");
		MAD_PASS(fields.count == 3u, "mad_pg_probe.metrics has 3 columns");
		MAD_PASS_EQUAL(fields[0].name, @"metric_id", "column 0 is metric_id");
		MAD_PASS(fields[0].primaryKey, "metric_id is primary key");
		MAD_PASS(fields[0].fieldType == MADDataTypeInteger, "metric_id is Integer");
		MAD_PASS_EQUAL(fields[1].name, @"label", "column 1 is label");
		MAD_PASS(fields[1].fieldType == MADDataTypeString, "label is String");
		MAD_PASS(fields[1].width == 50, "label width is 50");
		MAD_PASS_EQUAL(fields[2].name, @"score", "column 2 is score");
		MAD_PASS(fields[2].fieldType == MADDataTypeDecimal, "score is Decimal");
		MAD_PASS(fields[2].width == 8 && fields[2].decimals == 2, "score precision and scale match");

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
		MAD_PASS(ok, "query against schema-qualified table succeeded");
		MAD_PASS([resultTable numberOfRows] == 1u, "resultTable has 1 row");
		MAD_PASS_EQUAL([resultTable objectAtRow:0 column:0], @(1LL), "metric_id is 1");
		MAD_PASS_EQUAL([resultTable objectAtRow:0 column:1], @"apdex", "label is apdex");
		MAD_PASS_EQUAL([resultTable objectAtRow:0 column:2],
					   [NSDecimalNumber decimalNumberWithString:@"98.50"], "score is 98.50");
	} @finally {
		PGresult *cleanup = PQexec(session.pgConn, "DROP SCHEMA IF EXISTS mad_pg_probe CASCADE;");
		PQclear(cleanup);
		[db closeConnection:session];
	}
}

#pragma mark - Query Execution and Data Types

static void testExecuteSQLReadsChinookArtistsAndTracks(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

	MADDataTable *artists = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	BOOL ok = [db executeSQL:@"SELECT \"artist_id\", \"name\" FROM \"artist\" ORDER BY \"artist_id\""
				   fieldKeys:@[@"artist.artist_id", @"artist.name"]
				onConnection:session
			 intoResultTable:artists
				   withError:&error];
	MAD_PASS(ok, "artist query succeeded");
	MAD_PASS(error == nil, "artist query error is nil");
	MAD_PASS([artists numberOfRows] == 275u, "Chinook has 275 artists");
	MAD_PASS([artists numberOfColumns] == 2u, "result has 2 columns");
	MAD_PASS_EQUAL(artists.columnKeys[0], @"artist.artist_id", "column 0 name uses fieldKeys");
	MAD_PASS_EQUAL(artists.columnKeys[1], @"artist.name", "column 1 name uses fieldKeys");
	MAD_PASS_EQUAL([artists objectAtRow:0 column:0], @(1LL), "artist 1 id is 1");
	MAD_PASS_EQUAL([artists objectAtRow:0 column:1], @"AC/DC", "artist 1 name is AC/DC");

	[db closeConnection:session];
}

static void testExecuteSQLReportsSyntaxError(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

	MADDataTable *table = [[MADDataTableVirtual alloc] initWithId:1];
	NSError *error = nil;
	BOOL ok = [db executeSQL:@"SELECT * FROM definitely_not_a_table_xyz"
				   fieldKeys:nil
				onConnection:session
			 intoResultTable:table
				   withError:&error];
	MAD_PASS(!ok, "invalid query returns NO");
	MAD_PASS(error != nil, "invalid query populates error");
	MAD_PASS_EQUAL(error.domain, @"MADDatabasePostgres", "error domain is MADDatabasePostgres");
	MAD_PASS(error.userInfo[@"PostgresSQLStateKey"] != nil, "error includes PostgresSQLStateKey");

	[db closeConnection:session];
}

static void testExecuteQueryViaDelegateCredentials(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = [[MADDatabasePostgres alloc] init];
	db.databaseConnection = testConnection();

	NSDictionary<NSString *, NSString *> *settings = testSettings();
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
	MAD_PASS(ok, "executeQuery: succeeded");
	MAD_PASS(error == nil, "executeQuery: error is nil");
	MAD_PASS([table numberOfRows] == 5u, "genre LIMIT 5 returned 5 rows");
	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @(1LL), "genre 1 id is 1");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @"Rock", "genre 1 name is Rock");
}

static void testExecuteSQLAllPostgresDataTypesRoundTrip(void) {
	REQUIRE_SERVER();
	MADDatabasePostgres *db = nil;
	MADPostgresConnection *session = openSessionWithDatabase(&db);

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
		@"decode('48656c6c6f', 'hex') AS col_bytea, "
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
	MAD_PASS(ok, "all-types query succeeded");
	MAD_PASS(error == nil, "all-types query error is nil");
	MAD_PASS([table numberOfRows] == 1u, "all-types query returned 1 row");
	MAD_PASS([table numberOfColumns] == 16u, "all-types query returned 16 columns");

	MAD_PASS_EQUAL([table objectAtRow:0 column:0], @YES, "col_bool is YES");
	MAD_PASS_EQUAL([table objectAtRow:0 column:1], @(12LL), "col_int2 is 12");
	MAD_PASS_EQUAL([table objectAtRow:0 column:2], @(345678LL), "col_int4 is 345678");
	MAD_PASS_EQUAL([table objectAtRow:0 column:3], @(9876543210LL), "col_int8 is 9876543210");
	MAD_PASS(fabs([[table objectAtRow:0 column:4] doubleValue] - 1.5) < 0.0001, "col_float4 is 1.5");
	MAD_PASS(fabs([[table objectAtRow:0 column:5] doubleValue] - 2.75) < 0.0001, "col_float8 is 2.75");
	MAD_PASS_EQUAL([table objectAtRow:0 column:6], [NSDecimalNumber decimalNumberWithString:@"19.99"], "col_numeric is 19.99");

	NSDateComponents *dateComp = [table objectAtRow:0 column:7];
	MAD_PASS([dateComp isKindOfClass:[NSDateComponents class]], "col_date is NSDateComponents");
	MAD_PASS(dateComp.year == 2026 && dateComp.month == 10 && dateComp.day == 28, "col_date components match");

	NSDateComponents *timeComp = [table objectAtRow:0 column:8];
	MAD_PASS([timeComp isKindOfClass:[NSDateComponents class]], "col_time is NSDateComponents");
	MAD_PASS(timeComp.hour == 14 && timeComp.minute == 35 && timeComp.second == 20, "col_time components match");

	NSDateComponents *tsComp = [table objectAtRow:0 column:9];
	MAD_PASS([tsComp isKindOfClass:[NSDateComponents class]], "col_ts is NSDateComponents");
	MAD_PASS(tsComp.year == 2026 && tsComp.month == 10 && tsComp.day == 28 &&
			 tsComp.hour == 14 && tsComp.minute == 35 && tsComp.second == 20, "col_ts components match");

	MAD_PASS_EQUAL([table objectAtRow:0 column:10], [@"Hello" dataUsingEncoding:NSUTF8StringEncoding], "col_bytea is Hello");
	MAD_PASS_EQUAL([table objectAtRow:0 column:11], @"Chinook", "col_varchar is Chinook");
	MAD_PASS_EQUAL([table objectAtRow:0 column:12], @"PostgreSQL", "col_text is PostgreSQL");
	MAD_PASS_EQUAL([table objectAtRow:0 column:13], @"a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "col_uuid matches");
	MAD_PASS_EQUAL([table objectAtRow:0 column:14], @"{\"k\": 1}", "col_jsonb matches");
	MAD_PASS_EQUAL([table objectAtRow:0 column:15], [NSNull null], "col_null is NSNull");

	[db closeConnection:session];
}

MAD_TEST_MAIN("MADPostgresLiveTests",
	MAD_TEST(testConnectToLocalServerSucceeds),
	MAD_TEST(testConnectionDescriptionMentionsHostAndConnectedState),
	MAD_TEST(testConnectWithWrongPasswordReportsAuthenticationFailure),
	MAD_TEST(testConnectWithUnknownDatabaseReportsError),
	MAD_TEST(testLiveEscapeLiteralAndIdentifier),
	MAD_TEST(testGetTablesFromConnectionFindsAllChinookTables),
	MAD_TEST(testEnumerateTablesFromConnectionStreamsTablesAndHonorsStop),
	MAD_TEST(testGetTablesUsesDelegateCredentials),
	MAD_TEST(testFieldsForTableDiscoversColumnsTypesNullabilityAndPrimaryKey),
	MAD_TEST(testNonPublicSchemaTableDiscoveryAndFields),
	MAD_TEST(testExecuteSQLReadsChinookArtistsAndTracks),
	MAD_TEST(testExecuteSQLReportsSyntaxError),
	MAD_TEST(testExecuteQueryViaDelegateCredentials),
	MAD_TEST(testExecuteSQLAllPostgresDataTypesRoundTrip));
