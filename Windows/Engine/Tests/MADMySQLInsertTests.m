//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADMySQLInsertTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MADMySQLInsertTests.m: offline coverage for
//  MADMySQLInsert.  The factory and the two guards in -execute are everything
//  that is reachable without a server: past them the class builds and binds a
//  prepared statement on a live handle.  The writing paths are covered in
//  MADMySQLLiveTests.m.
//

#import "MADTestSupport.h"

#import <MADMySQL/MADMySQLInsert.h>
#import <MADMySQL/MADMySQLConnection.h>
#import <MADMySQL/MADMySQLException.h>

// A connection object with no server behind it: its handle is NULL. Safe on
// these paths, which only carry the object around or raise before using it.
static MADMySQLConnection *connectionWithoutAServer(void) {
	return [[MADMySQLConnection alloc] init];
}

static void testFactoryRejectsANilConnection(void) {
	MAD_THROWS_NAMED([MADMySQLInsert insertWithConnection:nil], @"MADMySQLException",
					 "a nil connection is rejected");
}

static void testFactoryStoresTheConnectionAndStartsEmpty(void) {
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connectionWithoutAServer()];

	MAD_PASS(insert != nil, "the factory vends an insert");
	MAD_PASS(insert.table == nil, "the table starts unset");
	MAD_PASS(insert.rowData == nil, "the row data starts unset");
	MAD_PASS(insert.affectedRows == nil, "no affected-row count before the insert runs");
	MAD_PASS(insert.rowid == nil, "no row id before the insert runs");
	MAD_PASS(!insert.ignoreDuplicateErrors, "duplicate errors are not ignored by default");
}

static void testPropertiesAreWriteable(void) {
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connectionWithoutAServer()];

	insert.table = @"mad_scratch";
	insert.rowData = @{@"label": @"alpha"};
	insert.ignoreDuplicateErrors = YES;

	MAD_PASS_EQUAL(insert.table, @"mad_scratch", "the table is stored");
	MAD_PASS_EQUAL(insert.rowData, (@{@"label": @"alpha"}), "the row data is stored");
	MAD_PASS(insert.ignoreDuplicateErrors, "the ignore flag is stored");
}

static void testExecuteWithoutATableRaisesCarryingTheConnection(void) {
	MADMySQLConnection *connection = connectionWithoutAServer();
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connection];
	insert.rowData = @{@"label": @"alpha"};

	BOOL raised = NO;
	@try {
		[insert execute];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.name, @"MADMySQLException", "the exception is a MADMySQLException");
		MAD_PASS_EQUAL(exception.reason, @"No table specified for insert",
					   "the reason names the missing table");
		MAD_PASS(exception.userInfo[@"MADMySQLConnection"] == connection,
				 "the connection rides in the userInfo");
	}
	MAD_PASS(raised, "an insert with no table raises");
}

static void testExecuteWithoutRowDataRaises(void) {
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connectionWithoutAServer()];
	insert.table = @"mad_scratch";

	BOOL raised = NO;
	@try {
		[insert execute];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason, @"No rowData specified for insert",
					   "the reason names the missing row data");
	}
	MAD_PASS(raised, "an insert with no rowData raises");
}

static void testExecuteWithoutTableIsCheckedBeforeRowData(void) {
	// Both are missing: the table guard runs first, so that is the reason.
	MADMySQLInsert *insert = [MADMySQLInsert insertWithConnection:connectionWithoutAServer()];

	BOOL raised = NO;
	@try {
		[insert execute];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason, @"No table specified for insert",
					   "the table guard runs before the rowData guard");
	}
	MAD_PASS(raised, "an insert with neither table nor rowData raises");
}

MAD_TEST_MAIN("MADMySQLInsertTests",
	MAD_TEST(testFactoryRejectsANilConnection),
	MAD_TEST(testFactoryStoresTheConnectionAndStartsEmpty),
	MAD_TEST(testPropertiesAreWriteable),
	MAD_TEST(testExecuteWithoutATableRaisesCarryingTheConnection),
	MAD_TEST(testExecuteWithoutRowDataRaises),
	MAD_TEST(testExecuteWithoutTableIsCheckedBeforeRowData));
