//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADMySQLExceptionTests.m
//  Linux/Tests
//
//  Ported from MADMySQLTests/MADMySQLExceptionTests.m: offline coverage for the
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

#import <MADMySQL/MADMySQLException.h>
#import <MADMySQL/MADMySQLCommitException.h>
#import <MADMySQL/MADMySQLRollbackException.h>
#import <MADMySQL/MADMySQLConnection.h>

static MADMySQLConnection *connectionWithoutAServer(void) {
	return [[MADMySQLConnection alloc] init];
}

static void testRaiseWithoutAConnectionHasNoUserInfo(void) {
	BOOL raised = NO;
	@try {
		[MADMySQLException raiseConnection:nil withFormat:@"no connection here"];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.name, @"MADMySQLException", "the name is the raising class");
		MAD_PASS_EQUAL(exception.reason, @"no connection here", "the reason is the format");
		MAD_PASS(exception.userInfo == nil, "no connection means no userInfo");
	}
	MAD_PASS(raised, "raiseConnection: raises");
}

static void testRaiseCarriesTheConnectionInTheUserInfo(void) {
	MADMySQLConnection *connection = connectionWithoutAServer();

	BOOL raised = NO;
	@try {
		[MADMySQLException raiseConnection:connection withFormat:@"something went wrong"];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS(exception.userInfo[@"MADMySQLConnection"] == connection,
				 "the connection rides in the userInfo");
		MAD_PASS(exception.userInfo.count == 1u, "the userInfo carries one entry");
	}
	MAD_PASS(raised, "raiseConnection: raises");
}

static void testRaiseFormatsItsArguments(void) {
	BOOL raised = NO;
	@try {
		[MADMySQLException raiseConnection:nil withFormat:@"failed at %@ (%d)", @"step", 7];
	} @catch (MADMySQLException *exception) {
		raised = YES;
		MAD_PASS_EQUAL(exception.reason, @"failed at step (7)", "the format arguments are applied");
	}
	MAD_PASS(raised, "raiseConnection: raises");
}

static void testSubclassesRaiseUnderTheirOwnNames(void) {
	MAD_PASS([MADMySQLCommitException isSubclassOfClass:[MADMySQLException class]],
			 "MADMySQLCommitException is a MADMySQLException");
	MAD_PASS([MADMySQLRollbackException isSubclassOfClass:[MADMySQLException class]],
			 "MADMySQLRollbackException is a MADMySQLException");

	BOOL commitRaised = NO;
	@try {
		[MADMySQLCommitException raiseConnection:nil withFormat:@"commit failed"];
	} @catch (MADMySQLException *exception) {
		// The name is the raising class, so a caller can tell a commit failure
		// from a rollback failure even though both are MADMySQLException.
		commitRaised = YES;
		MAD_PASS_EQUAL(exception.name, @"MADMySQLCommitException", "the commit failure names its class");
		MAD_PASS([exception isKindOfClass:[MADMySQLCommitException class]], "and its class");
	}
	MAD_PASS(commitRaised, "a commit failure raises");

	BOOL rollbackRaised = NO;
	@try {
		[MADMySQLRollbackException raiseConnection:nil withFormat:@"rollback failed"];
	} @catch (MADMySQLException *exception) {
		rollbackRaised = YES;
		MAD_PASS_EQUAL(exception.name, @"MADMySQLRollbackException", "the rollback failure names its class");
	}
	MAD_PASS(rollbackRaised, "a rollback failure raises");
}

static void testTheHierarchySharesMADMySQLExceptionsInitialisers(void) {
	MADMySQLCommitException *commit = [[MADMySQLCommitException alloc] initWithName:@"x" reason:@"y" userInfo:nil];
	MADMySQLRollbackException *rollback = [[MADMySQLRollbackException alloc] initWithName:@"x" reason:@"y" userInfo:nil];

	MAD_PASS_EQUAL(commit.reason, @"y", "the commit exception keeps its reason");
	MAD_PASS_EQUAL(rollback.reason, @"y", "the rollback exception keeps its reason");
}

MAD_TEST_MAIN("MADMySQLExceptionTests",
	MAD_TEST(testRaiseWithoutAConnectionHasNoUserInfo),
	MAD_TEST(testRaiseCarriesTheConnectionInTheUserInfo),
	MAD_TEST(testRaiseFormatsItsArguments),
	MAD_TEST(testSubclassesRaiseUnderTheirOwnNames),
	MAD_TEST(testTheHierarchySharesMADMySQLExceptionsInitialisers));
