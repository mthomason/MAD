//
//  MADDatabaseDriverDispatchTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the constructor categories (MADDatabase+Constructor,
//  MADDatabaseConnection+Constructor) over the driver registry (docs/project/ROADMAP.md §5.1):
//  the type decides which driver answers, the driver's Identifier is the document
//  constant RptqDatabaseCredentals.driverID holds, and a driver that this process
//  links is the one that builds the connection and the database.  No connection is
//  ever opened -- the drivers' constructors only fill in descriptors.
//

#import <XCTest/XCTest.h>

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

#import "MADDatabase+Constructor.h"
#import "MADDatabaseConnection+Constructor.h"

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

@interface MADDatabaseDriverDispatchTests : XCTestCase
@end

@implementation MADDatabaseDriverDispatchTests

#pragma mark - Registration

- (void)testTheLinkedDriversRegisterThemselves {
	// This bundle links the three drivers, so all three are here without anything
	// importing them (their +load registers each).
	XCTAssertEqual([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeMySQL], [MADDatabaseConnectionMySql class]);
	XCTAssertEqual([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeTDS], [MADDatabaseConnectionSQLServer class]);
	XCTAssertEqual([MADDatabaseDriverRegistry driverClassForType: MADDatabaseTypeSqlite3], [MADDatabaseConnectionSqlite3 class]);
}

- (void)testIdentifierIsTheStoredDriverName {
	// These strings are in every .mad ever written as driverID, so they are pinned.
	XCTAssertEqualObjects([MADDatabaseConnection Identifier: MADDatabaseTypeMySQL], @"MySQL");
	XCTAssertEqualObjects([MADDatabaseConnection Identifier: MADDatabaseTypeTDS], @"TDS");
	XCTAssertEqualObjects([MADDatabaseConnection Identifier: MADDatabaseTypeSqlite3], @"Sqlite 3");
}

#pragma mark - Connection construction

- (void)testCredentialConstructionDispatchesToTheDriver {
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: MADTestProperties(MADDatabaseTypeMySQL)];

	XCTAssertEqual([connection class], [MADDatabaseConnectionMySql class]);
	XCTAssertEqual(connection.databaseType, MADDatabaseTypeMySQL);
}

- (void)testHostPortConstructionDispatchesToTheDriver {
	MADDatabaseConnection *mysql = [MADDatabaseConnection newDatabaseConnectionWithType: MADDatabaseTypeMySQL
																				  host: @"db.example.com"
																			  database: @"chinook"
																				  port: 3306];
	XCTAssertEqual([mysql class], [MADDatabaseConnectionMySql class]);
	XCTAssertEqualObjects(((MADDatabaseConnectionMySql *)mysql).host, @"db.example.com");
	XCTAssertEqualObjects(((MADDatabaseConnectionMySql *)mysql).database, @"chinook");
	XCTAssertEqual(((MADDatabaseConnectionMySql *)mysql).port, 3306);

	// The TDS switch always passed the one host it was given as the server too.
	MADDatabaseConnection *tds = [MADDatabaseConnection newDatabaseConnectionWithType: MADDatabaseTypeTDS
																				host: @"db.example.com"
																			database: @"chinook"
																				port: 1433];
	XCTAssertEqual([tds class], [MADDatabaseConnectionSQLServer class]);
	XCTAssertEqualObjects(((MADDatabaseConnectionSQLServer *)tds).server, @"db.example.com");
}

- (void)testUrlConstructionIsTheFileDriver {
	NSURL *url = [NSURL fileURLWithPath: @"/tmp/chinook.sqlite3"];
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnectionForUrl: url];

	XCTAssertEqual([connection class], [MADDatabaseConnectionSqlite3 class]);
	XCTAssertEqualObjects(((MADDatabaseConnectionSqlite3 *)connection).databaseUrl, url);
}

#pragma mark - Database construction

- (void)testDatabaseConstructionDispatchesToTheDriver {
	MADDatabaseConnection *connection = [MADDatabaseConnection newDatabaseConnection: MADTestProperties(MADDatabaseTypeMySQL)];
	MADDatabase *database = [MADDatabase newDatabaseWithConnection: connection];

	XCTAssertEqual([database class], [MADDatabaseMySQL class]);
	// The property is a copy: the database holds its own connection descriptor.
	XCTAssertEqual([database.databaseConnection class], [MADDatabaseConnectionMySql class]);
	XCTAssertEqualObjects(database.databaseConnection.connectionString, connection.connectionString);
}

- (void)testDatabaseConstructionForTdsAndSqlite3 {
	MADDatabaseConnection *tds = [MADDatabaseConnection newDatabaseConnectionWithType: MADDatabaseTypeTDS
																				host: @"db.example.com"
																			database: @"chinook"
																				port: 1433];
	XCTAssertEqual([[MADDatabase newDatabaseWithConnection: tds] class], [MADDatabaseSQLServer class]);

	MADDatabaseConnection *sqlite3 = [MADDatabaseConnection newDatabaseConnectionForUrl: [NSURL fileURLWithPath: @"/tmp/chinook.sqlite3"]];
	XCTAssertEqual([[MADDatabase newDatabaseWithConnection: sqlite3] class], [MADDatabaseSqlite3 class]);
}

@end
