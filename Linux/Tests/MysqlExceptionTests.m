//
//  MysqlExceptionTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MysqlExceptionTests.m: offline coverage for the
//  exception hierarchy.  +raiseConnection:withFormat: is how every class in
//  this framework reports a programming error, and both subclasses inherit it
//  -- raising under their own class name, which is what callers see when a
//  commit or a rollback fails.
//
//  +errorWithConnection:domain:andCode: is not covered here: it reads
//  mysql_errno()/mysql_error() straight off the handle, so it needs a live
//  session (MADMySQLLiveTests.m).
//

#import "MADTestSupport.h"

#import <MADMySQL/MysqlException.h>
#import <MADMySQL/MysqlCommitException.h>
#import <MADMySQL/MysqlRollbackException.h>
#import <MADMySQL/MysqlConnection.h>

static MysqlConnection *connectionWithoutAServer(void) {
	return [[MysqlConnection alloc] init];
}

static void testRaiseWithoutAConnectionHasNoUserInfo(void) {
	BOOL raised = NO;
	@try {
		[MysqlException raiseConnection:nil withFormat:@"no connection here"];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.name, @"MysqlException", "the name is the raising class");
		MAD_PASS_EQUAL(exception.reason, @"no connection here", "the reason is the format");
		MAD_PASS(exception.userInfo == nil, "no connection means no userInfo");
	}
	MAD_PASS(raised, "raiseConnection: raises");
}

static void testRaiseCarriesTheConnectionInTheUserInfo(void) {
	MysqlConnection *connection = connectionWithoutAServer();

	BOOL raised = NO;
	@try {
		[MysqlException raiseConnection:connection withFormat:@"something went wrong"];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS(exception.userInfo[@"MysqlConnection"] == connection,
				 "the connection rides in the userInfo");
		MAD_PASS(exception.userInfo.count == 1u, "the userInfo carries one entry");
	}
	MAD_PASS(raised, "raiseConnection: raises");
}

static void testRaiseFormatsItsArguments(void) {
	BOOL raised = NO;
	@try {
		[MysqlException raiseConnection:nil withFormat:@"failed at %@ (%d)", @"step", 7];
	} @catch (MysqlException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason, @"failed at step (7)", "the format arguments are applied");
	}
	MAD_PASS(raised, "raiseConnection: raises");
}

static void testSubclassesRaiseUnderTheirOwnNames(void) {
	MAD_PASS([MysqlCommitException isSubclassOfClass:[MysqlException class]],
			 "MysqlCommitException is a MysqlException");
	MAD_PASS([MysqlRollbackException isSubclassOfClass:[MysqlException class]],
			 "MysqlRollbackException is a MysqlException");

	BOOL commitRaised = NO;
	@try {
		[MysqlCommitException raiseConnection:nil withFormat:@"commit failed"];
	} @catch (MysqlException *exception) {
		// The name is the raising class, so a caller can tell a commit failure
		// from a rollback failure even though both are MysqlException.
		commitRaised = YES;
		MAD_PASS_EQUAL(exception.name, @"MysqlCommitException", "the commit failure names its class");
		MAD_PASS([exception isKindOfClass:[MysqlCommitException class]], "and its class");
	}
	MAD_PASS(commitRaised, "a commit failure raises");

	BOOL rollbackRaised = NO;
	@try {
		[MysqlRollbackException raiseConnection:nil withFormat:@"rollback failed"];
	} @catch (MysqlException *exception) {
		rollbackRaised = YES;
		MAD_PASS_EQUAL(exception.name, @"MysqlRollbackException", "the rollback failure names its class");
	}
	MAD_PASS(rollbackRaised, "a rollback failure raises");
}

static void testTheHierarchySharesMysqlExceptionsInitialisers(void) {
	MysqlCommitException *commit = [[MysqlCommitException alloc] initWithName:@"x" reason:@"y" userInfo:nil];
	MysqlRollbackException *rollback = [[MysqlRollbackException alloc] initWithName:@"x" reason:@"y" userInfo:nil];

	MAD_PASS_EQUAL(commit.reason, @"y", "the commit exception keeps its reason");
	MAD_PASS_EQUAL(rollback.reason, @"y", "the rollback exception keeps its reason");
}

MAD_TEST_MAIN("MysqlExceptionTests",
	MAD_TEST(testRaiseWithoutAConnectionHasNoUserInfo),
	MAD_TEST(testRaiseCarriesTheConnectionInTheUserInfo),
	MAD_TEST(testRaiseFormatsItsArguments),
	MAD_TEST(testSubclassesRaiseUnderTheirOwnNames),
	MAD_TEST(testTheHierarchySharesMysqlExceptionsInitialisers));
