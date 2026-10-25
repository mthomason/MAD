//
//  MADNotificationProgressTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADNotificationProgress: the singleton that posts progress
//  notifications, plus its notification-name/key constants.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADNotificationProgress.h>
#import <MADFoundation/MADProgress.h>

@interface MADNotificationProgressTests : XCTestCase
@end

@implementation MADNotificationProgressTests

- (void)testSharedObjectIsSingleton {
	MADNotificationProgress *a = [MADNotificationProgress sharedObject];
	MADNotificationProgress *b = [MADNotificationProgress sharedObject];
	XCTAssertNotNil(a);
	XCTAssertEqual(a, b);
}

- (void)testCopyReturnsSelf {
	MADNotificationProgress *a = [MADNotificationProgress sharedObject];
	XCTAssertEqual([a copy], a);
}

- (void)testNotificationConstants {
	XCTAssertEqualObjects(MADNotificationProgressIdentifier, @"MADProgressNotification");
	XCTAssertEqualObjects(MADNotificationProgressKey, @"p");
}

- (void)testUpdateProgressOfObjectPostsNotification {
	MADNotificationProgress *notifier = [MADNotificationProgress sharedObject];
	// The singleton throttles posts to 1/60s; back off to let the throttle pass.
	[NSThread sleepForTimeInterval:0.1];

	__block id capturedObject = nil;
	__block MADProgress *capturedProgress = nil;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MADNotificationProgressIdentifier
																	object:nil
																	 queue:nil
																usingBlock:^(NSNotification *note) {
		capturedObject = note.object;
		capturedProgress = note.userInfo[MADNotificationProgressKey];
	}];

	[notifier updateProgressOfObject:self withMessage:@"hello" progress:0.75f];
	[[NSNotificationCenter defaultCenter] removeObserver:observer];

	XCTAssertEqual(capturedObject, self);
	XCTAssertNotNil(capturedProgress);
	XCTAssertEqualObjects(capturedProgress.message, @"hello");
	XCTAssertEqual(capturedProgress.progress, 0.75f);
}

@end
