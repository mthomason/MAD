//
//  MysqlInsertTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for MysqlInsert. The factory and the two guards in
//  -execute are everything that is reachable without a server: past them the
//  class builds and binds a prepared statement on a live handle. The writing
//  paths are covered in MADMySQLLiveTests.m.
//

#import <XCTest/XCTest.h>

#import "MysqlInsert.h"
#import "MysqlConnection.h"
#import "MysqlException.h"

@interface MysqlInsertTests : XCTestCase
@end

@implementation MysqlInsertTests

// A connection object with no server behind it: its handle is NULL. Safe on
// these paths, which only carry the object around or raise before using it.
- (MysqlConnection *)connectionWithoutAServer {
	return [[MysqlConnection alloc] init];
}

- (void)testFactoryRejectsANilConnection {
	XCTAssertThrowsSpecificNamed([MysqlInsert insertWithConnection:nil],
								 MysqlException, @"MysqlException");
}

- (void)testFactoryStoresTheConnectionAndStartsEmpty {
	MysqlInsert *insert = [MysqlInsert insertWithConnection:[self connectionWithoutAServer]];

	XCTAssertNotNil(insert);
	XCTAssertNil(insert.table);
	XCTAssertNil(insert.rowData);
	XCTAssertNil(insert.affectedRows);
	XCTAssertNil(insert.rowid);
	XCTAssertFalse(insert.ignoreDuplicateErrors);
}

- (void)testPropertiesAreWriteable {
	MysqlInsert *insert = [MysqlInsert insertWithConnection:[self connectionWithoutAServer]];

	insert.table = @"mad_scratch";
	insert.rowData = @{@"label": @"alpha"};
	insert.ignoreDuplicateErrors = YES;

	XCTAssertEqualObjects(insert.table, @"mad_scratch");
	XCTAssertEqualObjects(insert.rowData, (@{@"label": @"alpha"}));
	XCTAssertTrue(insert.ignoreDuplicateErrors);
}

- (void)testExecuteWithoutATableRaisesCarryingTheConnection {
	MysqlConnection *connection = [self connectionWithoutAServer];
	MysqlInsert *insert = [MysqlInsert insertWithConnection:connection];
	insert.rowData = @{@"label": @"alpha"};

	@try {
		[insert execute];
		XCTFail(@"An insert with no table must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.name, @"MysqlException");
		XCTAssertEqualObjects(exception.reason, @"No table specified for insert");
		XCTAssertEqual(exception.userInfo[@"MysqlConnection"], connection);
	}
}

- (void)testExecuteWithoutRowDataRaises {
	MysqlInsert *insert = [MysqlInsert insertWithConnection:[self connectionWithoutAServer]];
	insert.table = @"mad_scratch";

	@try {
		[insert execute];
		XCTFail(@"An insert with no rowData must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.reason, @"No rowData specified for insert");
	}
}

- (void)testExecuteWithoutTableIsCheckedBeforeRowData {
	// Both are missing: the table guard runs first, so that is the reason.
	MysqlInsert *insert = [MysqlInsert insertWithConnection:[self connectionWithoutAServer]];

	@try {
		[insert execute];
		XCTFail(@"Expected a raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.reason, @"No table specified for insert");
	}
}

@end
