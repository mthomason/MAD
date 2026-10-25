//
//  MADMySQLExceptionTests.m
//  MADMySQLTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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

#import "MADMySQLException.h"
#import "MADMySQLCommitException.h"
#import "MADMySQLRollbackException.h"
#import "MADMySQLConnection.h"

@interface MADMySQLExceptionTests : XCTestCase
@end

@implementation MADMySQLExceptionTests

- (MADMySQLConnection *)connectionWithoutAServer {
	return [[MADMySQLConnection alloc] init];
}

- (void)testRaiseWithoutAConnectionHasNoUserInfo {
	@try {
		[MADMySQLException raiseConnection:nil withFormat:@"no connection here"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.name, @"MADMySQLException");
		XCTAssertEqualObjects(exception.reason, @"no connection here");
		XCTAssertNil(exception.userInfo);
	}
}

- (void)testRaiseCarriesTheConnectionInTheUserInfo {
	MADMySQLConnection *connection = [self connectionWithoutAServer];

	@try {
		[MADMySQLException raiseConnection:connection withFormat:@"something went wrong"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqual(exception.userInfo[@"MADMySQLConnection"], connection);
		XCTAssertEqual(exception.userInfo.count, (NSUInteger)1);
	}
}

- (void)testRaiseFormatsItsArguments {
	@try {
		[MADMySQLException raiseConnection:nil withFormat:@"failed at %@ (%d)", @"step", 7];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.reason, @"failed at step (7)");
	}
}

- (void)testSubclassesRaiseUnderTheirOwnNames {
	XCTAssertTrue([MADMySQLCommitException isSubclassOfClass:[MADMySQLException class]]);
	XCTAssertTrue([MADMySQLRollbackException isSubclassOfClass:[MADMySQLException class]]);

	@try {
		[MADMySQLCommitException raiseConnection:nil withFormat:@"commit failed"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MADMySQLException *exception) {
		// The name is the raising class, so a caller can tell a commit failure
		// from a rollback failure even though both are MADMySQLException.
		XCTAssertEqualObjects(exception.name, @"MADMySQLCommitException");
		XCTAssertTrue([exception isKindOfClass:[MADMySQLCommitException class]]);
	}

	@try {
		[MADMySQLRollbackException raiseConnection:nil withFormat:@"rollback failed"];
		XCTFail(@"raiseConnection: must raise");
	} @catch (MADMySQLException *exception) {
		XCTAssertEqualObjects(exception.name, @"MADMySQLRollbackException");
	}
}

- (void)testTheHierarchySharesMADMySQLExceptionsInitialisers {
	MADMySQLCommitException *commit = [[MADMySQLCommitException alloc] initWithName:@"x" reason:@"y" userInfo:nil];
	MADMySQLRollbackException *rollback = [[MADMySQLRollbackException alloc] initWithName:@"x" reason:@"y" userInfo:nil];

	XCTAssertEqualObjects(commit.reason, @"y");
	XCTAssertEqualObjects(rollback.reason, @"y");
}

@end
