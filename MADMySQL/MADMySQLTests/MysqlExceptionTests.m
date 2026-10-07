//
//  MysqlExceptionTests.m
//  MADMySQLTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Offline coverage for the exception hierarchy. +raiseConnection:withFormat:
//  is how every class in this framework reports a programming error, and both
//  subclasses inherit it -- raising under their own class name, which is what
//  callers see when a commit or a rollback fails.
//
//  +errorWithConnection:domain:andCode: is not covered here: it reads
//  mysql_errno()/mysql_error() straight off the handle, so it needs a live
//  session (MADMySQLLiveTests.m).
//

#import <XCTest/XCTest.h>

#import "MysqlException.h"
#import "MysqlCommitException.h"
#import "MysqlRollbackException.h"
#import "MysqlConnection.h"

@interface MysqlExceptionTests : XCTestCase
@end

@implementation MysqlExceptionTests

- (MysqlConnection *)connectionWithoutAServer {
	return [[MysqlConnection alloc] init];
}

- (void)testRaiseWithoutAConnectionHasNoUserInfo {
	@try {
		[MysqlException raiseConnection:nil withFormat:@"no connection here"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.name, @"MysqlException");
		XCTAssertEqualObjects(exception.reason, @"no connection here");
		XCTAssertNil(exception.userInfo);
	}
}

- (void)testRaiseCarriesTheConnectionInTheUserInfo {
	MysqlConnection *connection = [self connectionWithoutAServer];

	@try {
		[MysqlException raiseConnection:connection withFormat:@"something went wrong"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqual(exception.userInfo[@"MysqlConnection"], connection);
		XCTAssertEqual(exception.userInfo.count, (NSUInteger)1);
	}
}

- (void)testRaiseFormatsItsArguments {
	@try {
		[MysqlException raiseConnection:nil withFormat:@"failed at %@ (%d)", @"step", 7];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.reason, @"failed at step (7)");
	}
}

- (void)testSubclassesRaiseUnderTheirOwnNames {
	XCTAssertTrue([MysqlCommitException isSubclassOfClass:[MysqlException class]]);
	XCTAssertTrue([MysqlRollbackException isSubclassOfClass:[MysqlException class]]);

	@try {
		[MysqlCommitException raiseConnection:nil withFormat:@"commit failed"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MysqlException *exception) {
		// The name is the raising class, so a caller can tell a commit failure
		// from a rollback failure even though both are MysqlException.
		XCTAssertEqualObjects(exception.name, @"MysqlCommitException");
		XCTAssertTrue([exception isKindOfClass:[MysqlCommitException class]]);
	}

	@try {
		[MysqlRollbackException raiseConnection:nil withFormat:@"rollback failed"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MysqlException *exception) {
		XCTAssertEqualObjects(exception.name, @"MysqlRollbackException");
	}
}

- (void)testTheHierarchySharesMysqlExceptionsInitialisers {
	MysqlCommitException *commit = [[MysqlCommitException alloc] initWithName:@"x" reason:@"y" userInfo:nil];
	MysqlRollbackException *rollback = [[MysqlRollbackException alloc] initWithName:@"x" reason:@"y" userInfo:nil];

	XCTAssertEqualObjects(commit.reason, @"y");
	XCTAssertEqualObjects(rollback.reason, @"y");
}

@end
