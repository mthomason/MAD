//
//  MADMySQLTruncateTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MADMySQLTruncateTests.m: offline coverage for
//  MADMySQLTruncate -- the two factories and the table-name guard.  The truncate
//  itself is covered in MADMySQLLiveTests.m.
//

#import "MADTestSupport.h"

#import <MADMySQL/MADMySQLTruncate.h>
#import <MADMySQL/MADMySQLConnection.h>
#import <MADMySQL/MADMySQLException.h>

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
static MADMySQLConnection *connectionWithoutAServer(void) {
	return [[MADMySQLConnection alloc] init];
}

static void testFactoryWithoutATableLeavesTheNameUnset(void) {
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connectionWithoutAServer()];

	MAD_PASS(truncate != nil, "the factory vends a truncate");
	MAD_PASS(truncate.tableName == nil, "the table name starts unset");
}

static void testFactoryWithATableStoresIt(void) {
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connectionWithoutAServer()
														   forTable:@"mad_scratch"];

	MAD_PASS_EQUAL(truncate.tableName, @"mad_scratch", "the table name is stored");
}

static void testFactoryAcceptsANilConnection(void) {
	// Unlike MADMySQLInsert/MADMySQLUpdate/MADMySQLDelete, the truncate factory does not
	// check for a nil connection; the object comes back and -execute fails
	// later on. Pinned so the inconsistency is visible.
	MAD_NO_THROW([MADMySQLTruncate truncateWithConnection:nil],
				 "the factory does not reject a nil connection");
	MAD_PASS([MADMySQLTruncate truncateWithConnection:nil forTable:@"mad_scratch"] != nil,
			 "and the table variant still vends an object");
}

static void testTableNameIsWriteable(void) {
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connectionWithoutAServer()];
	truncate.tableName = @"mad_scratch";

	MAD_PASS_EQUAL(truncate.tableName, @"mad_scratch", "the table name is writeable");
}

static void testExecuteWithoutATableNameRaises(void) {
	MADMySQLTruncate *truncate = [MADMySQLTruncate truncateWithConnection:connectionWithoutAServer()];

	BOOL raised = NO;
	@try {
		[truncate execute];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.name, @"MADMySQLException", "the exception is a MADMySQLException");
		MAD_PASS_EQUAL(exception.reason, @"Truncate is missing table name",
					   "the reason names the missing table");
	}
	MAD_PASS(raised, "a truncate with no table raises");
}

MAD_TEST_MAIN("MADMySQLTruncateTests",
	MAD_TEST(testFactoryWithoutATableLeavesTheNameUnset),
	MAD_TEST(testFactoryWithATableStoresIt),
	MAD_TEST(testFactoryAcceptsANilConnection),
	MAD_TEST(testTableNameIsWriteable),
	MAD_TEST(testExecuteWithoutATableNameRaises));
