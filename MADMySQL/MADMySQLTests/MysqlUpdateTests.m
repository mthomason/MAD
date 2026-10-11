//
//  MysqlUpdateTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MysqlUpdate. Past the table guard, -execute builds its
//  statement and escapes every key through the live session, so the writing
//  paths live in MADMySQLLiveTests.m -- including the nil-qualifier crash,
//  which only reproduces once the session can escape.
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

- (void)testExecuteWithoutRowDataRaisesAnInvalidArgumentException {
	// BUGS.md: with no rows to set, the column list is still empty when
	// -execute deletes its leading ", ", so the intended "empty update" error
	// never runs.  NSMakeRange(0, 2) against an empty mutable string raises
	// NSInvalidArgumentException ("Range or index out of bounds").
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:[self connectionWithoutAServer]];
	update.table = @"mad_scratch";
	update.qualifier = @{@"id": @1};

	XCTAssertThrowsSpecificNamed([update execute], NSException, NSInvalidArgumentException);
}

- (void)testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:[self connectionWithoutAServer]];
	update.table = @"mad_scratch";
	update.rowData = @{};
	update.qualifier = @{@"id": @1};

	XCTAssertThrowsSpecificNamed([update execute], NSException, NSInvalidArgumentException);
}

@end
