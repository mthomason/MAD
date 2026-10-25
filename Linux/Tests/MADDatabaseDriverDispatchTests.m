//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDatabaseDriverDispatchTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDatabaseDriverDispatchTests.m: the constructor
//  categories over the driver registry (ROADMAP.md §5.1).  This executable links
//  libmad, so it is where the drivers' self-registration is pinned -- and, on
//  Linux, where the linkage that makes it happen is pinned: nothing in the
//  framework sources names a driver class, so the drivers are here because
//  Compat/MADDriverLinkage.m names them (see Linux/README.md).
//

#import "MADTestSupport.h"

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADAPI/MADDatabaseDriverRegistry.h>
#import <MADAPI/MADDatabaseType.h>

#import <MADMySQL/MADDatabaseConnectionMySql.h>
#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADTdsClient/MADDatabaseConnectionSQLServer.h>
#import <MADTdsClient/MADDatabaseSQLServer.h>

#import <MAD/MADDatabase+Constructor.h>
#import <MAD/MADDatabaseConnection+Constructor.h>

#pragma mark - Credentials double

/// The credential chain the connectors read, with no store behind it.
@interface MADTestConnectionProperties : NSObject <MADConnectionsPropertiesProtocol>
@property (nonatomic, assign, readwrite) MADDatabaseType databaseType;
@property (nonatomic, copy, readwrite) NSString *host;
@property (nonatomic, copy, readwrite) NSString *server;
@property (nonatomic, copy, readwrite) NSString *database;
@property (nonatomic, assign, readwrite) NSInteger port;
@end

@implementation MADTestConnectionProperties
@end

static MADTestConnectionProperties *MADTestProperties(MADDatabaseType type) {
	MADTestConnectionProperties *properties = [[MADTestConnectionProperties alloc] init];
	properties.databaseType = type;
	properties.host = @"db.example.com";
	properties.server = @"db.example.com";
	properties.database = @"chinook";
	properties.port = 3306;
	return properties;
}

#pragma mark - Tests

static void testTheLinkedDriversRegisterThemselves(void) {
	MAD_PASS([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeMySQL] == [MADDatabaseConnectionMySql class], "MySQL registered");
	MAD_PASS([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeTDS] == [MADDatabaseConnectionSQLServer class], "TDS registered");
	MAD_PASS([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeSqlite3] == [MADDatabaseConnectionSqlite3 class], "Sqlite3 registered");
}

// A driver's work is reached by *message send* through its categories, which the
// static linker has no reason to pull in unless the archive is whole-archived
// (Linux/CMakeLists.txt).  The CLI aborted on live MySQL the day that was not true --
// .objc_category_MADMySQLFetchDataTable was simply absent -- so the categories the data
// path needs are asserted here, where the arrangement is under test.  See BUGS.md.
static void testTheDriversCategoriesAreLinked(void) {
	Class fetch = NSClassFromString(@"MADMySQLFetch");
	MAD_NEED(fetch != Nil, @"MADMySQLFetch is not linked in");
	if (fetch == Nil) return;
	MAD_PASS([fetch instancesRespondToSelector:
			  NSSelectorFromString(@"fetchWithCommand:dataTable:onConnection:extendedNames:error:")],
			 "the MySQL fetch category survived the link");

	Class query = NSClassFromString(@"MADQuery");
	MAD_PASS([query instancesRespondToSelector: NSSelectorFromString(@"whereClauseWithRowIds:")],
			 "the Sqlite3 query category survived the link");
	MAD_PASS([query instancesRespondToSelector: NSSelectorFromString(@"whereClauseWithParameters:")],
			 "the other half of the Sqlite3 query category is there too");
}

static void testIdentifierIsTheStoredDriverName(void) {
	// These strings are in every .mad ever written as driverID, so they are pinned.
	MAD_PASS_EQUAL([MADDatabaseConnection Identifier: MADDatabaseTypeMySQL], @"MySQL", "MySQL's stored identifier");
	MAD_PASS_EQUAL([MADDatabaseConnection Identifier: MADDatabaseTypeTDS], @"TDS", "TDS's stored identifier");
	MAD_PASS_EQUAL([MADDatabaseConnection Identifier: MADDatabaseTypeSqlite3], @"Sqlite 3", "Sqlite3's stored identifier");
}

