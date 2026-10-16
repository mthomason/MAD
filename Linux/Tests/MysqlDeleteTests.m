//
//  MysqlDeleteTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MysqlDeleteTests.m: offline coverage for
//  MysqlDelete -- the factory, the statement it builds, and the two guards in
//  -execute.  A real delete is covered in MADMySQLLiveTests.m.
//

#import "MADTestSupport.h"

#import <MADMySQL/MysqlDelete.h>
#import <MADMySQL/MysqlConnection.h>
#import <MADMySQL/MysqlException.h>

// Implemented in MysqlDelete.m but declared in no header.
@interface MysqlDelete (MADMySQLTestsInternal)
- (NSString *)command;
@end

// A connection object with no server behind it: its handle is NULL. Nothing
// here reaches a MySQL call.
static MysqlConnection *connectionWithoutAServer(void) {
	return [[MysqlConnection alloc] init];
}

static void testFactoryRejectsANilConnection(void) {
	MAD_THROWS_NAMED([MysqlDelete deleteWithConnection:nil], @"MysqlException",
					 "a nil connection is rejected");
}

static void testFactoryStoresTheConnectionAndStartsEmpty(void) {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:connectionWithoutAServer()];

	MAD_PASS(delete != nil, "the factory vends a delete");
	MAD_PASS(delete.tableName == nil, "the table name starts unset");
	MAD_PASS(delete.qualifier == nil, "the qualifier starts unset");
	MAD_PASS(delete.affectedRows == nil, "no affected-row count before the delete runs");
}

static void testCommandPairsTheTableWithTheQualifier(void) {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:connectionWithoutAServer()];
	delete.tableName = @"mad_scratch";
	delete.qualifier = @"id=1";

	MAD_PASS_EQUAL([delete command], @"DELETE FROM mad_scratch WHERE id=1",
				   "the table and qualifier pair up");
}

static void testCommandFormatsAMissingQualifierAsTheLiteralNull(void) {
	// The qualifier is pasted into the statement with %@, so a nil one becomes
	// the string "(null)" rather than an error.  -execute refuses to run it.
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:connectionWithoutAServer()];
	delete.tableName = @"mad_scratch";

	MAD_PASS_EQUAL([delete command], @"DELETE FROM mad_scratch WHERE (null)",
				   "a missing qualifier formats as (null)");
}

static void testExecuteWithoutATableNameRaises(void) {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:connectionWithoutAServer()];
	delete.qualifier = @"id=1";

	BOOL raised = NO;
	@try {
		[delete execute];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.name, @"MysqlException", "the exception is a MysqlException");
		MAD_PASS_EQUAL(exception.reason, @"Delete is missing table name",
					   "the reason names the missing table");
	}
	MAD_PASS(raised, "a delete with no table raises");
}

static void testExecuteWithoutAQualifierRaises(void) {
	MysqlDelete *delete = [MysqlDelete deleteWithConnection:connectionWithoutAServer()];
	delete.tableName = @"mad_scratch";

	BOOL raised = NO;
	@try {
		[delete execute];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason,
					   @"Delete is unqualified. Use TRUNCATE to wipe out tables",
					   "the reason points at TRUNCATE");
	}
	MAD_PASS(raised, "an unqualified delete raises");
}

MAD_TEST_MAIN("MysqlDeleteTests",
	MAD_TEST(testFactoryRejectsANilConnection),
	MAD_TEST(testFactoryStoresTheConnectionAndStartsEmpty),
	MAD_TEST(testCommandPairsTheTableWithTheQualifier),
	MAD_TEST(testCommandFormatsAMissingQualifierAsTheLiteralNull),
	MAD_TEST(testExecuteWithoutATableNameRaises),
	MAD_TEST(testExecuteWithoutAQualifierRaises));
