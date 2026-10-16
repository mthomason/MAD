//
//  MysqlUpdateTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MysqlUpdateTests.m: offline coverage for
//  MysqlUpdate.  Past the guards, -execute builds its statement and escapes
//  every key through the live session, so the writing paths live in
//  MADMySQLLiveTests.m; the three guards -- table, row data and qualifier --
//  raise before any session call and are covered here.
//
//  The empty-rowData and empty-qualifier range errors were the pinned defects
//  (BUGS.md): the leading ", " and "AND " trims ran against empty buffers, so
//  the intended diagnostics never ran.  Both now raise MysqlException before
//  any buffer is built.
//

#import "MADTestSupport.h"

#import <MADMySQL/MysqlUpdate.h>
#import <MADMySQL/MysqlConnection.h>
#import <MADMySQL/MysqlException.h>

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
static MysqlConnection *connectionWithoutAServer(void) {
	return [[MysqlConnection alloc] init];
}

static void testFactoryRejectsANilConnection(void) {
	MAD_THROWS_NAMED([MysqlUpdate updateWithConnection:nil], @"MysqlException",
					 "a nil connection is rejected");
}

static void testFactoryStoresTheConnectionAndStartsEmpty(void) {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:connectionWithoutAServer()];

	MAD_PASS(update != nil, "the factory vends an update");
	MAD_PASS(update.table == nil, "the table starts unset");
	MAD_PASS(update.rowData == nil, "the row data starts unset");
	MAD_PASS(update.qualifier == nil, "the qualifier starts unset");
	MAD_PASS(update.affectedRows == nil, "no affected-row count before the update runs");
}

static void testExecuteWithoutATableRaises(void) {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:connectionWithoutAServer()];
	update.rowData = @{@"label": @"beta"};
	update.qualifier = @{@"id": @1};

	BOOL raised = NO;
	@try {
		[update execute];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.name, @"MysqlException", "the exception is a MysqlException");
		MAD_PASS_EQUAL(exception.reason, @"table must be specified to perform an update",
					   "the reason names the missing table");
		// This guard passes a nil connection to -raiseConnection:, so there is
		// no connection in the userInfo.
		MAD_PASS(exception.userInfo == nil, "the guard carries no connection");
	}
	MAD_PASS(raised, "an update with no table raises");
}

static void testExecuteWithoutRowDataRaisesTheUpdatesOwnError(void) {
	// BUGS.md: with no rows to set, the column list was still empty when
	// -execute deleted its leading ", ", so the range edit raised before the
	// intended diagnostic could run.
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:connectionWithoutAServer()];
	update.table = @"mad_scratch";
	update.qualifier = @{@"id": @1};

	BOOL raised = NO;
	@try {
		[update execute];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason, @"row data must be specified to perform an update",
					   "the reason names the missing row data");
		// Like the table guard, this one passes a nil connection, so there is no
		// connection in the userInfo.
		MAD_PASS(exception.userInfo == nil, "the guard carries no connection");
	}
	MAD_PASS(raised, "an update with no row data raises the update's own error");
}

static void testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay(void) {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:connectionWithoutAServer()];
	update.table = @"mad_scratch";
	update.rowData = @{};
	update.qualifier = @{@"id": @1};

	MAD_THROWS_NAMED([update execute], @"MysqlException",
					 "an empty rowData dictionary raises the update's own error");
}

static void testExecuteWithoutAQualifierRaisesTheUpdatesOwnError(void) {
	// BUGS.md: a nil qualifier left the WHERE-clause buffer empty, and the
	// four-character delete raised rather than telling the caller to qualify
	// the update.
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:connectionWithoutAServer()];
	update.table = @"mad_scratch";
	update.rowData = @{@"label": @"beta"};

	BOOL raised = NO;
	@try {
		[update execute];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason, @"a qualifier must be specified to perform an update",
					   "the reason names the missing qualifier");
		MAD_PASS(exception.userInfo == nil, "the guard carries no connection");
	}
	MAD_PASS(raised, "an update with no qualifier raises the update's own error");
}

MAD_TEST_MAIN("MysqlUpdateTests",
	MAD_TEST(testFactoryRejectsANilConnection),
	MAD_TEST(testFactoryStoresTheConnectionAndStartsEmpty),
	MAD_TEST(testExecuteWithoutATableRaises),
	MAD_TEST(testExecuteWithoutRowDataRaisesTheUpdatesOwnError),
	MAD_TEST(testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay),
	MAD_TEST(testExecuteWithoutAQualifierRaisesTheUpdatesOwnError));