static void testCredentialConstructionDispatchesToTheDriver(void) {
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: MADTestProperties(MADDatabaseTypeMySQL)];
	MAD_PASS_EQUAL(NSStringFromClass([connection class]), @"MADDatabaseConnectionMySql", "the MySQL driver built the connection");
	MAD_PASS(connection.databaseType == MADDatabaseTypeMySQL, "the connection carries the type");
}

static void testHostPortConstructionDispatchesToTheDriver(void) {
	MADDatabaseConnection *mysql = [MADDatabaseConnection newDatabaseConnectionWithType: MADDatabaseTypeMySQL
																				  host: @"db.example.com"
																			  database: @"chinook"
																				  port: 3306];
	MAD_PASS_EQUAL(NSStringFromClass([mysql class]), @"MADDatabaseConnectionMySql", "the type-based constructor builds MySQL");
	MAD_PASS_EQUAL(((MADDatabaseConnectionMySql *)mysql).host, @"db.example.com", "the host survives");
	MAD_PASS_EQUAL(((MADDatabaseConnectionMySql *)mysql).database, @"chinook", "the database survives");
	MAD_PASS(((MADDatabaseConnectionMySql *)mysql).port == 3306, "the port survives");

	// The TDS switch always passed the one host it was given as the server too.
	MADDatabaseConnection *tds = [MADDatabaseConnection newDatabaseConnectionWithType: MADDatabaseTypeTDS
																				host: @"db.example.com"
																			database: @"chinook"
																				port: 1433];
	MAD_PASS_EQUAL(NSStringFromClass([tds class]), @"MADDatabaseConnectionSQLServer", "the type-based constructor builds SQL Server");
	MAD_PASS_EQUAL(((MADDatabaseConnectionSQLServer *)tds).server, @"db.example.com", "the host is the server too");
}

static void testUrlConstructionIsTheFileDriver(void) {
	NSURL *url = [NSURL fileURLWithPath: @"/tmp/chinook.sqlite3"];
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnectionForUrl: url];
	MAD_PASS_EQUAL(NSStringFromClass([connection class]), @"MADDatabaseConnectionSqlite3", "the URL constructor builds Sqlite3");
	MAD_PASS_EQUAL(((MADDatabaseConnectionSqlite3 *)connection).databaseUrl, url, "the URL survives");
}

static void testDatabaseConstructionDispatchesToTheDriver(void) {
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: MADTestProperties(MADDatabaseTypeMySQL)];
	MADDatabase *database = [MADDatabase newDatabaseWithConnection: connection];
	MAD_PASS_EQUAL(NSStringFromClass([database class]), @"MADDatabaseMySQL", "the MySQL driver built the database");
	// The property is a copy: the database holds its own connection descriptor.
	MAD_PASS_EQUAL(NSStringFromClass([database.databaseConnection class]), @"MADDatabaseConnectionMySql", "the connection is on the database");
	MAD_PASS_EQUAL(database.databaseConnection.connectionString, connection.connectionString, "the connection's description survives the copy");
}

static void testDatabaseConstructionForTdsAndSqlite3(void) {
	MADDatabaseConnection *tds = [MADDatabaseConnection newDatabaseConnectionWithType: MADDatabaseTypeTDS
																				host: @"db.example.com"
																			database: @"chinook"
																				port: 1433];
	MAD_PASS_EQUAL(NSStringFromClass([[MADDatabase newDatabaseWithConnection: tds] class]), @"MADDatabaseSQLServer", "the TDS driver built the database");

	MADDatabaseConnection *sqlite3 = [MADDatabaseConnection newDatabaseConnectionForUrl: [NSURL fileURLWithPath: @"/tmp/chinook.sqlite3"]];
	MAD_PASS_EQUAL(NSStringFromClass([[MADDatabase newDatabaseWithConnection: sqlite3] class]), @"MADDatabaseSqlite3", "the Sqlite3 driver built the database");
}

MAD_TEST_MAIN("MADDatabaseDriverDispatchTests",
	MAD_TEST(testTheLinkedDriversRegisterThemselves),
	MAD_TEST(testTheDriversCategoriesAreLinked),
	MAD_TEST(testIdentifierIsTheStoredDriverName),
	MAD_TEST(testCredentialConstructionDispatchesToTheDriver),
	MAD_TEST(testHostPortConstructionDispatchesToTheDriver),
	MAD_TEST(testUrlConstructionIsTheFileDriver),
	MAD_TEST(testDatabaseConstructionDispatchesToTheDriver),
	MAD_TEST(testDatabaseConstructionForTdsAndSqlite3));
