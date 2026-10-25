//
//  MADNotificationDidReadRowsTests.m
//  MADAPITests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Tier 3 coverage for MADNotificationDidReadRows, the singleton that posts
//  row-read progress notifications while a database result set is being read.
//  Exercises the singleton identity, the copy contract, and the posted
//  notification's name and userInfo payload.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADNotificationDidReadRows.h>

@interface MADNotificationDidReadRowsTests : XCTestCase
@end

@implementation MADNotificationDidReadRowsTests

- (void)testSharedObjectIsSingleton {
	MADNotificationDidReadRows *a = [MADNotificationDidReadRows sharedObject];
	MADNotificationDidReadRows *b = [MADNotificationDidReadRows sharedObject];
	XCTAssertNotNil(a);
	XCTAssertEqual(a, b);
}

- (void)testCopyReturnsSelf {
	MADNotificationDidReadRows *a = [MADNotificationDidReadRows sharedObject];
	XCTAssertEqual([a copy], a);
}

- (void)testDatabaseReadRowPostsNotification {
	MADNotificationDidReadRows *notifier = [MADNotificationDidReadRows sharedObject];

	__block NSNumber *capturedRow = nil;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationDidReadRowsName
																	object:nil
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		capturedRow = note.userInfo[MADDatabaseNumberOfRowsReadKey];
	}];

	[notifier database:nil readRow:123];
	[[NSNotificationCenter defaultCenter] removeObserver:observer];

	XCTAssertEqualObjects(capturedRow, @123);
}

@end
