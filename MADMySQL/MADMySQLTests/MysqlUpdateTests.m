//
//  MysqlUpdateTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MysqlUpdate.  Past the guards, -execute builds its
//  statement and escapes every key through the live session, so the writing
//  paths live in MADMySQLLiveTests.m; the three guards -- table, row data and
//  qualifier -- raise before any session call and are covered here.
//

#import <XCTest/XCTest.h>

#import "MysqlUpdate.h"
#import "MysqlConnection.h"
#import "MysqlException.h"

@interface MysqlUpdateTests : XCTestCase
@end

@implementation MysqlUpdateTests

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
- (MysqlConnection *)connectionWithoutAServer {
	return [[MysqlConnection alloc] init];
}

- (void)testFactoryRejectsANilConnection {
	XCTAssertThrowsSpecificNamed([MysqlUpdate updateWithConnection:nil],
								 MysqlException, @"MysqlException");
}

- (void)testFactoryStoresTheConnectionAndStartsEmpty {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:[self connectionWithoutAServer]];

	XCTAssertNotNil(update);
	XCTAssertNil(update.table);
	XCTAssertNil(update.rowData);
	XCTAssertNil(update.qualifier);
	XCTAssertNil(update.affectedRows);
}

- (void)testExecuteWithoutATableRaises {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:[self connectionWithoutAServer]];
	update.rowData = @{@"label": @"beta"};
	update.qualifier = @{@"id": @1};

	@try {
		[update execute];
		XCTFail(@"An update with no table must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.name, @"MysqlException");
		XCTAssertEqualObjects(exception.reason, @"table must be specified to perform an update");
		// This guard passes a nil connection to -raiseConnection:, so there is
		// no connection in the userInfo.
		XCTAssertNil(exception.userInfo);
	}
}

- (void)testExecuteWithoutRowDataRaisesTheUpdatesOwnError {
	// BUGS.md: with no rows to set, the column list was still empty when -execute
	// deleted its leading ", ", so NSMakeRange(0, 2) raised
	// NSInvalidArgumentException instead of the class's own diagnostic.
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:[self connectionWithoutAServer]];
	update.table = @"mad_scratch";
	update.qualifier = @{@"id": @1};

	@try {
		[update execute];
		XCTFail(@"An update with no row data must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.reason, @"row data must be specified to perform an update");
		// Like the table guard, this one passes a nil connection, so there is no
		// connection in the userInfo.
		XCTAssertNil(exception.userInfo);
	}
}

- (void)testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:[self connectionWithoutAServer]];
	update.table = @"mad_scratch";
	update.rowData = @{};
	update.qualifier = @{@"id": @1};

	XCTAssertThrowsSpecificNamed([update execute], MysqlException, @"MysqlException");
}

- (void)testExecuteWithoutAQualifierRaisesTheUpdatesOwnError {
	// BUGS.md: a nil qualifier left the WHERE-clause buffer empty, and the
	// four-character delete raised NSInvalidArgumentException rather than the
	// "forgot the WHERE clause" diagnostic the caller needs.
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:[self connectionWithoutAServer]];
	update.table = @"mad_scratch";
	update.rowData = @{@"label": @"beta"};

	@try {
		[update execute];
		XCTFail(@"An update with no qualifier must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.reason, @"a qualifier must be specified to perform an update");
		XCTAssertNil(exception.userInfo);
	}
}

@end
