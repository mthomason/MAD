//
//  MADMySQLInsertTests.m
//  MADMySQLTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Offline coverage for MADMySQLInsert. The factory and the two guards in
//  -execute are everything that is reachable without a server: past them the
//  class builds and binds a prepared statement on a live handle. The writing
//  paths are covered in MADMySQLLiveTests.m.
//

#import <XCTest/XCTest.h>

#import "MADMySQLInsert.h"
#import "MADMySQLConnection.h"
#import "MADMySQLException.h"

@interface MADMySQLInsertTests : XCTestCase
@end

@implementation MADMySQLInsertTests

// A connection object with no server behind it: its handle is NULL. Safe on
// these paths, which only carry the object around or raise before using it.
- (MADMySQLConnection *)connectionWithoutAServer {
	return [[MADMySQLConnection alloc] init];
}

- (void)testFactoryRejectsANilConnection {
	XCTAssertThrowsSpecificNamed([MADMySQLInsert insertWithConnection:nil],
								 MADMySQLException, @"MADMySQLException");
}

- (void)testFactoryStoresTheConnectionAndStartsEmpty {
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:[self connectionWithoutAServer]];

	XCTAssertNotNil(insert);
	XCTAssertNil(insert.table);
	XCTAssertNil(insert.rowData);
	XCTAssertNil(insert.affectedRows);
	XCTAssertNil(insert.rowid);
	XCTAssertFalse(insert.ignoreDuplicateErrors);
}

- (void)testPropertiesAreWriteable {
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:[self connectionWithoutAServer]];

	insert.table = @"mad_scratch";
	insert.rowData = @{@"label": @"alpha"};
	insert.ignoreDuplicateErrors = YES;

	XCTAssertEqualObjects(insert.table, @"mad_scratch");
	XCTAssertEqualObjects(insert.rowData, (@{@"label": @"alpha"}));
	XCTAssertTrue(insert.ignoreDuplicateErrors);
}

- (void)testExecuteWithoutATableRaisesCarryingTheConnection {
	MADMySQLConnection *connection = [self connectionWithoutAServer];
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.rowData = @{@"label": @"alpha"};

	@try {
		[insert execute];
		XCTFail(@"An insert with no table must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.name, @"MADMySQLException");
		XCTAssertEqualObjects(exception.reason, @"No table specified for insert");
		XCTAssertEqual(exception.userInfo[@"MADMySQLConnection"], connection);
	}
}

- (void)testExecuteWithoutRowDataRaises {
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:[self connectionWithoutAServer]];
	insert.table = @"mad_scratch";

	@try {
		[insert execute];
		XCTFail(@"An insert with no rowData must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.reason, @"No rowData specified for insert");
	}
}

- (void)testExecuteWithoutTableIsCheckedBeforeRowData {
	// Both are missing: the table guard runs first, so that is the reason.
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:[self connectionWithoutAServer]];

	@try {
		[insert execute];
		XCTFail(@"Expected a raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.reason, @"No table specified for insert");
	}
}

@end
