//
//  MysqlUpdateTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MysqlUpdateTests.m: offline coverage for
//  MysqlUpdate.  Past the table guard, -execute builds its statement and
//  escapes every key through the live session, so the writing paths live in
//  MADMySQLLiveTests.m -- including the nil-qualifier crash, which only
//  reproduces once the session can escape.
//
//  The empty-rowData crash is the pinned defect (BUGS.md): with no rows to
//  set, the column list is still empty when -execute deletes its leading ", ",
//  so NSMakeRange(0, 2) is out of bounds before any MySQL call.  Apple's
//  __NSCFString raises NSInvalidArgumentException for that edit; GNUstep's
//  NSMutableString raises NSRangeException for the same one.  The defect, not
//  the Foundation spelling, is what is pinned here.
//

#import "MADTestSupport.h"

#import <MADMySQL/MysqlUpdate.h>
#import <MADMySQL/MysqlConnection.h>
#import <MADMySQL/MysqlException.h>

#if __APPLE__
#define MAD_UPDATE_RANGE_EXCEPTION NSInvalidArgumentException
#else
#define MAD_UPDATE_RANGE_EXCEPTION NSRangeException
#endif

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

static void testExecuteWithoutRowDataRaisesARangeError(void) {
	// BUGS.md: with no rows to set, the column list is still empty when
	// -execute deletes its leading ", ", so the intended "empty update" error
	// never runs.  The range edit against the empty mutable string raises
	// (see the note at the top of the file for the platform spelling).
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:connectionWithoutAServer()];
	update.table = @"mad_scratch";
	update.qualifier = @{@"id": @1};

	MAD_THROWS_NAMED([update execute], MAD_UPDATE_RANGE_EXCEPTION,
					 "an update with no rowData raises the range error");
}

static void testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay(void) {
	MysqlUpdate *update = [MysqlUpdate updateWithConnection:connectionWithoutAServer()];
	update.table = @"mad_scratch";
	update.rowData = @{};
	update.qualifier = @{@"id": @1};

	MAD_THROWS_NAMED([update execute], MAD_UPDATE_RANGE_EXCEPTION,
					 "an empty rowData dictionary raises the range error");
}

MAD_TEST_MAIN("MysqlUpdateTests",
	MAD_TEST(testFactoryRejectsANilConnection),
	MAD_TEST(testFactoryStoresTheConnectionAndStartsEmpty),
	MAD_TEST(testExecuteWithoutATableRaises),
	MAD_TEST(testExecuteWithoutRowDataRaisesARangeError),
	MAD_TEST(testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay));
