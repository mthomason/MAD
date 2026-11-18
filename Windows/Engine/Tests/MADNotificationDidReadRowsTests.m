//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADNotificationDidReadRowsTests.m
//  Linux/Tests
//
//  Ported from MADAPITests/MADNotificationDidReadRowsTests.m: the singleton
//  that posts row-read progress notifications -- its identity, the copy
//  contract, and the posted notification's name and payload.
//

#import "MADTestSupport.h"
#import <MADAPI/MADNotificationDidReadRows.h>

static void testSharedObjectIsSingleton(void) {
	MADNotificationDidReadRows *a = [MADNotificationDidReadRows sharedObject];
	MADNotificationDidReadRows *b = [MADNotificationDidReadRows sharedObject];
	MAD_PASS(a != nil, "the shared object exists");
	MAD_PASS(a == b, "the shared object is a singleton");
}

static void testCopyReturnsSelf(void) {
	MADNotificationDidReadRows *a = [MADNotificationDidReadRows sharedObject];
	MAD_PASS([a copy] == a, "the copy is the shared object itself");
}

static void testDatabaseReadRowPostsNotification(void) {
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

	MAD_PASS_EQUAL(capturedRow, @123, "the posted notification carries the row number");
}

MAD_TEST_MAIN("MADNotificationDidReadRowsTests",
	MAD_TEST(testSharedObjectIsSingleton),
	MAD_TEST(testCopyReturnsSelf),
	MAD_TEST(testDatabaseReadRowPostsNotification));
